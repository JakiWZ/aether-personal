package io.github.jakiwz.aether.missions.domain;

import io.github.jakiwz.aether.colonies.persistence.ColonyEntity;
import io.github.jakiwz.aether.colonies.persistence.ColonyRepository;
import io.github.jakiwz.aether.identity.domain.CurrentActor;
import io.github.jakiwz.aether.identity.persistence.UserAccountEntity;
import io.github.jakiwz.aether.identity.persistence.UserAccountRepository;
import io.github.jakiwz.aether.missions.persistence.MissionEntity;
import io.github.jakiwz.aether.missions.persistence.MissionObjectiveEntity;
import io.github.jakiwz.aether.missions.persistence.MissionRepository;
import io.github.jakiwz.aether.missions.persistence.MissionStatusHistoryEntity;
import io.github.jakiwz.aether.missions.persistence.MissionStatusHistoryRepository;
import io.github.jakiwz.aether.shared.error.BusinessRuleViolationException;
import io.github.jakiwz.aether.shared.error.ResourceNotFoundException;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.Locale;
import org.jspecify.annotations.Nullable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Mission planning (PHOENIX). A mission is always created as {@link MissionStatus#DRAFT}, from an
 * active base, and its first status is recorded in the history with its author (BR-012).
 * The time window is validated at the API boundary and again by {@code ck_mission_planned_dates}.
 */
@Service
@Transactional(readOnly = true)
public class MissionService {

    private final MissionRepository missions;
    private final MissionStatusHistoryRepository history;
    private final ColonyRepository colonies;
    private final UserAccountRepository accounts;
    private final CurrentActor actor;

    MissionService(MissionRepository missions, MissionStatusHistoryRepository history, ColonyRepository colonies,
            UserAccountRepository accounts, CurrentActor actor) {
        this.missions = missions;
        this.history = history;
        this.colonies = colonies;
        this.accounts = accounts;
        this.actor = actor;
    }

    /** Missions ordered by planned start, then code. */
    public Page<Mission> list(int page, int size) {
        return missions.findAllBy(PageRequest.of(page, size, Sort.by("plannedStartAt", "code")))
                .map(MissionService::toDomain);
    }

    public Mission get(String code) {
        return missions.findByCode(normaliseCode(code))
                .map(MissionService::toDomain)
                .orElseThrow(() -> new ResourceNotFoundException("Mission", code));
    }

    /** Drafts a mission with its first objective and its initial status history row (PHX-201). */
    @Transactional
    public Mission create(NewMission request) {
        String code = normaliseCode(request.code());
        if (missions.existsByCode(code)) {
            throw new BusinessRuleViolationException(MissionErrorCode.MISSION_CODE_TAKEN,
                    "Mission code '%s' is already in use.".formatted(code));
        }
        ColonyEntity origin = resolveOrigin(request.originColonyCode());
        UserAccountEntity author = accounts.findByUsername(actor.username())
                .orElseThrow(() -> new IllegalStateException("No user account '%s'".formatted(actor.username())));
        OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC).truncatedTo(ChronoUnit.MICROS);

        MissionEntity mission = MissionEntity.draft(code, request.title().strip(), blankToNull(request.description()),
                request.type(), origin, request.plannedStartAt(), request.plannedEndAt(), request.priority(),
                request.safetyLevel(), author, now);
        mission.addObjective(request.objective().strip());
        missions.save(mission);
        history.save(new MissionStatusHistoryEntity(mission, null, mission.getStatus(), author, now));
        return toDomain(mission);
    }

    private ColonyEntity resolveOrigin(String colonyCode) {
        ColonyEntity colony = colonies.findByCodeAndDeletedAtIsNull(colonyCode.strip())
                .orElseThrow(() -> new BusinessRuleViolationException(MissionErrorCode.ORIGIN_COLONY_NOT_FOUND,
                        "Base '%s' does not exist.".formatted(colonyCode.strip())));
        if (!colony.isActive()) {
            throw new BusinessRuleViolationException(MissionErrorCode.ORIGIN_COLONY_INACTIVE,
                    "Base '%s' is not active and cannot start missions.".formatted(colony.getCode()));
        }
        return colony;
    }

    private static String normaliseCode(String code) {
        return code.strip().toUpperCase(Locale.ROOT);
    }

    private static @Nullable String blankToNull(@Nullable String value) {
        return value == null || value.isBlank() ? null : value.strip();
    }

    private static Mission toDomain(MissionEntity entity) {
        return new Mission(entity.getCode(), entity.getTitle(), entity.getDescription(),
                entity.getObjectives().stream().map(MissionObjectiveEntity::getDescription).toList(),
                entity.getType(), entity.getOriginColony().getCode(), entity.getPlannedStartAt(),
                entity.getPlannedEndAt(), entity.getStatus(), entity.getPriority(), entity.getSafetyLevel(),
                entity.getCreatedBy().getUsername(), entity.getCreatedAt());
    }
}
