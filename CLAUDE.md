# CLAUDE.md

Guidance for Claude Code (and any other contributor) working in this repository.
Read this file fully before making changes. It is the single source of truth for *how* we work;
the product requirements live in [`docs/requirements/capitolato.md`](docs/requirements/capitolato.md).

## Product in one paragraph

**AETHER – Mars Operations Platform** is a full-stack system that lets Mission Control run Martian
colonies: bases/habitats and crew (ARES), missions (PHOENIX), fleet and maintenance (TITAN),
resources and logistics (ORION), incidents and safety (HELIOS), plus a Mission Control dashboard
that aggregates all domains. Business rules (no crew/vehicle double-booking, no negative stock,
atomic transfers, auditable state changes) must hold **server-side**, never only in the UI.

## Repository map

| Path | Content |
|------|---------|
| `backend/` | Spring Boot REST API (Java 21, Maven). Flyway migrations in `src/main/resources/db/migration`. |
| `frontend/` | Angular 22 SPA (standalone components, signals, zoneless). Layout in `frontend/README.md`. |
| `infrastructure/` | Docker Compose for local dev, later IaC. |
| `docs/requirements/` | Client requirements (capitolato): functional reqs, business rules `BR-xxx`, NFRs. |
| `docs/sprints/` | Sprint mission packs with detailed acceptance criteria per story. |
| `docs/adr/` | Architecture Decision Records (MADR). **Every significant technical decision gets one.** |
| `docs/agile/` | Definition of Ready/Done, ceremonies, Git workflow. |
| `docs/database/` | Data model documentation and legacy SQL. |

## Source of truth for work

- Work is tracked in **GitHub Issues** on `JakiWZ/aether-personal`. Backlog keys (e.g. `PHX-205`,
  `ORI-404`) appear in issue titles; the issue number is what goes in branch names and PRs.
- Epics: #1 Foundation, #2 ARES, #3 PHOENIX, #4 TITAN, #5 ORION, #6 HELIOS. Stories are sub-issues.
- Milestones `Sprint 1/2/3`; labels `type:*`, `priority:*`, `squad:*`, `area:*`, `sprint:*`.
- Before implementing a story, read its issue **and** the matching section in `docs/sprints/`
  (the mission packs have richer acceptance criteria and the "evidence for review").

## Workflow (non-negotiable)

1. Every change starts from an Issue. No issue → open one first (use the templates).
2. Branch from up-to-date `main`: `feature/<issue>-<kebab-desc>`, `fix/<issue>-…`, `docs/<issue>-…`,
   `refactor/<issue>-…`, `chore/<issue>-…`. Never commit to `main` directly.
3. Small commits using **Conventional Commits**: `feat(missions): reject overlapping crew assignment`.
   Scope = domain or layer (`missions`, `crew`, `fleet`, `inventory`, `incidents`, `db`, `ci`, `docs`).
4. Open a **draft PR** early, fill in the template, body contains `Closes #<issue>`.
5. CI must be green. Self-review the diff before requesting review. Squash-merge into `main`.
6. One concern per PR. If you discover unrelated problems, open a new issue instead of widening the PR.

## Definition of Done (summary — full list in `docs/agile/DEFINITION_OF_READY_DONE.md`)

Acceptance criteria met · builds · DB changes are versioned migrations · server-side validation ·
consistent error responses · automated tests including **at least one negative case** ·
PR reviewed, CI green, merged · docs/ADR updated when behaviour or architecture changed.

## Engineering standards

### General
- Code, identifiers, commit messages, ADRs and technical docs in **English**.
  Requirements and agile docs stay in Italian (they come from the client).
- No secrets in the repo, ever. Configuration via environment variables with safe local defaults
  (`.env.example` documents them; real `.env` files are git-ignored).
- All timestamps are persisted as `TIMESTAMPTZ` in UTC and exchanged as ISO-8601 with offset (BR-011).
- Prefer boring, well-known solutions. Anything non-obvious → write an ADR.

### Database (PostgreSQL 16)
- Schema changes **only** through Flyway migrations `V<n>__<snake_case_description>.sql`.
  Never edit a migration that has been merged — add a new one.
- Every table: surrogate `BIGINT GENERATED ALWAYS AS IDENTITY` PK, natural business key as `UNIQUE`
  (e.g. `code`), explicit FK, `NOT NULL`/`CHECK` constraints for domain rules, named constraints
  (`pk_`, `fk_`, `uq_`, `ck_`, `ix_`, `ex_`).
