# ADR-0008: Attribute writes to a system account until authentication exists

- **Status:** Superseded by [ADR-0012](0012-session-authentication-and-permission-checks.md) for requests made by users
- **Date:** 2026-10-16
- **Issue:** #22 (PHX-201)

## Context and problem statement

BR-012 requires changes to mission states, roles, critical inventory and incidents to be
attributable to a user, and the schema enforces it: `mission.created_by`,
`mission_status_history.changed_by` and similar columns are `NOT NULL` foreign keys to
`user_account`. Authentication (IAM-002) is not planned in Sprint 1, yet PHX-201 must create
missions. Something has to fill these columns without weakening the constraint.

## Considered options

1. **A technical `system` account created by a migration**, behind a `CurrentActor` abstraction.
2. Implement authentication first.
3. Make the author columns nullable until authentication exists.

## Decision

Option 1.

- `V15__insert_system_account.sql` creates the person "AETHER System" and the account `system`
  in every environment. It is `DISABLED` and its password hash matches no password, so nobody can
  log in with it.
- Domain services never pick the author themselves: they ask `identity.domain.CurrentActor` for
  the username and load the account. The only implementation, `SystemActor`, returns `system`.
- When authentication arrives, a new `CurrentActor` reads the authenticated principal and
  `SystemActor` is removed or kept for scheduled jobs. Callers do not change.

Option 2 pulls a large, unplanned story ahead of every Sprint 1 vertical slice. Option 3 needs a
migration now and another one later, and leaves rows without an author that can never be fixed.

## Consequences

- Every write recorded so far is attributed to `system`; history created before authentication
  stays honest about not knowing the human operator.
- The account must never be enabled. A future IAM story should reject logins for it explicitly.
