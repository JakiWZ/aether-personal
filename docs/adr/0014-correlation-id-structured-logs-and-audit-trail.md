# ADR-0014: Correlation id, structured logs and the audit trail

- **Status:** Accepted
- **Date:** 2026-10-17
- **Issue:** #97

## Context and problem statement

The security review found that nothing is recorded in a way that supports an investigation.
- Application logs are free text, and the lines of one request cannot be linked together.
  NFR-009 asks for structured logs.
- The `audit_event` table (V13) exists, but nothing writes to it. Logins, failed logins and lockouts
  are not recorded (IAM-008). Neither are the writes that BR-012 and UC-07 require to be attributable.

OWASP Top 10 2021 A09 (Security Logging and Monitoring Failures), the OWASP Logging Cheat Sheet and
ASVS 5.0 V16 ask for these things:
- authentication successes and failures, lockouts and access-control failures are logged;
- each event has a timestamp, the actor, the source address and an id that correlates it with the request;
- secrets and data the user typed by mistake are never logged;
- user-controlled values cannot forge log lines;
- the audit trail is kept apart from diagnostic logs. Section 11 of the requirements also asks for this.

## Decision

**Correlation id.** `CorrelationIdFilter` runs before every other filter.
- It takes the caller's `X-Request-ID` only when that header is a UUID. Any other value is replaced
  by a random UUID, so a caller cannot inject text into the logs or the audit trail.
- The id is echoed in the response and put in the logging MDC as `correlationId`.

**Structured logs.** We use Spring Boot's built-in structured logging. There is no extra dependency.
- `AETHER_LOG_FORMAT=ecs` writes one Elastic Common Schema JSON object per line, with the MDC
  included, which is what a log shipper expects.
- When the variable is empty, which is the local default, logs are readable text. The line carries
  the correlation id through `logging.pattern.correlation`.
- Refused requests of a signed-in user (403) are logged at `WARN`.

**Audit trail.** A new feature `audit` holds `AuditTrail`, and it depends on no other feature.
- Each event is appended to `audit_event` inside the caller's transaction, so it is stored if and
  only if the change is.
- Each event records the action, the entity, the account it is attributed to, a small JSON snapshot,
  a reason, the client address and the correlation id.
- The table is only ever inserted into. The entity is `@Immutable` and the repository has no update
  or delete.

| Action | When | Account | Reason |
|--------|------|---------|--------|
| `LOGIN_SUCCEEDED` | Valid credentials on an active account | The account | — |
| `LOGIN_FAILED` | Wrong password / unknown username | The account / none (`entity_id = unknown`) | `WRONG_PASSWORD` / `UNKNOWN_ACCOUNT` |
| `ACCOUNT_LOCKED` | The failure that reaches `max-failed-attempts` | The account | `TOO_MANY_FAILED_LOGINS` |
| `LOGIN_REFUSED` | Any login on a locked or non-active account | The account | `ACCOUNT_LOCKED`, `ACCOUNT_DISABLED`, … |
| `LOGOUT` | `POST /api/v1/auth/logout` | The account | — |
| `MISSION_CREATED` | PHX-201 | The author | — |
| `CREW_MEMBER_REGISTERED` | ARES-103 | The signed-in user | — |

What we never record:
- passwords;
- the text an unknown user typed as a username, because it is often a password typed into the
  wrong field;
- personal data in snapshots. A crew snapshot holds status and base, not name or email.

Future writes (mission status changes, inventory, incidents, roles) call `AuditTrail` in the same way.

## Consequences

- Each login now writes one row. The table grows with traffic. Retention and archiving belong to the
  operations backlog. Rows are never deleted by user workflows (BR-010).
- The client address is the TCP peer. Behind a reverse proxy, `server.forward-headers-strategy`
  must be set, and only for a trusted proxy, or every event shows the proxy's address.
- A failure to write the audit row fails the business operation. That is deliberate: an
  unattributable change is worse than a refused one.
- Reading the audit trail through the API (UC-07, the auditor role) is a separate story.
