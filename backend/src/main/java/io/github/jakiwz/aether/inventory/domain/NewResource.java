package io.github.jakiwz.aether.inventory.domain;

import org.jspecify.annotations.Nullable;

/**
 * Data needed to add a resource to the catalogue; already validated for shape by the API layer.
 */
public record NewResource(
        String code,
        String name,
        ResourceCategory category,
        String unitCode,
        boolean critical,
        @Nullable Integer shelfLifeDays) {
}
