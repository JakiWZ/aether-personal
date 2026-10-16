-- User notifications and preferences.
-- Source: docs/database/legacy/AETHER_MASTER_DATABASE_POSTGRESQL.sql (baseline, see ADR-0003).

CREATE TABLE notification (
    id_notification BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_account BIGINT NOT NULL REFERENCES user_account(id_account),
    notification_type VARCHAR(60) NOT NULL,
    title VARCHAR(180) NOT NULL,
    message TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'INFO',
    status VARCHAR(20) NOT NULL DEFAULT 'UNREAD',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at TIMESTAMPTZ,
    related_entity_type VARCHAR(60),
    related_entity_id BIGINT,
    CONSTRAINT ck_notification_severity CHECK (severity IN ('INFO','LOW','MEDIUM','HIGH','CRITICAL')),
    CONSTRAINT ck_notification_status CHECK (status IN ('UNREAD','READ','DISMISSED'))
);

CREATE TABLE notification_preference (
    id_account BIGINT NOT NULL REFERENCES user_account(id_account),
    event_type VARCHAR(60) NOT NULL,
    channel VARCHAR(30) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id_account, event_type, channel),
    CONSTRAINT ck_notification_channel CHECK (channel IN ('IN_APP','EMAIL','PUSH'))
);

-- Indexes supporting the main lookups of this domain.
CREATE INDEX ix_notification_account_status ON notification(id_account, status, created_at DESC);