- Invariants that the DB can enforce must be enforced in the DB too (exclusion constraints for
  overlapping assignments, `CHECK (quantity >= 0)`), *in addition* to service-level checks that
  produce friendly errors.
- Historical data is never physically deleted by user workflows (BR-010): use status/soft delete.
- Demo data lives in a separate Flyway location enabled only for the `dev`/`demo` profile.

### Backend (Spring Boot)
- Package by feature/domain (`…/missions`, `…/crew`, …), not by layer. Inside a feature:
  `api` (controllers + DTOs), `domain`/`service`, `persistence`.
- Controllers are thin; business rules live in services; multi-step writes are `@Transactional`
  service methods. Use pessimistic locking or optimistic versioning where concurrency matters (stock).
- DTOs are Java `record`s validated with Jakarta Bean Validation. Never expose JPA entities.
  Every request text has a length limit and `@PlainText` (or a `@Pattern`); unknown JSON properties
  are rejected (ADR-0010). `ArchitectureTest` enforces these and the package rules.
- Errors follow **RFC 9457 Problem Details** (`application/problem+json`) with a stable `code`
  property; no stack traces leak to clients.
- API documented with OpenAPI (springdoc). Paths are plural nouns under `/api/v1`.
  List endpoints are paginated (`page`, `size` ≤ 100) and return `PageResponse` (ADR-0011).
- Security (ADR-0012): session cookie + CSRF token, deny by default. Every endpoint carries
  `@PreAuthorize` with a permission code from the `permission` table (`ArchitectureTest` checks it).
  `@WebMvcTest`s `@Import(SecurityConfig.class)`, use `@WithMockUser(authorities = …)` and
  `.with(csrf())` on writes, and include the 401/403 negative cases.
- Audit (ADR-0014): every state change and security event calls `AuditTrail` inside its transaction;
  no passwords or personal data in snapshots. Logs carry the request's `correlationId` (MDC).
- Tests: JUnit 5 + AssertJ; integration tests with **Testcontainers PostgreSQL** (never H2);
  `@WebMvcTest` for controller contracts. Every business rule has a negative test.

### Frontend (Angular)
- Standalone components, signals, `OnPush`, lazy-loaded feature routes mirroring backend domains.
- API base URL from environment configuration, never hardcoded in components.
- Every data view handles loading, empty and error states. Forms use typed reactive forms;
  client validation is for UX only — the server is authoritative.
- Accessibility (labels, keyboard navigation, contrast) is part of done.
- Feature routes use `authGuard`; hide actions with `AuthService.hasPermission` (UX only).

## Commands

> Keep this section in sync with the README.

```bash
# Database: PostgreSQL 16 on localhost:5432 (db/user/password: aether)
docker compose -f infrastructure/docker-compose.yml up -d
docker compose -f infrastructure/docker-compose.yml --profile tools run --rm migrate   # apply migrations + demo data
docker compose -f infrastructure/docker-compose.yml down -v                           # reset

# Backend (from backend/): Swagger UI at http://localhost:8080/swagger-ui.html with the dev profile
./mvnw spring-boot:run
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev   # + demo dataset and API docs (ADR-0013)
./mvnw test      # fast tests, no Docker
./mvnw verify    # + Testcontainers integration tests (*IT), needs Docker

# Frontend (from frontend/, Node.js 24): http://localhost:4200, proxies /api to :8080
npm ci
npm start
npm test                              # Vitest, single run
npm run lint && npm run format:check  # ESLint (OnPush + a11y rules) and Prettier
npm run build
```

New migration: `backend/src/main/resources/db/migration/V<next>__<verb>_<object>.sql`.
See `docs/database/README.md` for the migration map and the rules enforced by the DB.

## How Claude should behave here

- Read the issue + relevant mission-pack section + related ADRs before coding.
- Propose a short plan for anything larger than a small fix; ask when a requirement is ambiguous
  instead of guessing (the requirements explicitly expect open questions to the Product Owner).
- Run the relevant build/tests locally before pushing; never push a red build knowingly.
- Keep PRs small and focused; update docs/ADRs in the same PR when decisions change.
- Never weaken a test, skip a check, or disable a constraint to get green.
