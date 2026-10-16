# ADR-0004: Schema migrations with Flyway

- **Status:** Accepted
- **Date:** 2026-10-16
- **Issue:** #9 (TASK-003)

## Context and problem statement

The capitolato requires that "the data schema can be created from scratch through versioned
migrations/scripts" (§17) and the Sprint 3 quality gate forbids "manual changes to the DB to run
the demo". Until now the schema existed only as hand-run SQL files, one of which did not even load.

## Considered options

1. Hand-run SQL scripts with a README.
2. **Flyway** with plain SQL versioned migrations.
3. Liquibase (XML/YAML changelogs).
4. Hibernate `ddl-auto=update`.

## Decision

**Flyway**, with migrations in `backend/src/main/resources/db/migration`.

- Plain SQL keeps the full power of PostgreSQL (exclusion constraints, partial indexes) and is
  readable by anyone who knows SQL; Liquibase's abstraction brings no benefit for a single RDBMS.
- Spring Boot runs Flyway automatically on startup, so every environment converges to the same
  schema; Hibernate is set to `ddl-auto=validate`, never `update`.
- Naming: `V<n>__<verb>_<object>.sql` (e.g. `V15__add_incident_event_immutability.sql`).
- **Merged migrations are immutable.** Fixes are new migrations; Flyway checksum validation in CI
  catches accidental edits.
- All objects live in the `aether` schema (`spring.flyway.schemas=aether`).
- Reference data that every environment needs (roles, permissions, units) is a versioned migration.
  Demo data goes to a separate location (`db/demo`) enabled only for local/demo profiles.

The initial baseline `V1`–`V14` is the master schema (ADR-0003) split by domain, so each file can
be reviewed on its own. A `pg_dump --schema-only` comparison confirmed the result is identical to
the original single script.

## Consequences

- CI job `Database migrations` applies all migrations to an empty PostgreSQL 16, validates
  checksums, re-runs `migrate` to prove idempotency and smoke-checks the reference data.
- Rolling back means writing a forward migration; Flyway Community has no `undo`, which is the
  safer default for production databases anyway.
