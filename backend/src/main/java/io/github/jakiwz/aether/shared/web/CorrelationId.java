package io.github.jakiwz.aether.shared.web;

import java.util.Optional;
import java.util.UUID;
import org.slf4j.MDC;

/**
 * The id that ties together the log lines and audit events of one request (NFR-009, ADR-0014).
 * Set by {@link CorrelationIdFilter}; absent outside an HTTP request.
 */
public final class CorrelationId {

    /** Request and response header carrying the id. */
    public static final String HEADER = "X-Request-ID";
    /** Key of the id in the logging MDC, and so in every structured log line. */
    public static final String MDC_KEY = "correlationId";

    private CorrelationId() {
    }

    public static Optional<UUID> current() {
        String value = MDC.get(MDC_KEY);
        return value == null ? Optional.empty() : Optional.of(UUID.fromString(value));
    }
}
