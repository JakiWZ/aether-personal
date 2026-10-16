-- Sensors, threshold rules, measurements, alerts, acknowledgements, escalations (TEL-*).
-- Source: docs/database/legacy/AETHER_MASTER_DATABASE_POSTGRESQL.sql (baseline, see ADR-0003).

CREATE TABLE sensor_type (
    id_sensor_type BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(60) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    metric VARCHAR(80) NOT NULL,
    id_unit BIGINT REFERENCES unit_of_measure(id_unit),
    expected_min NUMERIC(24,10),
    expected_max NUMERIC(24,10),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_sensor_expected_range CHECK (expected_min IS NULL OR expected_max IS NULL OR expected_max >= expected_min)
);

CREATE TABLE sensor (
    id_sensor BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(80) NOT NULL UNIQUE,
    id_sensor_type BIGINT NOT NULL REFERENCES sensor_type(id_sensor_type),
    id_colony BIGINT NOT NULL REFERENCES colony(id_colony),
    id_area BIGINT REFERENCES operational_area(id_area),
    id_asset BIGINT REFERENCES asset(id_asset),
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    installed_at TIMESTAMPTZ,
    last_calibrated_at TIMESTAMPTZ,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_sensor_status CHECK (status IN ('ACTIVE','DEGRADED','MAINTENANCE','OFFLINE','RETIRED'))
);

CREATE TABLE threshold_rule (
    id_rule BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_sensor BIGINT REFERENCES sensor(id_sensor),
    id_sensor_type BIGINT REFERENCES sensor_type(id_sensor_type),
    rule_name VARCHAR(150) NOT NULL,
    minimum_value NUMERIC(24,10),
    maximum_value NUMERIC(24,10),
    severity VARCHAR(20) NOT NULL,
    persistence_seconds INTEGER NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_threshold_target CHECK (
        (id_sensor IS NOT NULL AND id_sensor_type IS NULL) OR
        (id_sensor IS NULL AND id_sensor_type IS NOT NULL)),
    CONSTRAINT ck_threshold_range CHECK (minimum_value IS NOT NULL OR maximum_value IS NOT NULL),
    CONSTRAINT ck_threshold_value_range CHECK (minimum_value IS NULL OR maximum_value IS NULL OR maximum_value >= minimum_value),
    CONSTRAINT ck_threshold_severity CHECK (severity IN ('INFO','LOW','MEDIUM','HIGH','CRITICAL')),
    CONSTRAINT ck_threshold_persistence CHECK (persistence_seconds >= 0)
);

CREATE TABLE telemetry_measurement (
    id_measurement BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_sensor BIGINT NOT NULL REFERENCES sensor(id_sensor),
    measured_at TIMESTAMPTZ NOT NULL,
    numeric_value NUMERIC(24,10) NOT NULL,
    quality VARCHAR(20) NOT NULL DEFAULT 'GOOD',
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    source_batch_id UUID,
    CONSTRAINT uq_sensor_measurement UNIQUE (id_sensor, measured_at),
    CONSTRAINT ck_measurement_quality CHECK (quality IN ('GOOD','SUSPECT','BAD','MISSING','ESTIMATED'))
);

CREATE TABLE alert (
    id_alert BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_sensor BIGINT NOT NULL REFERENCES sensor(id_sensor),
    id_rule BIGINT REFERENCES threshold_rule(id_rule),
    id_measurement BIGINT REFERENCES telemetry_measurement(id_measurement),
    severity VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'OPEN',
    triggered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    acknowledged_at TIMESTAMPTZ,
    closed_at TIMESTAMPTZ,
    CONSTRAINT ck_alert_severity CHECK (severity IN ('INFO','LOW','MEDIUM','HIGH','CRITICAL')),
    CONSTRAINT ck_alert_status CHECK (status IN ('OPEN','ACKNOWLEDGED','ESCALATED','CLOSED')),
    CONSTRAINT ck_alert_dates CHECK (closed_at IS NULL OR closed_at >= triggered_at)
);

CREATE TABLE alert_acknowledgement (
    id_ack BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_alert BIGINT NOT NULL REFERENCES alert(id_alert),
    id_account BIGINT NOT NULL REFERENCES user_account(id_account),
    acknowledged_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    note TEXT
);

CREATE TABLE alert_escalation (
    id_escalation BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_alert BIGINT NOT NULL REFERENCES alert(id_alert),
    escalation_level INTEGER NOT NULL,
    target_role_code VARCHAR(60) NOT NULL,
    escalated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reason TEXT NOT NULL,
    CONSTRAINT ck_escalation_level CHECK (escalation_level > 0)
);

-- Indexes supporting the main lookups of this domain.
CREATE INDEX ix_sensor_colony_status ON sensor(id_colony, status);
CREATE INDEX ix_sensor_type ON sensor(id_sensor_type);
CREATE INDEX ix_measurement_sensor_time ON telemetry_measurement(id_sensor, measured_at DESC);
CREATE INDEX ix_measurement_time ON telemetry_measurement(measured_at DESC);
CREATE INDEX ix_alert_status_severity ON alert(status, severity, triggered_at DESC);
