package io.github.jakiwz.aether.incidents;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

import java.time.OffsetDateTime;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/**
 * HEL-501 end to end on the demo dataset: an incident is opened OPEN with a fresh code, the server
 * time, its reporter, a first timeline event and an audit row; an unknown base persists nothing.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("demo")
@WithMockUser(username = "crew.conti", authorities = {"INCIDENT_READ", "INCIDENT_REPORT"})
@Testcontainers
@Transactional // every incident is rolled back
class IncidentOpeningIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16-alpine");

    private static final String AIRLOCK = """
            {"colonyCode":"ARS-01","title":" Airlock pressure drop ","description":"Pressure fell to 96 kPa.",
             "severity":"HIGH"}""";

    @Autowired
    MockMvcTester mvc;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void opensAnIncidentThatIsThenRetrievable() {
        OffsetDateTime before = OffsetDateTime.now();

        MvcTestResult result = open(AIRLOCK);

        assertThat(result).hasStatus(HttpStatus.CREATED)
                .bodyJson().isLenientlyEqualTo("""
                        {"title":"Airlock pressure drop","severity":"HIGH","status":"OPEN",
                         "colonyCode":"ARS-01","reportedBy":"crew.conti"}""");
        String code = jdbc.queryForObject("SELECT code FROM aether.incident WHERE title = 'Airlock pressure drop'",
                String.class);
        assertThat(code).matches("INC-\\d{4,}").isNotIn("INC-0001", "INC-0002", "INC-0003", "INC-0004",
                "INC-0005", "INC-0006");
        assertThat(result).hasHeader("Location", "http://localhost/api/v1/incidents/" + code);
        OffsetDateTime openedAt = jdbc.queryForObject("SELECT opened_at FROM aether.incident WHERE code = ?",
                OffsetDateTime.class, code);
        assertThat(openedAt).isAfterOrEqualTo(before.minusSeconds(1)).isBeforeOrEqualTo(OffsetDateTime.now());

        assertThat(mvc.get().uri("/api/v1/incidents/{code}", code.toLowerCase()))
                .hasStatusOk()
                .bodyJson().extractingPath("$.code").isEqualTo(code);
        assertThat(mvc.get().uri("/api/v1/incidents"))
                .hasStatusOk()
                .bodyJson().extractingPath("$.items[0].code").isEqualTo(code);
    }

    @Test
    void recordsTheReportAsTheFirstTimelineEventAndInTheAuditTrail() {
        open(AIRLOCK);

        assertThat(jdbc.queryForObject("""
                SELECT e.event_type || ' ' || a.username FROM aether.incident_event e
                JOIN aether.incident i ON i.id_incident = e.id_incident
                JOIN aether.user_account a ON a.id_account = e.created_by
                WHERE i.title = 'Airlock pressure drop'""", String.class)).isEqualTo("OPENED crew.conti");
        assertThat(jdbc.queryForObject("""
                SELECT e.action || ' ' || (e.new_value_json->>'status') || ' ' || (e.new_value_json->>'severity')
                FROM aether.audit_event e JOIN aether.incident i ON i.code = e.entity_id
                WHERE e.entity_type = 'INCIDENT' AND i.title = 'Airlock pressure drop'""", String.class))
                .isEqualTo("INCIDENT_OPENED OPEN HIGH");
    }

    @Test
    void givesEachIncidentItsOwnCode() {
        open(AIRLOCK);
        open(AIRLOCK);

        assertThat(jdbc.queryForObject("""
                SELECT count(DISTINCT code) FROM aether.incident WHERE title = 'Airlock pressure drop'""",
                Long.class)).isEqualTo(2L);
    }

    @Test
    void rejectsAnUnknownBaseAndPersistsNothing() {
        assertThat(open(AIRLOCK.replace("ARS-01", "NOPE-01")))
                .hasStatus(HttpStatus.CONFLICT)
                .bodyJson().extractingPath("$.code").isEqualTo("INCIDENT_COLONY_NOT_FOUND");

        assertThat(jdbc.queryForObject("SELECT count(*) FROM aether.incident WHERE title = 'Airlock pressure drop'",
                Long.class)).isZero();
    }

    @Test
    void rejectsAnInvalidSeverity() {
        assertThat(open(AIRLOCK.replace("\"HIGH\"", "\"SEVERE\""))).hasStatus(HttpStatus.BAD_REQUEST);
    }

    @Test
    void grantsReportingToEveryOperationalRoleButTheAuditor() {
        assertThat(jdbc.queryForList("""
                SELECT r.code FROM aether.app_role r
                JOIN aether.role_permission rp ON rp.id_role = r.id_role
                JOIN aether.permission p ON p.id_permission = rp.id_permission
                WHERE p.code = 'INCIDENT_REPORT' ORDER BY r.code""", String.class))
                .containsExactly("ADMIN", "COLONY_COMMANDER", "CREW", "LOGISTICS", "MAINTENANCE",
                        "MISSION_CONTROLLER", "SCIENTIST");
    }

    private MvcTestResult open(String body) {
        return mvc.post().uri("/api/v1/incidents").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(body).exchange();
    }
}
