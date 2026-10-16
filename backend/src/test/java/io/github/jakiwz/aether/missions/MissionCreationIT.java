package io.github.jakiwz.aether.missions;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Map;
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
 * PHX-201 end to end on the demo dataset: a valid mission is drafted with its objective and its
 * attributed history row, and a reused code or an unusable base is rejected with a stable code.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("demo")
@WithMockUser(username = "mc.rossi", authorities = {"MISSION_READ", "MISSION_MANAGE"})
@Testcontainers
@Transactional // every creation is rolled back
class MissionCreationIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16-alpine");

    private static final OffsetDateTime START = OffsetDateTime.now(ZoneOffset.UTC).plusDays(40).withNano(0);

    private static final String JEZERO = """
            {"code":"phx-020","title":" Jezero delta survey ","description":"  ","objective":"Map the delta front",
             "type":"EXPLORATION","originColonyCode":"ARS-01","plannedStartAt":"%s","plannedEndAt":"%s",
             "priority":"HIGH","safetyLevel":"ELEVATED"}""".formatted(START, START.plusDays(2));

    @Autowired
    MockMvcTester mvc;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void draftsAMissionThatIsThenRetrievable() {
        assertThat(create(JEZERO)).hasStatus(HttpStatus.CREATED);

        assertThat(mvc.get().uri("/api/v1/missions/PHX-020"))
                .hasStatusOk()
                .bodyJson().isLenientlyEqualTo("""
                        {"code":"PHX-020","title":"Jezero delta survey","description":null,
                         "objectives":["Map the delta front"],"type":"EXPLORATION","originColonyCode":"ARS-01",
                         "status":"DRAFT","priority":"HIGH","safetyLevel":"ELEVATED","createdBy":"mc.rossi"}""");
        assertThat(mvc.get().uri("/api/v1/missions?size=100"))
                .bodyJson().extractingPath("$.items[*].code").asArray().contains("PHX-001", "PHX-020");
    }

    @Test
    void recordsTheInitialStatusWithItsAuthor() {
        create(JEZERO);

        Map<String, Object> row = jdbc.queryForMap("""
                SELECT h.previous_status, h.new_status, a.username
                FROM aether.mission_status_history h
                JOIN aether.mission m ON m.id_mission = h.id_mission
                JOIN aether.user_account a ON a.id_account = h.changed_by
                WHERE m.code = 'PHX-020'""");
        assertThat(row).containsEntry("previous_status", null)
                .containsEntry("new_status", "DRAFT")
                .containsEntry("username", "mc.rossi");
    }

    @Test
    void rejectsAnExistingCodeWhateverItsCase() {
        assertProblem(create(JEZERO.replace("phx-020", "phx-001")), "MISSION_CODE_TAKEN");
    }

    @Test
    void rejectsAnUnknownBase() {
        assertProblem(create(JEZERO.replace("ARS-01", "NOPE-01")), "ORIGIN_COLONY_NOT_FOUND");
    }

    @Test
    void rejectsAnInactiveBase() {
        jdbc.update("INSERT INTO aether.colony(code, name, status, active) VALUES ('OLD-01', 'Old Outpost', 'INACTIVE', false)");

        assertProblem(create(JEZERO.replace("ARS-01", "OLD-01")), "ORIGIN_COLONY_INACTIVE");
    }

    @Test
    void rejectsAnIncoherentWindowAndPersistsNothing() {
        MvcTestResult result = create(JEZERO.replace(START.plusDays(2).toString(), START.minusHours(1).toString()));

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST)
                .bodyJson().extractingPath("$.errors[0].field").isEqualTo("plannedEndAt");
        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM aether.mission WHERE code = 'PHX-020'", Long.class)).isZero();
    }

    private MvcTestResult create(String body) {
        return mvc.post().uri("/api/v1/missions").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(body)
                .exchange();
    }

    private static void assertProblem(MvcTestResult result, String code) {
        assertThat(result).hasStatus(HttpStatus.CONFLICT)
                .bodyJson().extractingPath("$.code").isEqualTo(code);
    }
}
