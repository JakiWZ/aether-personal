package io.github.jakiwz.aether.inventory.domain;

import org.jspecify.annotations.Nullable;

/**
 * A consumable resource of the catalogue (ORI-401). {@code code} is the business key; the unit of
 * measure is always declared, never inferred from the name (LOG-002).
 */
public record Resource(
        String code,
        String name,
        ResourceCategory category,
        String unitCode,
        String unitSymbol,
        boolean critical,
        boolean active,
        @Nullable Integer shelfLifeDays) {
}
