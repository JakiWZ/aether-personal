package io.github.jakiwz.aether.audit;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.jakiwz.aether.BrowserSession;
import java.net.http.HttpRequest.BodyPublishers;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;
import java.util.Map;
import java.util.UUID;
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
 * The audit trail over real HTTP (IAM-008, BR-012, UC-07, ADR-0014): every login outcome, the
 * lockout, the logout and the writes land in {@code audit_event} with their account, client
 * address and the request's correlation id. Every test uses its own account.
 */
// every login comes from 127.0.0.1: the per-address limit is tested on its own in LoginRateLimitIT
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT,
        properties = "aether.security.login.rate-limit.max-attempts=1000")
@ActiveProfiles("demo")
@Testcontainers
class AuditTrailIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16-alpine");

    @LocalServerPort
    int port;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void echoesTheCorrelationIdEvenOnRefusedRequests() {
        BrowserSession browser = new BrowserSession(port);
        String id = UUID.randomUUID().toString();

        HttpResponse<String> response = browser.sendRaw(HttpRequest.newBuilder(browser.uri("/api/v1/colonies"))
                .header("X-Request-ID", id).GET().build());
        HttpResponse<String> forged = browser.sendRaw(HttpRequest.newBuilder(browser.uri("/api/v1/colonies"))
                .header("X-Request-ID", "forged id").GET().build());

        assertThat(response.statusCode()).isEqualTo(401);
        assertThat(response.headers().firstValue("X-Request-ID")).contains(id);
        assertThat(forged.headers().firstValue("X-Request-ID")).get()
                .isNotEqualTo("forged id").satisfies(value -> UUID.fromString(value));
    }

    @Test
    void recordsASuccessfulLoginWithItsCorrelationIdAndAddress() {
        BrowserSession browser = new BrowserSession(port);
        browser.get("/api/v1/auth/session");
        String id = UUID.randomUUID().toString();

        HttpResponse<String> response = browser.sendRaw(HttpRequest.newBuilder(browser.uri("/api/v1/auth/login"))
                .header("Content-Type", "application/json")
                .header("X-XSRF-TOKEN", browser.cookie("XSRF-TOKEN").orElseThrow().getValue())
                .header("X-Request-ID", id)
                .POST(BodyPublishers.ofString(
                        "{\"username\":\"cmd.rizzo\",\"password\":\"" + BrowserSession.DEMO_PASSWORD + "\"}"))
                .build());

        assertThat(response.statusCode()).isEqualTo(200);
        Map<String, Object> event = jdbc.queryForMap("""
                SELECT e.action, e.entity_type, e.entity_id, host(e.ip_address) AS ip,
                       e.correlation_id::text AS correlation_id, a.username
                FROM aether.audit_event e JOIN aether.user_account a ON a.id_account = e.id_account
                WHERE e.correlation_id = ?::uuid""", id);
        assertThat(event).containsEntry("action", "LOGIN_SUCCEEDED").containsEntry("entity_type", "USER_ACCOUNT")
                .containsEntry("entity_id", "cmd.rizzo").containsEntry("username", "cmd.rizzo")
                .containsEntry("correlation_id", id);
        assertThat((String) event.get("ip")).isIn("127.0.0.1", "::1");
    }

    @Test
    void recordsAFailedLoginOfAnUnknownUserWithoutWhatWasTyped() {
        new BrowserSession(port).login("Typo-Or-Password-Secret", "whatever-1");

        List<Map<String, Object>> events = jdbc.queryForList("""
                SELECT id_account, entity_id, reason FROM aether.audit_event
                WHERE action = 'LOGIN_FAILED' AND reason = 'UNKNOWN_ACCOUNT'""");
        assertThat(events).isNotEmpty().allSatisfy(event -> assertThat(event)
                .containsEntry("id_account", null).containsEntry("entity_id", "unknown"));
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM aether.audit_event
                WHERE entity_id ILIKE '%typo%' OR reason ILIKE '%typo%' OR new_value_json::text ILIKE '%typo%'""",
                Long.class)).isZero();
    }

    @Test
    void recordsEachFailureThenTheLockoutThenTheRefusal() {
        long before = lastAuditId();
        for (int attempt = 1; attempt <= 5; attempt++) {
            new BrowserSession(port).login("cmd.romano", "guess-number-" + attempt);
        }
        new BrowserSession(port).login("cmd.romano", BrowserSession.DEMO_PASSWORD);

        assertThat(actionsOf("cmd.romano", before)).containsExactly(
                "LOGIN_FAILED", "LOGIN_FAILED", "LOGIN_FAILED", "LOGIN_FAILED", "LOGIN_FAILED",
                "ACCOUNT_LOCKED", "LOGIN_REFUSED");
        assertThat(jdbc.queryForObject("""
                SELECT new_value_json->>'lockedUntil' IS NOT NULL FROM aether.audit_event e
                JOIN aether.user_account a ON a.id_account = e.id_account
                WHERE a.username = 'cmd.romano' AND e.action = 'ACCOUNT_LOCKED'""", Boolean.class)).isTrue();
        assertThat(jdbc.queryForObject("""
                SELECT reason FROM aether.audit_event e JOIN aether.user_account a ON a.id_account = e.id_account
                WHERE a.username = 'cmd.romano' AND e.action = 'LOGIN_REFUSED'""", String.class))
                .isEqualTo("ACCOUNT_LOCKED");
    }

    @Test
    void recordsALogout() {
        long before = lastAuditId();
        BrowserSession browser = BrowserSession.signedIn(port, "log.marino");

        assertThat(browser.post("/api/v1/auth/logout", "").statusCode()).isLessThan(400);

        assertThat(actionsOf("log.marino", before)).containsExactly("LOGIN_SUCCEEDED", "LOGOUT");
    }

    @Test
    void attributesCreatedMissionsAndCrewMembersToTheirAuthor() {
        BrowserSession controller = BrowserSession.signedIn(port, "mc.rossi");
        BrowserSession admin = BrowserSession.signedIn(port, "admin.neri");

        assertThat(controller.post("/api/v1/missions", """
                {"code":"PHX-880","title":"Audited","objective":"Leave a trace","type":"EXPLORATION",
                 "originColonyCode":"ARS-01","plannedStartAt":"2099-05-01T08:00:00Z",
                 "plannedEndAt":"2099-05-02T08:00:00Z","priority":"LOW","safetyLevel":"STANDARD"}""")
                .statusCode()).isEqualTo(201);
        assertThat(admin.post("/api/v1/crew-members", """
                {"employeeCode":"CRW-880","firstName":"Private","lastName":"Person","email":"private@aether.demo",
                 "operationalRole":"Geologist","status":"TRAINING","homeColonyCode":"VLM-01"}""")
                .statusCode()).isEqualTo(201);

        assertThat(jdbc.queryForMap("""
                SELECT a.username, e.new_value_json->>'status' AS status, e.correlation_id IS NOT NULL AS traced
                FROM aether.audit_event e JOIN aether.user_account a ON a.id_account = e.id_account
                WHERE e.action = 'MISSION_CREATED' AND e.entity_type = 'MISSION' AND e.entity_id = 'PHX-880'"""))
                .containsEntry("username", "mc.rossi").containsEntry("status", "DRAFT").containsEntry("traced", true);
        Map<String, Object> crew = jdbc.queryForMap("""
                SELECT a.username, e.new_value_json::text AS snapshot
                FROM aether.audit_event e JOIN aether.user_account a ON a.id_account = e.id_account
                WHERE e.action = 'CREW_MEMBER_REGISTERED' AND e.entity_type = 'CREW_MEMBER'
                  AND e.entity_id = 'CRW-880'""");
        assertThat(crew).containsEntry("username", "admin.neri");
        assertThat((String) crew.get("snapshot")).contains("TRAINING", "VLM-01")
                .doesNotContain("Private", "Person", "private@aether.demo");
    }

    @Test
    void recordsNothingWhenAWriteIsRolledBack() {
        BrowserSession controller = BrowserSession.signedIn(port, "mc.rossi");

        HttpResponse<String> response = controller.post("/api/v1/missions", """
                {"code":"PHX-881","title":"Refused","objective":"None","type":"EXPLORATION",
                 "originColonyCode":"NOPE-99","plannedStartAt":"2099-05-01T08:00:00Z",
                 "plannedEndAt":"2099-05-02T08:00:00Z","priority":"LOW","safetyLevel":"STANDARD"}""");

        assertThat(response.statusCode()).isEqualTo(409);
        assertThat(jdbc.queryForObject("SELECT count(*) FROM aether.audit_event WHERE entity_id = 'PHX-881'",
                Long.class)).isZero();
    }

    /** The demo dataset ships audit rows of its own: only what happened after {@code after} counts. */
    private List<String> actionsOf(String username, long after) {
        return jdbc.queryForList("""
                SELECT e.action FROM aether.audit_event e JOIN aether.user_account a ON a.id_account = e.id_account
                WHERE a.username = ? AND e.id_audit > ? ORDER BY e.id_audit""", String.class, username, after);
    }

    private long lastAuditId() {
        return jdbc.queryForObject("SELECT coalesce(max(id_audit), 0) FROM aether.audit_event", Long.class);
    }
}
