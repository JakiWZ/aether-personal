package io.github.jakiwz.aether.shared.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.util.unit.DataSize;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Refuses a request whose declared body is larger than {@code aether.http.max-request-body}
 * with 413 before anything reads it (OWASP API4:2023, unrestricted resource consumption).
 * Bodies sent without a length are capped while parsing by Jackson's {@code max-document-length}.
 */
@Component
class RequestSizeLimitFilter extends OncePerRequestFilter {

    private final long maxBytes;

    RequestSizeLimitFilter(@Value("${aether.http.max-request-body:64KB}") DataSize maxRequestBody) {
        this.maxBytes = maxRequestBody.toBytes();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        if (request.getContentLengthLong() > maxBytes) {
            response.sendError(HttpStatus.CONTENT_TOO_LARGE.value());
            return;
        }
        chain.doFilter(request, response);
    }
}
