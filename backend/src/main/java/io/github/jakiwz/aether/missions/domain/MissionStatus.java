package io.github.jakiwz.aether.missions.domain;

/** Lifecycle of a mission, mirroring {@code ck_mission_status} (V6). New missions always start as DRAFT. */
public enum MissionStatus {
    DRAFT,
    PLANNED,
    APPROVAL_PENDING,
    APPROVED,
    IN_PROGRESS,
    COMPLETED,
    ABORTED,
    CANCELLED
}
