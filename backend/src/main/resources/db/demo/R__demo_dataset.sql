-- Demo dataset (TASK-004, issue #10): coherent sample data to develop and demonstrate AETHER.
--
-- Loaded only when Flyway also scans `db/demo` (Spring profiles `dev`/`demo`, the local Docker
-- Compose `migrate` service); never in tests or real environments. See ADR-0007.
--
-- * Runs once per database: if the demo colonies already exist the whole block is skipped,
--   so a re-run never duplicates rows. To reload after editing this file, reset the database.
-- * All timestamps are relative to the load time (t0), so "in progress" or "upcoming" missions
--   stay meaningful whenever the demo database is created.
-- * Rows reference each other by business code (colony.code, crew_member.employee_code, ...),
--   never by generated ids.
-- * Every demo account shares the documented password `Aether-demo-password` (ADR-0012), set by the
--   UPDATE after the block so that databases loaded before login existed get it too. Demo only.
--
-- Built-in cases for queries and negative tests are listed in docs/database/demo-dataset.md.

DO $demo$
DECLARE
    t0 CONSTANT TIMESTAMPTZ := date_trunc('hour', now());
BEGIN
    IF EXISTS (SELECT 1 FROM colony WHERE code = 'ARS-01') THEN
        RAISE NOTICE 'AETHER demo dataset already present, skipping';
        RETURN;
    END IF;

    -- ------------------------------------------------------------------ colonies (ARES)
    INSERT INTO colony(code, name, description, status, latitude, longitude, established_at, max_population) VALUES
    ('ARS-01','Ares Prime','Main settlement and Mission Control relay in Acidalia Planitia','OPERATIONAL',46.700000,-22.000000,DATE '2031-03-14',40),
    ('VLM-01','Valles Research Outpost','Geology and astrobiology outpost on the rim of Valles Marineris','OPERATIONAL',-13.900000,-59.200000,DATE '2033-08-02',16),
    ('ELY-01','Elysium Relay','Communications relay and power station, running on backup power','DEGRADED',25.000000,147.200000,DATE '2034-11-21',10),
    ('THR-01','Tharsis Forward Base','Forward base under construction near Arsia Mons','CONSTRUCTION',-8.300000,-120.100000,NULL,8);

    INSERT INTO habitat(id_colony, code, name, habitat_type, max_capacity, status)
    SELECT c.id_colony, v.code, v.name, v.habitat_type, v.max_capacity, v.status
    FROM (VALUES
        ('ARS-01','HAB-A','Ares Main Dome','DOME',30,'OPERATIONAL'),
        ('ARS-01','HAB-B','Ares Greenhouse Ring','GREENHOUSE',10,'OPERATIONAL'),
        ('VLM-01','HAB-A','Valles Lab Habitat','MODULAR',16,'OPERATIONAL'),
        ('ELY-01','HAB-A','Elysium Station','MODULAR',10,'DEGRADED'),
        ('THR-01','HAB-A','Tharsis Shelter','INFLATABLE',8,'PLANNED')
    ) AS v(colony_code, code, name, habitat_type, max_capacity, status)
    JOIN colony c ON c.code = v.colony_code;

    INSERT INTO habitat_module(id_habitat, code, name, module_type, status)
    SELECT h.id_habitat, v.code, v.name, v.module_type, v.status
    FROM (VALUES
        ('ARS-01','HAB-A','CMD','Command Center','COMMAND','OPERATIONAL'),
        ('ARS-01','HAB-A','RES','Crew Quarters','RESIDENTIAL','OPERATIONAL'),
        ('ARS-01','HAB-A','MED','Medical Bay','MEDICAL','OPERATIONAL'),
        ('ARS-01','HAB-A','STO','Main Storage','STORAGE','OPERATIONAL'),
        ('ARS-01','HAB-A','LSS','Life Support','LIFE_SUPPORT','OPERATIONAL'),
        ('ARS-01','HAB-A','AIR','North Airlock','AIRLOCK','OPERATIONAL'),
        ('ARS-01','HAB-B','GRN','Hydroponics','GREENHOUSE','OPERATIONAL'),
        ('VLM-01','HAB-A','CMD','Outpost Command','COMMAND','OPERATIONAL'),
        ('VLM-01','HAB-A','LAB','Geology Lab','LABORATORY','OPERATIONAL'),
        ('VLM-01','HAB-A','STO','Outpost Storage','STORAGE','OPERATIONAL'),
        ('ELY-01','HAB-A','PWR','Power Plant','POWER','DEGRADED'),
        ('ELY-01','HAB-A','COM','Relay Room','COMMUNICATION','OPERATIONAL'),
        ('ELY-01','HAB-A','STO','Station Storage','STORAGE','OPERATIONAL'),
        ('THR-01','HAB-A','STO','Construction Depot','STORAGE','PLANNED')
    ) AS v(colony_code, habitat_code, code, name, module_type, status)
    JOIN colony c ON c.code = v.colony_code
    JOIN habitat h ON h.id_colony = c.id_colony AND h.code = v.habitat_code;

    INSERT INTO operational_area(id_module, code, name, area_type, status)
    SELECT m.id_module, v.code, v.name, v.area_type, v.status
    FROM (VALUES
        ('ARS-01','HAB-A','STO','BAY-1','Bulk bay','STORAGE','OPERATIONAL'),
        ('ARS-01','HAB-A','STO','COLD-1','Cold room','STORAGE','OPERATIONAL'),
        ('ARS-01','HAB-A','AIR','GARAGE','Rover garage','VEHICLE_BAY','OPERATIONAL'),
        ('VLM-01','HAB-A','STO','BAY-1','Outpost bay','STORAGE','OPERATIONAL'),
        ('ELY-01','HAB-A','STO','BAY-1','Station bay','STORAGE','OPERATIONAL'),
        ('ELY-01','HAB-A','STO','EMERG','Emergency locker','STORAGE','RESTRICTED'),
        ('ELY-01','HAB-A','PWR','GEN-ROOM','Generator room','TECHNICAL','MAINTENANCE')
    ) AS v(colony_code, habitat_code, module_code, code, name, area_type, status)
    JOIN colony c ON c.code = v.colony_code
    JOIN habitat h ON h.id_colony = c.id_colony AND h.code = v.habitat_code
    JOIN habitat_module m ON m.id_habitat = h.id_habitat AND m.code = v.module_code;

    -- ------------------------------------------------------------------ people, accounts, crew
    INSERT INTO person(first_name, last_name, birth_date, nationality, email, status) VALUES
    ('Marco','Ferrari',DATE '1988-04-12','Italian','marco.ferrari@aether.demo','ACTIVE'),
    ('Elena','Conti',DATE '1990-09-03','Italian','elena.conti@aether.demo','ACTIVE'),
    ('Luca','Bianchi',DATE '1985-01-20','Italian','luca.bianchi@aether.demo','ACTIVE'),
    ('Franco','Villa',DATE '1984-03-25','Italian','franco.villa@aether.demo','ACTIVE'),
    ('Chiara','Fontana',DATE '1994-05-17','Italian','chiara.fontana@aether.demo','ACTIVE'),
    ('Giulia','Marino',DATE '1993-02-08','Italian','giulia.marino@aether.demo','ACTIVE'),
    ('Davide','Romano',DATE '1987-06-30','Italian','davide.romano@aether.demo','ACTIVE'),
    ('Sara','Greco',DATE '1992-11-15','Italian','sara.greco@aether.demo','ACTIVE'),
    ('Amara','Okafor',DATE '1991-07-22','Nigerian','amara.okafor@aether.demo','ACTIVE'),
    ('Tomas','Herrera',DATE '1995-10-09','Chilean','tomas.herrera@aether.demo','ACTIVE'),
    ('Ingrid','Larsen',DATE '1997-01-30','Norwegian','ingrid.larsen@aether.demo','ACTIVE'),
    ('Paolo','Rizzo',DATE '1986-07-19','Italian','paolo.rizzo@aether.demo','ACTIVE'),
    ('Anna','Colombo',DATE '1991-12-01','Italian','anna.colombo@aether.demo','ACTIVE'),
    ('Raj','Patel',DATE '1989-04-04','Indian','raj.patel@aether.demo','ACTIVE'),
    ('Mei','Chen',DATE '1990-08-18','Chinese','mei.chen@aether.demo','ACTIVE'),
    ('Yuki','Tanaka',DATE '1993-03-11','Japanese','yuki.tanaka@aether.demo','ACTIVE'),
    ('Pierre','Dubois',DATE '1983-09-27','French','pierre.dubois@aether.demo','SUSPENDED'),
    ('Omar','Haddad',DATE '1988-12-05','Jordanian','omar.haddad@aether.demo','ACTIVE'),
    ('Lena','Vogel',DATE '1979-06-14','German','lena.vogel@aether.demo','INACTIVE'),
    -- Mission Control staff on Earth: users of the platform, not crew.
    ('Laura','Rossi',DATE '1982-02-21','Italian','laura.rossi@aether.demo','ACTIVE'),
    ('Ivo','Neri',DATE '1980-10-10','Italian','ivo.neri@aether.demo','ACTIVE'),
    ('Nadia','Sala',DATE '1985-05-05','Italian','nadia.sala@aether.demo','ACTIVE');

    INSERT INTO crew_member(id_person, employee_code, id_home_colony, operational_role, status, hire_date, medical_clearance_until)
    SELECT p.id_person, v.employee_code, c.id_colony, v.operational_role, v.status, v.hire_date,
           (t0 + v.clearance_days * INTERVAL '1 day')::date
    FROM (VALUES
        ('marco.ferrari@aether.demo','CRW-001','ARS-01','Base Commander','ACTIVE',DATE '2030-01-15',180),
        ('elena.conti@aether.demo','CRW-002','ARS-01','Pilot','ACTIVE',DATE '2030-06-01',200),
        ('luca.bianchi@aether.demo','CRW-003','ARS-01','Maintenance Technician','ACTIVE',DATE '2030-06-01',150),
        ('franco.villa@aether.demo','CRW-004','ARS-01','Systems Engineer','ACTIVE',DATE '2029-11-20',-10),
        ('chiara.fontana@aether.demo','CRW-005','ARS-01','Medical Officer','ACTIVE',DATE '2031-02-10',300),
        ('giulia.marino@aether.demo','CRW-006','ARS-01','Logistics Officer','ACTIVE',DATE '2031-02-10',240),
        ('davide.romano@aether.demo','CRW-007','VLM-01','Base Commander','ACTIVE',DATE '2031-09-01',190),
        ('sara.greco@aether.demo','CRW-008','VLM-01','Geologist','ACTIVE',DATE '2032-03-15',210),
        ('amara.okafor@aether.demo','CRW-009','VLM-01','Biologist','ACTIVE',DATE '2032-03-15',220),
        ('tomas.herrera@aether.demo','CRW-010','VLM-01','Drone Operator','ACTIVE',DATE '2033-01-08',160),
        ('ingrid.larsen@aether.demo','CRW-011','VLM-01','Rover Pilot','TRAINING',DATE '2035-05-20',90),
        ('paolo.rizzo@aether.demo','CRW-012','ELY-01','Base Commander','ACTIVE',DATE '2032-07-07',170),
        ('anna.colombo@aether.demo','CRW-013','ELY-01','Rover Pilot','ACTIVE',DATE '2033-04-12',140),
        ('raj.patel@aether.demo','CRW-014','ELY-01','Communications Engineer','ACTIVE',DATE '2033-04-12',260),
        ('mei.chen@aether.demo','CRW-015','ELY-01','Power Systems Engineer','OFF_DUTY',DATE '2034-02-02',120),
        ('yuki.tanaka@aether.demo','CRW-016','ARS-01','EVA Specialist','MEDICAL_LEAVE',DATE '2032-10-30',30),
        ('pierre.dubois@aether.demo','CRW-017','VLM-01','Geologist','SUSPENDED',DATE '2031-09-01',60),
        ('omar.haddad@aether.demo','CRW-018','THR-01','Construction Engineer','ACTIVE',DATE '2034-09-09',200),
        ('lena.vogel@aether.demo','CRW-019','ARS-01','Systems Engineer','INACTIVE',DATE '2029-01-01',-400)
    ) AS v(email, employee_code, colony_code, operational_role, status, hire_date, clearance_days)
    JOIN person p ON p.email = v.email
    JOIN colony c ON c.code = v.colony_code;

    INSERT INTO user_account(id_person, username, password_hash, account_status, password_changed_at)
    SELECT p.id_person, v.username, 'DEMO-ACCOUNT-NO-LOGIN', v.account_status, t0 - INTERVAL '30 days'
    FROM (VALUES
        ('ivo.neri@aether.demo','admin.neri','ACTIVE'),
        ('laura.rossi@aether.demo','mc.rossi','ACTIVE'),
        ('nadia.sala@aether.demo','audit.sala','ACTIVE'),
        ('marco.ferrari@aether.demo','cmd.ferrari','ACTIVE'),
        ('davide.romano@aether.demo','cmd.romano','ACTIVE'),
        ('paolo.rizzo@aether.demo','cmd.rizzo','ACTIVE'),
        ('giulia.marino@aether.demo','log.marino','ACTIVE'),
        ('luca.bianchi@aether.demo','mnt.bianchi','ACTIVE'),
        ('sara.greco@aether.demo','sci.greco','ACTIVE'),
        ('elena.conti@aether.demo','crew.conti','ACTIVE'),
        ('pierre.dubois@aether.demo','sci.dubois','DISABLED')
    ) AS v(email, username, account_status)
    JOIN person p ON p.email = v.email;

    INSERT INTO user_role(id_account, id_role, assigned_at)
    SELECT a.id_account, r.id_role, t0 - INTERVAL '30 days'
    FROM (VALUES
        ('admin.neri','ADMIN'),
        ('mc.rossi','MISSION_CONTROLLER'),
        ('audit.sala','AUDITOR'),
        ('cmd.ferrari','COLONY_COMMANDER'),
        ('cmd.romano','COLONY_COMMANDER'),
        ('cmd.rizzo','COLONY_COMMANDER'),
        ('log.marino','LOGISTICS'),
        ('mnt.bianchi','MAINTENANCE'),
        ('sci.greco','SCIENTIST'),
        ('crew.conti','CREW'),
        ('sci.dubois','SCIENTIST')
    ) AS v(username, role_code)
    JOIN user_account a ON a.username = v.username
    JOIN app_role r ON r.code = v.role_code;

    INSERT INTO skill(code, name, category) VALUES
    ('EVA_OPS','Extravehicular operations','OPERATIONS'),
    ('ROVER_DRIVING','Pressurised rover driving','VEHICLES'),
    ('DRONE_PILOTING','Aerial drone piloting','VEHICLES'),
    ('GEOLOGY','Field geology','SCIENCE'),
    ('ASTROBIOLOGY','Astrobiology sampling','SCIENCE'),
    ('FIRST_AID','Advanced first aid','MEDICAL'),
    ('POWER_SYSTEMS','Power systems maintenance','ENGINEERING'),
    ('LIFE_SUPPORT','Life support maintenance','ENGINEERING'),
    ('COMMS','Communications systems','ENGINEERING'),
    ('LOGISTICS','Inventory and cargo handling','LOGISTICS');

    INSERT INTO crew_skill(id_crew_member, id_skill, proficiency_level, acquired_at, last_verified_at)
    SELECT cm.id_crew_member, s.id_skill, v.level, DATE '2032-01-01', (t0 - INTERVAL '60 days')::date
    FROM (VALUES
        ('CRW-001','EVA_OPS',5),('CRW-001','ROVER_DRIVING',4),
        ('CRW-002','ROVER_DRIVING',5),('CRW-002','EVA_OPS',4),
        ('CRW-003','POWER_SYSTEMS',4),('CRW-003','LIFE_SUPPORT',4),('CRW-003','EVA_OPS',3),
        ('CRW-004','LIFE_SUPPORT',5),('CRW-004','POWER_SYSTEMS',3),
        ('CRW-005','FIRST_AID',5),
        ('CRW-006','LOGISTICS',5),('CRW-006','ROVER_DRIVING',2),
        ('CRW-007','EVA_OPS',4),('CRW-007','GEOLOGY',3),
        ('CRW-008','GEOLOGY',5),('CRW-008','EVA_OPS',3),
        ('CRW-009','ASTROBIOLOGY',5),('CRW-009','GEOLOGY',2),
        ('CRW-010','DRONE_PILOTING',5),
        ('CRW-011','ROVER_DRIVING',2),
        ('CRW-012','EVA_OPS',4),('CRW-012','COMMS',3),
        ('CRW-013','ROVER_DRIVING',4),('CRW-013','EVA_OPS',3),
        ('CRW-014','COMMS',5),('CRW-014','POWER_SYSTEMS',2),
        ('CRW-015','POWER_SYSTEMS',5),
        ('CRW-016','EVA_OPS',5),
        ('CRW-017','GEOLOGY',4),
        ('CRW-018','EVA_OPS',3),('CRW-018','POWER_SYSTEMS',3)
    ) AS v(employee_code, skill_code, level)
    JOIN crew_member cm ON cm.employee_code = v.employee_code
    JOIN skill s ON s.code = v.skill_code;

    INSERT INTO certification(code, name, default_validity_months) VALUES
    ('EVA_SUIT','EVA suit operations',24),
    ('ROVER_LICENSE','Pressurised rover licence',36),
    ('MED_RESPONDER','Medical first responder',24),
    ('HAZMAT','Hazardous materials handling',12),
    ('POWER_SAFETY','High-voltage and reactor safety',12);

    INSERT INTO crew_certification(id_crew_member, id_certification, certificate_number, issuing_authority, issued_at, expires_at, status)
    SELECT cm.id_crew_member, ce.id_certification, v.number, 'AETHER Training Authority',
           (t0 + v.issued_days * INTERVAL '1 day')::date, (t0 + v.expires_days * INTERVAL '1 day')::date, v.status
    FROM (VALUES
        ('CRW-001','EVA_SUIT','EVA-0001',-400,330,'VALID'),
        ('CRW-001','ROVER_LICENSE','ROV-0001',-500,595,'VALID'),
        ('CRW-002','ROVER_LICENSE','ROV-0002',-1080,10,'VALID'),          -- expires in 10 days
        ('CRW-002','EVA_SUIT','EVA-0002',-300,430,'VALID'),
        ('CRW-003','EVA_SUIT','EVA-0003',-200,530,'VALID'),
        ('CRW-003','POWER_SAFETY','PWR-0003',-100,265,'VALID'),
        ('CRW-005','MED_RESPONDER','MED-0005',-150,580,'VALID'),
        ('CRW-006','HAZMAT','HAZ-0006',-90,275,'VALID'),
        ('CRW-007','EVA_SUIT','EVA-0007',-250,480,'VALID'),
        ('CRW-008','EVA_SUIT','EVA-0008',-120,610,'VALID'),
        ('CRW-010','ROVER_LICENSE','ROV-0010',-60,1035,'VALID'),
        ('CRW-012','EVA_SUIT','EVA-0012',-365,365,'VALID'),
        ('CRW-013','ROVER_LICENSE','ROV-0013',-700,395,'VALID'),
        ('CRW-013','EVA_SUIT','EVA-0013',-750,-20,'EXPIRED'),          -- expired: not eligible for EVA
        ('CRW-014','POWER_SAFETY','PWR-0014',-30,335,'VALID'),
        ('CRW-015','POWER_SAFETY','PWR-0015',-200,165,'VALID'),
        ('CRW-016','EVA_SUIT','EVA-0016',-100,630,'VALID'),
        ('CRW-017','EVA_SUIT','EVA-0017',-200,530,'SUSPENDED'),
        ('CRW-018','EVA_SUIT','EVA-0018',-50,680,'VALID')
    ) AS v(employee_code, cert_code, number, issued_days, expires_days, status)
    JOIN crew_member cm ON cm.employee_code = v.employee_code
    JOIN certification ce ON ce.code = v.cert_code;

    INSERT INTO crew_availability(id_crew_member, start_at, end_at, availability_type, reason)
    SELECT cm.id_crew_member, t0 + v.from_days * INTERVAL '1 day', t0 + v.to_days * INTERVAL '1 day', v.kind, v.reason
    FROM (VALUES
        ('CRW-016',-3,14,'MEDICAL','Recovery from a suit decompression injury'),
        ('CRW-009',4,10,'LEAVE','Scheduled rest period'),
        ('CRW-011',-20,10,'TRAINING','Rover pilot qualification course'),
        ('CRW-015',0,3,'UNAVAILABLE','Off duty after a double shift at the power plant')
    ) AS v(employee_code, from_days, to_days, kind, reason)
    JOIN crew_member cm ON cm.employee_code = v.employee_code;

    INSERT INTO crew_shift(id_crew_member, id_colony, start_at, end_at, shift_type, status)
    SELECT cm.id_crew_member, cm.id_home_colony, t0 + v.from_hours * INTERVAL '1 hour', t0 + v.to_hours * INTERVAL '1 hour', v.shift_type, v.status
    FROM (VALUES
        ('CRW-001',-24,-12,'DAY','COMPLETED'),
        ('CRW-001',0,12,'DAY','CONFIRMED'),
        ('CRW-004',12,24,'NIGHT','PLANNED'),
        ('CRW-005',0,12,'DAY','CONFIRMED'),
        ('CRW-006',24,36,'DAY','PLANNED'),
        ('CRW-007',0,12,'DAY','CONFIRMED'),
        ('CRW-012',0,12,'DAY','CONFIRMED'),
        ('CRW-014',12,24,'NIGHT','PLANNED'),
        ('CRW-015',-36,-12,'EMERGENCY','COMPLETED')
    ) AS v(employee_code, from_hours, to_hours, shift_type, status)
    JOIN crew_member cm ON cm.employee_code = v.employee_code;

    -- ------------------------------------------------------------------ fleet and assets (TITAN)
    INSERT INTO asset_type(code, name, category, description) VALUES
    ('ROVER','Pressurised rover','VEHICLE','Crewed surface vehicle'),
    ('DRONE','Survey drone','VEHICLE','Uncrewed aerial survey vehicle'),
    ('SHUTTLE','Suborbital shuttle','VEHICLE','Inter-colony hopper'),
    ('GENERATOR','Power generator','POWER','Primary or backup power unit'),
    ('LIFE_SUPPORT','Life support unit','LIFE_SUPPORT','Air and water recycling'),
    ('ANTENNA','High-gain antenna','COMMUNICATION','Earth and inter-colony link');

    INSERT INTO asset(code, id_asset_type, id_colony, serial_number, manufacturer, model, criticality, status, commissioned_at, operating_hours, active)
    SELECT v.code, t.id_asset_type, c.id_colony, v.serial, v.manufacturer, v.model, v.criticality, v.status, v.commissioned, v.hours, v.active
    FROM (VALUES
        ('ROV-ARS-01','ROVER','ARS-01','SN-RV-1001','RedRock Mobility','Pathfinder X2','HIGH','IN_USE',DATE '2031-05-01',4120.5,TRUE),
        ('ROV-ARS-02','ROVER','ARS-01','SN-RV-1002','RedRock Mobility','Pathfinder X2','HIGH','AVAILABLE',DATE '2032-02-11',2210.0,TRUE),
        ('ROV-ARS-03','ROVER','ARS-01','SN-RV-1003','RedRock Mobility','Pathfinder X1','HIGH','MAINTENANCE',DATE '2031-05-01',6890.2,TRUE),
        ('ROV-OLD-01','ROVER','ARS-01','SN-RV-0901','RedRock Mobility','Pathfinder X0','LOW','DECOMMISSIONED',DATE '2029-12-01',11020.0,FALSE),
        ('SHT-ARS-01','SHUTTLE','ARS-01','SN-SH-2001','Olympus Aero','Hopper 3','CRITICAL','AVAILABLE',DATE '2033-07-19',380.0,TRUE),
        ('ROV-VLM-01','ROVER','VLM-01','SN-RV-1101','RedRock Mobility','Canyon C1','HIGH','AVAILABLE',DATE '2033-09-01',1530.7,TRUE),
        ('DRN-VLM-01','DRONE','VLM-01','SN-DR-3001','Ingenuity Labs','Scout 5','MEDIUM','AVAILABLE',DATE '2034-01-15',320.4,TRUE),
        ('ROV-ELY-01','ROVER','ELY-01','SN-RV-1201','RedRock Mobility','Pathfinder X2','HIGH','AVAILABLE',DATE '2035-01-10',870.0,TRUE),
        ('DRN-ELY-01','DRONE','ELY-01','SN-DR-3002','Ingenuity Labs','Scout 5','MEDIUM','OUT_OF_SERVICE',DATE '2035-01-10',210.9,TRUE),
        ('GEN-ARS-01','GENERATOR','ARS-01','SN-GN-4001','Helios Power','Kilopower K10','CRITICAL','IN_USE',DATE '2031-03-14',38000.0,TRUE),
        ('GEN-ELY-01','GENERATOR','ELY-01','SN-GN-4002','Helios Power','Kilopower K5','CRITICAL','MAINTENANCE',DATE '2034-11-21',15500.0,TRUE),
        ('LSS-ELY-01','LIFE_SUPPORT','ELY-01','SN-LS-5001','Biosphere Systems','ECLSS-4','CRITICAL','IN_USE',DATE '2034-11-21',15400.0,TRUE),
        ('ANT-ARS-01','ANTENNA','ARS-01','SN-AN-6001','DeepLink','HGA-12','HIGH','IN_USE',DATE '2031-03-14',38010.0,TRUE)
    ) AS v(code, type_code, colony_code, serial, manufacturer, model, criticality, status, commissioned, hours, active)
    JOIN asset_type t ON t.code = v.type_code
    JOIN colony c ON c.code = v.colony_code;

    UPDATE asset a SET id_area = ar.id_area
    FROM operational_area ar
    JOIN habitat_module m ON m.id_module = ar.id_module
    JOIN habitat h ON h.id_habitat = m.id_habitat
    JOIN colony c ON c.id_colony = h.id_colony
    WHERE (a.code IN ('ROV-ARS-01','ROV-ARS-02','ROV-ARS-03') AND c.code = 'ARS-01' AND ar.code = 'GARAGE')
       OR (a.code = 'GEN-ELY-01' AND c.code = 'ELY-01' AND ar.code = 'GEN-ROOM');

    INSERT INTO asset_status_history(id_asset, previous_status, new_status, changed_by, changed_at, reason)
    SELECT a.id_asset, v.prev, v.next, u.id_account, t0 + v.at_days * INTERVAL '1 day', v.reason
    FROM (VALUES
        ('ROV-OLD-01','AVAILABLE','DECOMMISSIONED','mnt.bianchi',-200,'End of service life'),
        ('ROV-ARS-03','AVAILABLE','MAINTENANCE','mnt.bianchi',-4,'Suspension damage found during inspection'),
        ('DRN-ELY-01','AVAILABLE','OUT_OF_SERVICE','cmd.rizzo',-15,'Rotor motor burnt out, waiting for spare parts'),
        ('GEN-ELY-01','IN_USE','MAINTENANCE','cmd.rizzo',-2,'Primary generator tripped, station on backup power'),
        ('ROV-ARS-01','AVAILABLE','IN_USE','mc.rossi',-1,'Assigned to mission PHX-002')
    ) AS v(asset_code, prev, next, username, at_days, reason)
    JOIN asset a ON a.code = v.asset_code
    JOIN user_account u ON u.username = v.username;

    -- ------------------------------------------------------------------ resources and stock (ORION)
    INSERT INTO resource(code, name, category, id_unit, critical, shelf_life_days)
    SELECT v.code, v.name, v.category, u.id_unit, v.critical, v.shelf_life
    FROM (VALUES
        ('WATER','Potable water','LIFE_SUPPORT','L',TRUE,NULL),
        ('OXYGEN','Liquid oxygen','LIFE_SUPPORT','KG',TRUE,NULL),
        ('FOOD_RATION','Food ration pack','FOOD','PCS',TRUE,730),
        ('CH4_FUEL','Methane propellant','FUEL','KG',FALSE,NULL),
        ('AIR_FILTER','HEPA air filter cartridge','SPARE_PART','PCS',FALSE,NULL),
        ('MED_KIT','Trauma medical kit','MEDICAL','PCS',TRUE,1095),
        ('SOLAR_PANEL','Spare solar panel','SPARE_PART','PCS',FALSE,NULL)
    ) AS v(code, name, category, unit_code, critical, shelf_life)
    JOIN unit_of_measure u ON u.code = v.unit_code;

    INSERT INTO inventory_location(id_colony, id_area, code, name, location_type)
    SELECT c.id_colony, ar.id_area, v.code, v.name, v.location_type
    FROM (VALUES
        ('ARS-01','BAY-1','WH-MAIN','Ares main warehouse','WAREHOUSE'),
        ('ARS-01','COLD-1','COLD-01','Ares cold storage','COLD_STORAGE'),
        ('VLM-01','BAY-1','WH-MAIN','Valles warehouse','WAREHOUSE'),
        ('ELY-01','BAY-1','WH-MAIN','Elysium warehouse','WAREHOUSE'),
        ('ELY-01','EMERG','EMERG-01','Elysium emergency locker','EMERGENCY_STORAGE'),
        ('THR-01',NULL,'DEPOT-01','Tharsis construction depot','WAREHOUSE')
    ) AS v(colony_code, area_code, code, name, location_type)
    JOIN colony c ON c.code = v.colony_code
    LEFT JOIN LATERAL (
        SELECT oa.id_area FROM operational_area oa
        JOIN habitat_module m ON m.id_module = oa.id_module
        JOIN habitat h ON h.id_habitat = m.id_habitat
        WHERE h.id_colony = c.id_colony AND oa.code = v.area_code
    ) ar ON TRUE;

    INSERT INTO resource_lot(id_resource, lot_code, production_date, expiration_date, received_at, supplier, status)
    SELECT r.id_resource, v.lot_code, (t0 + v.produced_days * INTERVAL '1 day')::date,
           (t0 + v.expires_days * INTERVAL '1 day')::date, t0 + v.received_days * INTERVAL '1 day', v.supplier, v.status
    FROM (VALUES
        ('FOOD_RATION','FR-A-01',-120,610,-60,'Earth Provisions Consortium','AVAILABLE'),
        ('FOOD_RATION','FR-X-07',-745,-15,-700,'Earth Provisions Consortium','EXPIRED'),
        ('MED_KIT','MK-B-02',-200,895,-150,'Orbital Medical Supply','AVAILABLE')
    ) AS v(resource_code, lot_code, produced_days, expires_days, received_days, supplier, status)
    JOIN resource r ON r.code = v.resource_code;

    INSERT INTO inventory_stock(id_location, id_resource, id_lot, quantity, updated_at)
    SELECT l.id_location, r.id_resource, lot.id_lot, v.quantity, t0 - INTERVAL '2 days'
    FROM (VALUES
        ('ARS-01','WH-MAIN','WATER',NULL,5000),
        ('ARS-01','WH-MAIN','OXYGEN',NULL,1200),
        ('ARS-01','WH-MAIN','CH4_FUEL',NULL,3000),
        ('ARS-01','WH-MAIN','AIR_FILTER',NULL,40),
        ('ARS-01','WH-MAIN','MED_KIT','MK-B-02',25),
        ('ARS-01','WH-MAIN','SOLAR_PANEL',NULL,12),
        ('ARS-01','COLD-01','FOOD_RATION','FR-A-01',1500),
        ('VLM-01','WH-MAIN','WATER',NULL,1800),
        ('VLM-01','WH-MAIN','OXYGEN',NULL,400),
        ('VLM-01','WH-MAIN','FOOD_RATION','FR-A-01',600),
        ('VLM-01','WH-MAIN','AIR_FILTER',NULL,6),                 -- below minimum (10)
        ('VLM-01','WH-MAIN','MED_KIT','MK-B-02',8),
        ('ELY-01','WH-MAIN','WATER',NULL,300),                    -- below critical (400)
        ('ELY-01','WH-MAIN','OXYGEN',NULL,180),                   -- below warning (250)
        ('ELY-01','WH-MAIN','FOOD_RATION','FR-A-01',240),
        ('ELY-01','WH-MAIN','FOOD_RATION','FR-X-07',90),          -- expired lot still on shelf
        ('ELY-01','EMERG-01','MED_KIT','MK-B-02',0),              -- empty: any consumption must fail
        ('THR-01','DEPOT-01','WATER',NULL,400),
        ('THR-01','DEPOT-01','CH4_FUEL',NULL,800)
    ) AS v(colony_code, location_code, resource_code, lot_code, quantity)
    JOIN colony c ON c.code = v.colony_code
    JOIN inventory_location l ON l.id_colony = c.id_colony AND l.code = v.location_code
    JOIN resource r ON r.code = v.resource_code
    LEFT JOIN resource_lot lot ON lot.id_resource = r.id_resource AND lot.lot_code = v.lot_code;

    INSERT INTO inventory_threshold(id_location, id_resource, minimum_quantity, warning_quantity, critical_quantity)
    SELECT l.id_location, r.id_resource, v.minimum, v.warning, v.critical
    FROM (VALUES
        ('ARS-01','WH-MAIN','WATER',1000,1500,600),
        ('ARS-01','WH-MAIN','OXYGEN',300,450,150),
        ('VLM-01','WH-MAIN','AIR_FILTER',10,15,4),
        ('ELY-01','WH-MAIN','WATER',600,900,400),
        ('ELY-01','WH-MAIN','OXYGEN',150,250,100),
        ('ELY-01','EMERG-01','MED_KIT',4,6,2)
    ) AS v(colony_code, location_code, resource_code, minimum, warning, critical)
    JOIN colony c ON c.code = v.colony_code
    JOIN inventory_location l ON l.id_colony = c.id_colony AND l.code = v.location_code
    JOIN resource r ON r.code = v.resource_code;

    INSERT INTO shipment(code, origin_name, id_destination_colony, shipment_type, status, departure_at, estimated_arrival_at, actual_arrival_at)
    SELECT v.code, v.origin, c.id_colony, v.shipment_type, v.status,
           t0 + v.departure_days * INTERVAL '1 day', t0 + v.eta_days * INTERVAL '1 day',
           t0 + v.arrival_days * INTERVAL '1 day'
    FROM (VALUES
        ('SHP-0001','Earth - Kennedy Cargo Port','ARS-01','EARTH_CARGO','IN_TRANSIT',-150,25,NULL::int),
        ('SHP-0002','Ares Prime','VLM-01','INTER_COLONY','RECEIVED',-20,-18,-18),
        ('SHP-0003','Ares Prime','ELY-01','EMERGENCY','DELAYED',-3,-1,NULL::int),
        ('SHP-0004','Valles Research Outpost','THR-01','INTER_COLONY','PLANNED',10,12,NULL::int)
    ) AS v(code, origin, colony_code, shipment_type, status, departure_days, eta_days, arrival_days)
    JOIN colony c ON c.code = v.colony_code;

    INSERT INTO shipment_item(id_shipment, id_resource, expected_quantity, received_quantity, notes)
    SELECT s.id_shipment, r.id_resource, v.expected, v.received, v.notes
    FROM (VALUES
        ('SHP-0001','MED_KIT',50,0,NULL),
        ('SHP-0001','AIR_FILTER',100,0,NULL),
        ('SHP-0001','SOLAR_PANEL',20,0,NULL),
        ('SHP-0002','FOOD_RATION',600,600,'Lot FR-A-01'),
        ('SHP-0003','WATER',1000,0,'Delayed by dust storm'),
        ('SHP-0003','OXYGEN',200,0,'Delayed by dust storm'),
        ('SHP-0004','WATER',300,0,NULL)
    ) AS v(shipment_code, resource_code, expected, received, notes)
    JOIN shipment s ON s.code = v.shipment_code
    JOIN resource r ON r.code = v.resource_code;

    -- Ledger (BR-006): every stock row is backed by movements whose net equals its quantity.
    INSERT INTO inventory_movement(id_resource, id_lot, to_location_id, movement_type, quantity, created_by, occurred_at, reason)
    SELECT st.id_resource, st.id_lot, st.id_location, 'RECEIPT',
           st.quantity + CASE WHEN l.code = 'EMERG-01' AND r.code = 'MED_KIT' THEN 3 ELSE 0 END,
           u.id_account, t0 - INTERVAL '40 days', 'Demo opening balance'
    FROM inventory_stock st
    JOIN inventory_location l ON l.id_location = st.id_location
    JOIN resource r ON r.id_resource = st.id_resource
    JOIN user_account u ON u.username = 'log.marino'
    WHERE st.quantity > 0 OR (l.code = 'EMERG-01' AND r.code = 'MED_KIT');

    INSERT INTO inventory_movement(id_resource, id_lot, from_location_id, movement_type, quantity, created_by, occurred_at, reason)
    SELECT st.id_resource, st.id_lot, st.id_location, 'CONSUMPTION', 3, u.id_account, t0 - INTERVAL '2 days',
           'Used during incident INC-0001 (generator failure)'
    FROM inventory_stock st
    JOIN inventory_location l ON l.id_location = st.id_location
    JOIN resource r ON r.id_resource = st.id_resource
    JOIN user_account u ON u.username = 'cmd.rizzo'
    WHERE l.code = 'EMERG-01' AND r.code = 'MED_KIT';

    -- ------------------------------------------------------------------ missions (PHOENIX)
    INSERT INTO mission(code, title, description, mission_type, id_origin_colony, id_destination_colony, destination_name,
                        planned_start_at, planned_end_at, actual_start_at, actual_end_at, status, priority, safety_level,
                        created_by, created_at, cancelled_reason)
    SELECT v.code, v.title, v.description, v.mission_type, o.id_colony, d.id_colony, v.destination_name,
           t0 + v.start_days * INTERVAL '1 day', t0 + v.end_days * INTERVAL '1 day',
           t0 + v.actual_start_days * INTERVAL '1 day', t0 + v.actual_end_days * INTERVAL '1 day',
           v.status, v.priority, v.safety_level, u.id_account,
           -- planned missions are drafted ten days ahead; a rescue is drafted two hours before departure
           CASE WHEN v.mission_type = 'RESCUE' THEN t0 + v.start_days * INTERVAL '1 day' - INTERVAL '2 hours'
                ELSE t0 + (LEAST(v.start_days, 0) - 10) * INTERVAL '1 day' END,
           v.cancelled_reason
    FROM (VALUES
        ('PHX-001','Acidalia ridge survey','Map the ridge north of Ares Prime for future landing pads','EXPLORATION','ARS-01',NULL,'Acidalia north ridge',-30,-27,-30,-27,'COMPLETED','MEDIUM','ELEVATED',NULL),
        ('PHX-002','Relay antenna inspection','EVA inspection of the high-gain antenna after the dust storm','INSPECTION','ARS-01',NULL,'Antenna field',-1,2,-1,NULL::int,'IN_PROGRESS','HIGH','ELEVATED',NULL),
        ('PHX-003','Candor Chasma core sampling','Drill and retrieve core samples from Candor Chasma','SCIENCE','VLM-01',NULL,'Candor Chasma',5,9,NULL::int,NULL::int,'APPROVED','HIGH','HIGH_RISK',NULL),
        ('PHX-004','Water resupply to Elysium','Rover convoy carrying water and oxygen to Elysium Relay','TRANSPORT','ARS-01','ELY-01',NULL,12,15,NULL::int,NULL::int,'APPROVAL_PENDING','CRITICAL','ELEVATED',NULL),
        ('PHX-005','Elysium generator overhaul','Replace the failed primary generator coils','MAINTENANCE','ELY-01',NULL,'Power plant',20,22,NULL::int,NULL::int,'PLANNED','HIGH','HIGH_RISK',NULL),
        ('PHX-006','Arsia Mons lava tube scouting','Scout lava tubes for the future Tharsis habitat','EXPLORATION','THR-01',NULL,'Arsia Mons south flank',30,35,NULL::int,NULL::int,'DRAFT','MEDIUM','HIGH_RISK',NULL),
        ('PHX-007','Stranded rover rescue','Recover a crew stranded after a rover rollover','RESCUE','VLM-01',NULL,'Ius Chasma rim',-10,-8,-10,-9,'ABORTED','CRITICAL','CRITICAL',NULL),
        ('PHX-008','Elysium cargo pickup','Collect spare parts from the landing site','LOGISTICS','ELY-01',NULL,'Elysium landing site',-5,-4,NULL::int,NULL::int,'CANCELLED','LOW','STANDARD','Dust storm: visibility below EVA minimums'),
        ('PHX-009','Melas Chasma drone mapping','Drone mapping overlapping the PHX-003 window','SCIENCE','VLM-01',NULL,'Melas Chasma',6,8,NULL::int,NULL::int,'DRAFT','MEDIUM','STANDARD',NULL),
        ('PHX-010','Hydroponics radiator EVA','Replace a radiator panel outside the greenhouse ring','EVA','ARS-01',NULL,'Greenhouse ring exterior',3,4,NULL::int,NULL::int,'PLANNED','MEDIUM','ELEVATED',NULL)
    ) AS v(code, title, description, mission_type, origin_code, destination_code, destination_name,
           start_days, end_days, actual_start_days, actual_end_days, status, priority, safety_level, cancelled_reason)
    JOIN colony o ON o.code = v.origin_code
    LEFT JOIN colony d ON d.code = v.destination_code
    JOIN user_account u ON u.username = 'mc.rossi';

    INSERT INTO mission_objective(id_mission, sequence_no, description, priority, status)
    SELECT m.id_mission, v.seq, v.description, v.priority, v.status
    FROM (VALUES
        ('PHX-001',1,'Survey 12 km of ridge with lidar','HIGH','COMPLETED'),
        ('PHX-001',2,'Identify two candidate landing pads','MEDIUM','COMPLETED'),
        ('PHX-002',1,'Inspect antenna dish and feed horn','HIGH','IN_PROGRESS'),
        ('PHX-002',2,'Clean solar panels on the antenna mast','MEDIUM','PENDING'),
        ('PHX-003',1,'Retrieve three 2 m core samples','HIGH','PENDING'),
        ('PHX-004',1,'Deliver 1000 L water and 200 kg oxygen','CRITICAL','PENDING'),
        ('PHX-007',1,'Bring the stranded crew back to the outpost','CRITICAL','FAILED')
    ) AS v(mission_code, seq, description, priority, status)
    JOIN mission m ON m.code = v.mission_code;

    INSERT INTO mission_phase(id_mission, sequence_no, name, planned_start_at, planned_end_at, actual_start_at, actual_end_at, status)
    SELECT m.id_mission, v.seq, v.name,
           m.planned_start_at + v.from_h * INTERVAL '1 hour', m.planned_start_at + v.to_h * INTERVAL '1 hour',
           CASE WHEN v.status IN ('IN_PROGRESS','COMPLETED') THEN m.planned_start_at + v.from_h * INTERVAL '1 hour' END,
           CASE WHEN v.status = 'COMPLETED' THEN m.planned_start_at + v.to_h * INTERVAL '1 hour' END,
           v.status
    FROM (VALUES
        ('PHX-001',1,'Traverse',0,24,'COMPLETED'),
        ('PHX-001',2,'Survey',24,60,'COMPLETED'),
        ('PHX-001',3,'Return',60,72,'COMPLETED'),
        ('PHX-002',1,'EVA preparation',0,12,'COMPLETED'),
        ('PHX-002',2,'Inspection',12,48,'IN_PROGRESS'),
        ('PHX-002',3,'Debrief',48,72,'PLANNED'),
        ('PHX-003',1,'Drive to site',0,24,'PLANNED'),
        ('PHX-003',2,'Drilling',24,80,'PLANNED'),
        ('PHX-003',3,'Return',80,96,'PLANNED')
    ) AS v(mission_code, seq, name, from_h, to_h, status)
    JOIN mission m ON m.code = v.mission_code;

    INSERT INTO mission_task(id_phase, title, assigned_crew_member, priority, status, planned_start_at, planned_end_at, completed_at)
    SELECT ph.id_phase, v.title, cm.id_crew_member, v.priority, v.status, ph.planned_start_at, ph.planned_end_at,
           CASE WHEN v.status = 'DONE' THEN ph.planned_end_at END
    FROM (VALUES
        ('PHX-002',1,'Suit checks and pre-breathe','CRW-005','HIGH','DONE'),
        ('PHX-002',2,'Inspect feed horn','CRW-003','HIGH','IN_PROGRESS'),
        ('PHX-002',2,'Drive rover to antenna field','CRW-002','MEDIUM','DONE'),
        ('PHX-002',2,'Replace damaged cable','CRW-003','HIGH','BLOCKED'),
        ('PHX-003',2,'Set up drill rig','CRW-008','HIGH','TODO')
    ) AS v(mission_code, phase_seq, title, employee_code, priority, status)
    JOIN mission m ON m.code = v.mission_code
    JOIN mission_phase ph ON ph.id_mission = m.id_mission AND ph.sequence_no = v.phase_seq
    JOIN crew_member cm ON cm.employee_code = v.employee_code;

    -- Active (ASSIGNED/CONFIRMED) windows never overlap for the same crew member or asset (BR-003, BR-005).
    INSERT INTO mission_crew_assignment(id_mission, id_crew_member, mission_role, is_commander, assigned_from, assigned_to, status, assigned_at)
    SELECT m.id_mission, cm.id_crew_member, v.mission_role, v.commander, m.planned_start_at, m.planned_end_at, v.status,
           m.created_at + INTERVAL '1 day'
    FROM (VALUES
        ('PHX-001','CRW-001','Commander',TRUE,'RELEASED'),
        ('PHX-001','CRW-002','Pilot',FALSE,'RELEASED'),
        ('PHX-001','CRW-004','Engineer',FALSE,'RELEASED'),
        ('PHX-002','CRW-002','Commander',TRUE,'CONFIRMED'),
        ('PHX-002','CRW-003','EVA Technician',FALSE,'CONFIRMED'),
        ('PHX-002','CRW-005','Medical Support',FALSE,'CONFIRMED'),
        ('PHX-003','CRW-007','Commander',TRUE,'CONFIRMED'),
        ('PHX-003','CRW-008','Lead Geologist',FALSE,'CONFIRMED'),
        ('PHX-003','CRW-010','Drone Operator',FALSE,'CONFIRMED'),
        ('PHX-004','CRW-001','Commander',TRUE,'ASSIGNED'),
        ('PHX-004','CRW-006','Cargo Master',FALSE,'ASSIGNED'),
        ('PHX-005','CRW-012','Commander',TRUE,'ASSIGNED'),
        ('PHX-005','CRW-014','Engineer',FALSE,'ASSIGNED'),
        ('PHX-007','CRW-007','Commander',TRUE,'RELEASED'),
        ('PHX-007','CRW-011','Rover Pilot',FALSE,'RELEASED'),
        ('PHX-008','CRW-013','Commander',TRUE,'CANCELLED')
    ) AS v(mission_code, employee_code, mission_role, commander, status)
    JOIN mission m ON m.code = v.mission_code
    JOIN crew_member cm ON cm.employee_code = v.employee_code;

    INSERT INTO mission_asset_assignment(id_mission, id_asset, asset_role, assigned_from, assigned_to, status, assigned_at)
    SELECT m.id_mission, a.id_asset, v.asset_role, m.planned_start_at, m.planned_end_at, v.status, m.created_at + INTERVAL '1 day'
    FROM (VALUES
        ('PHX-001','ROV-ARS-01','Survey vehicle','RELEASED'),
        ('PHX-002','ROV-ARS-01','Crew transport','CONFIRMED'),
        ('PHX-003','ROV-VLM-01','Crew transport','CONFIRMED'),
        ('PHX-003','DRN-VLM-01','Aerial survey','CONFIRMED'),
        ('PHX-004','ROV-ARS-02','Cargo carrier','ASSIGNED'),
        ('PHX-007','ROV-VLM-01','Rescue vehicle','RELEASED')
    ) AS v(mission_code, asset_code, asset_role, status)
    JOIN mission m ON m.code = v.mission_code
    JOIN asset a ON a.code = v.asset_code;

    INSERT INTO mission_skill_requirement(id_mission, id_skill, minimum_level, required_people)
    SELECT m.id_mission, s.id_skill, v.min_level, v.people
    FROM (VALUES
        ('PHX-003','GEOLOGY',4,1),
        ('PHX-003','EVA_OPS',3,2),
        ('PHX-004','ROVER_DRIVING',3,1),
        ('PHX-005','POWER_SYSTEMS',4,1),
        ('PHX-010','EVA_OPS',3,2)
    ) AS v(mission_code, skill_code, min_level, people)
    JOIN mission m ON m.code = v.mission_code
    JOIN skill s ON s.code = v.skill_code;

    INSERT INTO mission_cert_requirement(id_mission, id_certification, required_people, validity_buffer_days)
    SELECT m.id_mission, ce.id_certification, v.people, v.buffer
    FROM (VALUES
        ('PHX-002','EVA_SUIT',2,0),
        ('PHX-003','EVA_SUIT',2,14),
        ('PHX-004','ROVER_LICENSE',1,30),
        ('PHX-005','POWER_SAFETY',1,0),
        ('PHX-010','EVA_SUIT',2,7)
    ) AS v(mission_code, cert_code, people, buffer)
    JOIN mission m ON m.code = v.mission_code
    JOIN certification ce ON ce.code = v.cert_code;

    INSERT INTO mission_resource_requirement(id_mission, id_resource, required_quantity)
    SELECT m.id_mission, r.id_resource, v.quantity
    FROM (VALUES
        ('PHX-003','OXYGEN',60),
        ('PHX-003','FOOD_RATION',40),
        ('PHX-004','WATER',1000),
        ('PHX-004','OXYGEN',200),
        ('PHX-005','AIR_FILTER',4)
    ) AS v(mission_code, resource_code, quantity)
    JOIN mission m ON m.code = v.mission_code
    JOIN resource r ON r.code = v.resource_code;

    -- PHX-003 (approved) has its resources reserved from the Valles warehouse.
    INSERT INTO mission_resource_allocation(id_requirement, id_inventory_stock, allocated_quantity, status, allocated_at)
    SELECT req.id_requirement, st.id_inventory_stock, req.required_quantity, 'RESERVED', t0 - INTERVAL '1 day'
    FROM mission_resource_requirement req
    JOIN mission m ON m.id_mission = req.id_mission AND m.code = 'PHX-003'
    JOIN colony c ON c.code = 'VLM-01'
    JOIN inventory_location l ON l.id_colony = c.id_colony AND l.code = 'WH-MAIN'
    JOIN inventory_stock st ON st.id_location = l.id_location AND st.id_resource = req.id_resource;

    INSERT INTO mission_risk(id_mission, title, likelihood, impact, mitigation, owner_crew_member, status)
    SELECT m.id_mission, v.title, v.likelihood, v.impact, v.mitigation, cm.id_crew_member, v.status
    FROM (VALUES
        ('PHX-003','Canyon wall rockfall',2,5,'Keep 50 m clearance from the wall, drone overwatch','CRW-007','OPEN'),
        ('PHX-004','Dust storm on the convoy route',3,4,'Daily weather go/no-go with Mission Control','CRW-001','OPEN'),
        ('PHX-002','Suit puncture on antenna structure',2,4,'Edge guards installed on mast','CRW-005','MITIGATED')
    ) AS v(mission_code, title, likelihood, impact, mitigation, employee_code, status)
    JOIN mission m ON m.code = v.mission_code
    JOIN crew_member cm ON cm.employee_code = v.employee_code;

    -- Separation of duties (BR-013): the requester never decides.
    INSERT INTO mission_approval(id_mission, approval_type, requested_by, requested_at, decision, decided_by, decided_at, notes)
    SELECT m.id_mission, v.approval_type, rq.id_account, m.created_at + ra.request_after, v.decision, dc.id_account,
           CASE WHEN v.decision <> 'PENDING' THEN m.created_at + ra.request_after * 1.5 END, v.notes
    FROM (VALUES
        ('PHX-001','OPERATIONAL','mc.rossi','APPROVED','cmd.ferrari',NULL),
        ('PHX-002','OPERATIONAL','mc.rossi','APPROVED','cmd.ferrari',NULL),
        ('PHX-002','SAFETY','mc.rossi','APPROVED','admin.neri','EVA in pairs only'),
        ('PHX-003','OPERATIONAL','mc.rossi','APPROVED','cmd.romano',NULL),
        ('PHX-003','SAFETY','mc.rossi','APPROVED','cmd.ferrari','High-risk site: drone overwatch mandatory'),
        ('PHX-003','SCIENCE','sci.greco','APPROVED','cmd.romano',NULL),
        ('PHX-004','OPERATIONAL','mc.rossi','PENDING',NULL,NULL),
        ('PHX-004','LOGISTICS','log.marino','PENDING',NULL,NULL),
        ('PHX-007','OPERATIONAL','mc.rossi','APPROVED','cmd.romano','Emergency approval'),
        ('PHX-008','OPERATIONAL','mc.rossi','REJECTED','cmd.rizzo','Weather window closed')
    ) AS v(mission_code, approval_type, requested_by, decision, decided_by, notes)
    JOIN mission m ON m.code = v.mission_code
    CROSS JOIN LATERAL (SELECT CASE WHEN m.mission_type = 'RESCUE' THEN INTERVAL '30 minutes'
                                    ELSE INTERVAL '2 days' END AS request_after) ra
    JOIN user_account rq ON rq.username = v.requested_by
    LEFT JOIN user_account dc ON dc.username = v.decided_by;

    -- Lifecycle history: each mission walks the documented states up to its current one.
    INSERT INTO mission_status_history(id_mission, previous_status, new_status, changed_by, changed_at, reason)
    SELECT m.id_mission, v.prev, v.next, u.id_account, m.created_at + v.step::float8 * INTERVAL '1 day', v.reason
    FROM (VALUES
        ('PHX-001',0,NULL,'DRAFT','mc.rossi',NULL),
        ('PHX-001',1,'DRAFT','PLANNED','mc.rossi',NULL),
        ('PHX-001',2,'PLANNED','APPROVAL_PENDING','mc.rossi',NULL),
        ('PHX-001',3,'APPROVAL_PENDING','APPROVED','cmd.ferrari',NULL),
        ('PHX-001',10,'APPROVED','IN_PROGRESS','cmd.ferrari',NULL),
        ('PHX-001',13,'IN_PROGRESS','COMPLETED','cmd.ferrari','All objectives met'),
        ('PHX-002',0,NULL,'DRAFT','mc.rossi',NULL),
        ('PHX-002',1,'DRAFT','PLANNED','mc.rossi',NULL),
        ('PHX-002',2,'PLANNED','APPROVAL_PENDING','mc.rossi',NULL),
        ('PHX-002',3,'APPROVAL_PENDING','APPROVED','cmd.ferrari',NULL),
        ('PHX-002',10,'APPROVED','IN_PROGRESS','cmd.ferrari',NULL),
        ('PHX-003',0,NULL,'DRAFT','mc.rossi',NULL),
        ('PHX-003',1,'DRAFT','PLANNED','mc.rossi',NULL),
        ('PHX-003',2,'PLANNED','APPROVAL_PENDING','mc.rossi',NULL),
        ('PHX-003',3,'APPROVAL_PENDING','APPROVED','cmd.romano',NULL),
        ('PHX-004',0,NULL,'DRAFT','mc.rossi',NULL),
        ('PHX-004',1,'DRAFT','PLANNED','mc.rossi',NULL),
        ('PHX-004',2,'PLANNED','APPROVAL_PENDING','mc.rossi',NULL),
        ('PHX-005',0,NULL,'DRAFT','mc.rossi',NULL),
        ('PHX-005',1,'DRAFT','PLANNED','mc.rossi',NULL),
        ('PHX-006',0,NULL,'DRAFT','mc.rossi',NULL),
        ('PHX-007',0,NULL,'DRAFT','mc.rossi','Emergency'),
        ('PHX-007',0.04,'DRAFT','APPROVED','cmd.romano','Emergency approval'),
        ('PHX-007',0.08,'APPROVED','IN_PROGRESS','cmd.romano',NULL),
        ('PHX-007',1.08,'IN_PROGRESS','ABORTED','cmd.romano','Rescue rover rolled over, see INC-0002'),
        ('PHX-008',0,NULL,'DRAFT','mc.rossi',NULL),
        ('PHX-008',1,'DRAFT','PLANNED','mc.rossi',NULL),
        ('PHX-008',2,'PLANNED','APPROVAL_PENDING','mc.rossi',NULL),
        ('PHX-008',3,'APPROVAL_PENDING','CANCELLED','cmd.rizzo','Dust storm: visibility below EVA minimums'),
        ('PHX-009',0,NULL,'DRAFT','mc.rossi',NULL),
        ('PHX-010',0,NULL,'DRAFT','mc.rossi',NULL),
        ('PHX-010',1,'DRAFT','PLANNED','mc.rossi',NULL)
    ) AS v(mission_code, step, prev, next, username, reason)
    JOIN mission m ON m.code = v.mission_code
    JOIN user_account u ON u.username = v.username;

    -- ------------------------------------------------------------------ telemetry
    INSERT INTO sensor_type(code, name, metric, id_unit, expected_min, expected_max)
    SELECT v.code, v.name, v.metric, u.id_unit, v.min, v.max
    FROM (VALUES
        ('O2_PARTIAL','Oxygen partial pressure','o2_partial_pressure','KPA',19.5,23.5),
        ('CO2','Carbon dioxide','co2_concentration','PPM',0,5000),
        ('HAB_TEMP','Habitat temperature','air_temperature','C',18,26)
    ) AS v(code, name, metric, unit_code, min, max)
    JOIN unit_of_measure u ON u.code = v.unit_code;

    INSERT INTO sensor(code, id_sensor_type, id_colony, id_asset, status, installed_at, last_calibrated_at)
    SELECT v.code, st.id_sensor_type, c.id_colony, a.id_asset, v.status, t0 - INTERVAL '400 days', t0 - INTERVAL '30 days'
    FROM (VALUES
        ('SNS-ARS-O2-01','O2_PARTIAL','ARS-01',NULL,'ACTIVE'),
        ('SNS-ARS-CO2-01','CO2','ARS-01',NULL,'ACTIVE'),
        ('SNS-ELY-TEMP-01','HAB_TEMP','ELY-01','GEN-ELY-01','DEGRADED')
    ) AS v(code, type_code, colony_code, asset_code, status)
    JOIN sensor_type st ON st.code = v.type_code
    JOIN colony c ON c.code = v.colony_code
    LEFT JOIN asset a ON a.code = v.asset_code;

    INSERT INTO threshold_rule(id_sensor_type, rule_name, maximum_value, severity, persistence_seconds)
    SELECT id_sensor_type, 'CO2 above habitability limit', 5000, 'HIGH', 300 FROM sensor_type WHERE code = 'CO2';

    INSERT INTO telemetry_measurement(id_sensor, measured_at, numeric_value, quality)
    SELECT s.id_sensor, t0 - v.minutes_ago * INTERVAL '1 minute', v.value, v.quality
    FROM (VALUES
        ('SNS-ARS-O2-01',60,21.2,'GOOD'),('SNS-ARS-O2-01',30,21.1,'GOOD'),('SNS-ARS-O2-01',0,21.0,'GOOD'),
        ('SNS-ARS-CO2-01',60,3900,'GOOD'),('SNS-ARS-CO2-01',30,5120,'GOOD'),('SNS-ARS-CO2-01',0,5480,'GOOD'),
        ('SNS-ELY-TEMP-01',60,29.5,'SUSPECT'),('SNS-ELY-TEMP-01',0,31.2,'SUSPECT')
    ) AS v(sensor_code, minutes_ago, value, quality)
    JOIN sensor s ON s.code = v.sensor_code;

    INSERT INTO alert(id_sensor, id_rule, id_measurement, severity, message, status, triggered_at, acknowledged_at)
    SELECT s.id_sensor, r.id_rule, tm.id_measurement, 'HIGH', 'CO2 at 5120 ppm in Ares Main Dome', 'ACKNOWLEDGED', tm.measured_at, tm.measured_at + INTERVAL '10 minutes'
    FROM sensor s
    JOIN threshold_rule r ON r.id_sensor_type = s.id_sensor_type
    JOIN telemetry_measurement tm ON tm.id_sensor = s.id_sensor AND tm.measured_at = t0 - INTERVAL '30 minutes'
    WHERE s.code = 'SNS-ARS-CO2-01';

    INSERT INTO alert_acknowledgement(id_alert, id_account, acknowledged_at, note)
    SELECT al.id_alert, u.id_account, al.acknowledged_at, 'Scrubber check requested'
    FROM alert al JOIN user_account u ON u.username = 'cmd.ferrari';

    -- ------------------------------------------------------------------ incidents (HELIOS)
    INSERT INTO incident(code, id_colony, id_mission, id_asset, title, description, severity, status, reported_by,
                         opened_at, acknowledged_at, resolved_at, closed_at, root_cause, resolution, closed_by, closure_reason)
    SELECT v.code, c.id_colony, m.id_mission, a.id_asset, v.title, v.description, v.severity, v.status, rp.id_account,
           t0 + v.opened_h * INTERVAL '1 hour', t0 + v.ack_h * INTERVAL '1 hour', t0 + v.resolved_h * INTERVAL '1 hour',
           t0 + v.closed_h * INTERVAL '1 hour', v.root_cause, v.resolution, cb.id_account, v.closure_reason
    FROM (VALUES
        ('INC-0001','ELY-01',NULL,'GEN-ELY-01','Primary generator failure','Primary generator tripped; station running on backup power at 40 % capacity','CRITICAL','IN_PROGRESS','cmd.rizzo',-50,-49,NULL::int,NULL::int,NULL,NULL,NULL,NULL),
        ('INC-0002','VLM-01','PHX-007','ROV-VLM-01','Rescue rover rollover','Rover rolled on a loose slope during the rescue; crew unhurt','HIGH','CLOSED','cmd.romano',-228,-227,-200,-190,'Slope stability not assessed before descent','Rover recovered and repaired; new slope checklist','cmd.romano','Corrective actions completed and verified'),
        ('INC-0003','ARS-01',NULL,NULL,'CO2 above limit in main dome','CO2 sensor reports values above 5000 ppm','HIGH','ACKNOWLEDGED','cmd.ferrari',0,0,NULL::int,NULL::int,NULL,NULL,NULL,NULL),
        ('INC-0004','ELY-01',NULL,NULL,'Water reserve below critical threshold','Elysium warehouse water below the critical level while resupply is delayed','HIGH','OPEN','log.marino',-6,NULL::int,NULL::int,NULL::int,NULL,NULL,NULL,NULL),
        ('INC-0005','ARS-01',NULL,'ROV-ARS-03','Rover suspension damage','Cracked suspension arm found during inspection','MEDIUM','RESOLVED','mnt.bianchi',-96,-95,-20,NULL::int,'Metal fatigue','Rover taken out of service for repair',NULL,NULL),
        ('INC-0006','VLM-01',NULL,'DRN-VLM-01','Drone lost GPS lock','Short loss of navigation during test flight','LOW','CANCELLED','sci.greco',-300,NULL::int,NULL::int,NULL::int,NULL,NULL,NULL,NULL)
    ) AS v(code, colony_code, mission_code, asset_code, title, description, severity, status, reported_by,
           opened_h, ack_h, resolved_h, closed_h, root_cause, resolution, closed_by, closure_reason)
    JOIN colony c ON c.code = v.colony_code
    LEFT JOIN mission m ON m.code = v.mission_code
    LEFT JOIN asset a ON a.code = v.asset_code
    JOIN user_account rp ON rp.username = v.reported_by
    LEFT JOIN user_account cb ON cb.username = v.closed_by;

    UPDATE incident SET source_alert_id = (SELECT id_alert FROM alert LIMIT 1) WHERE code = 'INC-0003';

    INSERT INTO incident_assignee(id_incident, id_crew_member, responder_role, assigned_at, released_at)
    SELECT i.id_incident, cm.id_crew_member, v.role, i.opened_at + INTERVAL '30 minutes',
           CASE WHEN i.status IN ('CLOSED','RESOLVED') THEN i.resolved_at END
    FROM (VALUES
        ('INC-0001','CRW-012','Incident commander'),
        ('INC-0001','CRW-014','Electrical responder'),
        ('INC-0002','CRW-007','Incident commander'),
        ('INC-0002','CRW-011','Witness'),
        ('INC-0003','CRW-004','Life support engineer'),
        ('INC-0005','CRW-003','Inspector')
    ) AS v(incident_code, employee_code, role)
    JOIN incident i ON i.code = v.incident_code
    JOIN crew_member cm ON cm.employee_code = v.employee_code;

    INSERT INTO incident_event(id_incident, event_type, description, created_by, created_at)
    SELECT i.id_incident, v.event_type, v.description, u.id_account, i.opened_at + v.after_h * INTERVAL '1 hour'
    FROM (VALUES
        ('INC-0001','OPENED','Generator trip detected, backup power engaged','cmd.rizzo',0),
        ('INC-0001','ACKNOWLEDGED','Response team assigned','cmd.rizzo',1),
        ('INC-0001','STATUS_CHANGED','Diagnosis started: coil insulation failure suspected','cmd.rizzo',6),
        ('INC-0002','OPENED','Rover rollover reported by the rescue crew','cmd.romano',0),
        ('INC-0002','RESOLVED','Rover recovered, crew back at the outpost','cmd.romano',28),
        ('INC-0002','CLOSED','Corrective actions verified','cmd.romano',38),
        ('INC-0003','OPENED','Raised from CO2 alert','cmd.ferrari',0),
        ('INC-0004','OPENED','Reported from the stock threshold dashboard','log.marino',0),
        ('INC-0005','OPENED','Damage found during routine inspection','mnt.bianchi',0),
        ('INC-0005','RESOLVED','Rover moved to maintenance, work order opened','mnt.bianchi',76),
        ('INC-0006','CANCELLED','Duplicate of a test-flight log entry','sci.greco',2)
    ) AS v(incident_code, event_type, description, username, after_h)
    JOIN incident i ON i.code = v.incident_code
    JOIN user_account u ON u.username = v.username;

    INSERT INTO corrective_action(id_incident, description, assigned_to, due_at, completed_at, status)
    SELECT i.id_incident, v.description, cm.id_crew_member, t0 + v.due_days * INTERVAL '1 day',
           t0 + v.completed_days * INTERVAL '1 day', v.status
    FROM (VALUES
        ('INC-0001','Replace generator coil pack','CRW-014',5,NULL::int,'IN_PROGRESS'),
        ('INC-0002','Add slope stability check to rescue procedure','CRW-007',-195,-196,'DONE'),
        ('INC-0004','Ration water use to 60 % until resupply','CRW-012',2,NULL::int,'OPEN')
    ) AS v(incident_code, description, employee_code, due_days, completed_days, status)
    JOIN incident i ON i.code = v.incident_code
    JOIN crew_member cm ON cm.employee_code = v.employee_code;

    -- ------------------------------------------------------------------ maintenance (TITAN)
    INSERT INTO maintenance_work_order(code, id_asset, id_incident, maintenance_type, priority, status, description, opened_by,
                                       assigned_to, opened_at, scheduled_at, started_at, completed_at, resolution)
    SELECT v.code, a.id_asset, i.id_incident, v.maintenance_type, v.priority, v.status, v.description, u.id_account,
           cm.id_crew_member, t0 + v.opened_days * INTERVAL '1 day', t0 + v.scheduled_days * INTERVAL '1 day',
           t0 + v.started_days * INTERVAL '1 day', t0 + v.completed_days * INTERVAL '1 day', v.resolution
    FROM (VALUES
        ('WO-0001','GEN-ELY-01','INC-0001','EMERGENCY','CRITICAL','IN_PROGRESS','Diagnose and repair primary generator','cmd.rizzo','CRW-014',-2,-2,-2,NULL::int,NULL),
        ('WO-0002','ROV-ARS-03','INC-0005','CORRECTIVE','HIGH','PLANNED','Replace cracked suspension arm','mnt.bianchi','CRW-003',-1,6,NULL::int,NULL::int,NULL),
        ('WO-0003','ROV-ARS-01',NULL,'PREVENTIVE','MEDIUM','COMPLETED','500-hour service','mnt.bianchi','CRW-003',-50,-45,-45,-44,'Filters and seals replaced'),
        ('WO-0004','DRN-ELY-01',NULL,'CORRECTIVE','MEDIUM','BLOCKED','Replace rotor motor','cmd.rizzo','CRW-013',-15,-10,NULL::int,NULL::int,NULL),
        ('WO-0005','LSS-ELY-01',NULL,'INSPECTION','HIGH','OPEN','Inspect life support after power loss','cmd.rizzo',NULL,-1,1,NULL::int,NULL::int,NULL)
    ) AS v(code, asset_code, incident_code, maintenance_type, priority, status, description, opened_by,
           employee_code, opened_days, scheduled_days, started_days, completed_days, resolution)
    JOIN asset a ON a.code = v.asset_code
    LEFT JOIN incident i ON i.code = v.incident_code
    JOIN user_account u ON u.username = v.opened_by
    LEFT JOIN crew_member cm ON cm.employee_code = v.employee_code;

    INSERT INTO maintenance_action(id_work_order, id_crew_member, description, performed_at, duration_minutes)
    SELECT w.id_work_order, cm.id_crew_member, v.description, t0 + v.at_hours * INTERVAL '1 hour', v.minutes
    FROM (VALUES
        ('WO-0001','CRW-014','Isolated generator and ran insulation test',-40,180),
        ('WO-0003','CRW-003','Replaced air and coolant filters',-1070,120),
        ('WO-0003','CRW-003','Replaced door seals and tested pressure',-1060,90)
    ) AS v(wo_code, employee_code, description, at_hours, minutes)
    JOIN maintenance_work_order w ON w.code = v.wo_code
    JOIN crew_member cm ON cm.employee_code = v.employee_code;

    -- ------------------------------------------------------------------ audit trail (BR-012)
    INSERT INTO audit_event(id_account, action, entity_type, entity_id, old_value_json, new_value_json, reason, occurred_at)
    SELECT u.id_account, v.action, v.entity_type, v.entity_id, v.old_value::jsonb, v.new_value::jsonb, v.reason,
           t0 + v.at_hours * INTERVAL '1 hour'
    FROM (VALUES
        ('cmd.romano','INCIDENT_CLOSED','INCIDENT','INC-0002','{"status":"RESOLVED"}','{"status":"CLOSED"}','Corrective actions completed and verified',-190),
        ('cmd.ferrari','MISSION_STATUS_CHANGED','MISSION','PHX-002','{"status":"APPROVED"}','{"status":"IN_PROGRESS"}',NULL,-24),
        ('cmd.rizzo','ASSET_STATUS_CHANGED','ASSET','GEN-ELY-01','{"status":"IN_USE"}','{"status":"MAINTENANCE"}','Primary generator tripped',-48)
    ) AS v(username, action, entity_type, entity_id, old_value, new_value, reason, at_hours)
    JOIN user_account u ON u.username = v.username;
END
$demo$;

-- Demo login (ADR-0012): Argon2id hash of `Aether-demo-password`. Outside the guarded block so that it
-- also reaches demo databases loaded earlier with the no-login placeholder; it never touches other hashes.
UPDATE user_account
SET password_hash = '{argon2id}$argon2id$v=19$m=19456,t=2,p=1$t2iADnYZFJC69cNr65AcxA$h6C1eYJcnHleMu1ApggzcCq61zaNhqTgOD0+U3ea5Jk'
WHERE password_hash = 'DEMO-ACCOUNT-NO-LOGIN';
