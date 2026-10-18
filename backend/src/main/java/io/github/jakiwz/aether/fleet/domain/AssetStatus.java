package io.github.jakiwz.aether.fleet.domain;

/**
 * Operational status of a technical asset, vehicles included, as allowed by {@code ck_asset_status} (V5).
 *
 * <ul>
 *   <li>{@link #AVAILABLE}: ready to be assigned.</li>
 *   <li>{@link #IN_USE}: assigned to an operation or a mission.</li>
 *   <li>{@link #MAINTENANCE}: being serviced; back in operation afterwards.</li>
 *   <li>{@link #OUT_OF_SERVICE}: broken or unsafe, waiting for a repair decision.</li>
 *   <li>{@link #DECOMMISSIONED}: permanently retired; the record is kept (BR-010).</li>
 * </ul>
 */
public enum AssetStatus {
    AVAILABLE,
    IN_USE,
    MAINTENANCE,
    OUT_OF_SERVICE,
    DECOMMISSIONED
}
