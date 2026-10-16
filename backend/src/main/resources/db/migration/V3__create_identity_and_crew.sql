-- People, accounts, RBAC and crew: skills, certifications, availability, shifts (IAM-*, CRW-*).
-- Source: docs/database/legacy/AETHER_MASTER_DATABASE_POSTGRESQL.sql (baseline, see ADR-0003).

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

-- Indexes supporting the main lookups of this domain.
CREATE INDEX ix_person_name ON person(last_name, first_name);
CREATE INDEX ix_crew_home_colony ON crew_member(id_home_colony);
CREATE INDEX ix_crew_status ON crew_member(status);
CREATE INDEX ix_crew_skill_skill ON crew_skill(id_skill);
CREATE INDEX ix_crew_cert_crew_exp ON crew_certification(id_crew_member, expires_at);
CREATE INDEX ix_availability_crew_dates ON crew_availability(id_crew_member, start_at, end_at);
CREATE INDEX ix_shift_colony_dates ON crew_shift(id_colony, start_at, end_at);
