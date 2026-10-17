package io.github.jakiwz.aether;

import static org.assertj.core.api.Assertions.assertThat;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/**
 * Boots the whole application against a real PostgreSQL 16 (TASK-005): Flyway must build the
 * schema from scratch, Hibernate must validate against it and the operational endpoints must be up.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Testcontainers
class AetherApplicationIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16-alpine");

    @Autowired
    MockMvcTester mvc;

    @Autowired
    Flyway flyway;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void appliesAllMigrationsOnAnEmptyDatabase() {
        assertThat(flyway.info().pending()).isEmpty();
        assertThat(flyway.info().applied()).hasSizeGreaterThanOrEqualTo(14);
    }

    @Test
    void loadsNoDemoDataWithoutTheDemoProfile() {
        assertThat(jdbc.queryForObject("SELECT count(*) FROM aether.colony", Long.class)).isZero();
        assertThat(jdbc.queryForObject("SELECT count(*) FROM aether.app_role", Long.class)).isEqualTo(8);
    }

    @Test
    void providesTheDisabledSystemAccountEveryEnvironmentWritesWith() {
        assertThat(jdbc.queryForObject(
                "SELECT account_status FROM aether.user_account WHERE username = 'system'", String.class))
                .isEqualTo("DISABLED");
    }

    @Test
    void healthEndpointReportsUp() {
        assertThat(mvc.get().uri("/actuator/health"))
                .hasStatusOk()
                .bodyJson().extractingPath("$.status").isEqualTo("UP");
    }

    @Test
    void keepsTheApiDescriptionPrivateOutsideDevelopment() {
        assertThat(mvc.get().uri("/v3/api-docs")).hasStatus(HttpStatus.NOT_FOUND);
        assertThat(mvc.get().uri("/swagger-ui.html")).hasStatus(HttpStatus.NOT_FOUND);
    }

    @Test
    void sendsTheSecurityHeadersOnEveryApiResponse() {
        assertThat(mvc.get().uri("/api/v1/missions"))
                .hasStatus(HttpStatus.UNAUTHORIZED)
                .headers()
                .hasValue("Content-Security-Policy",
                        "default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'")
                .hasValue("Referrer-Policy", "no-referrer")
                .hasValue("X-Content-Type-Options", "nosniff")
                .hasValue("X-Frame-Options", "DENY")
                .hasValue("Cross-Origin-Opener-Policy", "same-origin")
                .hasValue("Cross-Origin-Resource-Policy", "same-origin")
                .containsHeader("Permissions-Policy");
    }

    @Test
    @WithMockUser
    void unknownApiRouteReturnsAProblemDocument() {
        assertThat(mvc.get().uri("/api/v1/unknown"))
                .hasStatus(HttpStatus.NOT_FOUND)
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON)
                .bodyJson().extractingPath("$.code").isEqualTo("RESOURCE_NOT_FOUND");
    }
}
