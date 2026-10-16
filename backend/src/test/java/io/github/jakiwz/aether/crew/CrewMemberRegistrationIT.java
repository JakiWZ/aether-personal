package io.github.jakiwz.aether.crew;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/**
 * ARES-103 end to end on the demo dataset: a valid member is persisted and retrievable, a reused
 * code or email and an unusable base are rejected with a stable code.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("demo")
@Testcontainers
@Transactional // every registration is rolled back
class CrewMemberRegistrationIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16-alpine");

    private static final String ANNA = """
            {"employeeCode":"crw-020","firstName":" Anna ","lastName":"Verdi","email":"Anna.Verdi@AETHER.demo",
             "operationalRole":"Geologist","status":"TRAINING","homeColonyCode":"VLM-01"}""";

    @Autowired
    MockMvcTester mvc;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void registersAMemberThatIsThenRetrievable() {
        assertThat(register(ANNA)).hasStatus(HttpStatus.CREATED);

        assertThat(mvc.get().uri("/api/v1/crew-members/CRW-020"))
                .hasStatusOk()
                .bodyJson().isLenientlyEqualTo("""
                        {"employeeCode":"CRW-020","firstName":"Anna","lastName":"Verdi",
                         "email":"anna.verdi@aether.demo","operationalRole":"Geologist",
                         "status":"TRAINING","homeColonyCode":"VLM-01"}""");
        assertThat(mvc.get().uri("/api/v1/crew-members?size=100"))
                .bodyJson().extractingPath("$.items[*].employeeCode").asArray().contains("CRW-001", "CRW-020");
    }

    @Test
    void registersAMemberWithoutBaseOrEmail() {
        assertThat(register("""
                {"employeeCode":"CRW-021","firstName":"Ugo","lastName":"Neri","email":"",
                 "operationalRole":"Pilot","status":"ACTIVE"}"""))
                .hasStatus(HttpStatus.CREATED)
                .bodyJson().extractingPath("$.homeColonyCode").isNull();
    }

    @Test
    void rejectsAnExistingCodeWhateverItsCase() {
        assertProblem(register(ANNA.replace("crw-020", "crw-001")), "CREW_MEMBER_CODE_TAKEN");
    }

    @Test
    void rejectsAnEmailAlreadyRegistered() {
        assertProblem(register(ANNA.replace("Anna.Verdi@AETHER.demo", "Laura.Rossi@aether.demo")),
                "PERSON_EMAIL_TAKEN");
    }

    @Test
    void rejectsAnUnknownBase() {
        assertProblem(register(ANNA.replace("VLM-01", "NOPE-01")), "HOME_COLONY_NOT_FOUND");
    }

    @Test
    void rejectsAnInactiveBase() {
        jdbc.update("INSERT INTO aether.colony(code, name, status, active) VALUES ('OLD-01', 'Old Outpost', 'INACTIVE', false)");

        assertProblem(register(ANNA.replace("VLM-01", "OLD-01")), "HOME_COLONY_INACTIVE");
    }

    @Test
    void persistsNothingWhenRejected() {
        register(ANNA.replace("VLM-01", "NOPE-01"));

        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM aether.person WHERE email = 'anna.verdi@aether.demo'", Long.class)).isZero();
    }

    private MvcTestResult register(String body) {
        return mvc.post().uri("/api/v1/crew-members")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body)
                .exchange();
    }

    private static void assertProblem(MvcTestResult result, String code) {
        assertThat(result).hasStatus(HttpStatus.CONFLICT)
                .bodyJson().extractingPath("$.code").isEqualTo(code);
    }
}
