package io.github.jakiwz.aether.incidents.api;

import io.github.jakiwz.aether.incidents.domain.IncidentSeverity;
import io.github.jakiwz.aether.incidents.domain.NewIncident;
import io.github.jakiwz.aether.shared.validation.PlainText;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

@Schema(name = "OpenIncident", description = "Reports an operational incident (HEL-501). "
        + "Code, status (OPEN), reporter and opening time are set by the server.")
public record OpenIncidentRequest(
        @Schema(description = "Code of the base where the incident happened", example = "ARS-01")
        @NotBlank @Size(max = 30) @PlainText String colonyCode,
        @Schema(example = "Pressure drop in airlock B") @NotBlank @Size(max = 200) @PlainText String title,
        @Schema(description = "What happened and what was done so far",
                example = "Pressure fell from 101 to 96 kPa in ten minutes; airlock sealed.")
        @NotBlank @Size(max = 4000) @PlainText(multiline = true) String description,
        @Schema(description = "LOW: no impact · MEDIUM: degraded operations · HIGH: operations or crew at risk · "
                + "CRITICAL: immediate danger") @NotNull IncidentSeverity severity) {

    NewIncident toCommand() {
        return new NewIncident(colonyCode, title, description, severity);
    }
}
