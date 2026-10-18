package io.github.jakiwz.aether.incidents.persistence;

import io.github.jakiwz.aether.identity.persistence.UserAccountEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import org.hibernate.annotations.Immutable;

/** Append-only mapping of {@code aether.incident_event} (V10): the timeline of an incident. */
@Entity
@Immutable
@Table(name = "incident_event")
public class IncidentEventEntity {

    public static final String OPENED = "OPENED";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_event")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_incident", nullable = false)
    private IncidentEntity incident;

    @Column(name = "event_type", nullable = false, length = 50)
    private String eventType;

    @Column(nullable = false, columnDefinition = "text")
    private String description;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "created_by", nullable = false)
    private UserAccountEntity createdBy;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt;

    protected IncidentEventEntity() {
        // for JPA
    }

    public IncidentEventEntity(IncidentEntity incident, String eventType, String description,
            UserAccountEntity createdBy, OffsetDateTime createdAt) {
        this.incident = incident;
        this.eventType = eventType;
        this.description = description;
        this.createdBy = createdBy;
        this.createdAt = createdAt;
    }
}
