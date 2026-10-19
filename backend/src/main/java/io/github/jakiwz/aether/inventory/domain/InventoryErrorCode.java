package io.github.jakiwz.aether.inventory.domain;

/**
 * Stable error codes of the inventory domain (ADR-0005); part of the public API.
 */
public final class InventoryErrorCode {

    public static final String RESOURCE_CODE_TAKEN = "RESOURCE_CODE_TAKEN";
    public static final String UNIT_OF_MEASURE_NOT_FOUND = "UNIT_OF_MEASURE_NOT_FOUND";

    private InventoryErrorCode() {
    }
}
