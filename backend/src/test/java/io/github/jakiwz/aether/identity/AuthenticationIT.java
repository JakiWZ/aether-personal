package io.github.jakiwz.aether.identity;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.jakiwz.aether.BrowserSession;
import java.net.http.HttpRequest.BodyPublishers;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
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
 * Login, session and permissions over real HTTP on the demo accounts (FUT-701, IAM-002/005/007/008):
 * the cookies a browser gets, the generic failure, the lockout, and what each role may do.
 * Every test signs in with its own account, so lockouts and logouts do not leak between tests.
 */
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@ActiveProfiles("demo")
@Testcontainers
class AuthenticationIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16-alpine");

    @LocalServerPort
    int port;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void signsInWithAHardenedSessionCookie() {
        BrowserSession browser = new BrowserSession(port);

        HttpResponse<String> response = browser.login("mc.rossi", BrowserSession.DEMO_PASSWORD);

        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.body()).contains("\"authenticated\":true", "\"username\":\"mc.rossi\"",
                "\"MISSION_CONTROLLER\"", "\"MISSION_MANAGE\"");
        List<String> setCookies = response.headers().allValues("Set-Cookie");
        assertThat(setCookies).anySatisfy(cookie -> assertThat(cookie)
                .startsWith("AETHER_SESSION=").contains("HttpOnly", "SameSite=Strict", "Path=/"));
        assertThat(setCookies).anySatisfy(cookie -> assertThat(cookie)
                .startsWith("XSRF-TOKEN=").contains("SameSite=Strict").doesNotContain("HttpOnly"));
        assertThat(browser.get("/api/v1/auth/session").body()).contains("\"username\":\"mc.rossi\"");
        assertThat(jdbc.queryForObject("SELECT last_login_at FROM aether.user_account WHERE username = 'mc.rossi'",
                OffsetDateTime.class)).isNotNull();
    }

    @Test
    void handsOutTheCsrfCookieBeforeLogin() {
        BrowserSession browser = new BrowserSession(port);

        HttpResponse<String> response = browser.get("/api/v1/auth/session");

        assertThat(response.statusCode()).isEqualTo(200);
        assertThat(response.body()).contains("\"authenticated\":false");
        assertThat(browser.cookie("XSRF-TOKEN")).isPresent();
        assertThat(browser.cookie("AETHER_SESSION")).isEmpty();
    }

    @Test
    void issuesANewSessionIdAtEveryLogin() {
        BrowserSession browser = BrowserSession.signedIn(port, "cmd.ferrari");
        String first = browser.cookie("AETHER_SESSION").orElseThrow().getValue();

        browser.login("cmd.ferrari", BrowserSession.DEMO_PASSWORD);

        assertThat(browser.cookie("AETHER_SESSION").orElseThrow().getValue()).isNotEqualTo(first);
    }

    @Test
    void answersUnknownUsersWrongPasswordsAndDisabledAccountsAlike() {
        HttpResponse<String> unknown = new BrowserSession(port).login("nobody.here", "Aether-demo-password");
        HttpResponse<String> wrong = new BrowserSession(port).login("log.marino", "not-the-password-1");
        HttpResponse<String> disabled = new BrowserSession(port).login("sci.dubois", BrowserSession.DEMO_PASSWORD);
        HttpResponse<String> system = new BrowserSession(port).login("system", BrowserSession.DEMO_PASSWORD);

        for (HttpResponse<String> response : List.of(unknown, wrong, disabled, system)) {
            assertThat(response.statusCode()).isEqualTo(401);
            assertThat(response.body()).contains("\"code\":\"INVALID_CREDENTIALS\"")
                    .contains("Invalid username or password.");
        }
        assertThat(wrong.body()).isEqualTo(unknown.body().replace("nobody.here", "log.marino"));
    }

    @Test
    void locksTheAccountAfterFiveFailuresInARow() {
        for (int attempt = 1; attempt <= 5; attempt++) {
            assertThat(new BrowserSession(port).login("mnt.bianchi", "guess-number-" + attempt).statusCode())
                    .isEqualTo(401);
        }

        HttpResponse<String> rightPasswordTooLate = new BrowserSession(port)
                .login("mnt.bianchi", BrowserSession.DEMO_PASSWORD);

        assertThat(rightPasswordTooLate.statusCode()).isEqualTo(401);
        assertThat(jdbc.queryForObject("SELECT locked_until FROM aether.user_account WHERE username = 'mnt.bianchi'",
                OffsetDateTime.class)).isAfter(OffsetDateTime.now(ZoneOffset.UTC).plusMinutes(14));
    }

    @Test
    void resetsTheFailureCountAfterASuccessfulLogin() {
        new BrowserSession(port).login("sci.greco", "a-wrong-password-1");

        BrowserSession.signedIn(port, "sci.greco");

        assertThat(jdbc.queryForObject(
                "SELECT failed_login_count FROM aether.user_account WHERE username = 'sci.greco'", Integer.class))
                .isZero();
    }

    @Test
    void refusesTheApiWithoutASession() {
        HttpResponse<String> response = new BrowserSession(port).get("/api/v1/missions");

        assertThat(response.statusCode()).isEqualTo(401);
        assertThat(response.headers().firstValue("WWW-Authenticate")).isEmpty();
        assertThat(response.body()).contains("\"code\":\"AUTHENTICATION_REQUIRED\"");
    }

    @Test
    void letsEachRoleDoOnlyWhatItsPermissionsAllow() {
        BrowserSession crew = BrowserSession.signedIn(port, "crew.conti");

        assertThat(crew.get("/api/v1/missions").statusCode()).isEqualTo(200);
        assertThat(crew.get("/api/v1/crew-members").statusCode()).isEqualTo(403);
        HttpResponse<String> draft = crew.post("/api/v1/missions", """
                {"code":"PHX-777","title":"Unauthorised","objective":"None","type":"EXPLORATION",
                 "originColonyCode":"ARS-01","plannedStartAt":"2099-05-01T08:00:00Z",
                 "plannedEndAt":"2099-05-02T08:00:00Z","priority":"LOW","safetyLevel":"STANDARD"}""");
        assertThat(draft.statusCode()).isEqualTo(403);
        assertThat(draft.body()).contains("\"code\":\"ACCESS_DENIED\"");
        assertThat(jdbc.queryForObject("SELECT count(*) FROM aether.mission WHERE code = 'PHX-777'", Long.class))
                .isZero();
    }

    @Test
    void refusesAStateChangeWithoutTheCsrfHeader() {
        BrowserSession admin = BrowserSession.signedIn(port, "admin.neri");

        HttpResponse<String> response = admin.sendRaw(HttpRequest.newBuilder(admin.uri("/api/v1/auth/logout"))
                .POST(BodyPublishers.noBody()).build());

        assertThat(response.statusCode()).isEqualTo(403);
        assertThat(response.body()).contains("\"code\":\"CSRF_TOKEN_INVALID\"");
        assertThat(admin.get("/api/v1/auth/session").body()).contains("\"authenticated\":true");
    }

    @Test
    void endsTheSessionOnLogout() {
        BrowserSession auditor = BrowserSession.signedIn(port, "audit.sala");

        HttpResponse<String> logout = auditor.post("/api/v1/auth/logout", "");

        assertThat(logout.statusCode()).isEqualTo(204);
        assertThat(auditor.get("/api/v1/missions").statusCode()).isEqualTo(401);
    }
}
