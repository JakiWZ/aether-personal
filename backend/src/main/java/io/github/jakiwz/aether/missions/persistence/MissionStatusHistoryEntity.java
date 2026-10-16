package io.github.jakiwz.aether.missions.persistence;

import io.github.jakiwz.aether.identity.persistence.UserAccountEntity;
import io.github.jakiwz.aether.missions.domain.MissionStatus;
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
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import org.jspecify.annotations.Nullable;

/** Append-only mapping of {@code aether.mission_status_history} (V6): who changed a status, and when. */
@Entity
@Table(name = "mission_status_history")
public class MissionStatusHistoryEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_history")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_mission", nullable = false, updatable = false)
    private MissionEntity mission;

    @Enumerated(EnumType.STRING)
    @Column(name = "previous_status", length = 30, updatable = false)
    private @Nullable MissionStatus previousStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "new_status", nullable = false, length = 30, updatable = false)
    private MissionStatus newStatus;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "changed_by", nullable = false, updatable = false)
    private UserAccountEntity changedBy;

    @Column(name = "changed_at", nullable = false, updatable = false)
    private OffsetDateTime changedAt;

    protected MissionStatusHistoryEntity() {
        // for JPA
    }

    public MissionStatusHistoryEntity(MissionEntity mission, @Nullable MissionStatus previousStatus,
            MissionStatus newStatus, UserAccountEntity changedBy, OffsetDateTime changedAt) {
        this.mission = mission;
        this.previousStatus = previousStatus;
        this.newStatus = newStatus;
        this.changedBy = changedBy;
        this.changedAt = changedAt;
    }
}
