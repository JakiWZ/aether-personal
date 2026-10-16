package io.github.jakiwz.aether;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.ByteArrayInputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpRequest.BodyPublisher;
import java.net.http.HttpRequest.BodyPublishers;
import java.net.http.HttpResponse;
import java.net.http.HttpResponse.BodyHandlers;
import java.nio.charset.StandardCharsets;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.SpringBootTest.WebEnvironment;
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

    private final HttpClient http = HttpClient.newHttpClient();

    @LocalServerPort
    int port;

    @Test
    void rejectsTextThatPostgresWouldRefuseAsAValidationError() throws Exception {
        HttpResponse<String> response = send("POST", "/api/v1/crew-members", BodyPublishers.ofString(CREW));

        assertProblem(response, 400, "VALIDATION_FAILED");
    }

    @Test
    void refusesADeclaredOversizedBodyWithAProblem() throws Exception {
        HttpResponse<String> response = send("POST", "/api/v1/missions",
                BodyPublishers.ofString("{\"title\":\"" + "x".repeat(70 * 1024) + "\"}"));

        assertProblem(response, 413, "PAYLOAD_TOO_LARGE");
    }

    @Test
    void capsABodySentWithoutALengthWhileParsing() throws Exception {
        byte[] body = ("{\"title\":\"" + "x".repeat(70 * 1024) + "\"}").getBytes(StandardCharsets.UTF_8);

        HttpResponse<String> response = send("POST", "/api/v1/missions",
                BodyPublishers.ofInputStream(() -> new ByteArrayInputStream(body)));

        assertProblem(response, 400, "MALFORMED_REQUEST");
    }

    @Test
    void answersAMethodTheContainerRefusesWithAProblem() throws Exception {
        HttpResponse<String> response = send("TRACE", "/api/v1/missions", BodyPublishers.noBody());

        assertProblem(response, 405, "METHOD_NOT_ALLOWED");
    }

    private HttpResponse<String> send(String method, String path, BodyPublisher body) throws Exception {
        HttpRequest request = HttpRequest.newBuilder(URI.create("http://localhost:" + port + path))
                .header("Content-Type", "application/json")
                .method(method, body)
                .build();
        return http.send(request, BodyHandlers.ofString());
    }

    private static void assertProblem(HttpResponse<String> response, int status, String code) {
        assertThat(response.statusCode()).isEqualTo(status);
        assertThat(response.headers().firstValue("Content-Type")).hasValueSatisfying(
                type -> assertThat(type).startsWith("application/problem+json"));
        assertThat(response.body()).contains("\"code\":\"" + code + "\"");
    }
}
