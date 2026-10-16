-- Missions with objectives, phases, tasks, crew/asset assignments, requirements, risks, approvals (MIS-*).
-- Source: docs/database/legacy/AETHER_MASTER_DATABASE_POSTGRESQL.sql (baseline, see ADR-0003).

CREATE TABLE mission (
    id_mission BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(60) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    mission_type VARCHAR(40) NOT NULL,
    id_origin_colony BIGINT NOT NULL REFERENCES colony(id_colony),
    id_destination_colony BIGINT REFERENCES colony(id_colony),
    destination_name VARCHAR(180),
    destination_latitude NUMERIC(9,6),
    destination_longitude NUMERIC(9,6),
    planned_start_at TIMESTAMPTZ NOT NULL,
    planned_end_at TIMESTAMPTZ NOT NULL,
    actual_start_at TIMESTAMPTZ,
    actual_end_at TIMESTAMPTZ,
    status VARCHAR(30) NOT NULL DEFAULT 'DRAFT',
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    safety_level VARCHAR(20) NOT NULL DEFAULT 'STANDARD',
    created_by BIGINT NOT NULL REFERENCES user_account(id_account),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    cancelled_reason TEXT,
    CONSTRAINT ck_mission_type CHECK (mission_type IN (
        'INTERNAL','EVA','SCIENCE','LOGISTICS','MAINTENANCE','RESCUE','INSPECTION','EXPLORATION','TRANSPORT')),
    CONSTRAINT ck_mission_status CHECK (status IN (
        'DRAFT','PLANNED','APPROVAL_PENDING','APPROVED','IN_PROGRESS','COMPLETED','ABORTED','CANCELLED')),
    CONSTRAINT ck_mission_priority CHECK (priority IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    CONSTRAINT ck_mission_safety CHECK (safety_level IN ('STANDARD','ELEVATED','HIGH_RISK','CRITICAL')),
    CONSTRAINT ck_mission_planned_dates CHECK (planned_end_at > planned_start_at),
    CONSTRAINT ck_mission_actual_dates CHECK (actual_end_at IS NULL OR actual_start_at IS NULL OR actual_end_at >= actual_start_at)
);

CREATE TABLE mission_objective (
    id_objective BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_mission BIGINT NOT NULL REFERENCES mission(id_mission),
    sequence_no INTEGER NOT NULL,
    description TEXT NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    completion_notes TEXT,
    CONSTRAINT uq_mission_objective_seq UNIQUE (id_mission, sequence_no),
    CONSTRAINT ck_objective_status CHECK (status IN ('PENDING','IN_PROGRESS','COMPLETED','FAILED','CANCELLED')),
    CONSTRAINT ck_objective_priority CHECK (priority IN ('LOW','MEDIUM','HIGH','CRITICAL'))
);

CREATE TABLE mission_phase (
    id_phase BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_mission BIGINT NOT NULL REFERENCES mission(id_mission),
    sequence_no INTEGER NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    planned_start_at TIMESTAMPTZ,
    planned_end_at TIMESTAMPTZ,
    actual_start_at TIMESTAMPTZ,
    actual_end_at TIMESTAMPTZ,
    status VARCHAR(30) NOT NULL DEFAULT 'PLANNED',
    CONSTRAINT uq_mission_phase_seq UNIQUE (id_mission, sequence_no),
    CONSTRAINT ck_phase_status CHECK (status IN ('PLANNED','IN_PROGRESS','COMPLETED','SKIPPED','CANCELLED')),
    CONSTRAINT ck_phase_planned_dates CHECK (planned_end_at IS NULL OR planned_start_at IS NULL OR planned_end_at >= planned_start_at),
    CONSTRAINT ck_phase_actual_dates CHECK (actual_end_at IS NULL OR actual_start_at IS NULL OR actual_end_at >= actual_start_at)
);

CREATE TABLE mission_task (
    id_task BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_phase BIGINT NOT NULL REFERENCES mission_phase(id_phase),
    title VARCHAR(180) NOT NULL,
    description TEXT,
    assigned_crew_member BIGINT REFERENCES crew_member(id_crew_member),
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    status VARCHAR(30) NOT NULL DEFAULT 'TODO',
    planned_start_at TIMESTAMPTZ,
    planned_end_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    CONSTRAINT ck_task_priority CHECK (priority IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    CONSTRAINT ck_task_status CHECK (status IN ('TODO','IN_PROGRESS','BLOCKED','DONE','CANCELLED'))
);

CREATE TABLE mission_crew_assignment (
    id_assignment BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_mission BIGINT NOT NULL REFERENCES mission(id_mission),
    id_crew_member BIGINT NOT NULL REFERENCES crew_member(id_crew_member),
    mission_role VARCHAR(80) NOT NULL,
    is_commander BOOLEAN NOT NULL DEFAULT FALSE,
    assigned_from TIMESTAMPTZ NOT NULL,
    assigned_to TIMESTAMPTZ NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'ASSIGNED',
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_mission_crew UNIQUE (id_mission, id_crew_member),
    CONSTRAINT ck_mission_crew_dates CHECK (assigned_to > assigned_from),
    CONSTRAINT ck_mission_crew_status CHECK (status IN ('ASSIGNED','CONFIRMED','RELEASED','CANCELLED'))
);
CREATE UNIQUE INDEX uq_one_commander_per_mission ON mission_crew_assignment(id_mission)
WHERE is_commander = TRUE AND status IN ('ASSIGNED','CONFIRMED');
ALTER TABLE mission_crew_assignment ADD CONSTRAINT ex_crew_no_overlapping_missions
EXCLUDE USING gist (id_crew_member WITH =, tstzrange(assigned_from, assigned_to, '[)') WITH &&)
WHERE (status IN ('ASSIGNED','CONFIRMED'));

CREATE TABLE mission_asset_assignment (
    id_assignment BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_mission BIGINT NOT NULL REFERENCES mission(id_mission),
    id_asset BIGINT NOT NULL REFERENCES asset(id_asset),
    asset_role VARCHAR(80),
    assigned_from TIMESTAMPTZ NOT NULL,
    assigned_to TIMESTAMPTZ NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'ASSIGNED',
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_mission_asset UNIQUE (id_mission, id_asset),
    CONSTRAINT ck_mission_asset_dates CHECK (assigned_to > assigned_from),
    CONSTRAINT ck_mission_asset_status CHECK (status IN ('ASSIGNED','CONFIRMED','RELEASED','CANCELLED'))
);
ALTER TABLE mission_asset_assignment ADD CONSTRAINT ex_asset_no_overlapping_missions
EXCLUDE USING gist (id_asset WITH =, tstzrange(assigned_from, assigned_to, '[)') WITH &&)
WHERE (status IN ('ASSIGNED','CONFIRMED'));

CREATE TABLE mission_skill_requirement (
    id_requirement BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_mission BIGINT NOT NULL REFERENCES mission(id_mission),
    id_skill BIGINT NOT NULL REFERENCES skill(id_skill),
    minimum_level SMALLINT NOT NULL,
    required_people INTEGER NOT NULL DEFAULT 1,
    mandatory BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_mission_skill_req UNIQUE (id_mission, id_skill),
    CONSTRAINT ck_mission_skill_level CHECK (minimum_level BETWEEN 1 AND 5),
    CONSTRAINT ck_mission_skill_people CHECK (required_people > 0)
);

CREATE TABLE mission_cert_requirement (
    id_requirement BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_mission BIGINT NOT NULL REFERENCES mission(id_mission),
    id_certification BIGINT NOT NULL REFERENCES certification(id_certification),
    required_people INTEGER NOT NULL DEFAULT 1,
    mandatory BOOLEAN NOT NULL DEFAULT TRUE,
    recognized_authority VARCHAR(180),
    validity_buffer_days INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT uq_mission_cert_req UNIQUE (id_mission, id_certification),
    CONSTRAINT ck_mission_cert_people CHECK (required_people > 0),
    CONSTRAINT ck_cert_buffer CHECK (validity_buffer_days >= 0)
);

CREATE TABLE mission_resource_requirement (
    id_requirement BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_mission BIGINT NOT NULL REFERENCES mission(id_mission),
    id_resource BIGINT NOT NULL REFERENCES resource(id_resource),
    required_quantity NUMERIC(18,6) NOT NULL,
    mandatory BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_mission_resource_req UNIQUE (id_mission, id_resource),
    CONSTRAINT ck_mission_resource_qty CHECK (required_quantity > 0)
);

CREATE TABLE mission_resource_allocation (
    id_allocation BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_requirement BIGINT NOT NULL REFERENCES mission_resource_requirement(id_requirement),
    id_inventory_stock BIGINT NOT NULL REFERENCES inventory_stock(id_inventory_stock),
    allocated_quantity NUMERIC(18,6) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'RESERVED',
    allocated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    released_at TIMESTAMPTZ,
    CONSTRAINT ck_mission_alloc_qty CHECK (allocated_quantity > 0),
    CONSTRAINT ck_mission_alloc_status CHECK (status IN ('RESERVED','CONSUMED','RETURNED','RELEASED','CANCELLED'))
);

CREATE TABLE mission_risk (
    id_risk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_mission BIGINT NOT NULL REFERENCES mission(id_mission),
    title VARCHAR(180) NOT NULL,
    description TEXT,
    likelihood SMALLINT NOT NULL,
    impact SMALLINT NOT NULL,
    mitigation TEXT,
    owner_crew_member BIGINT REFERENCES crew_member(id_crew_member),
    status VARCHAR(30) NOT NULL DEFAULT 'OPEN',
    CONSTRAINT ck_risk_likelihood CHECK (likelihood BETWEEN 1 AND 5),
    CONSTRAINT ck_risk_impact CHECK (impact BETWEEN 1 AND 5),
    CONSTRAINT ck_risk_status CHECK (status IN ('OPEN','MITIGATED','ACCEPTED','CLOSED'))
);

CREATE TABLE mission_approval (
    id_approval BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_mission BIGINT NOT NULL REFERENCES mission(id_mission),
    approval_type VARCHAR(40) NOT NULL,
    requested_by BIGINT NOT NULL REFERENCES user_account(id_account),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    decision VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    decided_by BIGINT REFERENCES user_account(id_account),
    decided_at TIMESTAMPTZ,
    notes TEXT,
    CONSTRAINT ck_approval_type CHECK (approval_type IN ('OPERATIONAL','SAFETY','SCIENCE','LOGISTICS','COMMAND')),
    CONSTRAINT ck_approval_decision CHECK (decision IN ('PENDING','APPROVED','REJECTED','CANCELLED')),
    CONSTRAINT ck_approval_separation CHECK (decided_by IS NULL OR decided_by <> requested_by)
);

CREATE TABLE mission_status_history (
    id_history BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_mission BIGINT NOT NULL REFERENCES mission(id_mission),
    previous_status VARCHAR(30),
    new_status VARCHAR(30) NOT NULL,
    changed_by BIGINT NOT NULL REFERENCES user_account(id_account),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reason TEXT
);

-- Indexes supporting the main lookups of this domain.
CREATE INDEX ix_mission_status_dates ON mission(status, planned_start_at, planned_end_at);
CREATE INDEX ix_mission_origin ON mission(id_origin_colony);
CREATE INDEX ix_mission_destination ON mission(id_destination_colony);
CREATE INDEX ix_mission_crew_member ON mission_crew_assignment(id_crew_member);
CREATE INDEX ix_mission_asset_asset ON mission_asset_assignment(id_asset);
CREATE INDEX ix_mission_skill_skill ON mission_skill_requirement(id_skill);
CREATE INDEX ix_mission_cert_cert ON mission_cert_requirement(id_certification);
CREATE INDEX ix_mission_resource_resource ON mission_resource_requirement(id_resource);
CREATE INDEX ix_mission_status_history ON mission_status_history(id_mission, changed_at DESC);
CREATE INDEX ix_mission_approval ON mission_approval(id_mission, decision);
CREATE INDEX ix_mission_task_assignee ON mission_task(assigned_crew_member);
