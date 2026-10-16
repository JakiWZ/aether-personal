package io.github.jakiwz.aether.crew.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

import io.github.jakiwz.aether.crew.domain.CrewErrorCode;
import io.github.jakiwz.aether.crew.domain.CrewMember;
import io.github.jakiwz.aether.crew.domain.CrewMemberService;
import io.github.jakiwz.aether.crew.domain.CrewStatus;
import io.github.jakiwz.aether.shared.error.BusinessRuleViolationException;
import io.github.jakiwz.aether.shared.error.ResourceNotFoundException;
import io.github.jakiwz.aether.shared.security.SecurityConfig;
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
 * Contract of {@code /api/v1/crew-members} (ARES-103).
 */
@WebMvcTest(CrewMemberController.class)
@Import(SecurityConfig.class)
@WithMockUser(authorities = {"CREW_READ", "CREW_MANAGE"})
class CrewMemberControllerTest {

    private static final String VALID_BODY = """
            {"employeeCode":"crw-020","firstName":"Anna","lastName":"Verdi","email":"Anna.Verdi@aether.demo",
             "operationalRole":"Geologist","status":"ACTIVE","homeColonyCode":"ARS-01"}""";

    private static final CrewMember ANNA = new CrewMember("CRW-020", "Anna", "Verdi", "anna.verdi@aether.demo",
            "Geologist", CrewStatus.ACTIVE, "ARS-01");

    @Autowired
    MockMvcTester mvc;

    @MockitoBean
    CrewMemberService service;

    @Test
    void listsOnePageOfMembers() {
        given(service.list(1, 10)).willReturn(new PageImpl<>(List.of(ANNA), PageRequest.of(1, 10), 11));

        assertThat(mvc.get().uri("/api/v1/crew-members?page=1&size=10"))
                .hasStatusOk()
                .bodyJson().isLenientlyEqualTo("""
                        {"items":[{"employeeCode":"CRW-020"}],"page":1,"size":10,"totalItems":11,"totalPages":2}""");
    }

    @Test
    void refusesAPageLargerThanTheServerLimit() {
        assertThat(mvc.get().uri("/api/v1/crew-members?size=1000"))
                .hasStatus(HttpStatus.BAD_REQUEST)
                .bodyJson().extractingPath("$.errors[0].field").isEqualTo("size");
        verifyNoInteractions(service);
    }

    @Test
    void registersAMemberAndPointsToIt() {
        given(service.register(any())).willReturn(ANNA);

        MvcTestResult result = post(VALID_BODY);

        assertThat(result).hasStatus(HttpStatus.CREATED)
                .hasHeader("Location", "http://localhost/api/v1/crew-members/CRW-020");
        assertThat(result).bodyJson().extractingPath("$.employeeCode").isEqualTo("CRW-020");
        assertThat(result).bodyJson().extractingPath("$.homeColonyCode").isEqualTo("ARS-01");
    }

    @Test
    void rejectsMissingMandatoryFields() {
        MvcTestResult result = post("""
                {"employeeCode":"","firstName":" ","email":"not-an-email"}""");

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("VALIDATION_FAILED");
        assertThat(result).bodyJson().extractingPath("$.errors[*].field").asArray()
                .contains("employeeCode", "firstName", "lastName", "email", "operationalRole", "status");
        verify(service, never()).register(any());
    }

    @Test
    void rejectsAnEmployeeCodeWithInvalidCharacters() {
        MvcTestResult result = post(VALID_BODY.replace("crw-020", "crw 020!"));

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST);
        assertThat(result).bodyJson().extractingPath("$.errors[0].field").isEqualTo("employeeCode");
    }

    @Test
    void rejectsAStatusOutsideTheDocumentedSet() {
        MvcTestResult result = post(VALID_BODY.replace("\"ACTIVE\"", "\"ON_HOLIDAY\""));

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("MALFORMED_REQUEST");
        verify(service, never()).register(any());
    }

    @Test
    void reportsADuplicateCodeAsAConflict() {
        given(service.register(any())).willThrow(new BusinessRuleViolationException(
                CrewErrorCode.CREW_MEMBER_CODE_TAKEN, "Crew member code 'CRW-020' is already in use."));

        MvcTestResult result = post(VALID_BODY);

        assertThat(result).hasStatus(HttpStatus.CONFLICT)
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("CREW_MEMBER_CODE_TAKEN");
    }

    @Test
    void unknownMemberIsA404() {
        given(service.get("CRW-999")).willThrow(new ResourceNotFoundException("Crew member", "CRW-999"));

        assertThat(mvc.get().uri("/api/v1/crew-members/CRW-999"))
                .hasStatus(HttpStatus.NOT_FOUND)
                .bodyJson().extractingPath("$.code").isEqualTo("RESOURCE_NOT_FOUND");
    }

    private MvcTestResult post(String body) {
        return mvc.post().uri("/api/v1/crew-members").with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content(body)
                .exchange();
    }
}
