# AGENTS.md

Instructions for AI coding agents (Codex, Copilot, Cursor, Claude Code, …) working on AETHER.

**[`CLAUDE.md`](CLAUDE.md) is the single source of truth.** Read it in full before changing anything;
it applies to every agent, not only Claude. This file only summarises it, so if the two ever differ,
`CLAUDE.md` wins.

## Before you start

- Every change starts from a GitHub Issue on `JakiWZ/aether-personal`. Read the issue, the matching
  section in `docs/sprints/` and the related ADRs in `docs/adr/`.
- Requirements are in `docs/requirements/capitolato.md` (Italian). What is done, partial or missing
  is in `docs/requirements/traceability.md`.

## Commands

```bash
docker compose -f infrastructure/docker-compose.yml up -d     # PostgreSQL 16 on :5432
cd backend  && ./mvnw test                                    # fast tests, no Docker
cd backend  && ./mvnw verify                                  # + Testcontainers integration tests
cd frontend && npm ci && npm test && npm run lint && npm run format:check && npm run build
```

## Rules you must not break

- Branch `feature|fix|docs|refactor|chore/<issue>-<kebab-desc>` from `main`. Use Conventional Commits.
  Open a draft PR whose body says `Closes #<issue>`. Never push to `main`.
- Code, commits, ADRs and technical docs are written in English. Requirements and agile docs stay in Italian.
- Schema changes go only in new Flyway migrations. Never edit a merged migration.
- Business rules are enforced server-side, in services and in DB constraints. Never only in the UI.
- Every endpoint carries `@PreAuthorize` with a permission code.
- Request DTOs are bounded `record`s.
- Errors use RFC 9457 Problem Details.
- `ArchitectureTest` checks these rules.
- State changes and security events go to `AuditTrail` (ADR-0014). Never log or store passwords or
  personal data.
- Every business rule has a negative test. Integration tests use PostgreSQL via Testcontainers, never H2.
- Error Prone and NullAway run in every backend build (ADR-0015). Mark nullable values with JSpecify
  `@Nullable` and fix findings instead of suppressing them.
- Never weaken a test, skip a check or disable a constraint to get green. Never commit secrets.
- When a story closes, update its requirement rows in `traceability.md`.
- Any significant technical decision gets an ADR.
