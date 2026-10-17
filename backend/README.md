# AETHER backend

Spring Boot 4 · Java 21 · PostgreSQL 16 · Flyway. Decisions: [ADR-0002](../docs/adr/0002-technology-stack.md),
[ADR-0004](../docs/adr/0004-schema-migrations-with-flyway.md), [ADR-0005](../docs/adr/0005-rest-error-contract.md).

## Run locally

```bash
# 1. database (from the repository root)
docker compose -f infrastructure/docker-compose.yml up -d

# 2. backend (Flyway migrates the schema on startup)
cd backend
./mvnw spring-boot:run
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev   # same, plus the demo dataset
```

Profile `dev` (or `demo`) also loads the demo dataset from `db/demo`
([details](../docs/database/demo-dataset.md), [ADR-0007](../docs/adr/0007-demo-dataset-as-repeatable-migration.md)).

| URL | What |
|-----|------|
| http://localhost:8080/actuator/health | Liveness/readiness |
| http://localhost:8080/swagger-ui.html | Interactive API docs (`dev` profile or `AETHER_API_DOCS_ENABLED=true`, ADR-0013) |
| http://localhost:8080/v3/api-docs | OpenAPI contract (JSON) |

Configuration comes from environment variables (defaults match Docker Compose):
`AETHER_DB_HOST`, `AETHER_DB_PORT`, `AETHER_DB_NAME`, `AETHER_DB_USER`, `AETHER_DB_PASSWORD`.

## Test

```bash
./mvnw test      # fast tests, no Docker needed
./mvnw verify    # + integration tests (*IT) on a real PostgreSQL via Testcontainers; needs Docker
```

## Code layout

Package by feature under `io.github.jakiwz.aether`:

```text
shared/
  config/   cross-cutting configuration (OpenAPI, …)
  error/    RFC 9457 error contract: exceptions + GlobalExceptionHandler
<domain>/   one package per domain (crew, colonies, missions, fleet, inventory, incidents)
  api/          controllers + request/response records
  domain/       services with business rules (@Transactional)
  persistence/  JPA entities and repositories
```
