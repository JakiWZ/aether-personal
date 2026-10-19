package io.github.jakiwz.aether.inventory.api;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

@Schema(name = "UpdateResource", description = "Activates or deactivates a resource (ORI-401).")
public record UpdateResourceRequest(
        @Schema(description = "False takes the resource out of use; its history is kept", example = "false")
        @NotNull Boolean active) {
}
