-- Reference data required by the application in every environment:
-- application roles (capitolato §3.1), permissions, role-permission matrix, units of measure.
-- Demo/sample data lives in a separate location (see TASK-004).
-- Source: docs/database/legacy/AETHER_MASTER_DATABASE_POSTGRESQL.sql (baseline, see ADR-0003).

INSERT INTO app_role(code, name, description) VALUES
('ADMIN','Administrator','Platform administration'),
('MISSION_CONTROLLER','Mission Controller','Mission planning and operational control'),
('COLONY_COMMANDER','Colony Commander','Colony-level operational authority'),
('SCIENTIST','Scientist','Experiments, samples and scientific data'),
('LOGISTICS','Logistics Officer','Inventory, resources and shipments'),
('MAINTENANCE','Maintenance Engineer','Assets, work orders and maintenance'),
('CREW','Crew Member','Personal assignments and mission participation'),
('AUDITOR','Auditor','Read-only audit and compliance access')
ON CONFLICT (code) DO NOTHING;

INSERT INTO permission(code, description) VALUES
('COLONY_READ','Read colony/habitat data'),('COLONY_MANAGE','Manage colony/habitat data'),
('CREW_READ','Read crew information'),('CREW_MANAGE','Manage crew information'),
('MISSION_READ','Read missions'),('MISSION_MANAGE','Create and update missions'),
('MISSION_APPROVE','Approve missions'),('ASSET_READ','Read assets'),
('ASSET_MANAGE','Manage asset state and assignments'),('MAINTENANCE_MANAGE','Manage maintenance work orders'),
('INVENTORY_READ','Read inventory'),('INVENTORY_MANAGE','Manage inventory movements'),
('SHIPMENT_MANAGE','Manage shipments'),('INCIDENT_READ','Read incidents'),
('INCIDENT_MANAGE','Manage incidents'),('INCIDENT_CLOSE','Close incidents'),
('SCIENCE_READ','Read scientific data'),('SCIENCE_MANAGE','Manage experiments and samples'),
('TELEMETRY_READ','Read telemetry'),('ALERT_MANAGE','Acknowledge and manage alerts'),
('AUDIT_READ','Read audit trail'),('SECURITY_MANAGE','Manage users, roles and permissions')
ON CONFLICT (code) DO NOTHING;

INSERT INTO role_permission(id_role,id_permission)
SELECT r.id_role,p.id_permission FROM app_role r CROSS JOIN permission p WHERE r.code='ADMIN'
ON CONFLICT DO NOTHING;

INSERT INTO role_permission(id_role,id_permission)
SELECT r.id_role,p.id_permission FROM app_role r JOIN permission p ON p.code IN
('COLONY_READ','CREW_READ','MISSION_READ','MISSION_MANAGE','MISSION_APPROVE','ASSET_READ','INVENTORY_READ','INCIDENT_READ','TELEMETRY_READ','ALERT_MANAGE')
WHERE r.code='MISSION_CONTROLLER' ON CONFLICT DO NOTHING;

INSERT INTO role_permission(id_role,id_permission)
SELECT r.id_role,p.id_permission FROM app_role r JOIN permission p ON p.code IN
('COLONY_READ','COLONY_MANAGE','CREW_READ','MISSION_READ','MISSION_APPROVE','ASSET_READ','INVENTORY_READ','INCIDENT_READ','INCIDENT_MANAGE','INCIDENT_CLOSE','TELEMETRY_READ','ALERT_MANAGE')
WHERE r.code='COLONY_COMMANDER' ON CONFLICT DO NOTHING;

INSERT INTO role_permission(id_role,id_permission)
SELECT r.id_role,p.id_permission FROM app_role r JOIN permission p ON p.code IN
('COLONY_READ','CREW_READ','MISSION_READ','SCIENCE_READ','SCIENCE_MANAGE','TELEMETRY_READ')
WHERE r.code='SCIENTIST' ON CONFLICT DO NOTHING;

INSERT INTO role_permission(id_role,id_permission)
SELECT r.id_role,p.id_permission FROM app_role r JOIN permission p ON p.code IN
('COLONY_READ','MISSION_READ','ASSET_READ','INVENTORY_READ','INVENTORY_MANAGE','SHIPMENT_MANAGE','INCIDENT_READ')
WHERE r.code='LOGISTICS' ON CONFLICT DO NOTHING;

INSERT INTO role_permission(id_role,id_permission)
SELECT r.id_role,p.id_permission FROM app_role r JOIN permission p ON p.code IN
('COLONY_READ','MISSION_READ','ASSET_READ','ASSET_MANAGE','MAINTENANCE_MANAGE','INCIDENT_READ','INCIDENT_MANAGE','TELEMETRY_READ','ALERT_MANAGE')
WHERE r.code='MAINTENANCE' ON CONFLICT DO NOTHING;

INSERT INTO role_permission(id_role,id_permission)
SELECT r.id_role,p.id_permission FROM app_role r JOIN permission p ON p.code IN
('COLONY_READ','MISSION_READ','ASSET_READ','INCIDENT_READ')
WHERE r.code='CREW' ON CONFLICT DO NOTHING;

INSERT INTO role_permission(id_role,id_permission)
SELECT r.id_role,p.id_permission FROM app_role r JOIN permission p ON p.code IN
('COLONY_READ','CREW_READ','MISSION_READ','ASSET_READ','INVENTORY_READ','INCIDENT_READ','SCIENCE_READ','TELEMETRY_READ','AUDIT_READ')
WHERE r.code='AUDITOR' ON CONFLICT DO NOTHING;

INSERT INTO unit_of_measure(code,name,symbol,quantity_type) VALUES
('KG','Kilogram','kg','MASS'),('G','Gram','g','MASS'),('L','Litre','L','VOLUME'),
('ML','Millilitre','mL','VOLUME'),('PCS','Pieces','pcs','COUNT'),('KWH','Kilowatt-hour','kWh','ENERGY'),
('M3','Cubic metre','m3','VOLUME'),('PA','Pascal','Pa','PRESSURE'),('KPA','Kilopascal','kPa','PRESSURE'),
('C','Degrees Celsius','°C','TEMPERATURE'),('PERCENT','Percentage','%','PERCENTAGE'),
('PPM','Parts per million','ppm','CONCENTRATION'),('SV','Sievert','Sv','OTHER'),('H','Hour','h','TIME')
ON CONFLICT (code) DO NOTHING;
