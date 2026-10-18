-- Opening incidents (HEL-501).
-- Incident codes are assigned by the system from a sequence (INC-0001, INC-0002, ...), so whoever
-- reports an emergency never has to invent one; codes already taken are skipped by the service.
CREATE SEQUENCE incident_code_seq AS BIGINT START WITH 1 NO CYCLE;

-- Lets the application read the sequence through {h-schema} without naming the schema: the
-- SQL-standard body binds the sequence when the function is created.
CREATE FUNCTION next_incident_number() RETURNS BIGINT LANGUAGE sql VOLATILE
BEGIN ATOMIC
    SELECT nextval('incident_code_seq');
END;

-- Anyone working on Mars can report an incident; handling it stays with INCIDENT_MANAGE.
-- The auditor keeps a read-only profile.
INSERT INTO permission(code, description) VALUES ('INCIDENT_REPORT', 'Open (report) incidents')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permission(id_role, id_permission)
SELECT r.id_role, p.id_permission
FROM app_role r JOIN permission p ON p.code = 'INCIDENT_REPORT'
WHERE r.code IN ('ADMIN','MISSION_CONTROLLER','COLONY_COMMANDER','SCIENTIST','LOGISTICS','MAINTENANCE','CREW')
ON CONFLICT DO NOTHING;
