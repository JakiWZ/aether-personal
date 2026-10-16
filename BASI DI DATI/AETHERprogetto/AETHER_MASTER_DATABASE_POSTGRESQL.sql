-- ============================================================================
-- AETHER – MARS OPERATIONS PLATFORM
-- MASTER DATABASE SCHEMA / TEACHER REFERENCE
-- Target DBMS: PostgreSQL 16+
-- ============================================================================

BEGIN;
CREATE SCHEMA IF NOT EXISTS aether;
SET search_path TO aether, public;
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- 00. COMMON / REFERENCE -----------------------------------------------------
CREATE TABLE unit_of_measure (
    id_unit BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(20) NOT NULL,
    quantity_type VARCHAR(40) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_uom_quantity_type CHECK (quantity_type IN (
        'MASS','VOLUME','COUNT','ENERGY','LENGTH','TIME','PRESSURE',
        'TEMPERATURE','PERCENTAGE','CONCENTRATION','OTHER'))
);

-- 01. COLONY / HABITAT / PHYSICAL STRUCTURE ---------------------------------
CREATE TABLE colony (
    id_colony BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'PLANNED',
    latitude NUMERIC(9,6),
    longitude NUMERIC(9,6),
    established_at DATE,
    max_population INTEGER,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT ck_colony_status CHECK (status IN (
        'PLANNED','CONSTRUCTION','OPERATIONAL','DEGRADED','EMERGENCY','INACTIVE')),
    CONSTRAINT ck_colony_lat CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT ck_colony_lon CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_colony_population CHECK (max_population IS NULL OR max_population > 0)
);

CREATE TABLE habitat (
    id_habitat BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_colony BIGINT NOT NULL REFERENCES colony(id_colony),
    code VARCHAR(30) NOT NULL,
    name VARCHAR(150) NOT NULL,
    habitat_type VARCHAR(40) NOT NULL,
    max_capacity INTEGER NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'OPERATIONAL',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_habitat_code UNIQUE (id_colony, code),
    CONSTRAINT ck_habitat_capacity CHECK (max_capacity > 0),
    CONSTRAINT ck_habitat_status CHECK (status IN (
        'PLANNED','OPERATIONAL','DEGRADED','MAINTENANCE','EMERGENCY','INACTIVE'))
);

CREATE TABLE habitat_module (
    id_module BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_habitat BIGINT NOT NULL REFERENCES habitat(id_habitat),
    code VARCHAR(30) NOT NULL,
    name VARCHAR(150) NOT NULL,
    module_type VARCHAR(40) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'OPERATIONAL',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_module_code UNIQUE (id_habitat, code),
    CONSTRAINT ck_module_type CHECK (module_type IN (
        'RESIDENTIAL','COMMAND','MEDICAL','LABORATORY','STORAGE','LIFE_SUPPORT',
        'POWER','COMMUNICATION','WORKSHOP','AIRLOCK','GREENHOUSE','OTHER')),
    CONSTRAINT ck_module_status CHECK (status IN (
        'PLANNED','OPERATIONAL','DEGRADED','MAINTENANCE','EMERGENCY','INACTIVE'))
);

CREATE TABLE operational_area (
    id_area BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_module BIGINT NOT NULL REFERENCES habitat_module(id_module),
    parent_area_id BIGINT REFERENCES operational_area(id_area),
    code VARCHAR(40) NOT NULL,
    name VARCHAR(150) NOT NULL,
    area_type VARCHAR(50) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'OPERATIONAL',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_area_code UNIQUE (id_module, code),
    CONSTRAINT ck_area_status CHECK (status IN (
        'OPERATIONAL','RESTRICTED','MAINTENANCE','EMERGENCY','INACTIVE')),
    CONSTRAINT ck_area_not_self_parent CHECK (parent_area_id IS NULL OR parent_area_id <> id_area)
);

-- 02. IDENTITY / SECURITY / CREW --------------------------------------------
CREATE TABLE person (
    id_person BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(80),
    email VARCHAR(200),
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT uq_person_email UNIQUE (email),
    CONSTRAINT ck_person_status CHECK (status IN ('ACTIVE','INACTIVE','SUSPENDED','DECEASED'))
);

