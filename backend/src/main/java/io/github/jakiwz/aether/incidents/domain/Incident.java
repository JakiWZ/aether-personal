package io.github.jakiwz.aether.incidents.domain;

import java.time.OffsetDateTime;

/**
 * An operational incident (HEL-501). {@code code} is assigned by the system; {@code openedAt} is
 * the server time of the report, in UTC (BR-011).
 */
public record Incident(
        String code,
        String title,
        String description,
        IncidentSeverity severity,
        IncidentStatus status,
        String colonyCode,
        String reportedBy,
        OffsetDateTime openedAt) {
}
