-- Resource catalogue, locations, lots, stock, thresholds and shipments (LOG-001..LOG-008).
-- Source: docs/database/legacy/AETHER_MASTER_DATABASE_POSTGRESQL.sql (baseline, see ADR-0003).

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

-- Indexes supporting the main lookups of this domain.
CREATE INDEX ix_resource_category ON resource(category);
CREATE INDEX ix_inventory_stock_resource ON inventory_stock(id_resource);
CREATE INDEX ix_inventory_stock_location ON inventory_stock(id_location);
CREATE INDEX ix_inventory_threshold_resource ON inventory_threshold(id_resource);
CREATE INDEX ix_resource_lot_expiration ON resource_lot(expiration_date);
CREATE INDEX ix_shipment_destination_status ON shipment(id_destination_colony, status);
CREATE INDEX ix_shipment_item_shipment ON shipment_item(id_shipment);
