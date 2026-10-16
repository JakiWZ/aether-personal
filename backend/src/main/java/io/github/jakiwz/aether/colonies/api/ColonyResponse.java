package io.github.jakiwz.aether.colonies.api;

import io.github.jakiwz.aether.colonies.domain.Colony;
import io.github.jakiwz.aether.colonies.domain.ColonyStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;
import org.jspecify.annotations.Nullable;

@Schema(name = "Colony", description = "A Martian base (colony).")
public record ColonyResponse(
        @Schema(description = "Unique business code", example = "ARS-01") String code,
        @Schema(example = "Ares Prime") String name,
        @Schema(description = "Operational status") ColonyStatus status,
        @Schema(description = "False for bases taken out of operation; their history is kept")
        boolean active,
        @Schema(description = "Maximum population, when defined", nullable = true) @Nullable Integer maxPopulation,
        @Schema(description = "Date the base was established", nullable = true) @Nullable LocalDate establishedAt) {

    static ColonyResponse from(Colony colony) {
        return new ColonyResponse(colony.code(), colony.name(), colony.status(), colony.active(),
                colony.maxPopulation(), colony.establishedAt());
    }
}
