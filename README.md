# AETHER — Mars Operations Platform

[![CI](https://github.com/JakiWZ/aether-personal/actions/workflows/ci.yml/badge.svg)](https://github.com/JakiWZ/aether-personal/actions/workflows/ci.yml)

A full-stack operations platform for Martian colonies: crew and habitats, mission planning,
fleet maintenance, logistics and incident response, unified in a Mission Control dashboard.

Built as an evolutive capstone (Data → Backend → Frontend → Big Data → Security → Cloud → AI)
following Scrum, GitHub Flow and an AI-assisted engineering workflow with
[Claude Code](https://claude.com/claude-code) (see [`CLAUDE.md`](CLAUDE.md)).

## Domains

| Squad | Domain | Examples of rules enforced server-side |
|-------|--------|----------------------------------------|
| **ARES** | Colonies, habitats, crew, skills, certifications | Base capacity, unique crew codes |
| **PHOENIX** | Missions, crew assignment, lifecycle | No overlapping crew assignments, one commander |
| **TITAN** | Fleet (rovers/vehicles), maintenance | Vehicles under maintenance cannot be assigned |
| **ORION** | Resources, stock, movements, thresholds | Stock never negative, atomic transfers |
| **HELIOS** | Incidents, responders, timeline | Controlled severity, auditable closure |
| **CROSS** | Mission Control dashboard, CI, release | Real data from ≥ 4 domains |

## Tech stack

Java 21 · Spring Boot 4 · PostgreSQL 16 · Flyway · Testcontainers · Angular 22 · Docker Compose ·
GitHub Actions. Rationale in [ADR-0002](docs/adr/0002-technology-stack.md).

## Repository layout

```text
backend/         Spring Boot REST API + Flyway migrations
frontend/        Angular SPA
infrastructure/  Docker Compose (local), later IaC
docs/
  requirements/  Client requirements (capitolato)
  sprints/       Sprint mission packs with detailed acceptance criteria
  adr/           Architecture Decision Records
  agile/         Definition of Ready/Done, ceremonies, Git workflow
  database/      Data model documentation
.github/         Issue/PR templates, CI workflows
```

## Getting started

Prerequisites: Docker, Java 21, Node.js 24 LTS.

```bash
# 1. database: PostgreSQL 16 with defaults from .env.example
docker compose -f infrastructure/docker-compose.yml up -d

# 2. backend: applies migrations on startup (profile `dev` also loads the demo dataset)
cd backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev

# 3. frontend (another terminal): proxies /api to the backend
cd frontend && npm ci && npm start
```

| URL | What |
|-----|------|
| http://localhost:4200 | Web application (Mission Control) |
| http://localhost:8080/swagger-ui.html | API documentation (OpenAPI) |
| http://localhost:8080/actuator/health | Health check |

With the demo dataset, sign in as any demo account (for example `mc.rossi`, Mission Controller, or
`crew.conti`, read-only crew) with the demo-only password `Aether-demo-password`; the accounts and
their roles are listed in [`docs/database/demo-dataset.md`](docs/database/demo-dataset.md).
Without the demo dataset there are no accounts that can sign in yet (ADR-0012).

More: [`backend/README.md`](backend/README.md), [`frontend/README.md`](frontend/README.md),
[`docs/database/README.md`](docs/database/README.md).

## How we work

- Backlog: [GitHub Issues](https://github.com/JakiWZ/aether-personal/issues) organised in Epics
  (#1–#6) and milestones `Sprint 1–3`.
- Every change: Issue → branch `feature/<issue>-…` → small Conventional Commits → PR with
  `Closes #<issue>` → green CI → review → squash merge.
  Details: [`docs/agile/GIT_WORKFLOW.md`](docs/agile/GIT_WORKFLOW.md).
- Quality bar: [`docs/agile/DEFINITION_OF_READY_DONE.md`](docs/agile/DEFINITION_OF_READY_DONE.md).

## Documentation

- [Requirements (capitolato)](docs/requirements/capitolato.md)
- Sprints: [1 – Foundation](docs/sprints/sprint-1-foundation.md) ·
  [2 – Core Operations](docs/sprints/sprint-2-core-operations.md) ·
  [3 – Integrated MVP](docs/sprints/sprint-3-integrated-mvp.md)
- [Architecture Decision Records](docs/adr/README.md)
