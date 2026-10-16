package io.github.jakiwz.aether.colonies;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/**
 * ARES-101 end to end: the list comes from the persisted demo dataset, inactive bases are listed
 * without being deleted, soft-deleted ones are not.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("demo")
@Testcontainers
@Transactional // the extra rows inserted by a test are rolled back
class ColonyListIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16-alpine");

    @Autowired
    MockMvcTester mvc;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void listsTheDemoBasesOrderedByCode() {
        assertThat(mvc.get().uri("/api/v1/colonies"))
                .hasStatusOk()
                .bodyJson().extractingPath("$[*].code").asArray()
                .containsExactly("ARS-01", "ELY-01", "THR-01", "VLM-01");
    }

    @Test
    void distinguishesInactiveBasesAndHidesDeletedOnes() {
        jdbc.update("INSERT INTO aether.colony(code, name, status, active) VALUES ('OLD-01', 'Old Outpost', 'INACTIVE', false)");
        jdbc.update("""
                INSERT INTO aether.colony(code, name, status, active, deleted_at)
                VALUES ('DEL-01', 'Deleted Outpost', 'INACTIVE', false, now())""");

        assertThat(mvc.get().uri("/api/v1/colonies"))
                .hasStatusOk()
                .bodyJson().extractingPath("$[*].code").asArray()
                .contains("OLD-01").doesNotContain("DEL-01");
        assertThat(mvc.get().uri("/api/v1/colonies?active=false"))
                .hasStatusOk()
                .bodyJson().extractingPath("$[*].code").asArray().containsExactly("OLD-01");
        assertThat(mvc.get().uri("/api/v1/colonies?active=true"))
                .hasStatusOk()
                .bodyJson().extractingPath("$[*].code").asArray().doesNotContain("OLD-01");
    }
}
