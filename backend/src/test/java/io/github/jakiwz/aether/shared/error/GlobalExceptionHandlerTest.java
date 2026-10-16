package io.github.jakiwz.aether.shared.error;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;

/**
 * Contract tests for TASK-007: every failure is an RFC 9457 problem with a stable {@code code}
 * and no internal details.
 */
@WebMvcTest(controllers = ProbeController.class)
@Import(ProbeController.class)
@AutoConfigureMockMvc(addFilters = false) // error mapping only; security has its own tests
class GlobalExceptionHandlerTest {

    @Autowired
    MockMvcTester mvc;

    @Test
    void notFoundIsA404WithResourceNotFoundCode() {
        MvcTestResult result = mvc.get().uri("/probe/missing").exchange();

        assertProblem(result, HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");
        assertThat(result).bodyJson().extractingPath("$.detail").isEqualTo("Mission 'MSN-404' was not found");
    }

    @Test
    void businessRuleViolationIsA409WithDomainCode() {
        MvcTestResult result = mvc.post().uri("/probe/rule").exchange();

        assertProblem(result, HttpStatus.CONFLICT, "CREW_ASSIGNMENT_OVERLAP");
        assertThat(result).bodyJson().extractingPath("$.detail").asString().contains("CRW-001");
    }

    @Test
    void invalidBodyListsEveryFieldViolation() {
        MvcTestResult result = mvc.post().uri("/probe/validate")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"\",\"quantity\":0}")
                .exchange();

        assertProblem(result, HttpStatus.BAD_REQUEST, "VALIDATION_FAILED");
        assertThat(result).bodyJson().extractingPath("$.errors[*].field").asArray()
                .containsExactly("code", "quantity");
    }

    @Test
    void invalidRequestParameterIsAValidationProblem() {
        MvcTestResult result = mvc.get().uri("/probe/param?page=0").exchange();

        assertProblem(result, HttpStatus.BAD_REQUEST, "VALIDATION_FAILED");
        assertThat(result).bodyJson().extractingPath("$.errors[0].field").isEqualTo("page");
    }

    @Test
    void malformedJsonIsDistinguishableFromValidationErrors() {
        MvcTestResult result = mvc.post().uri("/probe/validate")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{not json")
                .exchange();

        assertProblem(result, HttpStatus.BAD_REQUEST, "MALFORMED_REQUEST");
    }

    @Test
    void unknownRouteIsA404Problem() {
        MvcTestResult result = mvc.get().uri("/probe/does-not-exist").exchange();

        assertProblem(result, HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND");
    }

    @Test
    void wrongMethodIsA405Problem() {
        MvcTestResult result = mvc.delete().uri("/probe/missing").exchange();

        assertProblem(result, HttpStatus.METHOD_NOT_ALLOWED, "METHOD_NOT_ALLOWED");
    }

    @Test
    void databaseConstraintViolationDoesNotLeakConstraintNames() {
        MvcTestResult result = mvc.get().uri("/probe/integrity").exchange();

        assertProblem(result, HttpStatus.CONFLICT, "DATA_INTEGRITY_VIOLATION");
        assertThat(result).bodyText().doesNotContain("crew_member_employee_code_key", "duplicate key");
    }

    @Test
    void unexpectedErrorIsA500WithoutInternalDetails() {
        MvcTestResult result = mvc.get().uri("/probe/boom").exchange();

        assertProblem(result, HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR");
        assertThat(result).bodyText().doesNotContain("hunter2", "IllegalStateException", "at io.github");
    }

    private static void assertProblem(MvcTestResult result, HttpStatus status, String code) {
        assertThat(result).hasStatus(status);
        assertThat(result).hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(result).bodyJson().extractingPath("$.status").isEqualTo(status.value());
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo(code);
    }
}
