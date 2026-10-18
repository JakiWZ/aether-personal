package io.github.jakiwz.aether.inventory.domain;

/**
 * A unit of measure resources are counted in (reference data, V14).
 */
public record UnitOfMeasure(String code, String name, String symbol, String quantityType) {
}
