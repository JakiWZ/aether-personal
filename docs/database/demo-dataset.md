# Demo dataset

Coherent sample data to develop and demonstrate AETHER (TASK-004, issue #10). Source:
[`backend/src/main/resources/db/demo/R__demo_dataset.sql`](../../backend/src/main/resources/db/demo/R__demo_dataset.sql).
How it is loaded and why: [ADR-0007](../adr/0007-demo-dataset-as-repeatable-migration.md).

## Load it

```bash
# local database: the compose `migrate` service loads schema + demo data
docker compose -f infrastructure/docker-compose.yml up -d
docker compose -f infrastructure/docker-compose.yml --profile tools run --rm migrate

# or let the backend do it on startup
cd backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

Tests and real environments never load it. Timestamps are relative to the load time (t0), so
the timeline below always reads "now". To reload after editing the script, reset the database
(`docker compose -f infrastructure/docker-compose.yml down -v`).

## What is in it

| Area | Content |
|------|---------|
| Bases | `ARS-01` Ares Prime (OPERATIONAL), `VLM-01` Valles Research Outpost (OPERATIONAL), `ELY-01` Elysium Relay (DEGRADED), `THR-01` Tharsis Forward Base (CONSTRUCTION); 5 habitats, 14 modules, 7 areas |
| Crew | 19 members `CRW-001`…`CRW-019` across all four bases; statuses ACTIVE, TRAINING, OFF_DUTY, MEDICAL_LEAVE, SUSPENDED, INACTIVE; 10 skills, 5 certifications |
| Users | 11 accounts covering every role (`admin.neri`, `mc.rossi`, `cmd.ferrari`, `log.marino`, …). All share the demo-only password `Aether-demo-password` (ADR-0012) |
| Missions | `PHX-001`…`PHX-010` covering all 8 states (DRAFT, PLANNED, APPROVAL_PENDING, APPROVED, IN_PROGRESS, COMPLETED, ABORTED, CANCELLED), with phases, tasks, crew/vehicle assignments, requirements, risks, approvals and status history |
| Fleet | 13 assets: rovers, drones and a shuttle plus generators, life support and an antenna; statuses AVAILABLE, IN_USE, MAINTENANCE, OUT_OF_SERVICE, DECOMMISSIONED |
| Logistics | 7 resources, 6 locations, 3 lots, 19 stock rows backed by the movement ledger, thresholds, 4 shipments (PLANNED, IN_TRANSIT, DELAYED, RECEIVED) |
| Safety | 6 incidents (OPEN … CLOSED, one CRITICAL in progress), corrective actions, 5 work orders, sensors with a CO2 alert, audit events |

## Timeline (relative to t0)

| Mission | State | Window | Crew / vehicles |
|---------|-------|--------|-----------------|
| PHX-001 | COMPLETED | t0−30d → t0−27d | released |
| PHX-002 | IN_PROGRESS | t0−1d → t0+2d | CRW-002 (cmd), CRW-003, CRW-005 · ROV-ARS-01 |
| PHX-003 | APPROVED | t0+5d → t0+9d | CRW-007 (cmd), CRW-008, CRW-010 · ROV-VLM-01, DRN-VLM-01 |
| PHX-004 | APPROVAL_PENDING | t0+12d → t0+15d | CRW-001 (cmd), CRW-006 · ROV-ARS-02 |
| PHX-005 | PLANNED | t0+20d → t0+22d | CRW-012 (cmd), CRW-014 |
| PHX-006 | DRAFT | t0+30d → t0+35d | none |
| PHX-007 | ABORTED | t0−10d → t0−8d | released, see INC-0002 |
| PHX-008 | CANCELLED | t0−5d → t0−4d | cancelled |
| PHX-009 | DRAFT | t0+6d → t0+8d (overlaps PHX-003) | none |
| PHX-010 | PLANNED | t0+3d → t0+4d (needs EVA certification) | none |

## Built-in cases for negative tests and demos

| Case | Data | Expected outcome |
|------|------|------------------|
| Crew double booking (BR-003) | assign `CRW-008` to `PHX-009` | rejected, `ex_crew_no_overlapping_missions` |
| Vehicle double booking (BR-005) | assign `ROV-VLM-01` to `PHX-009` | rejected, `ex_asset_no_overlapping_missions` |
| Vehicle under maintenance (invariant B) | assign `ROV-ARS-03` (MAINTENANCE) or `DRN-ELY-01` (OUT_OF_SERVICE) | rejected by the service |
| Crew not available (invariant A) | assign `CRW-016` (MEDICAL_LEAVE), `CRW-017` (SUSPENDED) or `CRW-009` (on leave during PHX-003) | rejected by the service |
| Expired certification | `CRW-013` EVA_SUIT expired; `CRW-002` rover licence expires in 10 days | not eligible for `PHX-010` / buffer checks |
| Expired medical clearance | `CRW-004` clearance expired 10 days ago | not eligible |
| Second commander (PHX-204) | add another commander to `PHX-002` | rejected, `uq_one_commander_per_mission` |
| Negative stock (BR-007) | consume 1 `MED_KIT` from `ELY-01/EMERG-01` (quantity 0) | rejected, `ck_inventory_quantity_nonnegative` |
| Low stock | `VLM-01` AIR_FILTER, `ELY-01` WATER and OXYGEN below thresholds | show up in threshold queries |
| Expired lot | `FOOD_RATION` lot `FR-X-07` at `ELY-01` | must not be allocated |
| Duplicate codes (ARES-103, PHX-201) | reuse `CRW-001`, `PHX-001`, `ARS-01` | rejected, unique constraint |
| Self-approval (BR-013) | `mc.rossi` deciding a request of `mc.rossi` (e.g. PHX-004) | rejected, `ck_approval_separation` |
| Closing an incident without data (BR-009) | close `INC-0001` (CRITICAL) without reason | rejected, `ck_incident_close_required` |
| Disabled account | `sci.dubois` is DISABLED | cannot act |

`DemoDatasetIT` checks the acceptance criteria of issue #10 and the database-enforced cases above.
