# ADR-0005: REST error contract (RFC 9457 Problem Details)

- **Status:** Accepted
- **Date:** 2026-10-16
- **Issue:** #13 (TASK-007)

## Context and problem statement

Five domains expose REST endpoints consumed by one Angular client and, later, by other services.
TASK-007 requires errors that carry a code and a message, distinguish validation errors from
404s and business conflicts, and never expose stack traces. Without a shared contract every
controller would invent its own JSON shape.

## Considered options

1. Custom `{ "error": ..., "message": ... }` envelope.
2. **RFC 9457 Problem Details** (`application/problem+json`), extended with a `code` property.

## Decision

Option 2, implemented once in `shared/error/GlobalExceptionHandler`.

```json
{
  "type": "about:blank",
  "title": "Conflict",
  "status": 409,
  "detail": "Crew member CRW-001 is already assigned to an overlapping mission.",
  "instance": "/api/v1/missions/42/crew",
  "code": "CREW_ASSIGNMENT_OVERLAP"
}
```

| Situation | Status | `code` |
|-----------|--------|--------|
| Bean Validation failure (body or parameters) | 400 | `VALIDATION_FAILED` + `errors: [{field, message}]` |
| Unreadable/malformed request | 400 | `MALFORMED_REQUEST` |
| Entity not found / unknown route | 404 | `RESOURCE_NOT_FOUND` |
| Business rule or state conflict | 409 | domain specific, e.g. `CREW_ASSIGNMENT_OVERLAP` |
| DB constraint caught as last line of defence | 409 | `DATA_INTEGRITY_VIOLATION` (constraint name only in logs) |
| Method / media type not supported | 405 / 415 | `METHOD_NOT_ALLOWED` / `UNSUPPORTED_MEDIA_TYPE` |
| Anything unexpected | 500 | `INTERNAL_ERROR` (logged with stack trace, generic detail) |

Rules for domain code:

- Throw `ResourceNotFoundException(resource, id)` or
  `BusinessRuleViolationException(CODE, safeMessage)`; never build error responses in controllers.
- `code` values are part of the public API: SCREAMING_SNAKE_CASE, never renamed once released.
- `detail` is human readable and may change; clients must not parse it.

## Consequences

- Standard media type understood by tooling; Spring Framework produces it natively.
- The frontend can map `code` to localised messages (NFR-011) and highlight `errors[].field`.
- Contract covered by `GlobalExceptionHandlerTest` (one test per row of the table above).
