package io.github.jakiwz.aether.shared.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.UUID;
import java.util.regex.Pattern;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Gives every request a correlation id (ADR-0014): the caller's {@code X-Request-ID} when it is a
 * UUID, so a proxy or the SPA can follow its own id, otherwise a new random one. Anything else the
 * caller sends is ignored rather than copied into logs (OWASP Logging Cheat Sheet, log injection).
 * The id is echoed in the response and is in the MDC for every log line written while serving it.
 * Runs first, so even requests refused by later filters are traceable.
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
class CorrelationIdFilter extends OncePerRequestFilter {

    private static final Pattern UUID_TEXT =
            Pattern.compile("\\p{XDigit}{8}-\\p{XDigit}{4}-\\p{XDigit}{4}-\\p{XDigit}{4}-\\p{XDigit}{12}");

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String id = correlationId(request.getHeader(CorrelationId.HEADER));
        response.setHeader(CorrelationId.HEADER, id);
        MDC.put(CorrelationId.MDC_KEY, id);
        try {
            chain.doFilter(request, response);
        } finally {
            MDC.remove(CorrelationId.MDC_KEY);
        }
    }

    @Override
    protected boolean shouldNotFilterErrorDispatch() {
        return false; // keep the id in the MDC while the error page is rendered
    }

    private static String correlationId(String header) {
        if (header != null && UUID_TEXT.matcher(header).matches()) {
            return UUID.fromString(header).toString();
        }
        return UUID.randomUUID().toString();
    }
}
