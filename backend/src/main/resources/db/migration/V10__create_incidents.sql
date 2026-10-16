-- Incidents, responders, timeline events and corrective actions (MNT-006..MNT-008).
-- Source: docs/database/legacy/AETHER_MASTER_DATABASE_POSTGRESQL.sql (baseline, see ADR-0003).

CREATE TABLE incident (
    id_incident BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(60) NOT NULL UNIQUE,
    id_colony BIGINT NOT NULL REFERENCES colony(id_colony),
    id_mission BIGINT REFERENCES mission(id_mission),
    id_asset BIGINT REFERENCES asset(id_asset),
    source_alert_id BIGINT REFERENCES alert(id_alert),
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'OPEN',
    reported_by BIGINT NOT NULL REFERENCES user_account(id_account),
    opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    acknowledged_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    closed_at TIMESTAMPTZ,
    root_cause TEXT,
    resolution TEXT,
    closed_by BIGINT REFERENCES user_account(id_account),
    closure_reason TEXT,
    CONSTRAINT ck_incident_severity CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
    CONSTRAINT ck_incident_status CHECK (status IN ('OPEN','ACKNOWLEDGED','IN_PROGRESS','RESOLVED','CLOSED','CANCELLED')),
    CONSTRAINT ck_incident_close_required CHECK (
        status <> 'CLOSED' OR (closed_at IS NOT NULL AND closed_by IS NOT NULL AND closure_reason IS NOT NULL))
);

CREATE TABLE incident_assignee (
    id_incident BIGINT NOT NULL REFERENCES incident(id_incident),
    id_crew_member BIGINT NOT NULL REFERENCES crew_member(id_crew_member),
    responder_role VARCHAR(80),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    released_at TIMESTAMPTZ,
    PRIMARY KEY (id_incident, id_crew_member)
);

CREATE TABLE incident_event (
    id_event BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_incident BIGINT NOT NULL REFERENCES incident(id_incident),
    event_type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    created_by BIGINT NOT NULL REFERENCES user_account(id_account),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE corrective_action (
    id_action BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_incident BIGINT NOT NULL REFERENCES incident(id_incident),
    description TEXT NOT NULL,
    assigned_to BIGINT REFERENCES crew_member(id_crew_member),
    due_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    status VARCHAR(30) NOT NULL DEFAULT 'OPEN',
    CONSTRAINT ck_corrective_action_status CHECK (status IN ('OPEN','IN_PROGRESS','DONE','CANCELLED'))
);

-- Indexes supporting the main lookups of this domain.
CREATE INDEX ix_incident_colony_status ON incident(id_colony, status);
CREATE INDEX ix_incident_severity_status ON incident(severity, status);
CREATE INDEX ix_incident_asset ON incident(id_asset);
CREATE INDEX ix_incident_mission ON incident(id_mission);
CREATE INDEX ix_incident_event_timeline ON incident_event(id_incident, created_at);
CREATE INDEX ix_corrective_incident ON corrective_action(id_incident, status);
