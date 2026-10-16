-- Append-only audit trail (BR-012) and transactional outbox for future event streaming.
-- Source: docs/database/legacy/AETHER_MASTER_DATABASE_POSTGRESQL.sql (baseline, see ADR-0003).

CREATE TABLE audit_event (
    id_audit BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_account BIGINT REFERENCES user_account(id_account),
    action VARCHAR(80) NOT NULL,
    entity_type VARCHAR(80) NOT NULL,
    entity_id VARCHAR(120) NOT NULL,
    old_value_json JSONB,
    new_value_json JSONB,
    reason TEXT,
    ip_address INET,
    correlation_id UUID,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE outbox_event (
    id_event UUID PRIMARY KEY,
    aggregate_type VARCHAR(80) NOT NULL,
    aggregate_id VARCHAR(120) NOT NULL,
    event_type VARCHAR(120) NOT NULL,
    payload JSONB NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    published_at TIMESTAMPTZ,
    retry_count INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    CONSTRAINT ck_outbox_retry CHECK (retry_count >= 0)
);

-- Indexes supporting the main lookups of this domain.
CREATE INDEX ix_audit_entity ON audit_event(entity_type, entity_id, occurred_at DESC);
CREATE INDEX ix_audit_account_date ON audit_event(id_account, occurred_at DESC);
CREATE INDEX ix_outbox_unpublished ON outbox_event(occurred_at) WHERE published_at IS NULL;
