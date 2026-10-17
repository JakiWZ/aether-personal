package io.github.jakiwz.aether.audit.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.net.InetAddress;
import java.time.OffsetDateTime;
import java.util.UUID;
import org.hibernate.annotations.Immutable;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.jspecify.annotations.Nullable;

/** One row of the append-only audit trail ({@code audit_event}, V13). Never updated or deleted. */
@Entity
@Immutable
@Table(name = "audit_event")
public class AuditEventEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_audit")
    private Long id;

    @Column(name = "id_account")
    private @Nullable Long accountId;

    @Column(nullable = false, length = 80)
    private String action;

    @Column(name = "entity_type", nullable = false, length = 80)
    private String entityType;

    @Column(name = "entity_id", nullable = false, length = 120)
    private String entityId;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "new_value_json")
    private @Nullable String newValueJson;

    private @Nullable String reason;

    @JdbcTypeCode(SqlTypes.INET)
    @Column(name = "ip_address")
    private @Nullable InetAddress ipAddress;

    @Column(name = "correlation_id")
    private @Nullable UUID correlationId;

    @Column(name = "occurred_at", nullable = false)
    private OffsetDateTime occurredAt;

    protected AuditEventEntity() {
    }

    public AuditEventEntity(@Nullable Long accountId, String action, String entityType, String entityId,
            @Nullable String newValueJson, @Nullable String reason, @Nullable InetAddress ipAddress,
            @Nullable UUID correlationId, OffsetDateTime occurredAt) {
        this.accountId = accountId;
        this.action = action;
        this.entityType = entityType;
        this.entityId = entityId;
        this.newValueJson = newValueJson;
        this.reason = reason;
        this.ipAddress = ipAddress;
        this.correlationId = correlationId;
        this.occurredAt = occurredAt;
    }
}
