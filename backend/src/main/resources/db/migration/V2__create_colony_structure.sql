-- Reference data types and the physical structure of colonies (COL-001, COL-002).
-- Source: docs/database/legacy/AETHER_MASTER_DATABASE_POSTGRESQL.sql (baseline, see ADR-0003).

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

-- Indexes supporting the main lookups of this domain.
CREATE INDEX ix_habitat_colony ON habitat(id_colony);
CREATE INDEX ix_module_habitat ON habitat_module(id_habitat);
CREATE INDEX ix_area_module ON operational_area(id_module);
