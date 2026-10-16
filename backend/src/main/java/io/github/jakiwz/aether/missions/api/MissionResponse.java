package io.github.jakiwz.aether.missions.api;

import io.github.jakiwz.aether.missions.domain.Mission;
import io.github.jakiwz.aether.missions.domain.MissionPriority;
import io.github.jakiwz.aether.missions.domain.MissionStatus;
import io.github.jakiwz.aether.missions.domain.MissionType;
import io.github.jakiwz.aether.missions.domain.SafetyLevel;
import io.swagger.v3.oas.annotations.media.Schema;
import java.time.OffsetDateTime;
import java.util.List;
import org.jspecify.annotations.Nullable;

@Schema(name = "Mission", description = "A mission and its planned window.")
public record MissionResponse(
        @Schema(example = "PHX-001") String code,
        String title,
        @Schema(nullable = true) @Nullable String description,
        @Schema(description = "Objectives in sequence order") List<String> objectives,
        MissionType type,
        @Schema(example = "ARS-01") String originColonyCode,
        OffsetDateTime plannedStartAt,
        OffsetDateTime plannedEndAt,
        MissionStatus status,
        MissionPriority priority,
        @Schema(description = "Risk level") SafetyLevel safetyLevel,
        @Schema(description = "Username of the author") String createdBy,
        OffsetDateTime createdAt) {

    static MissionResponse from(Mission mission) {
        return new MissionResponse(mission.code(), mission.title(), mission.description(), mission.objectives(),
                mission.type(), mission.originColonyCode(), mission.plannedStartAt(), mission.plannedEndAt(),
                mission.status(), mission.priority(), mission.safetyLevel(), mission.createdBy(),
                mission.createdAt());
    }
}
