package io.github.jakiwz.aether.incidents.domain;

/**
 * Data needed to open an incident; already validated for shape by the API layer.
 */
public record NewIncident(String colonyCode, String title, String description, IncidentSeverity severity) {
}
