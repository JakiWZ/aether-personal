package io.github.jakiwz.aether.inventory.api;

import io.github.jakiwz.aether.inventory.domain.Resource;
import io.github.jakiwz.aether.inventory.domain.ResourceCategory;
import io.swagger.v3.oas.annotations.media.Schema;
import org.jspecify.annotations.Nullable;

@Schema(name = "Resource", description = "A consumable resource of the catalogue.")
public record ResourceResponse(
        @Schema(description = "Unique business code", example = "WATER") String code,
        @Schema(example = "Potable water") String name,
        ResourceCategory category,
        @Schema(description = "Code of the unit of measure", example = "L") String unitCode,
        @Schema(description = "Symbol of the unit of measure", example = "L") String unitSymbol,
        @Schema(description = "True when running out endangers the crew") boolean critical,
        @Schema(description = "False for resources taken out of use; their history is kept") boolean active,
        @Schema(description = "Days a lot stays usable", nullable = true) @Nullable Integer shelfLifeDays) {

    static ResourceResponse from(Resource resource) {
        return new ResourceResponse(resource.code(), resource.name(), resource.category(), resource.unitCode(),
                resource.unitSymbol(), resource.critical(), resource.active(), resource.shelfLifeDays());
    }
}
