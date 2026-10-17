package io.github.jakiwz.aether.shared.security;

import io.github.jakiwz.aether.shared.error.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URI;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ProblemDetail;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.security.web.csrf.CsrfException;
import tools.jackson.databind.json.JsonMapper;

/**
 * Answers the requests the security filters reject with the same Problem Details as every other
 * error (ADR-0005): {@code 401 AUTHENTICATION_REQUIRED}, {@code 403 ACCESS_DENIED} or
 * {@code 403 CSRF_TOKEN_INVALID}. No {@code WWW-Authenticate} challenge: the SPA shows its login page.
 * Refusals of a signed-in user are logged as warnings: a burst of them is worth a look (OWASP A09).
 */
class ProblemSecurityHandler implements AuthenticationEntryPoint, AccessDeniedHandler {

    private static final Logger log = LoggerFactory.getLogger(ProblemSecurityHandler.class);

    private final JsonMapper json;

    ProblemSecurityHandler(JsonMapper json) {
        this.json = json;
    }

    @Override
    public void commence(HttpServletRequest request, HttpServletResponse response,
            AuthenticationException exception) throws IOException {
        write(request, response, HttpStatus.UNAUTHORIZED, ErrorCode.AUTHENTICATION_REQUIRED,
                "Sign in to use this function.");
    }

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response,
            AccessDeniedException exception) throws IOException {
        // The URI is logged as received, still percent-encoded, so it cannot break the log line.
        log.warn("Access denied: {} {} for {} ({})", request.getMethod(), request.getRequestURI(),
                request.getRemoteUser(), exception.getClass().getSimpleName());
        if (exception instanceof CsrfException) {
            write(request, response, HttpStatus.FORBIDDEN, ErrorCode.CSRF_TOKEN_INVALID,
                    "The request did not carry a valid CSRF token. Reload the page and try again.");
        } else {
            write(request, response, HttpStatus.FORBIDDEN, ErrorCode.ACCESS_DENIED,
                    "Your roles do not allow this operation.");
        }
    }

    private void write(HttpServletRequest request, HttpServletResponse response, HttpStatus status, String code,
            String detail) throws IOException {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(status, detail);
        problem.setProperty("code", code);
        try {
            problem.setInstance(URI.create(request.getRequestURI()));
        } catch (IllegalArgumentException ignored) {
            // a path java.net.URI rejects; the problem stays valid without it
        }
        response.setStatus(status.value());
        response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        json.writeValue(response.getOutputStream(), problem);
    }
}
