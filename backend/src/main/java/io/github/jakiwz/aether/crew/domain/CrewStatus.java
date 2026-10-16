package io.github.jakiwz.aether.crew.domain;

/**
 * Operational status of a crew member, as allowed by {@code ck_crew_status} (V3).
 *
 * <ul>
 *   <li>{@link #ACTIVE}: available for operations.</li>
 *   <li>{@link #OFF_DUTY}: temporarily not working (rest, leave).</li>
 *   <li>{@link #TRAINING}: in training, not yet assignable to operations.</li>
 *   <li>{@link #MEDICAL_LEAVE}: not fit for duty.</li>
 *   <li>{@link #SUSPENDED}: removed from duty pending a decision.</li>
 *   <li>{@link #INACTIVE}: no longer part of the crew; the record is kept (BR-010).</li>
 * </ul>
 */
public enum CrewStatus {
    ACTIVE,
    OFF_DUTY,
    TRAINING,
    MEDICAL_LEAVE,
    SUSPENDED,
    INACTIVE
}
