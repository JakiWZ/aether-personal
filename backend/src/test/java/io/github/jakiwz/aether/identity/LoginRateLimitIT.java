package io.github.jakiwz.aether.identity;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.jakiwz.aether.BrowserSession;
import java.net.http.HttpResponse;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/**
 * Per-address login throttling over real HTTP (ADR-0012): a host spraying passwords over several
 * accounts is stopped with 429 before any password is checked or any account is touched.
 */
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT,
        properties = {"aether.security.login.rate-limit.max-attempts=3",
                "aether.security.login.rate-limit.window=10m"})
@ActiveProfiles("demo")
@Testcontainers
class LoginRateLimitIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16-alpine");

    @LocalServerPort
    int port;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void stopsAPasswordSprayAcrossAccountsBeforeCheckingThePassword() {
        for (String account : new String[] {"cmd.ferrari", "cmd.rizzo", "cmd.romano"}) {
            assertThat(new BrowserSession(port).login(account, "Spring2026!").statusCode()).isEqualTo(401);
        }

        HttpResponse<String> throttled = new BrowserSession(port).login("mc.rossi", BrowserSession.DEMO_PASSWORD);

        assertThat(throttled.statusCode()).isEqualTo(429);
        assertThat(throttled.body()).contains("\"code\":\"TOO_MANY_LOGIN_ATTEMPTS\"");
        assertThat(throttled.headers().firstValue("Retry-After")).get()
                .satisfies(seconds -> assertThat(Long.parseLong(seconds)).isBetween(1L, 600L));
        assertThat(jdbc.queryForObject(
                "SELECT last_login_at IS NULL AND failed_login_count = 0 FROM aether.user_account "
                        + "WHERE username = 'mc.rossi'", Boolean.class)).isTrue();
        assertThat(jdbc.queryForObject(
                "SELECT count(*) FROM aether.audit_event e JOIN aether.user_account a ON a.id_account = e.id_account "
                        + "WHERE a.username = 'mc.rossi' AND e.action LIKE 'LOGIN%'", Long.class)).isZero();
    }
}
