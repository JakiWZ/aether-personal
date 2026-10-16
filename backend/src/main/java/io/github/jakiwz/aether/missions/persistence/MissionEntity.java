package io.github.jakiwz.aether.missions.persistence;

import io.github.jakiwz.aether.colonies.persistence.ColonyEntity;
import io.github.jakiwz.aether.identity.persistence.UserAccountEntity;
import io.github.jakiwz.aether.missions.domain.MissionPriority;
import io.github.jakiwz.aether.missions.domain.MissionStatus;
import io.github.jakiwz.aether.missions.domain.MissionType;
import io.github.jakiwz.aether.missions.domain.SafetyLevel;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import org.jspecify.annotations.Nullable;

/**
 * Mapping of {@code aether.mission} (V6). Only the columns used so far are mapped; destination,
 * actual dates and cancellation keep their database defaults.
 */
@Entity
@Table(name = "mission")
public class MissionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_mission")
    private Long id;

    @Column(nullable = false, unique = true, length = 60)
    private String code;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "text")
    private @Nullable String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "mission_type", nullable = false, length = 40)
    private MissionType type;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_origin_colony", nullable = false)
    private ColonyEntity originColony;

    @Column(name = "planned_start_at", nullable = false)
    private OffsetDateTime plannedStartAt;

    @Column(name = "planned_end_at", nullable = false)
    private OffsetDateTime plannedEndAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private MissionStatus status;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private MissionPriority priority;

    @Enumerated(EnumType.STRING)
    @Column(name = "safety_level", nullable = false, length = 20)
    private SafetyLevel safetyLevel;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "created_by", nullable = false, updatable = false)
    private UserAccountEntity createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @OneToMany(mappedBy = "mission", cascade = CascadeType.PERSIST)
    @OrderBy("sequenceNo")
    private List<MissionObjectiveEntity> objectives = new ArrayList<>();

    protected MissionEntity() {
        // for JPA
    }

    /** A new mission in {@link MissionStatus#DRAFT}. */
    public static MissionEntity draft(String code, String title, @Nullable String description, MissionType type,
            ColonyEntity originColony, OffsetDateTime plannedStartAt, OffsetDateTime plannedEndAt,
            MissionPriority priority, SafetyLevel safetyLevel, UserAccountEntity createdBy,
            OffsetDateTime createdAt) {
        MissionEntity mission = new MissionEntity();
        mission.code = code;
        mission.title = title;
        mission.description = description;
        mission.type = type;
        mission.originColony = originColony;
        mission.plannedStartAt = plannedStartAt;
        mission.plannedEndAt = plannedEndAt;
        mission.status = MissionStatus.DRAFT;
        mission.priority = priority;
        mission.safetyLevel = safetyLevel;
        mission.createdBy = createdBy;
        mission.createdAt = createdAt;
        return mission;
    }

    /** Appends an objective after the existing ones. */
    public void addObjective(String objectiveDescription) {
        objectives.add(new MissionObjectiveEntity(this, objectives.size() + 1, objectiveDescription));
    }

    public Long getId() {
        return id;
    }

    public String getCode() {
        return code;
    }

    public String getTitle() {
        return title;
    }

    public @Nullable String getDescription() {
        return description;
    }

    public MissionType getType() {
        return type;
    }

    public ColonyEntity getOriginColony() {
        return originColony;
    }

    public OffsetDateTime getPlannedStartAt() {
        return plannedStartAt;
    }

    public OffsetDateTime getPlannedEndAt() {
        return plannedEndAt;
    }

    public MissionStatus getStatus() {
        return status;
    }

    public MissionPriority getPriority() {
        return priority;
    }

    public SafetyLevel getSafetyLevel() {
        return safetyLevel;
    }

    public UserAccountEntity getCreatedBy() {
        return createdBy;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public List<MissionObjectiveEntity> getObjectives() {
        return objectives;
    }
}
