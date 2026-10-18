package io.github.jakiwz.aether.inventory.api;

import io.github.jakiwz.aether.inventory.domain.UnitOfMeasure;
import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "UnitOfMeasure", description = "A unit resources are counted in.")
public record UnitOfMeasureResponse(
        @Schema(example = "KG") String code,
        @Schema(example = "Kilogram") String name,
        @Schema(example = "kg") String symbol,
        @Schema(description = "What the unit measures", example = "MASS") String quantityType) {

    static UnitOfMeasureResponse from(UnitOfMeasure unit) {
        return new UnitOfMeasureResponse(unit.code(), unit.name(), unit.symbol(), unit.quantityType());
    }
}
