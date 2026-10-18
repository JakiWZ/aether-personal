package io.github.jakiwz.aether.inventory.domain;

/**
 * Category of a consumable resource, as allowed by {@code ck_resource_category} (V16).
 */
public enum ResourceCategory {
    /** Water, oxygen and other consumables of the life support systems. */
    LIFE_SUPPORT,
    FOOD,
    FUEL,
    SPARE_PART,
    MEDICAL,
    /** Reagents and materials for laboratories. */
    SCIENTIFIC,
    OTHER
}
