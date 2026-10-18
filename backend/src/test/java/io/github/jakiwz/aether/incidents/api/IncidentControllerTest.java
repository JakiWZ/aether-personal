package io.github.jakiwz.aether.incidents.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

import io.github.jakiwz.aether.incidents.domain.Incident;
import io.github.jakiwz.aether.incidents.domain.IncidentErrorCode;
import io.github.jakiwz.aether.incidents.domain.IncidentService;
import io.github.jakiwz.aether.incidents.domain.IncidentSeverity;
import io.github.jakiwz.aether.incidents.domain.IncidentStatus;
import io.github.jakiwz.aether.incidents.domain.NewIncident;
import io.github.jakiwz.aether.shared.config.JacksonConfig;
import io.github.jakiwz.aether.shared.error.BusinessRuleViolationException;
import io.github.jakiwz.aether.shared.error.ResourceNotFoundException;
import io.github.jakiwz.aether.shared.security.SecurityConfig;
import java.time.OffsetDateTime;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
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
 * Contract of {@code /api/v1/incidents} (HEL-501).
 */
@WebMvcTest(IncidentController.class)
@Import({JacksonConfig.class, SecurityConfig.class})
@WithMockUser(username = "crew.conti", authorities = {"INCIDENT_READ", "INCIDENT_REPORT"})
class IncidentControllerTest {

    private static final String VALID_BODY = """
            {"colonyCode":"ARS-01","title":"Airlock pressure drop",
             "description":"Pressure fell to 96 kPa.\\nAirlock sealed.","severity":"HIGH"}""";

    private static final Incident AIRLOCK = new Incident("INC-0007", "Airlock pressure drop",
            "Pressure fell to 96 kPa.\nAirlock sealed.", IncidentSeverity.HIGH, IncidentStatus.OPEN, "ARS-01",
            "crew.conti", OffsetDateTime.parse("2040-03-01T10:15:30Z"));

    @Autowired
    MockMvcTester mvc;

    @MockitoBean
    IncidentService service;

    @Test
    void listsIncidentsNewestFirst() {
        given(service.list(0, 20)).willReturn(new PageImpl<>(List.of(AIRLOCK), PageRequest.of(0, 20), 1));

        assertThat(mvc.get().uri("/api/v1/incidents"))
                .hasStatusOk()
                .bodyJson().isEqualTo("""
                        {"items":[{"code":"INC-0007","title":"Airlock pressure drop",
                          "description":"Pressure fell to 96 kPa.\\nAirlock sealed.","severity":"HIGH",
                          "status":"OPEN","colonyCode":"ARS-01","reportedBy":"crew.conti",
                          "openedAt":"2040-03-01T10:15:30Z"}],
                         "page":0,"size":20,"totalItems":1,"totalPages":1}""");
    }

    @Test
    void opensAnIncidentAndPointsToIt() {
        given(service.open(any())).willReturn(AIRLOCK);

        MvcTestResult result = post(VALID_BODY);

        assertThat(result).hasStatus(HttpStatus.CREATED)
                .hasHeader("Location", "http://localhost/api/v1/incidents/INC-0007");
        assertThat(result).bodyJson().extractingPath("$.status").isEqualTo("OPEN");
        assertThat(result).bodyJson().extractingPath("$.openedAt").isEqualTo("2040-03-01T10:15:30Z");
        verify(service).open(new NewIncident("ARS-01", "Airlock pressure drop",
                "Pressure fell to 96 kPa.\nAirlock sealed.", IncidentSeverity.HIGH));
    }

    @ParameterizedTest
    @ValueSource(strings = {"colonyCode", "title", "description", "severity"})
    void rejectsAnIncidentWithoutAMandatoryField(String field) {
        MvcTestResult result = post(VALID_BODY.replaceFirst("\"" + field + "\":\"[^\"]*\"", "\"" + field + "\":null"));

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST)
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("VALIDATION_FAILED");
        assertThat(result).bodyJson().extractingPath("$.errors[0].field").isEqualTo(field);
        verifyNoInteractions(service);
    }

    @Test
    void rejectsASeverityOutsideTheControlledList() {
        MvcTestResult result = post(VALID_BODY.replace("\"HIGH\"", "\"CATASTROPHIC\""));

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST)
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        verifyNoInteractions(service);
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "\"status\":\"CLOSED\",", "\"code\":\"INC-9999\",", "\"openedAt\":\"2000-01-01T00:00:00Z\","})
    void refusesFieldsTheServerAssigns(String field) {
        assertThat(post(VALID_BODY.replaceFirst("\\{", "{" + field))).hasStatus(HttpStatus.BAD_REQUEST);
        verifyNoInteractions(service);
    }

    @Test
    void reportsAnUnknownBaseAsAConflict() {
        given(service.open(any())).willThrow(new BusinessRuleViolationException(
                IncidentErrorCode.INCIDENT_COLONY_NOT_FOUND, "Base 'NOPE-01' does not exist."));

        assertThat(post(VALID_BODY.replace("ARS-01", "NOPE-01")))
                .hasStatus(HttpStatus.CONFLICT)
                .bodyJson().extractingPath("$.code").isEqualTo("INCIDENT_COLONY_NOT_FOUND");
    }

    @Test
    void answersNotFoundForAnUnknownIncident() {
        given(service.get("INC-9999")).willThrow(new ResourceNotFoundException("Incident", "INC-9999"));

        assertThat(mvc.get().uri("/api/v1/incidents/INC-9999"))
                .hasStatus(HttpStatus.NOT_FOUND)
                .bodyJson().extractingPath("$.code").isEqualTo("RESOURCE_NOT_FOUND");
    }

    private MvcTestResult post(String body) {
        return mvc.post().uri("/api/v1/incidents").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(body).exchange();
    }
}
