package io.github.jakiwz.aether.missions.domain;

/** Stable error codes of the missions domain (ADR-0005). */
public final class MissionErrorCode {

    public static final String MISSION_CODE_TAKEN = "MISSION_CODE_TAKEN";
    public static final String ORIGIN_COLONY_NOT_FOUND = "ORIGIN_COLONY_NOT_FOUND";
    public static final String ORIGIN_COLONY_INACTIVE = "ORIGIN_COLONY_INACTIVE";

    private MissionErrorCode() {
    }
}
