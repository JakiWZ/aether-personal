package io.github.jakiwz.aether.incidents.domain;

/**
 * How serious an incident is, lowest first, as allowed by {@code ck_incident_severity} (V10).
 *
 * <ul>
 *   <li>{@link #LOW}: no impact on safety or operations.</li>
 *   <li>{@link #MEDIUM}: degraded operations, no danger for the crew.</li>
 *   <li>{@link #HIGH}: operations at risk or a potential danger for the crew.</li>
 *   <li>{@link #CRITICAL}: immediate danger for the crew or the base.</li>
 * </ul>
 */
public enum IncidentSeverity {
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL
}
