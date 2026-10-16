package io.github.jakiwz.aether.missions.domain;

/** Operational priority, mirroring {@code ck_mission_priority} (V6), lowest first. */
public enum MissionPriority {
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL
}
