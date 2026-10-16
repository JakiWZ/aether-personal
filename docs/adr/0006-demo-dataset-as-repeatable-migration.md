# ADR-0006: Demo dataset as a profile-scoped repeatable migration

- **Status:** Accepted
- **Date:** 2026-10-16
- **Issue:** #10 (TASK-004)

## Context and problem statement

ADR-0004 puts demo data in a separate Flyway location (`db/demo`) that only local/demo
environments load. We still had to decide *how* that data is versioned. Flyway merges all
locations into one version sequence, so versioned demo files (`V…`) would collide with, or run
out of order against, the schema migrations that keep coming in `db/migration`.

## Considered options

1. Versioned demo migrations with a reserved high range (e.g. `V1000__…`).
2. **One repeatable migration** `db/demo/R__demo_dataset.sql`, guarded to run once per database.
3. A Spring `CommandLineRunner` / `data.sql` that inserts through JPA or JDBC at startup.

## Decision

Option 2.

- Repeatable migrations always run after every versioned one, so the demo data is applied on the
  latest schema and never blocks a new `V<n>` migration.
- The script is one `DO` block that returns early when the demo colonies already exist: a re-run
  (for example after an edit changes its checksum) never duplicates rows. Changing the demo data
  on an existing database means resetting it (`docker compose … down -v`).
- Timestamps are computed from the load time, so "in progress" or "upcoming" missions stay
  coherent whenever a demo database is created.
- Rows reference each other by business code, never by generated ids.
- Activation: Spring profile `demo` (`application-demo.yml` adds `classpath:db/demo` to
  `spring.flyway.locations`); profile `dev` includes `demo` through a profile group. The local
  Docker Compose `migrate` service loads it as well. Tests and real environments do not.
- Because a database seeded with `demo` and later opened without it would fail Flyway validation
  ("applied migration not resolved locally"), the base configuration sets
  `spring.flyway.ignore-migration-patterns: "*:future,repeatable:missing"`. Versioned migrations
  are still fully validated.

Option 1 forces `outOfOrder` or renumbering as soon as a schema migration is added. Option 3
duplicates what Flyway already does, couples the seed to entities that do not exist yet and runs
outside the migration history.

## Consequences

- CI loads the demo dataset on top of the schema twice (second run must be a no-op) and checks the
  issue #10 acceptance criteria; `DemoDatasetIT` checks them on Testcontainers together with the
  negative cases the database must reject.
- The dataset content and its built-in negative cases are documented in
  [`docs/database/demo-dataset.md`](../database/demo-dataset.md).
