package io.github.jakiwz.aether.incidents.domain;

/**
 * Lifecycle status of an incident, as allowed by {@code ck_incident_status} (V10). A new incident
 * is always {@link #OPEN}; the other transitions belong to later stories.
 */
public enum IncidentStatus {
    OPEN,
    ACKNOWLEDGED,
    IN_PROGRESS,
    RESOLVED,
    CLOSED,
    CANCELLED
}
