# Database

PostgreSQL 16, schema `aether`, managed by Flyway (see [ADR-0003](../adr/0003-database-schema-baseline.md)
and [ADR-0004](../adr/0004-schema-migrations-with-flyway.md)).

## Where things are

| Path | Content |
|------|---------|
| `backend/src/main/resources/db/migration/` | **Source of truth.** Versioned Flyway migrations. |
| `backend/src/main/resources/db/demo/` | Demo dataset, loaded only for `dev`/`demo` and the local `migrate` service. See [demo-dataset.md](demo-dataset.md). |
| [`er-model.md`](er-model.md) | **Conceptual E-R model v1**: entities, cardinalities and their rationale, as Mermaid diagrams. |
| `docs/database/design/` | Conceptual design documents (E-R reasoning, normalisation) and table sketches. |
| `docs/database/legacy/` | Superseded scripts kept for reference. Do not use them to build a database. |

## Run it locally

```bash
# start PostgreSQL 16 (defaults: db/user/password = aether, port 5432)
docker compose -f infrastructure/docker-compose.yml up -d

# apply migrations and the demo dataset without starting the backend
docker compose -f infrastructure/docker-compose.yml --profile tools run --rm migrate

# connect
docker compose -f infrastructure/docker-compose.yml exec postgres psql -U aether -d aether -c '\dt aether.*'
```

Reset everything: `docker compose -f infrastructure/docker-compose.yml down -v`.

## Migration map

| Version | Domain | Main tables |
|---------|--------|-------------|
| V1 | Extensions | `btree_gist` (needed by exclusion constraints) |
| V2 | Colonies (ARES) | `unit_of_measure`, `colony`, `habitat`, `habitat_module`, `operational_area` |
| V3 | Identity & crew (ARES) | `person`, `user_account`, `app_role`, `permission`, `crew_member`, `skill`, `certification`, `crew_availability`, `crew_shift` |
| V4 | Logistics (ORION) | `resource`, `inventory_location`, `resource_lot`, `inventory_stock`, `inventory_threshold`, `shipment` |
| V5 | Assets & fleet (TITAN) | `asset_type`, `asset`, `asset_status_history` |
| V6 | Missions (PHOENIX) | `mission`, `mission_phase`, `mission_task`, `mission_crew_assignment`, `mission_asset_assignment`, requirements, approvals, history |
| V7 | Inventory ledger (ORION) | `inventory_movement` |
| V8 | Science | `laboratory`, `experiment`, `sample`, `sample_location_history`, `experiment_result` |
| V9 | Telemetry | `sensor_type`, `sensor`, `threshold_rule`, `telemetry_measurement`, `alert` |
| V10 | Incidents (HELIOS) | `incident`, `incident_assignee`, `incident_event`, `corrective_action` |
| V11 | Maintenance (TITAN) | `maintenance_work_order`, `maintenance_action` |
| V12 | Notifications | `notification`, `notification_preference` |
| V13 | Audit | `audit_event`, `outbox_event` |
| V14 | Reference data | 8 roles, 22 permissions, role-permission matrix, 14 units of measure |
| R (demo) | Demo dataset | 4 bases, 19 crew, 10 missions in every state, fleet, stock, incidents ([details](demo-dataset.md)) |

## Business rules enforced by the database

| Rule | Mechanism |
|------|-----------|
| BR-003 no overlapping crew assignments | `ex_crew_no_overlapping_missions` (GiST exclusion on `tstzrange`) |
| BR-005 no double-booked assets | `ex_asset_no_overlapping_missions` |
| PHX-204 one commander per mission | partial unique index `uq_one_commander_per_mission` |
| BR-007 stock never negative | `ck_inventory_quantity_nonnegative` |
| ORI-402 one stock row per location/resource | partial unique indexes `uq_stock_with_lot` / `uq_stock_without_lot` |
| BR-008 one current sample location | partial unique index `uq_sample_current_location` |
| BR-009 critical closure data | `ck_incident_close_required` |
| BR-013 separation of duties | `ck_approval_separation` |

The service layer checks the same rules first to return friendly errors; the constraints are the
last line of defence against races and direct writes.

## Application-level invariants (not expressible as constraints)

Kept from the original master script:

- **A.** Crew assignment: member ACTIVE, available, no overlap, valid skills/certifications.
- **B.** Asset assignment: AVAILABLE, not MAINTENANCE/OUT_OF_SERVICE, no overlap.
- **C.** Mission approval validates crew/assets/resources/certifications/approvals.
- **D.** Inventory update is one ACID transaction: lock/read stock → verify → insert movement → update stock → commit/rollback.
- **E.** Receiving a multi-item shipment is one atomic transaction.
- **F.** Closing CRITICAL incidents requires authorisation, reason and an audit event.
- **G.** Historical records are not physically deleted by normal user workflows.
- **H.** Closing an alert never deletes telemetry.
- **I.** `audit_event` is append-only from the application's point of view.
- **J.** `telemetry_measurement` may later move to a time-series/Big Data store; PostgreSQL remains
  the source of truth for sensors, alerts and transactional data.
