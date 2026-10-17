package io.github.jakiwz.aether.shared.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;

import io.github.jakiwz.aether.colonies.domain.ColonyService;
import io.github.jakiwz.aether.crew.domain.CrewMemberService;
import io.github.jakiwz.aether.identity.domain.LoginRateLimiter;
import io.github.jakiwz.aether.identity.domain.LoginService;
import io.github.jakiwz.aether.missions.domain.MissionService;
import java.util.List;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester.MockMvcRequestBuilder;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;

/**
 * Access control of every endpoint (OWASP API1/API5:2023, IAM-005): nothing is open without a
 * session, each function needs its permission, and state changes need the CSRF token.
 * The allowed cases are covered by each controller's own test.
 */
@WebMvcTest
@Import(SecurityConfig.class)
class EndpointSecurityTest {

    /** Every permission an endpoint checks today. */
    private static final List<String> PERMISSIONS = List.of(
            "COLONY_READ", "CREW_READ", "CREW_MANAGE", "MISSION_READ", "MISSION_MANAGE");

    private static final String MISSION = """
            {"code":"PHX-020","title":"Jezero delta survey","objective":"Map the delta front",
             "type":"EXPLORATION","originColonyCode":"ARS-01",
             "plannedStartAt":"2099-05-01T08:00:00Z","plannedEndAt":"2099-05-03T18:00:00Z",
             "priority":"HIGH","safetyLevel":"ELEVATED"}""";

    private static final String CREW = """
            {"employeeCode":"CRW-020","firstName":"Anna","lastName":"Verdi","email":null,
             "operationalRole":"Geologist","status":"ACTIVE","homeColonyCode":null}""";

    @Autowired
    MockMvcTester mvc;

    @MockitoBean
    MissionService missions;

    @MockitoBean
    CrewMemberService crew;

    @MockitoBean
    ColonyService colonies;

    @MockitoBean
    LoginService logins;

    @MockitoBean
    LoginRateLimiter rateLimiter;

    static Stream<Arguments> endpoints() {
        return Stream.of(
                Arguments.of(HttpMethod.GET, "/api/v1/colonies", null, "COLONY_READ"),
                Arguments.of(HttpMethod.GET, "/api/v1/crew-members", null, "CREW_READ"),
                Arguments.of(HttpMethod.GET, "/api/v1/crew-members/CRW-001", null, "CREW_READ"),
                Arguments.of(HttpMethod.POST, "/api/v1/crew-members", CREW, "CREW_MANAGE"),
                Arguments.of(HttpMethod.GET, "/api/v1/missions", null, "MISSION_READ"),
                Arguments.of(HttpMethod.GET, "/api/v1/missions/PHX-001", null, "MISSION_READ"),
                Arguments.of(HttpMethod.POST, "/api/v1/missions", MISSION, "MISSION_MANAGE"));
    }

    @ParameterizedTest(name = "{0} {1}")
    @MethodSource("endpoints")
    void refusesARequestWithoutASession(HttpMethod method, String path, String body, String permission) {
        MvcTestResult result = request(method, path, body).with(csrf()).exchange();

        assertProblem(result, HttpStatus.UNAUTHORIZED, "AUTHENTICATION_REQUIRED");
        assertThat(result).doesNotContainHeader(HttpHeaders.WWW_AUTHENTICATE);
        verifyNoInteractions(missions, crew, colonies);
    }

    @ParameterizedTest(name = "{0} {1} needs {3}")
    @MethodSource("endpoints")
    void refusesAUserWithEveryPermissionButTheOneNeeded(HttpMethod method, String path, String body,
            String permission) {
        String[] others = PERMISSIONS.stream().filter(p -> !p.equals(permission)).toArray(String[]::new);

        MvcTestResult result = request(method, path, body)
                .with(user("crew.conti").authorities(
                        Stream.of(others).map(SimpleGrantedAuthority::new)
                                .toList()))
                .with(csrf())
                .exchange();

        assertProblem(result, HttpStatus.FORBIDDEN, "ACCESS_DENIED");
        verifyNoInteractions(missions, crew, colonies);
    }

    @Test
    void refusesAStateChangeWithoutTheCsrfToken() {
        MvcTestResult result = request(HttpMethod.POST, "/api/v1/missions", MISSION)
                .with(user("mc.rossi").authorities(
                        new SimpleGrantedAuthority("MISSION_MANAGE")))
                .exchange();

        assertProblem(result, HttpStatus.FORBIDDEN, "CSRF_TOKEN_INVALID");
        verifyNoInteractions(missions);
    }

    @Test
    void refusesAForgedCsrfToken() {
        MvcTestResult result = request(HttpMethod.POST, "/api/v1/missions", MISSION)
                .with(user("mc.rossi").authorities(
                        new SimpleGrantedAuthority("MISSION_MANAGE")))
                .with(csrf().useInvalidToken())
                .exchange();

        assertProblem(result, HttpStatus.FORBIDDEN, "CSRF_TOKEN_INVALID");
        verifyNoInteractions(missions);
    }

    @Test
    void deniesUnknownRoutesByDefault() {
        assertProblem(mvc.get().uri("/api/v1/not-yet-written").exchange(),
                HttpStatus.UNAUTHORIZED, "AUTHENTICATION_REQUIRED");
    }

    @Test
    void asksBrowsersToStayOnHttpsOnceTheyUsedIt() {
        assertThat(mvc.get().uri("/api/v1/missions").secure(true).exchange())
                .headers().hasValue("Strict-Transport-Security", "max-age=31536000 ; includeSubDomains");
        assertThat(mvc.get().uri("/api/v1/missions").exchange())
                .headers().doesNotContainHeader("Strict-Transport-Security");
    }

    @Test
    void forbidsEmbeddingAndBrowserFeaturesOnEveryResponse() {
        assertThat(mvc.get().uri("/api/v1/missions").exchange()).headers()
                .hasValue("Content-Security-Policy", SecurityConfig.API_CONTENT_SECURITY_POLICY)
                .hasValue("Permissions-Policy", SecurityConfig.PERMISSIONS_POLICY)
                .hasValue("Referrer-Policy", "no-referrer")
                .hasValue("X-Frame-Options", "DENY");
    }

    private MockMvcRequestBuilder request(HttpMethod method, String path, String body) {
        MockMvcRequestBuilder request = mvc.method(method).uri(path);
        return body == null ? request : request.contentType(MediaType.APPLICATION_JSON).content(body);
    }

    private static void assertProblem(MvcTestResult result, HttpStatus status, String code) {
        assertThat(result).hasStatus(status);
        assertThat(result).hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo(code);
    }
}
