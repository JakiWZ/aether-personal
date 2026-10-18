package io.github.jakiwz.aether;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

import io.github.jakiwz.aether.colonies.domain.ColonyService;
import io.github.jakiwz.aether.crew.domain.CrewMemberService;
import io.github.jakiwz.aether.fleet.domain.VehicleService;
import io.github.jakiwz.aether.identity.domain.LoginRateLimiter;
import io.github.jakiwz.aether.identity.domain.LoginService;
import io.github.jakiwz.aether.missions.domain.Mission;
import io.github.jakiwz.aether.missions.domain.MissionPriority;
import io.github.jakiwz.aether.missions.domain.MissionService;
import io.github.jakiwz.aether.missions.domain.MissionStatus;
import io.github.jakiwz.aether.missions.domain.MissionType;
import io.github.jakiwz.aether.missions.domain.SafetyLevel;
import io.github.jakiwz.aether.shared.config.JacksonConfig;
import io.github.jakiwz.aether.shared.error.ResourceNotFoundException;
import io.github.jakiwz.aether.shared.security.SecurityConfig;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;

/**
 * Hostile and malformed input against the public API (OWASP Top 10:2025 A10, API3/API4:2023).
 * Every case must end in a 4xx Problem Details with a stable {@code code}, never a 500 and never
 * a call into the domain.
 */
@WebMvcTest
@Import({JacksonConfig.class, SecurityConfig.class})
@WithMockUser(authorities = {"MISSION_READ", "MISSION_MANAGE", "CREW_READ", "CREW_MANAGE", "COLONY_READ",
        "ASSET_READ"})
class HostileInputTest {

