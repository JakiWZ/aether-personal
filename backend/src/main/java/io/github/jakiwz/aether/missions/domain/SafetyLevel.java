package io.github.jakiwz.aether.missions.domain;

/** Risk level of a mission, mirroring {@code ck_mission_safety} (V6), lowest first. */
public enum SafetyLevel {
    /** Routine activity inside normal operating limits. */
    STANDARD,
    /** Extra precautions, e.g. EVA or travel outside the base perimeter. */
    ELEVATED,
    /** Known hazards that require dedicated safety measures. */
    HIGH_RISK,
    /** Life-threatening conditions, e.g. rescue operations. */
    CRITICAL
}
