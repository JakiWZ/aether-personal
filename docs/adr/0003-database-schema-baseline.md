# ADR-0003: Database schema baseline

- **Status:** Accepted
- **Date:** 2026-10-16
- **Issues:** #8 (TASK-002), #9 (TASK-003)

## Context and problem statement

The repository inherited **two incompatible schemas**:

1. `docs/database/04_AETHER_schema.sql` — Italian naming (`colonie`, `astronauti`, …), derived from
   `02_AETHER_Progettazione_Database.docx`. Its seed (`05_AETHER_seed.sql`) **does not load**
   against it (e.g. it inserts `unita_misura.simbolo`, a column that does not exist, and targets a
   schema `aether` that is never created).
2. `docs/database/AETHER_MASTER_DATABASE_POSTGRESQL.sql` — English naming, ~70 tables covering all
   ten functional domains, rich constraints (exclusion constraints against double booking, partial
   unique indexes, non-negative stock checks, separation of duties on approvals), audit and outbox
   tables. It loads cleanly on PostgreSQL 16.

We need exactly one schema that the backend, the seed data and the documentation agree on.

## Considered options

1. Fix the Italian schema and its seed.
2. Adopt the English master schema as the baseline.
3. Design a new schema from scratch.

## Decision

**Option 2.** The master schema becomes the baseline (Flyway `V1`), split into readable migrations.

- It already encodes most business rules from the capitolato in the database
  (BR-003 crew overlap, BR-005 asset availability, BR-007 non-negative stock, BR-008 one current
  sample location, BR-009 incident closure, BR-013 separation of duties).
- English identifiers match the Java/TypeScript code and the international audience of the project.
- The Italian design documents remain valuable as *conceptual* documentation (E-R reasoning,
  normalisation discussion) and are kept under `docs/database/design/`.

### Mapping of the course vocabulary

| Mission packs / backlog (IT) | Schema (EN) |
|------------------------------|-------------|
| Base / colonia | `colony` (+ `habitat`, `habitat_module`, `operational_area`) |
| Membro equipaggio / astronauta | `person` + `crew_member` |
| Veicolo / rover / mezzo | `asset` with `asset_type.category = 'VEHICLE'` |
| Intervento di manutenzione | `maintenance_work_order` |
| Risorsa / stock / soglia | `resource`, `inventory_stock`, `inventory_threshold` (per `inventory_location`) |
| Movimento / trasferimento | `inventory_movement` (ledger) |
| Incidente / responder / timeline | `incident`, `incident_assignee`, `incident_event` |

## Consequences

- The legacy Italian SQL files move to `docs/database/legacy/` with a note that they are superseded.
- Demo data must be rewritten for the English schema (TASK-004, #10).
- Gaps found while implementing stories (e.g. base membership history for ARES-104, immutability of
  `incident_event` for HEL-504) are handled with **new** migrations, each referencing its story.
