package io.github.jakiwz.aether;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.ByteArrayInputStream;
import java.net.http.HttpRequest.BodyPublisher;
import java.net.http.HttpRequest.BodyPublishers;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.test.context.ActiveProfiles;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/**
 * Hostile input through the real servlet container and database, where MockMvc cannot reach:
 * container-level rejections, bodies sent without a length and text PostgreSQL would refuse.
 */
@SpringBootTest(webEnvironment = WebEnvironment.RANDOM_PORT)
@ActiveProfiles("demo")
@Testcontainers
class HostileInputIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16-alpine");

    private static final String CREW = """
            {"employeeCode":"CRW-HOSTILE","firstName":"An\\u0000na","lastName":"Verdi","email":null,
             "operationalRole":"Geologist","status":"ACTIVE","homeColonyCode":null}""";

    @LocalServerPort
    int port;

    @Test
    void rejectsTextThatPostgresWouldRefuseAsAValidationError() {
        HttpResponse<String> response = send("POST", "/api/v1/crew-members", BodyPublishers.ofString(CREW));

        assertProblem(response, 400, "VALIDATION_FAILED");
    }

    @Test
    void refusesADeclaredOversizedBodyWithAProblem() {
        HttpResponse<String> response = send("POST", "/api/v1/missions",
                BodyPublishers.ofString("{\"title\":\"" + "x".repeat(70 * 1024) + "\"}"));

        assertProblem(response, 413, "PAYLOAD_TOO_LARGE");
    }

    @Test
    void capsABodySentWithoutALengthWhileParsing() {
        byte[] body = ("{\"title\":\"" + "x".repeat(70 * 1024) + "\"}").getBytes(StandardCharsets.UTF_8);

        HttpResponse<String> response = send("POST", "/api/v1/missions",
                BodyPublishers.ofInputStream(() -> new ByteArrayInputStream(body)));

        assertProblem(response, 400, "MALFORMED_REQUEST");
    }

    @Test
    void answersAMethodTheContainerRefusesWithAProblem() {
        HttpResponse<String> response = send("TRACE", "/api/v1/missions", BodyPublishers.noBody());

        assertProblem(response, 405, "METHOD_NOT_ALLOWED");
    }

    /** Signed in with every permission, so each request reaches the layer under test. */
    private HttpResponse<String> send(String method, String path, BodyPublisher body) {
        return BrowserSession.signedIn(port, "admin.neri").send(method, path, body);
    }

    private static void assertProblem(HttpResponse<String> response, int status, String code) {
        assertThat(response.statusCode()).isEqualTo(status);
        assertThat(response.headers().firstValue("Content-Type")).hasValueSatisfying(
                type -> assertThat(type).startsWith("application/problem+json"));
        assertThat(response.body()).contains("\"code\":\"" + code + "\"");
    }
}
