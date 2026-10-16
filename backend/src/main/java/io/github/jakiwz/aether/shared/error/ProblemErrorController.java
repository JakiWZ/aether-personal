package io.github.jakiwz.aether.shared.error;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.http.HttpServletRequest;
import java.net.URI;
import org.springframework.boot.webmvc.error.ErrorController;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Renders the errors that never reach a controller (rejected by a filter or by the servlet
 * container, e.g. {@code TRACE} or an oversized body) as Problem Details with a stable {@code code},
 * like {@link GlobalExceptionHandler} does for everything else. Replaces Spring Boot's
 * {@code BasicErrorController}, whose body has neither the RFC 9457 shape nor a {@code code}.
 */
@RestController
class ProblemErrorController implements ErrorController {

    @RequestMapping("${server.error.path:/error}")
    ResponseEntity<ProblemDetail> error(HttpServletRequest request) {
        HttpStatusCode status = statusOf(request);
        HttpStatus known = HttpStatus.resolve(status.value());
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(status,
                known != null ? known.getReasonPhrase() : "The request could not be processed.");
        problem.setProperty(GlobalExceptionHandler.CODE, ErrorCode.forStatus(status));
        if (request.getAttribute(RequestDispatcher.ERROR_REQUEST_URI) instanceof String uri) {
            try {
                problem.setInstance(URI.create(uri));
            } catch (IllegalArgumentException ignored) {
                // The container accepted a path java.net.URI rejects; the problem stays valid without it.
            }
        }
        return ResponseEntity.status(status).contentType(MediaType.APPLICATION_PROBLEM_JSON).body(problem);
    }

    private static HttpStatusCode statusOf(HttpServletRequest request) {
        Object code = request.getAttribute(RequestDispatcher.ERROR_STATUS_CODE);
        return code instanceof Integer value && value >= 400 && value <= 599
                ? HttpStatusCode.valueOf(value)
                : HttpStatus.INTERNAL_SERVER_ERROR;
    }
}
