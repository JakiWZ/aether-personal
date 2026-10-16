package io.github.jakiwz.aether.shared.error;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.servlet.RequestDispatcher;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;

/**
 * Errors forwarded to {@code /error} by the servlet container are Problem Details too.
 */
@WebMvcTest(ProblemErrorController.class)
@AutoConfigureMockMvc(addFilters = false) // error mapping only; security has its own tests
class ProblemErrorControllerTest {

    @Autowired
    MockMvcTester mvc;

    @Test
    void rendersAContainerErrorAsAProblemWithACode() {
        MvcTestResult result = mvc.post().uri("/error")
                .requestAttr(RequestDispatcher.ERROR_STATUS_CODE, 413)
                .requestAttr(RequestDispatcher.ERROR_REQUEST_URI, "/api/v1/missions")
                .exchange();

        assertThat(result).hasStatus(HttpStatus.CONTENT_TOO_LARGE)
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(result).bodyJson().isLenientlyEqualTo("""
                {"status":413,"code":"PAYLOAD_TOO_LARGE","instance":"/api/v1/missions"}""");
    }

    @Test
    void treatsAMissingOrInvalidStatusAsAnInternalError() {
        MvcTestResult result = mvc.get().uri("/error")
                .requestAttr(RequestDispatcher.ERROR_STATUS_CODE, 200)
                .requestAttr(RequestDispatcher.ERROR_REQUEST_URI, "/not a uri")
                .exchange();

        assertThat(result).hasStatus(HttpStatus.INTERNAL_SERVER_ERROR);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("INTERNAL_ERROR");
    }
}
