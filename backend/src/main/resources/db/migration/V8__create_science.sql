-- Laboratories, experiments, samples with chain of custody, results (SCI-*).
-- Source: docs/database/legacy/AETHER_MASTER_DATABASE_POSTGRESQL.sql (baseline, see ADR-0003).

CREATE TABLE laboratory (
    id_laboratory BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_colony BIGINT NOT NULL REFERENCES colony(id_colony),
    id_area BIGINT NOT NULL REFERENCES operational_area(id_area),
    code VARCHAR(50) NOT NULL,
    name VARCHAR(150) NOT NULL,
    laboratory_type VARCHAR(60) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'OPERATIONAL',
    CONSTRAINT uq_laboratory_code UNIQUE (id_colony, code),
    CONSTRAINT ck_laboratory_status CHECK (status IN ('OPERATIONAL','MAINTENANCE','RESTRICTED','INACTIVE'))
);

CREATE TABLE experiment (
    id_experiment BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(60) NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    id_laboratory BIGINT NOT NULL REFERENCES laboratory(id_laboratory),
    id_lead_scientist BIGINT NOT NULL REFERENCES crew_member(id_crew_member),
    id_mission BIGINT REFERENCES mission(id_mission),
    protocol_version VARCHAR(50),
    status VARCHAR(30) NOT NULL DEFAULT 'PLANNED',
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_experiment_status CHECK (status IN ('PLANNED','APPROVED','IN_PROGRESS','PAUSED','COMPLETED','CANCELLED')),
    CONSTRAINT ck_experiment_dates CHECK (completed_at IS NULL OR started_at IS NULL OR completed_at >= started_at)
);

CREATE TABLE sample (
    id_sample BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(80) NOT NULL UNIQUE,
    id_experiment BIGINT REFERENCES experiment(id_experiment),
    id_mission BIGINT REFERENCES mission(id_mission),
    sample_type VARCHAR(60) NOT NULL,
    description TEXT,
    collected_at TIMESTAMPTZ NOT NULL,
    origin_description TEXT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'COLLECTED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_sample_status CHECK (status IN (
        'COLLECTED','IN_TRANSIT','STORED','UNDER_ANALYSIS','ARCHIVED','CONSUMED','DISPOSED'))
);

CREATE TABLE sample_location_history (
    id_sample_location BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_sample BIGINT NOT NULL REFERENCES sample(id_sample),
    id_laboratory BIGINT NOT NULL REFERENCES laboratory(id_laboratory),
    valid_from TIMESTAMPTZ NOT NULL,
    valid_to TIMESTAMPTZ,
    handed_by BIGINT REFERENCES crew_member(id_crew_member),
    received_by BIGINT REFERENCES crew_member(id_crew_member),
    condition_notes TEXT,
    CONSTRAINT ck_sample_location_dates CHECK (valid_to IS NULL OR valid_to > valid_from)
);
CREATE UNIQUE INDEX uq_sample_current_location ON sample_location_history(id_sample) WHERE valid_to IS NULL;

CREATE TABLE experiment_result (
    id_result BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_experiment BIGINT NOT NULL REFERENCES experiment(id_experiment),
    id_sample BIGINT REFERENCES sample(id_sample),
    result_type VARCHAR(80) NOT NULL,
    numeric_value NUMERIC(24,10),
    text_value TEXT,
    json_value JSONB,
    id_unit BIGINT REFERENCES unit_of_measure(id_unit),
    recorded_by BIGINT NOT NULL REFERENCES crew_member(id_crew_member),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    document_uri TEXT,
    CONSTRAINT ck_result_has_value CHECK (
        numeric_value IS NOT NULL OR text_value IS NOT NULL OR json_value IS NOT NULL OR document_uri IS NOT NULL)
);

-- Indexes supporting the main lookups of this domain.
CREATE INDEX ix_experiment_lab_status ON experiment(id_laboratory, status);
CREATE INDEX ix_experiment_mission ON experiment(id_mission);
CREATE INDEX ix_sample_experiment ON sample(id_experiment);
CREATE INDEX ix_sample_mission ON sample(id_mission);
CREATE INDEX ix_sample_location_history ON sample_location_history(id_sample, valid_from DESC);
CREATE INDEX ix_experiment_result_exp_date ON experiment_result(id_experiment, recorded_at DESC);
