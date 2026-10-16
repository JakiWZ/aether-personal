package io.github.jakiwz.aether.colonies.domain;

/**
 * Operational status of a base, as allowed by {@code ck_colony_status} (V2).
 * {@link #INACTIVE} bases keep their history (BR-010) and are listed like any other.
 */
public enum ColonyStatus {
    PLANNED,
    CONSTRUCTION,
    OPERATIONAL,
    DEGRADED,
    EMERGENCY,
    INACTIVE
}
