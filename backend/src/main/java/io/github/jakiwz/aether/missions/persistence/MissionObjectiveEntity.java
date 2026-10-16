package io.github.jakiwz.aether.missions.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/** Mapping of {@code aether.mission_objective} (V6); priority and status keep their defaults. */
@Entity
@Table(name = "mission_objective")
public class MissionObjectiveEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_objective")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_mission", nullable = false)
    private MissionEntity mission;

    @Column(name = "sequence_no", nullable = false)
    private int sequenceNo;

    @Column(nullable = false, columnDefinition = "text")
    private String description;

    protected MissionObjectiveEntity() {
        // for JPA
    }

    MissionObjectiveEntity(MissionEntity mission, int sequenceNo, String description) {
        this.mission = mission;
        this.sequenceNo = sequenceNo;
        this.description = description;
    }

    public int getSequenceNo() {
        return sequenceNo;
    }

    public String getDescription() {
        return description;
    }
}
