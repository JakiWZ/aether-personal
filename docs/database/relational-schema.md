# Relational schema v1 and normalisation

Logical schema derived from the conceptual E-R model (TASK-002, #8). It explains **how** the
entities became tables: keys, data types, `NOT NULL`/`UNIQUE` choices, and a normal-form review
that names every place where the schema deliberately or accidentally departs from 3NF.

The DDL itself is in the Flyway migrations (`backend/src/main/resources/db/migration/V1`–`V14`),
which stay the source of truth for every column; the E-R model is in [er-model.md](er-model.md).
Figures below were measured on a database built from `main` (migrations plus demo dataset):
64 tables, 64 primary keys, 119 foreign keys, 40 unique constraints, 104 checks, 3 exclusion constraints.

## From entities to tables

| E-R construct | Relational mapping | Example |
|---------------|--------------------|---------|
| Strong entity | Table with a surrogate PK and a `UNIQUE` business key | `mission (id_mission PK, code UNIQUE, …)` |
| Weak / child entity | Table with FK to the parent; business key unique **within** the parent | `habitat UNIQUE (id_colony, code)` |
| 1 : N | FK on the N side; `NOT NULL` when participation is mandatory | `mission.id_origin_colony NOT NULL` vs `id_destination_colony` nullable |
| 1 : 0..1 | FK with a `UNIQUE` constraint on the dependent side | `crew_member.id_person UNIQUE` |
| N : M without own lifecycle | Association table with a **composite PK** of the two FKs | `crew_skill (id_crew_member, id_skill)` |
| N : M with own lifecycle or repeats | Association table with a **surrogate PK** plus a `UNIQUE` on the pair where repeats are not allowed | `mission_crew_assignment`, `crew_certification` |
| Recursive relationship | Self-referencing FK | `operational_area.parent_area_id` |
| Multi-valued attribute | Child table, never repeated columns or arrays | `mission_objective (id_mission, sequence_no, …)` instead of `objective_1`, `objective_2` |
| History of an attribute | Append-only history table | `mission_status_history`, `asset_status_history` |

## Keys

**Primary keys.** Every entity table has `BIGINT GENERATED ALWAYS AS IDENTITY`. Surrogate keys are
stable (a mission code can be corrected without touching 10 referencing tables), compact in indexes
and FKs, and `ALWAYS` stops callers from inserting their own ids. `BIGINT` instead of `INTEGER`
because telemetry and ledger tables can outgrow 2³¹ rows. The pure association tables
(`crew_skill`, `role_permission`, `user_role`, `incident_assignee`) use the composite FK pair as PK,
and `notification_preference` uses (account, event type, channel): the combination is the
identity and nothing references those rows.

**Business keys.** Every table people search or talk about carries a natural key declared `UNIQUE`
(BR-001): `code` on `colony`, `mission`, `asset`, `resource`, `incident`, `maintenance_work_order`,
`shipment`; `employee_code` on `crew_member`; `username` on `user_account`. Child codes are unique
per parent. The API exposes business keys; surrogate ids stay internal.

**Foreign keys.** Every relationship is a declared FK (BR-015), with the default `NO ACTION` on
delete: nothing cascades, which matches BR-010 (history is never physically deleted by users).
FKs to `user_account` (`created_by`, `changed_by`, `reported_by`, `closed_by`) record who did what (BR-012).

## Data types

| Type | Used for | Why |
|------|----------|-----|
| `BIGINT` identity | PKs and FKs | See above. |
| `VARCHAR(n)` | Codes, names, enumerations | A length cap documents intent and stops runaway input. Lengths are generous (codes 30–60, names 150–200). |
| `TEXT` | Descriptions, notes, reasons | Free text with no meaningful limit; PostgreSQL stores it like `VARCHAR`. |
| `VARCHAR` + `CHECK (… IN (…))` | Statuses, priorities, severities, types | Controlled vocabularies (PHX-201, HEL-502). Chosen over PostgreSQL `ENUM` because adding a value to a `CHECK` is a plain migration, while `ENUM` values cannot be removed or reordered. Over lookup tables because the sets are small, fixed and carry no attributes. |
| `TIMESTAMPTZ` | Every instant (`*_at`) | BR-011: stored in UTC, exchanged as ISO-8601 with offset. Never `TIMESTAMP` without time zone. |
| `DATE` | Calendar facts with no time of day | Birth date, hire date, certification issue/expiry, lot expiry. Certification validity is checked against the mission date (BR-004), so day precision is enough. |
| `NUMERIC(18,6)` | Quantities (stock, movements, thresholds, requirements) | Exact decimal arithmetic: stock is summed and compared to zero (BR-007), which floating point would get wrong. Six decimals cover litres of water and grams of reagent alike. |
| `NUMERIC(9,6)` | Latitude / longitude | Six decimals ≈ 6 cm on Mars; exact comparisons in range checks. |
| `NUMERIC(14,2)` | `asset.operating_hours` | Counter with two decimals. |
| `SMALLINT` | Bounded scales 1–5 | Proficiency, likelihood, impact; the `CHECK` gives the range. |
| `INTEGER` | Counts and capacities | `max_capacity`, `required_people`, `duration_minutes`. |
| `BOOLEAN` | Flags | `is_commander`, `critical`, `mandatory`, `active`. |
| `UUID` | Correlation ids | Groups the rows of one business operation (`inventory_movement.correlation_id`) without a central sequence. |
| `JSONB` | Opaque payloads only | `audit_event.old/new_value_json`, `outbox_event.payload`, `experiment_result.json_value`. Never queried by field in business logic, so they do not hide relational structure (see 1NF). |
| `tstzrange` (expression) | Exclusion constraints | `tstzrange(assigned_from, assigned_to, '[)')` with GiST (`btree_gist`, V1) prevents overlapping bookings (BR-003, BR-005). Half-open, so back-to-back assignments are allowed. |

## NOT NULL and UNIQUE

**NOT NULL** is the default for anything the domain cannot do without: every FK of a mandatory
participation, every business key, every status (with a `DEFAULT` initial value such as `DRAFT`
or `OPEN`), every interval bound, every audit actor. Columns are nullable only when "unknown" or
"not applicable" is a real state:

- optional relationships: `mission.id_destination_colony`, `incident.id_mission`/`id_asset`,
  `crew_member.id_home_colony` (member not yet assigned to a base);
- facts that happen later: `actual_start_at`, `closed_at`, `decided_by`, `released_at`;
- data that may be missing at registration: `person.email`, `asset.serial_number`, `birth_date`.

Conditional requirements are `CHECK`s across columns instead of `NOT NULL`, e.g.
`ck_incident_close_required`: when `status = 'CLOSED'`, `closed_at`, `closed_by` and
`closure_reason` must all be present (BR-009).

**UNIQUE** is evaluated per candidate key:

| Case | Choice |
|------|--------|
| Business keys | `UNIQUE NOT NULL`. |
| Optional natural keys (`person.email`, `asset.serial_number`, `crew_certification.certificate_number`) | Plain `UNIQUE` on a nullable column: PostgreSQL treats `NULL`s as distinct, so many rows may lack the value but no two may share it. |
| Uniqueness that depends on state | Partial unique index, e.g. `uq_one_commander_per_mission … WHERE is_commander AND status IN ('ASSIGNED','CONFIRMED')`. |
| Uniqueness over a nullable column | Two partial indexes, because `NULL` would defeat a single constraint: `uq_stock_with_lot (location, resource, lot) WHERE id_lot IS NOT NULL` and `uq_stock_without_lot (location, resource) WHERE id_lot IS NULL`. |
| Uniqueness over time | Exclusion constraint, not `UNIQUE`: the same member may have many assignments, just not overlapping ones. |

## Normal-form review

### 1NF: atomic values, no repeating groups

Holds. Every column is single-valued; multi-valued facts are child tables (`mission_objective`,
`mission_phase`, `crew_skill`, `shipment_item`). There are no array columns. The four `JSONB`
columns are payloads stored and returned whole (an audit snapshot, an outbox message, a free-form
experiment result) and never decomposed by business rules, so they are atomic from the schema's
point of view.

### 2NF: no partial dependencies on a composite key

Only the five tables with a composite PK can violate 2NF, and none does: each non-key attribute
describes the **whole** key, not part of it.

| Table | Key | Non-key attributes | Depend on |
|-------|-----|--------------------|-----------|
| `crew_skill` | (member, skill) | `proficiency_level`, `acquired_at`, `last_verified_at` | the member's level **in that skill** |
| `user_role` | (account, role) | `assigned_by`, `assigned_at`, `revoked_at` | that grant |
| `incident_assignee` | (incident, member) | `responder_role`, `assigned_at`, `released_at` | that member's role **on that incident** |
| `notification_preference` | (account, event type, channel) | `enabled` | that account's choice **for that event on that channel** |
| `role_permission` | (role, permission) | none | — |

Tables with a surrogate PK and a `UNIQUE` pair (e.g. `mission_crew_assignment`) are checked
against the pair as well: `mission_role`, `is_commander` and the time window describe the
assignment, not the mission or the member alone.

### 3NF: no transitive dependencies

The schema is in 3NF except for the cases below. Each is either a **deliberate redundancy**
(stored for performance or simplicity, kept consistent by the service layer) or a **gap** where
the redundant value can drift today.

| # | Table | Dependency | Kind | Consistency today |
|---|-------|-----------|------|-------------------|
| 1 | `inventory_stock`, `inventory_movement` | `id_lot → id_resource` (a lot belongs to one resource) | Redundant FK, kept so that lot-less stock is still keyed by resource | **Not enforced.** Verified: the database accepts a stock row whose lot belongs to another resource. Fix: composite FK `(id_lot, id_resource) → resource_lot (id_lot, id_resource)`. |
| 2 | `asset`, `inventory_location` | `id_area → … → id_colony` (area → module → habitat → colony) | Redundant FK, kept because the area is optional while the colony is mandatory and is the main filter ("assets of base X") | Not enforced; service layer must check the area is inside the colony. Demo data is consistent. |
| 3 | `mission_resource_allocation` | requirement's resource and stock row's resource must match | Two paths to `resource` | Not enforced; service layer check (ORI-403, mission allocation). |
| 4 | `inventory_stock.quantity` | sum of `inventory_movement` per location/resource/lot | Derived value, stored (BR-006) | By design: the movement and the stock update happen in one transaction with optimistic locking on `version_no`; `CHECK (quantity >= 0)` is the safety net (BR-007). |
| 5 | `mission.status`, `asset.status` | latest row of `*_status_history` | Derived value, stored for cheap reads and filtering | By design: status change and history insert in one transaction. |
| 6 | `shipment_item.received_quantity` | sum of `RECEIPT` movements for that item | Derived value, stored | By design, same transaction as the receipt (invariant E). |
| 7 | `colony.active` (also habitat, module, area) | largely implied by `status = 'INACTIVE'` | Overlapping attributes | Not enforced; demo data is consistent. The service should treat `status` as the source and derive `active`, or a `CHECK` should tie them. |

Cases 4–6 are the denormalisations the capitolato allows when motivated: they avoid aggregating
the full ledger or history on every read of a dashboard. Cases 1–3 and 7 are real integrity gaps.
Following the project rule, they are fixed by **new** migrations, not by editing the baseline.

### BCNF

The tables with more than one candidate key (`crew_member`: `id_crew_member`, `id_person`,
`employee_code`; `user_account`: `id_account`, `id_person`, `username`) have every determinant
as a candidate key, so they are in BCNF. Reviewing the MVP tables found no other determinant
that is not a key, apart from the cases listed under 3NF.

## Known deviations from the engineering standards

- **Constraint names.** CLAUDE.md asks for named constraints. All `CHECK` and exclusion constraints
  are named, but the baseline declares PKs, FKs and most `UNIQUE`s inline, so PostgreSQL generated
  their names (`colony_pkey`, `mission_id_origin_colony_fkey`, `colony_code_key`): 0 of 64 PKs,
  0 of 119 FKs and 19 of 40 unique constraints follow the `pk_`/`fk_`/`uq_` convention. New
  migrations name every constraint; renaming the baseline ones is a separate, mechanical migration.
- **`incident_assignee` key.** The composite PK (incident, member) means a responder released from
  an incident cannot be re-assigned to it as a new row; HEL-503 must either reactivate the row or
  the key must change.

## Follow-ups

Each has its own issue and will get its own migration:

1. Composite FKs that tie `id_lot` to `id_resource` in `inventory_stock` and `inventory_movement` (gap 1): #83.
2. Rename the generated PK/FK/UNIQUE constraint names to the project convention: #84.

Gaps 2, 3 and 7 are left to the stories that write those tables (TIT-301/ORI-401, ORI-403 and
ARES-101), which must check them in the service layer and add a negative test.
