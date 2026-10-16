-- Inventory movement ledger: every stock change derives from a movement (BR-006).
-- Source: docs/database/legacy/AETHER_MASTER_DATABASE_POSTGRESQL.sql (baseline, see ADR-0003).

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

-- Indexes supporting the main lookups of this domain.
CREATE INDEX ix_inventory_movement_resource_date ON inventory_movement(id_resource, occurred_at DESC);
CREATE INDEX ix_inventory_movement_from_date ON inventory_movement(from_location_id, occurred_at DESC);
CREATE INDEX ix_inventory_movement_to_date ON inventory_movement(to_location_id, occurred_at DESC);
CREATE INDEX ix_inventory_movement_mission ON inventory_movement(id_mission);