    private static final String MISSION = """
            {"code":"PHX-020","title":"Jezero delta survey","description":"Line one","objective":"Map the delta",
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
    VehicleService vehicles;

    @MockitoBean
    LoginService logins;

    @MockitoBean
    LoginRateLimiter rateLimiter;

    static Stream<Arguments> hostileMissions() {
        return Stream.of(
                invalid("NUL byte", MISSION.replace("Jezero", "Jez\\u0000ero"), "title"),
                invalid("terminal escape", MISSION.replace("Jezero", "\\u001b[2JJezero"), "title"),
                invalid("line break in a single-line field", MISSION.replace("Jezero", "Jezero\\nSOL"), "title"),
                invalid("bidi override (Trojan Source)", MISSION.replace("Map the", "Map \\u202Ethe"), "objective"),
                invalid("unpaired surrogate", MISSION.replace("Jezero", "\\ud800Jezero"), "title"),
                invalid("NUL in a lookup code", MISSION.replace("ARS-01", "ARS-01\\u0000"), "originColonyCode"),
                invalid("year beyond 9999", MISSION.replace("2099-05-03T18:00:00Z", "+300000-05-03T18:00:00Z"),
                        "plannedEndAt"),
                invalid("text over the limit", MISSION.replace("Jezero", "x".repeat(201)), "title"),
                malformed("unknown property (mass assignment)", MISSION.replace("{", "{\"status\":\"APPROVED\",")),
                malformed("duplicate property", MISSION.replace("{", "{\"code\":\"PHX-999\",")),
                malformed("number where text is expected", MISSION.replace("\"PHX-020\"", "20")),
                malformed("boolean where text is expected", MISSION.replace("\"Jezero delta survey\"", "true")),
                malformed("object where text is expected", MISSION.replace("\"Jezero delta survey\"", "{}")),
                malformed("unknown enum constant", MISSION.replace("EXPLORATION", "'; DROP TABLE mission;--")),
                malformed("trailing content", MISSION + " {}"),
                malformed("truncated JSON", MISSION.substring(0, 40)),
                malformed("JSON array", "[" + MISSION + "]"),
                malformed("JSON null", "null"),
                malformed("empty body", ""),
                malformed("5000-digit number", MISSION.replace("\"Jezero delta survey\"", "1" + "0".repeat(5000))),
                malformed("deep nesting", "{\"title\":" + "[".repeat(2000) + "]".repeat(2000) + "}"));
    }

    @ParameterizedTest(name = "{0}")
    @MethodSource("hostileMissions")
    void rejectsHostileMissionBodies(String name, String body, HttpStatus status, String code, String field) {
        MvcTestResult result = mvc.post().uri("/api/v1/missions").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(body).exchange();

        assertProblem(result, status, code);
        if (field != null) {
            assertThat(result).bodyJson().extractingPath("$.errors[*].field").asArray().contains(field);
        }
        verifyNoInteractions(missions);
    }

    @Test
    void rejectsControlCharactersInCrewNames() {
        MvcTestResult result = mvc.post().uri("/api/v1/crew-members").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(CREW.replace("Anna", "An\\u0000na")).exchange();

        assertProblem(result, HttpStatus.BAD_REQUEST, "VALIDATION_FAILED");
        verifyNoInteractions(crew);
    }

    @Test
    void keepsLineBreaksAndEmojiInFreeText() {
        given(missions.create(any())).willReturn(new Mission("PHX-020", "Jezero", "Line one\nLine two",
                List.of("Map"), MissionType.EXPLORATION, "ARS-01", OffsetDateTime.parse("2099-05-01T08:00:00Z"),
                OffsetDateTime.parse("2099-05-03T18:00:00Z"), MissionStatus.DRAFT, MissionPriority.HIGH,
                SafetyLevel.ELEVATED, "system", OffsetDateTime.parse("2026-10-16T10:00:00Z")));

        assertThat(mvc.post().uri("/api/v1/missions").with(csrf()).contentType(MediaType.APPLICATION_JSON)
                .content(MISSION.replace("Line one", "Line one\\n\\tLine two 🚀")))
                .hasStatus(HttpStatus.CREATED);
    }

    @Test
    void refusesADeclaredBodyOverTheLimitBeforeReadingIt() {
        String body = MISSION.replace("Line one", "x".repeat(70 * 1024));

        assertThat(mvc.post().uri("/api/v1/missions").with(csrf()).contentType(MediaType.APPLICATION_JSON).content(body))
                .hasStatus(HttpStatus.CONTENT_TOO_LARGE);
        verifyNoInteractions(missions);
    }

    @Test
    void refusesAnUnsupportedMediaType() {
        assertProblem(mvc.post().uri("/api/v1/missions").with(csrf()).contentType(MediaType.APPLICATION_XML)
                .content("<mission/>").exchange(), HttpStatus.UNSUPPORTED_MEDIA_TYPE, "UNSUPPORTED_MEDIA_TYPE");
    }

    @Test
    void refusesOversizedCodesInThePathBeforeLookingThemUp() {
        String longCode = "A".repeat(5000);

        MvcTestResult mission = mvc.get().uri("/api/v1/missions/{code}", longCode).exchange();
        MvcTestResult member = mvc.get().uri("/api/v1/crew-members/{code}", longCode).exchange();
        MvcTestResult vehicle = mvc.get().uri("/api/v1/vehicles/{code}", longCode).exchange();

        assertProblem(mission, HttpStatus.BAD_REQUEST, "VALIDATION_FAILED");
        assertProblem(member, HttpStatus.BAD_REQUEST, "VALIDATION_FAILED");
        assertProblem(vehicle, HttpStatus.BAD_REQUEST, "VALIDATION_FAILED");
        assertThat(mission).bodyJson().extractingPath("$.errors[0].message").asString().doesNotContain(longCode);
        verifyNoInteractions(missions, crew, vehicles);
    }

    @Test
    void treatsInjectionInThePathAsAnOrdinaryUnknownCode() {
        given(missions.get(any())).willThrow(new ResourceNotFoundException("Mission", "X"));

        assertProblem(mvc.get().uri("/api/v1/missions/{code}", "' OR 1=1--").exchange(),
                HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");
    }

    private static Arguments invalid(String name, String body, String field) {
        return Arguments.of(name, body, HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", field);
    }

    private static Arguments malformed(String name, String body) {
        return Arguments.of(name, body, HttpStatus.BAD_REQUEST, "MALFORMED_REQUEST", null);
    }

    private static void assertProblem(MvcTestResult result, HttpStatus status, String code) {
        assertThat(result).hasStatus(status);
        assertThat(result).hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo(code);
    }
}
