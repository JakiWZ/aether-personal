package io.github.jakiwz.aether.incidents.domain;

import io.github.jakiwz.aether.audit.domain.AuditAction;
import io.github.jakiwz.aether.audit.domain.AuditTrail;
import io.github.jakiwz.aether.colonies.persistence.ColonyEntity;
import io.github.jakiwz.aether.colonies.persistence.ColonyRepository;
import io.github.jakiwz.aether.identity.domain.CurrentActor;
import io.github.jakiwz.aether.identity.persistence.UserAccountEntity;
import io.github.jakiwz.aether.identity.persistence.UserAccountRepository;
import io.github.jakiwz.aether.incidents.persistence.IncidentEntity;
import io.github.jakiwz.aether.incidents.persistence.IncidentEventEntity;
import io.github.jakiwz.aether.incidents.persistence.IncidentEventRepository;
import io.github.jakiwz.aether.incidents.persistence.IncidentRepository;
import io.github.jakiwz.aether.shared.error.BusinessRuleViolationException;
import io.github.jakiwz.aether.shared.error.ResourceNotFoundException;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Incident reporting (HELIOS). An incident is always opened as {@link IncidentStatus#OPEN} at the
 * server time, with a system-assigned code, on a base that exists; the report is the first event of
 * its timeline and goes to the audit trail (ADR-0014).
 */
@Service
@Transactional(readOnly = true)
public class IncidentService {

    private final IncidentRepository incidents;
    private final IncidentEventRepository events;
    private final ColonyRepository colonies;
    private final UserAccountRepository accounts;
    private final CurrentActor actor;
    private final AuditTrail audit;

    IncidentService(IncidentRepository incidents, IncidentEventRepository events, ColonyRepository colonies,
            UserAccountRepository accounts, CurrentActor actor, AuditTrail audit) {
        this.incidents = incidents;
        this.events = events;
        this.colonies = colonies;
        this.accounts = accounts;
        this.actor = actor;
        this.audit = audit;
    }

    /** Incidents newest first, then by code. */
    public Page<Incident> list(int page, int size) {
        Sort newestFirst = Sort.by(Sort.Order.desc("openedAt"), Sort.Order.asc("code"));
        return incidents.findAllBy(PageRequest.of(page, size, newestFirst)).map(IncidentService::toDomain);
    }

    public Incident get(String code) {
        return incidents.findByCode(code.strip().toUpperCase(Locale.ROOT))
                .map(IncidentService::toDomain)
                .orElseThrow(() -> new ResourceNotFoundException("Incident", code));
    }

    /** Opens an incident and records its first timeline event (HEL-501). */
    @Transactional
    public Incident open(NewIncident request) {
        String colonyCode = request.colonyCode().strip();
        ColonyEntity colony = colonies.findByCodeAndDeletedAtIsNull(colonyCode)
                .orElseThrow(() -> new BusinessRuleViolationException(IncidentErrorCode.INCIDENT_COLONY_NOT_FOUND,
                        "Base '%s' does not exist.".formatted(colonyCode)));
        UserAccountEntity reporter = accounts.findByUsername(actor.username())
                .orElseThrow(() -> new IllegalStateException("No user account '%s'".formatted(actor.username())));
        OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC).truncatedTo(ChronoUnit.MICROS);

        IncidentEntity incident = incidents.save(IncidentEntity.open(nextCode(), colony, request.title().strip(),
                request.description().strip(), request.severity(), reporter, now));
        events.save(new IncidentEventEntity(incident, IncidentEventEntity.OPENED,
                "Incident reported with severity " + incident.getSeverity(), reporter, now));
        audit.recordFor(reporter.getId(), AuditAction.INCIDENT_OPENED, "INCIDENT", incident.getCode(),
                auditSnapshot(incident), null);
        return toDomain(incident);
    }

    /** {@code INC-0001}, {@code INC-0002}, ...; numbers already used (e.g. by imported data) are skipped. */
    private String nextCode() {
        String code;
        do {
            code = "INC-%04d".formatted(incidents.nextCodeNumber());
        } while (incidents.existsByCode(code));
        return code;
    }

    /** The state an auditor needs, not the free text the reporter typed. */
    private static Map<String, Object> auditSnapshot(IncidentEntity incident) {
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("status", incident.getStatus());
        snapshot.put("severity", incident.getSeverity());
        snapshot.put("colonyCode", incident.getColony().getCode());
        snapshot.put("openedAt", incident.getOpenedAt());
        return snapshot;
    }

    private static Incident toDomain(IncidentEntity entity) {
        return new Incident(entity.getCode(), entity.getTitle(), entity.getDescription(), entity.getSeverity(),
                entity.getStatus(), entity.getColony().getCode(), entity.getReportedBy().getUsername(),
                entity.getOpenedAt());
    }
}
