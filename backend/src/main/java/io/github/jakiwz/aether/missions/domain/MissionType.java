package io.github.jakiwz.aether.missions.domain;

/** Kind of mission, mirroring {@code ck_mission_type} (V6). */
public enum MissionType {
    INTERNAL,
    EVA,
    SCIENCE,
    LOGISTICS,
    MAINTENANCE,
    RESCUE,
    INSPECTION,
    EXPLORATION,
    TRANSPORT
}
