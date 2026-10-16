# Legacy SQL (superseded)

These scripts predate the Flyway migrations and are kept only for historical reference.
**Do not use them to build a database** — use `backend/src/main/resources/db/migration/`.

| File | Status |
|------|--------|
| `AETHER_MASTER_DATABASE_POSTGRESQL.sql` | Original master schema. Split into Flyway `V1`–`V14` (identical result, verified with `pg_dump`). |
| `04_AETHER_schema.sql` | Italian-named schema. Superseded by ADR-0003. |
| `05_AETHER_seed.sql` | Seed for `04`; fails on load (`unita_misura.simbolo` does not exist, schema `aether` never created). |
| `06_AETHER_query.sql` | Example queries against `04`; to be rewritten for the current schema in INT-603 (#52). |
