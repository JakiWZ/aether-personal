package io.github.jakiwz.aether.incidents.persistence;

import io.github.jakiwz.aether.colonies.persistence.ColonyEntity;
import io.github.jakiwz.aether.identity.persistence.UserAccountEntity;
import io.github.jakiwz.aether.incidents.domain.IncidentSeverity;
import io.github.jakiwz.aether.incidents.domain.IncidentStatus;
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

/**
 * Mapping of {@code aether.incident} (V10). Only the columns an opened incident needs are mapped;
 * links to missions, assets and alerts, and the closure data, come with the stories that set them.
 */
@Entity
@Table(name = "incident")
public class IncidentEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_incident")
    private Long id;

    @Column(nullable = false, unique = true, length = 60, updatable = false)
    private String code;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_colony", nullable = false, updatable = false)
    private ColonyEntity colony;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, columnDefinition = "text")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private IncidentSeverity severity;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private IncidentStatus status;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reported_by", nullable = false, updatable = false)
    private UserAccountEntity reportedBy;

    @Column(name = "opened_at", nullable = false, updatable = false)
    private OffsetDateTime openedAt;

    protected IncidentEntity() {
        // for JPA
    }

    private IncidentEntity(String code, ColonyEntity colony, String title, String description,
            IncidentSeverity severity, UserAccountEntity reportedBy, OffsetDateTime openedAt) {
        this.code = code;
        this.colony = colony;
        this.title = title;
        this.description = description;
        this.severity = severity;
        this.status = IncidentStatus.OPEN;
        this.reportedBy = reportedBy;
        this.openedAt = openedAt;
    }

    /** A new incident is always {@link IncidentStatus#OPEN}, whatever the caller asks (HEL-501). */
    public static IncidentEntity open(String code, ColonyEntity colony, String title, String description,
            IncidentSeverity severity, UserAccountEntity reportedBy, OffsetDateTime openedAt) {
        return new IncidentEntity(code, colony, title, description, severity, reportedBy, openedAt);
    }

    public Long getId() {
        return id;
    }

    public String getCode() {
        return code;
    }

    public ColonyEntity getColony() {
        return colony;
    }

    public String getTitle() {
        return title;
    }

    public String getDescription() {
        return description;
    }

    public IncidentSeverity getSeverity() {
        return severity;
    }

    public IncidentStatus getStatus() {
        return status;
    }

    public UserAccountEntity getReportedBy() {
        return reportedBy;
    }

    public OffsetDateTime getOpenedAt() {
        return openedAt;
    }
}
