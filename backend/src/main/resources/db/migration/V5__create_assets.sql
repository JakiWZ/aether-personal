-- Technical assets and fleet with status history (COL-003..COL-006).
-- Source: docs/database/legacy/AETHER_MASTER_DATABASE_POSTGRESQL.sql (baseline, see ADR-0003).

CREATE TABLE asset_type (
    id_asset_type BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(60) NOT NULL,
    description TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE asset (
    id_asset BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(60) NOT NULL UNIQUE,
    id_asset_type BIGINT NOT NULL REFERENCES asset_type(id_asset_type),
    id_colony BIGINT NOT NULL REFERENCES colony(id_colony),
    id_area BIGINT REFERENCES operational_area(id_area),
    serial_number VARCHAR(120),
    manufacturer VARCHAR(120),
    model VARCHAR(120),
    criticality VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    status VARCHAR(30) NOT NULL DEFAULT 'AVAILABLE',
    commissioned_at DATE,
    operating_hours NUMERIC(14,2) NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_asset_serial UNIQUE (serial_number),
    CONSTRAINT ck_asset_criticality CHECK (criticality IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    CONSTRAINT ck_asset_status CHECK (status IN ('AVAILABLE','IN_USE','MAINTENANCE','OUT_OF_SERVICE','DECOMMISSIONED')),
    CONSTRAINT ck_asset_hours CHECK (operating_hours >= 0)
);

CREATE TABLE asset_status_history (
    id_history BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_asset BIGINT NOT NULL REFERENCES asset(id_asset),
    previous_status VARCHAR(30),
    new_status VARCHAR(30) NOT NULL,
    changed_by BIGINT REFERENCES user_account(id_account),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reason TEXT
);

-- Indexes supporting the main lookups of this domain.
CREATE INDEX ix_asset_colony_status ON asset(id_colony, status);
CREATE INDEX ix_asset_type ON asset(id_asset_type);
CREATE INDEX ix_asset_area ON asset(id_area);
CREATE INDEX ix_asset_history_asset_date ON asset_status_history(id_asset, changed_at DESC);
