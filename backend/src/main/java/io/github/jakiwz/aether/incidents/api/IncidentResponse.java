package io.github.jakiwz.aether.incidents.api;

import io.github.jakiwz.aether.incidents.domain.Incident;
import io.github.jakiwz.aether.incidents.domain.IncidentSeverity;
import io.github.jakiwz.aether.incidents.domain.IncidentStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.OffsetDateTime;

@Schema(name = "Incident", description = "An operational incident.")
public record IncidentResponse(
        @Schema(description = "Unique code assigned by the server", example = "INC-0007") String code,
        String title,
        String description,
        IncidentSeverity severity,
        IncidentStatus status,
        @Schema(description = "Code of the base", example = "ARS-01") String colonyCode,
        @Schema(description = "Username of the reporter", example = "crew.conti") String reportedBy,
        @Schema(description = "Server time of the report, ISO-8601 in UTC") OffsetDateTime openedAt) {

    static IncidentResponse from(Incident incident) {
        return new IncidentResponse(incident.code(), incident.title(), incident.description(), incident.severity(),
                incident.status(), incident.colonyCode(), incident.reportedBy(), incident.openedAt());
    }
}
