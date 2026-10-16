package io.github.jakiwz.aether.missions.domain;

import java.time.OffsetDateTime;
import java.util.List;
import org.jspecify.annotations.Nullable;

/** A mission as read back from the store. Objectives are ordered by sequence number. */
public record Mission(
        String code,
        String title,
        @Nullable String description,
        List<String> objectives,
        MissionType type,
        String originColonyCode,
        OffsetDateTime plannedStartAt,
        OffsetDateTime plannedEndAt,
        MissionStatus status,
        MissionPriority priority,
        SafetyLevel safetyLevel,
        String createdBy,
        OffsetDateTime createdAt) {
}
