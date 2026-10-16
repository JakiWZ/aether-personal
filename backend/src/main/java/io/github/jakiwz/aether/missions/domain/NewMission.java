package io.github.jakiwz.aether.missions.domain;

import java.time.OffsetDateTime;
import org.jspecify.annotations.Nullable;

/** Data needed to draft a mission (PHX-201); status and author are set by the server. */
public record NewMission(
        String code,
        String title,
        @Nullable String description,
        String objective,
        MissionType type,
        String originColonyCode,
        OffsetDateTime plannedStartAt,
        OffsetDateTime plannedEndAt,
        MissionPriority priority,
        SafetyLevel safetyLevel) {
}