CREATE TABLE user_account (
    id_account BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_person BIGINT NOT NULL UNIQUE REFERENCES person(id_person),
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    account_status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    failed_login_count INTEGER NOT NULL DEFAULT 0,
    locked_until TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    password_changed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    disabled_at TIMESTAMPTZ,
    CONSTRAINT ck_account_status CHECK (account_status IN ('ACTIVE','LOCKED','DISABLED','PENDING')),
    CONSTRAINT ck_failed_login_count CHECK (failed_login_count >= 0)
);

CREATE TABLE app_role (
    id_role BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(60) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    description TEXT,
    system_role BOOLEAN NOT NULL DEFAULT TRUE,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE permission (
    id_permission BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NOT NULL
);

CREATE TABLE role_permission (
    id_role BIGINT NOT NULL REFERENCES app_role(id_role),
    id_permission BIGINT NOT NULL REFERENCES permission(id_permission),
    PRIMARY KEY (id_role, id_permission)
);

CREATE TABLE user_role (
    id_account BIGINT NOT NULL REFERENCES user_account(id_account),
    id_role BIGINT NOT NULL REFERENCES app_role(id_role),
    assigned_by BIGINT REFERENCES user_account(id_account),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at TIMESTAMPTZ,
    PRIMARY KEY (id_account, id_role)
);

CREATE TABLE crew_member (
    id_crew_member BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_person BIGINT NOT NULL UNIQUE REFERENCES person(id_person),
    employee_code VARCHAR(40) NOT NULL UNIQUE,
    id_home_colony BIGINT REFERENCES colony(id_colony),
    operational_role VARCHAR(80) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    hire_date DATE,
    medical_clearance_until DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_crew_status CHECK (status IN (
        'ACTIVE','OFF_DUTY','TRAINING','MEDICAL_LEAVE','SUSPENDED','INACTIVE'))
);

CREATE TABLE skill (
    id_skill BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(60) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    category VARCHAR(80),
    description TEXT,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE crew_skill (
    id_crew_member BIGINT NOT NULL REFERENCES crew_member(id_crew_member),
    id_skill BIGINT NOT NULL REFERENCES skill(id_skill),
    proficiency_level SMALLINT NOT NULL,
    acquired_at DATE,
    last_verified_at DATE,
    notes TEXT,
    PRIMARY KEY (id_crew_member, id_skill),
    CONSTRAINT ck_skill_level CHECK (proficiency_level BETWEEN 1 AND 5)
);

CREATE TABLE certification (
    id_certification BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(60) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    default_validity_months INTEGER,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_cert_validity CHECK (default_validity_months IS NULL OR default_validity_months > 0)
);

CREATE TABLE crew_certification (
    id_crew_certification BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_crew_member BIGINT NOT NULL REFERENCES crew_member(id_crew_member),
    id_certification BIGINT NOT NULL REFERENCES certification(id_certification),
    certificate_number VARCHAR(100),
    issuing_authority VARCHAR(180) NOT NULL,
    issued_at DATE NOT NULL,
    expires_at DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'VALID',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_crew_cert_number UNIQUE (id_certification, certificate_number),
    CONSTRAINT ck_crew_cert_dates CHECK (expires_at IS NULL OR expires_at >= issued_at),
    CONSTRAINT ck_crew_cert_status CHECK (status IN ('VALID','EXPIRED','SUSPENDED','REVOKED'))
);

CREATE TABLE crew_availability (
    id_availability BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_crew_member BIGINT NOT NULL REFERENCES crew_member(id_crew_member),
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    availability_type VARCHAR(30) NOT NULL,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_availability_dates CHECK (end_at > start_at),
    CONSTRAINT ck_availability_type CHECK (availability_type IN (
        'AVAILABLE','UNAVAILABLE','LEAVE','MEDICAL','TRAINING','RESERVED'))
);

CREATE TABLE crew_shift (
    id_shift BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_crew_member BIGINT NOT NULL REFERENCES crew_member(id_crew_member),
    id_colony BIGINT NOT NULL REFERENCES colony(id_colony),
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    shift_type VARCHAR(40) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PLANNED',
    CONSTRAINT ck_shift_dates CHECK (end_at > start_at),
    CONSTRAINT ck_shift_status CHECK (status IN ('PLANNED','CONFIRMED','COMPLETED','CANCELLED'))
);

ALTER TABLE crew_shift ADD CONSTRAINT ex_crew_shift_no_overlap
EXCLUDE USING gist (
    id_crew_member WITH =,
    tstzrange(start_at, end_at, '[)') WITH &&
) WHERE (status IN ('PLANNED','CONFIRMED'));

-- 03. RESOURCE / LOGISTICS ---------------------------------------------------
CREATE TABLE resource (
    id_resource BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(60) NOT NULL,
    id_unit BIGINT NOT NULL REFERENCES unit_of_measure(id_unit),
    critical BOOLEAN NOT NULL DEFAULT FALSE,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    shelf_life_days INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_resource_shelf_life CHECK (shelf_life_days IS NULL OR shelf_life_days > 0)
);

CREATE TABLE inventory_location (
    id_location BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_colony BIGINT NOT NULL REFERENCES colony(id_colony),
    id_area BIGINT REFERENCES operational_area(id_area),
    code VARCHAR(50) NOT NULL,
    name VARCHAR(150) NOT NULL,
    location_type VARCHAR(40) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_inventory_location UNIQUE (id_colony, code),
    CONSTRAINT ck_inventory_location_type CHECK (location_type IN (
        'WAREHOUSE','LAB_STORAGE','COLD_STORAGE','VEHICLE_STORAGE',
        'MISSION_CACHE','EMERGENCY_STORAGE','OTHER'))
);

CREATE TABLE resource_lot (
    id_lot BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_resource BIGINT NOT NULL REFERENCES resource(id_resource),
    lot_code VARCHAR(100) NOT NULL,
    production_date DATE,
    expiration_date DATE,
    received_at TIMESTAMPTZ,
    supplier VARCHAR(180),
    status VARCHAR(30) NOT NULL DEFAULT 'AVAILABLE',
    CONSTRAINT uq_resource_lot UNIQUE (id_resource, lot_code),
    CONSTRAINT ck_lot_dates CHECK (expiration_date IS NULL OR production_date IS NULL OR expiration_date >= production_date),
    CONSTRAINT ck_lot_status CHECK (status IN ('AVAILABLE','QUARANTINED','EXPIRED','DEPLETED','RECALLED'))
);

CREATE TABLE inventory_stock (
    id_inventory_stock BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_location BIGINT NOT NULL REFERENCES inventory_location(id_location),
    id_resource BIGINT NOT NULL REFERENCES resource(id_resource),
    id_lot BIGINT REFERENCES resource_lot(id_lot),
    quantity NUMERIC(18,6) NOT NULL DEFAULT 0,
    version_no BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_inventory_quantity_nonnegative CHECK (quantity >= 0)
);
CREATE UNIQUE INDEX uq_stock_with_lot ON inventory_stock(id_location, id_resource, id_lot) WHERE id_lot IS NOT NULL;
CREATE UNIQUE INDEX uq_stock_without_lot ON inventory_stock(id_location, id_resource) WHERE id_lot IS NULL;

CREATE TABLE inventory_threshold (
    id_threshold BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_location BIGINT NOT NULL REFERENCES inventory_location(id_location),
    id_resource BIGINT NOT NULL REFERENCES resource(id_resource),
    minimum_quantity NUMERIC(18,6) NOT NULL,
    warning_quantity NUMERIC(18,6),
    critical_quantity NUMERIC(18,6),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT uq_inventory_threshold UNIQUE (id_location, id_resource),
    CONSTRAINT ck_threshold_min CHECK (minimum_quantity >= 0),
    CONSTRAINT ck_threshold_warning CHECK (warning_quantity IS NULL OR warning_quantity >= 0),
    CONSTRAINT ck_threshold_critical CHECK (critical_quantity IS NULL OR critical_quantity >= 0)
);

CREATE TABLE shipment (
    id_shipment BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(60) NOT NULL UNIQUE,
    origin_name VARCHAR(180) NOT NULL,
    id_destination_colony BIGINT NOT NULL REFERENCES colony(id_colony),
    shipment_type VARCHAR(40) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PLANNED',
    departure_at TIMESTAMPTZ,
    estimated_arrival_at TIMESTAMPTZ,
    actual_arrival_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_shipment_type CHECK (shipment_type IN ('EARTH_CARGO','INTER_COLONY','EMERGENCY','RETURN')),
    CONSTRAINT ck_shipment_status CHECK (status IN (
        'PLANNED','IN_TRANSIT','PARTIALLY_RECEIVED','RECEIVED','DELAYED','CANCELLED')),
    CONSTRAINT ck_shipment_dates CHECK (estimated_arrival_at IS NULL OR departure_at IS NULL OR estimated_arrival_at >= departure_at)
);

CREATE TABLE shipment_item (
    id_shipment_item BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_shipment BIGINT NOT NULL REFERENCES shipment(id_shipment),
    id_resource BIGINT NOT NULL REFERENCES resource(id_resource),
    expected_quantity NUMERIC(18,6) NOT NULL,
    received_quantity NUMERIC(18,6) NOT NULL DEFAULT 0,
    notes TEXT,
    CONSTRAINT uq_shipment_resource UNIQUE (id_shipment, id_resource),
    CONSTRAINT ck_shipment_item_expected CHECK (expected_quantity > 0),
    CONSTRAINT ck_shipment_item_received CHECK (received_quantity >= 0)
);

-- 04. ASSETS / FLEET ---------------------------------------------------------
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

-- 05. MISSIONS ----------------------------------------------------------------
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

-- 06. INVENTORY MOVEMENT LEDGER ---------------------------------------------
CREATE TABLE inventory_movement (
    id_movement BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_resource BIGINT NOT NULL REFERENCES resource(id_resource),
    id_lot BIGINT REFERENCES resource_lot(id_lot),
    from_location_id BIGINT REFERENCES inventory_location(id_location),
    to_location_id BIGINT REFERENCES inventory_location(id_location),
    movement_type VARCHAR(40) NOT NULL,
    quantity NUMERIC(18,6) NOT NULL,
    id_mission BIGINT REFERENCES mission(id_mission),
    id_shipment_item BIGINT REFERENCES shipment_item(id_shipment_item),
    created_by BIGINT NOT NULL REFERENCES user_account(id_account),
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    reason TEXT,
    correlation_id UUID,
    CONSTRAINT ck_inventory_movement_qty CHECK (quantity > 0),
    CONSTRAINT ck_inventory_movement_type CHECK (movement_type IN (
        'RECEIPT','CONSUMPTION','TRANSFER','ADJUSTMENT','MISSION_ALLOCATION','MISSION_RETURN','DISPOSAL')),
    CONSTRAINT ck_inventory_locations CHECK (from_location_id IS NOT NULL OR to_location_id IS NOT NULL),
    CONSTRAINT ck_inventory_different_locations CHECK (
        from_location_id IS NULL OR to_location_id IS NULL OR from_location_id <> to_location_id)
);

-- 07. SCIENCE / LABS / SAMPLES ----------------------------------------------
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

-- 08. TELEMETRY / ALERTS -----------------------------------------------------
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

-- 09. INCIDENT MANAGEMENT ----------------------------------------------------
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

-- 10. MAINTENANCE ------------------------------------------------------------
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

-- 11. COMMUNICATION / NOTIFICATIONS -----------------------------------------
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

-- 12. AUDIT / OUTBOX ---------------------------------------------------------
CREATE TABLE audit_event (
    id_audit BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_account BIGINT REFERENCES user_account(id_account),
    action VARCHAR(80) NOT NULL,
    entity_type VARCHAR(80) NOT NULL,
    entity_id VARCHAR(120) NOT NULL,
    old_value_json JSONB,
    new_value_json JSONB,
    reason TEXT,
    ip_address INET,
    correlation_id UUID,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE outbox_event (
    id_event UUID PRIMARY KEY,
    aggregate_type VARCHAR(80) NOT NULL,
    aggregate_id VARCHAR(120) NOT NULL,
    event_type VARCHAR(120) NOT NULL,
    payload JSONB NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    published_at TIMESTAMPTZ,
    retry_count INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    CONSTRAINT ck_outbox_retry CHECK (retry_count >= 0)
);

-- 13. INDEXES ----------------------------------------------------------------
CREATE INDEX ix_habitat_colony ON habitat(id_colony);
CREATE INDEX ix_module_habitat ON habitat_module(id_habitat);
CREATE INDEX ix_area_module ON operational_area(id_module);
CREATE INDEX ix_person_name ON person(last_name, first_name);
CREATE INDEX ix_crew_home_colony ON crew_member(id_home_colony);
CREATE INDEX ix_crew_status ON crew_member(status);
CREATE INDEX ix_crew_skill_skill ON crew_skill(id_skill);
CREATE INDEX ix_crew_cert_crew_exp ON crew_certification(id_crew_member, expires_at);
CREATE INDEX ix_availability_crew_dates ON crew_availability(id_crew_member, start_at, end_at);
CREATE INDEX ix_shift_colony_dates ON crew_shift(id_colony, start_at, end_at);
CREATE INDEX ix_resource_category ON resource(category);
CREATE INDEX ix_inventory_stock_resource ON inventory_stock(id_resource);
CREATE INDEX ix_inventory_stock_location ON inventory_stock(id_location);
CREATE INDEX ix_inventory_threshold_resource ON inventory_threshold(id_resource);
CREATE INDEX ix_resource_lot_expiration ON resource_lot(expiration_date);
CREATE INDEX ix_shipment_destination_status ON shipment(id_destination_colony, status);
CREATE INDEX ix_shipment_item_shipment ON shipment_item(id_shipment);
CREATE INDEX ix_asset_colony_status ON asset(id_colony, status);
CREATE INDEX ix_asset_type ON asset(id_asset_type);
CREATE INDEX ix_asset_area ON asset(id_area);
CREATE INDEX ix_asset_history_asset_date ON asset_status_history(id_asset, changed_at DESC);
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
CREATE INDEX ix_inventory_movement_resource_date ON inventory_movement(id_resource, occurred_at DESC);
CREATE INDEX ix_inventory_movement_from_date ON inventory_movement(from_location_id, occurred_at DESC);
CREATE INDEX ix_inventory_movement_to_date ON inventory_movement(to_location_id, occurred_at DESC);
CREATE INDEX ix_inventory_movement_mission ON inventory_movement(id_mission);
CREATE INDEX ix_experiment_lab_status ON experiment(id_laboratory, status);
CREATE INDEX ix_experiment_mission ON experiment(id_mission);
CREATE INDEX ix_sample_experiment ON sample(id_experiment);
CREATE INDEX ix_sample_mission ON sample(id_mission);
CREATE INDEX ix_sample_location_history ON sample_location_history(id_sample, valid_from DESC);
CREATE INDEX ix_experiment_result_exp_date ON experiment_result(id_experiment, recorded_at DESC);
CREATE INDEX ix_sensor_colony_status ON sensor(id_colony, status);
CREATE INDEX ix_sensor_type ON sensor(id_sensor_type);
CREATE INDEX ix_measurement_sensor_time ON telemetry_measurement(id_sensor, measured_at DESC);
CREATE INDEX ix_measurement_time ON telemetry_measurement(measured_at DESC);
CREATE INDEX ix_alert_status_severity ON alert(status, severity, triggered_at DESC);
CREATE INDEX ix_incident_colony_status ON incident(id_colony, status);
CREATE INDEX ix_incident_severity_status ON incident(severity, status);
CREATE INDEX ix_incident_asset ON incident(id_asset);
CREATE INDEX ix_incident_mission ON incident(id_mission);
CREATE INDEX ix_incident_event_timeline ON incident_event(id_incident, created_at);
CREATE INDEX ix_corrective_incident ON corrective_action(id_incident, status);
CREATE INDEX ix_maintenance_asset_status ON maintenance_work_order(id_asset, status);
CREATE INDEX ix_maintenance_assignee ON maintenance_work_order(assigned_to, status);
CREATE INDEX ix_notification_account_status ON notification(id_account, status, created_at DESC);
CREATE INDEX ix_audit_entity ON audit_event(entity_type, entity_id, occurred_at DESC);
CREATE INDEX ix_audit_account_date ON audit_event(id_account, occurred_at DESC);
CREATE INDEX ix_outbox_unpublished ON outbox_event(occurred_at) WHERE published_at IS NULL;

-- 14. SEED DATA --------------------------------------------------------------
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

COMMIT;

-- ============================================================================
-- CRITICAL APPLICATION-LEVEL INVARIANTS
-- ============================================================================
-- A. Crew assignment: ACTIVE, available, no overlap, valid skills/certifications.
-- B. Asset assignment: AVAILABLE, not MAINTENANCE/OUT_OF_SERVICE, no overlap.
-- C. Mission approval validates crew/assets/resources/certifications/approvals.
-- D. Inventory update is one ACID transaction:
--    lock/read stock -> verify -> insert movement -> update stock -> commit/rollback.
-- E. Receiving a multi-item shipment is one atomic transaction.
-- F. Closing CRITICAL incidents requires authorization, reason and audit event.
-- G. Historical records are not physically deleted by normal user workflows.
-- H. Alert closure never deletes telemetry.
-- I. AUDIT_EVENT is append-only from the application point of view.
-- J. TELEMETRY_MEASUREMENT can later move to a dedicated time-series/Big Data store;
--    PostgreSQL remains source of truth for sensors, alerts and transactional data.
-- ============================================================================
