package io.github.jakiwz.aether.missions.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

import io.github.jakiwz.aether.missions.domain.Mission;
import io.github.jakiwz.aether.missions.domain.MissionErrorCode;
import io.github.jakiwz.aether.missions.domain.MissionPriority;
import io.github.jakiwz.aether.missions.domain.MissionService;
import io.github.jakiwz.aether.missions.domain.MissionStatus;
import io.github.jakiwz.aether.missions.domain.MissionType;
import io.github.jakiwz.aether.missions.domain.SafetyLevel;
import io.github.jakiwz.aether.shared.error.BusinessRuleViolationException;
import io.github.jakiwz.aether.shared.error.ResourceNotFoundException;
import io.github.jakiwz.aether.shared.security.SecurityConfig;
import java.time.OffsetDateTime;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;

/**
 * Contract of {@code /api/v1/missions} (PHX-201).
 */
@WebMvcTest(MissionController.class)
@Import(SecurityConfig.class)
@WithMockUser(authorities = {"MISSION_READ", "MISSION_MANAGE"})
class MissionControllerTest {

    private static final String VALID_BODY = """
            {"code":"phx-020","title":"Jezero delta survey","objective":"Map the delta front",
             "type":"EXPLORATION","originColonyCode":"ARS-01",
             "plannedStartAt":"2099-05-01T08:00:00Z","plannedEndAt":"2099-05-03T18:00:00+02:00",
             "priority":"HIGH","safetyLevel":"ELEVATED"}""";

    private static final Mission JEZERO = new Mission("PHX-020", "Jezero delta survey", null,
            List.of("Map the delta front"), MissionType.EXPLORATION, "ARS-01",
            OffsetDateTime.parse("2099-05-01T08:00:00Z"), OffsetDateTime.parse("2099-05-03T16:00:00Z"),
            MissionStatus.DRAFT, MissionPriority.HIGH, SafetyLevel.ELEVATED, "system",
            OffsetDateTime.parse("2026-10-16T10:00:00Z"));

    @Autowired
    MockMvcTester mvc;

    @MockitoBean
    MissionService service;

    @Test
    void listsTheFirstPageByDefault() {
        given(service.list(0, 20)).willReturn(new PageImpl<>(List.of(JEZERO), PageRequest.of(0, 20), 1));

        assertThat(mvc.get().uri("/api/v1/missions"))
                .hasStatusOk()
                .bodyJson().isLenientlyEqualTo("""
                        {"items":[{"code":"PHX-020","objectives":["Map the delta front"]}],
                         "page":0,"size":20,"totalItems":1,"totalPages":1}""");
    }

    @Test
    void refusesANegativePage() {
        assertThat(mvc.get().uri("/api/v1/missions?page=-1"))
                .hasStatus(HttpStatus.BAD_REQUEST)
                .bodyJson().extractingPath("$.errors[0].field").isEqualTo("page");
        verify(service, never()).list(anyInt(), anyInt());
    }

    @Test
    void draftsAMissionAndPointsToIt() {
        given(service.create(any())).willReturn(JEZERO);

        MvcTestResult result = post(VALID_BODY);

        assertThat(result).hasStatus(HttpStatus.CREATED)
                .hasHeader("Location", "http://localhost/api/v1/missions/PHX-020");
        assertThat(result).bodyJson().isLenientlyEqualTo("""
                {"code":"PHX-020","status":"DRAFT","objectives":["Map the delta front"],
                 "plannedStartAt":"2099-05-01T08:00:00Z","createdBy":"system"}""");
    }

    @Test
    void rejectsAStatusSentByTheClient() {
        assertThat(post(VALID_BODY.replace("\"priority\"", "\"status\":\"APPROVED\",\"priority\"")))
                .hasStatus(HttpStatus.BAD_REQUEST)
                .bodyJson().extractingPath("$.code").isEqualTo("MALFORMED_REQUEST");
        verify(service, never()).create(any());
    }

    @Test
    void rejectsMissingMandatoryFields() {
        MvcTestResult result = post("""
                {"code":"","title":" "}""");

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("VALIDATION_FAILED");
        assertThat(result).bodyJson().extractingPath("$.errors[*].field").asArray()
                .contains("code", "title", "objective", "type", "originColonyCode", "plannedStartAt",
                        "plannedEndAt", "priority", "safetyLevel");
        verify(service, never()).create(any());
    }

    @Test
    void rejectsAnEndThatDoesNotFollowTheStart() {
        MvcTestResult result = post(VALID_BODY.replace("2099-05-03T18:00:00+02:00", "2099-05-01T10:00:00+02:00"));

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST);
        assertThat(result).bodyJson().isLenientlyEqualTo("""
                {"code":"VALIDATION_FAILED","errors":[{"field":"plannedEndAt","message":"must be after plannedStartAt"}]}""");
        verify(service, never()).create(any());
    }

    @Test
    void rejectsAStartInThePast() {
        MvcTestResult result = post(VALID_BODY.replace("2099-05-01T08:00:00Z", "2020-05-01T08:00:00Z"));

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST);
        assertThat(result).bodyJson().extractingPath("$.errors[0].field").isEqualTo("plannedStartAt");
    }

    @Test
    void rejectsAPriorityOutsideTheDocumentedSet() {
        MvcTestResult result = post(VALID_BODY.replace("\"HIGH\"", "\"URGENT\""));

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("MALFORMED_REQUEST");
        verify(service, never()).create(any());
    }

    @Test
    void reportsAnUnknownBaseAsAConflict() {
        given(service.create(any())).willThrow(new BusinessRuleViolationException(
                MissionErrorCode.ORIGIN_COLONY_NOT_FOUND, "Base 'NOPE-01' does not exist."));

        MvcTestResult result = post(VALID_BODY);

        assertThat(result).hasStatus(HttpStatus.CONFLICT)
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("ORIGIN_COLONY_NOT_FOUND");
    }

    @Test
    void unknownMissionIsA404() {
        given(service.get("PHX-999")).willThrow(new ResourceNotFoundException("Mission", "PHX-999"));

        assertThat(mvc.get().uri("/api/v1/missions/PHX-999"))
                .hasStatus(HttpStatus.NOT_FOUND)
                .bodyJson().extractingPath("$.code").isEqualTo("RESOURCE_NOT_FOUND");
    }

    private MvcTestResult post(String body) {
        return mvc.post().uri("/api/v1/missions").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(body)
                .exchange();
    }
}
