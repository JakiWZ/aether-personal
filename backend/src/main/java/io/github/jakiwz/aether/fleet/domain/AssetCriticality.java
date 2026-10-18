package io.github.jakiwz.aether.fleet.domain;

/**
 * How much operations depend on an asset, lowest first, as allowed by {@code ck_asset_criticality} (V5).
 */
public enum AssetCriticality {
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL
}
