# ADR-0010: Strict request input and architecture tests

- **Status:** Accepted
- **Date:** 2026-10-16
- **Issue:** #90

## Context and problem statement

The 2026-10-16 security review and a probe of the running API with hostile input found:

- a NUL character in a name passed validation and was refused by PostgreSQL, so the client got
  `409 DATA_INTEGRITY_VIOLATION` instead of a `400` naming the field; terminal escapes, unpaired
  surrogates and bidirectional overrides were stored as is;
- an instant such as `+300000-01-01T00:00Z` parsed in Java and failed only in the database;
- unknown properties (`"status": "APPROVED"`) and duplicate properties were silently ignored or
  overwritten, and `"code": 123` became `"123"`;
- a 5 MB body was read in full before validation rejected it; an oversized path code was looked up;
- errors raised outside Spring MVC (`TRACE`, a filter) were not Problem Details and had no `code`.

OWASP Top 10:2025 A10 (*Mishandling of Exceptional Conditions*) and API Security Top 10 2023 API3
(*Broken Object Property Level Authorization*, mass assignment) and API4 (*Unrestricted Resource
Consumption*) cover these cases. Separately, the package rules in `CLAUDE.md` were only checked in
review.

## Decision

**Strict input, rejected at the edge with a stable code.**

- `@PlainText` (shared validation) on every free-text request field: no control characters
  (line breaks and tabs only where `multiline = true`), no unpaired surrogates, no bidirectional
  controls (Trojan Source, CVE-2021-42574). Codes keep their `@Pattern`.
- `@SupportedInstant` on request instants: years 0001 to 9999, the ISO 8601 range (BR-011) that
  fits `TIMESTAMPTZ`.
- Path codes carry `@Size`, so an oversized code is `400 VALIDATION_FAILED` without a lookup.
- Jackson rejects unknown and duplicate properties, trailing content and scalar-to-text coercion
  (`400 MALFORMED_REQUEST`). Clients must send only the documented fields; the server still
  decides the fields it owns (status, author) and never reads them from the body.
- Request bodies are limited to 64 KB (`aether.http.max-request-body`): a larger declared
  `Content-Length` is `413 PAYLOAD_TOO_LARGE` before the body is read, and a body without a length
  is cut by Jackson's `max-document-length`.
- `ProblemErrorController` replaces Spring Boot's `BasicErrorController`, so errors forwarded to
  `/error` by the container are Problem Details with a `code` too.

**Architecture rules as tests.** `ArchitectureTest` (ArchUnit) checks that layers inside a feature
point inwards (`api` → `domain` ← `persistence`), features have no cycles and never call another
feature's `api`, shared code depends on no feature, controllers expose no JPA entity, request and
response bodies are records, and every request text is bounded and plain. Cross-feature
dependencies are an explicit allow-list in the test (`crew` → `colonies`, `missions` →
`colonies`, `identity`): adding one is a reviewed change.

`HostileInputTest` (MockMvc) and `HostileInputIT` (real Tomcat and PostgreSQL) keep the probe as
regression tests.

## Consequences

- A client that sends extra fields now gets `400` instead of having them ignored. The frontend
  already sends exactly the documented fields.
- `@Size` counts UTF-16 units, so text made only of emoji reaches the limit at half the characters.
  Accepted: the limit stays conservative with respect to the database column.
- Requests rejected by Tomcat before the application (an encoded slash or NUL in the path,
  invalid UTF-8) still get Tomcat's minimal HTML 400 page, without version information.
- New request fields fail the build until they declare a length and `@PlainText` or `@Pattern`.
