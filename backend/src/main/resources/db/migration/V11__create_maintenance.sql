-- Maintenance work orders and actions (MNT-001..MNT-005).
-- Source: docs/database/legacy/AETHER_MASTER_DATABASE_POSTGRESQL.sql (baseline, see ADR-0003).

CREATE TABLE maintenance_work_order (
    id_work_order BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(60) NOT NULL UNIQUE,
    id_asset BIGINT NOT NULL REFERENCES asset(id_asset),
    id_incident BIGINT REFERENCES incident(id_incident),
    maintenance_type VARCHAR(30) NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    status VARCHAR(30) NOT NULL DEFAULT 'OPEN',
    description TEXT NOT NULL,
    opened_by BIGINT NOT NULL REFERENCES user_account(id_account),
    assigned_to BIGINT REFERENCES crew_member(id_crew_member),
    opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    scheduled_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    resolution TEXT,
    CONSTRAINT ck_maintenance_type CHECK (maintenance_type IN ('PREVENTIVE','CORRECTIVE','INSPECTION','EMERGENCY')),
    CONSTRAINT ck_maintenance_priority CHECK (priority IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    CONSTRAINT ck_maintenance_status CHECK (status IN ('OPEN','PLANNED','IN_PROGRESS','BLOCKED','COMPLETED','CANCELLED')),
    CONSTRAINT ck_maintenance_dates CHECK (completed_at IS NULL OR started_at IS NULL OR completed_at >= started_at)
);

CREATE TABLE maintenance_action (
    id_action BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_work_order BIGINT NOT NULL REFERENCES maintenance_work_order(id_work_order),
    id_crew_member BIGINT REFERENCES crew_member(id_crew_member),
    description TEXT NOT NULL,
    performed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    duration_minutes INTEGER,
    notes TEXT,
    CONSTRAINT ck_maintenance_duration CHECK (duration_minutes IS NULL OR duration_minutes >= 0)
);

-- Indexes supporting the main lookups of this domain.
CREATE INDEX ix_maintenance_asset_status ON maintenance_work_order(id_asset, status);
CREATE INDEX ix_maintenance_assignee ON maintenance_work_order(assigned_to, status);
