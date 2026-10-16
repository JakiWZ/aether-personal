package io.github.jakiwz.aether.missions.api;

import io.github.jakiwz.aether.missions.domain.MissionPriority;
import io.github.jakiwz.aether.missions.domain.MissionType;
import io.github.jakiwz.aether.missions.domain.NewMission;
import io.github.jakiwz.aether.missions.domain.SafetyLevel;
import io.github.jakiwz.aether.shared.validation.PlainText;
import io.github.jakiwz.aether.shared.validation.SupportedInstant;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.OffsetDateTime;
import org.jspecify.annotations.Nullable;

@PlannedWindow
@Schema(name = "CreateMission", description = "Drafts a mission (PHX-201). The server sets status DRAFT.")
public record CreateMissionRequest(
        @Schema(description = "Unique mission code; stored upper case", example = "PHX-020")
        @NotBlank @Pattern(regexp = "^[A-Za-z0-9][A-Za-z0-9-]{2,59}$",
                message = "must be 3-60 letters, digits or dashes") String code,
        @Schema(example = "Jezero delta survey") @NotBlank @Size(max = 200) @PlainText String title,
        @Schema(description = "Free-text context", nullable = true)
        @Size(max = 4000) @PlainText(multiline = true) @Nullable String description,
        @Schema(description = "What the mission must achieve; stored as objective 1",
                example = "Map the delta front with lidar")
        @NotBlank @Size(max = 2000) @PlainText(multiline = true) String objective,
        @Schema(description = "Kind of mission") @NotNull MissionType type,
        @Schema(description = "Code of an existing, active base the mission departs from", example = "ARS-01")
        @NotBlank @Size(max = 30) @PlainText String originColonyCode,
        @Schema(description = "ISO-8601 with offset; not in the past", example = "2040-05-01T08:00:00Z")
        @NotNull @FutureOrPresent @SupportedInstant OffsetDateTime plannedStartAt,
        @Schema(description = "ISO-8601 with offset; after plannedStartAt", example = "2040-05-03T18:00:00Z")
        @NotNull @SupportedInstant OffsetDateTime plannedEndAt,
        @Schema(description = "LOW, MEDIUM, HIGH or CRITICAL") @NotNull MissionPriority priority,
        @Schema(description = "Risk level: STANDARD, ELEVATED, HIGH_RISK or CRITICAL") @NotNull SafetyLevel safetyLevel) {

    NewMission toCommand() {
        return new NewMission(code, title, description, objective, type, originColonyCode, plannedStartAt,
                plannedEndAt, priority, safetyLevel);
    }
}
