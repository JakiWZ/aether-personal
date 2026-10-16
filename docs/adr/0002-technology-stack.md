# ADR-0002: Technology stack

- **Status:** Accepted
- **Date:** 2026-10-16
- **Issue:** #60

## Context and problem statement

The client imposes Java/Spring Boot for the backend, Angular for the frontend and a relational SQL
database (capitolato §14). Within those constraints we must pick versions and supporting tools
that are current, supported for the life of the project and familiar to the market.

## Decision

| Concern | Choice | Rationale |
|---------|--------|-----------|
| Language/runtime | **Java 21 (LTS)** | Supported LTS, records/sealed types/virtual threads; already used by CI. |
| Backend framework | **Spring Boot 4.x** (Spring Framework 7) | Current generation; Jakarta EE 11, first-class Problem Details, observability. |
| Build | **Maven** with the Maven Wrapper | Reproducible builds without a local Maven install; CI already expects it. |
| Database | **PostgreSQL 16** | Rich constraint support (exclusion constraints, partial unique indexes, `TIMESTAMPTZ`, JSONB) that lets the DB enforce business rules. |
| Migrations | **Flyway** | Plain-SQL versioned migrations, native Spring Boot integration (see ADR-0004). |
| Persistence | Spring Data JPA (Hibernate) + native SQL for reports | JPA for aggregates, SQL where set-based queries are clearer. |
| API docs | **springdoc-openapi** | OpenAPI 3 contract and Swagger UI generated from code (INT-602). |
| Errors | **RFC 9457 Problem Details** | Standard error contract (TASK-007). |
| Tests | JUnit 5, AssertJ, **Testcontainers** | Integration tests run against real PostgreSQL, not H2, so DB constraints are exercised. |
| Frontend | **Angular** (current major), standalone components, signals | Client constraint; modern Angular idioms. |
| Local runtime | Docker Compose | One command to start the database (and later the full stack). |
| CI | GitHub Actions | Already in place; runs on every PR. |

Exact versions are pinned in `pom.xml` / `package.json` and upgraded via Dependabot PRs.

## Consequences

- Positive: mainstream, well-documented stack; DB-level guarantees for the critical rules
  (BR-003, BR-005, BR-007) in addition to service checks.
- Negative: Spring Boot 4 is recent, so some third-party examples still target 3.x; we follow
  official documentation first.
- Telemetry/Big Data storage is intentionally **not** decided here (capitolato §12); it will get
  its own ADR in Release 5.
