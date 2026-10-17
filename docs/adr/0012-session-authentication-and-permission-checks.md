# ADR-0012: Session authentication and permission checks

- **Status:** Accepted
- **Date:** 2026-10-16
- **Issue:** #56 (FUT-701)
- **Supersedes:** [ADR-0008](0008-attribute-writes-to-a-system-account.md) (for requests made by users)

## Context and problem statement

Until now every endpoint was open and every write was attributed to the `system` account
(ADR-0008). The capitolato requires login (IAM-002), roles and permissions (IAM-004/005), a
session timeout (IAM-007), protection against repeated failed logins (IAM-008) and attribution of
every change to its author (BR-012). OWASP API Security Top 10 2023 ranks broken object/function
level authorization and broken authentication (API1, API2, API5) as the top API risks.

The only client is our own Angular SPA, served from the same origin as the API (dev proxy,
reverse proxy in production). Accounts, roles and permissions already exist in the schema (V3).

## Considered options

1. **Server-side session in an `HttpOnly` cookie, CSRF token for state changes.**
2. JWT access token kept by the SPA (memory or `localStorage`) and sent as a bearer header.
3. External identity provider (OIDC) with the backend as resource server.

## Decision

Option 1, with Spring Security.

**Login and passwords**
- `POST /api/v1/auth/login` checks the account in `user_account` (`LoginService`). Any failure
  (unknown user, wrong password, locked, disabled or pending account) answers the same
  `401 INVALID_CREDENTIALS`, and a hash is computed in every case so timing does not tell them apart.
- Passwords are hashed with **Argon2id, m = 19 MiB, t = 2, p = 1**, the minimum of the OWASP
  Password Storage Cheat Sheet, behind a `DelegatingPasswordEncoder` (`{argon2id}` prefix) so the
  parameters can be raised later; weaker hashes are re-encoded at the next successful login.
  Values without a known prefix (the `system` placeholder) never match.
- After **5 consecutive failures** the account is locked for **15 minutes**
  (`aether.security.login.*`). NIST SP 800-63B-4 allows up to 100; we choose fewer because there
  is no second factor yet. The price is that someone can lock a known username for 15 minutes.
- **Per-address throttling** (added by #101). A client address may try at most **10 logins per minute**,
  whatever the accounts (`aether.security.login.rate-limit.*`). The account lockout alone does not
  stop password spraying or credential stuffing, which try few passwords on many accounts. It also
  does not stop a flood of Argon2id hashes (OWASP Authentication Cheat Sheet; API4:2023).
  - Past the limit the answer is `429 TOO_MANY_LOGIN_ATTEMPTS` with `Retry-After`, before any
    password check, account update or audit write.
  - Windows are fixed and kept in memory, at most `max-tracked-addresses` of them (10,000). When the
    table is full, new addresses are let through to the account lockout instead of being refused,
    so a botnet cannot lock everyone out.
  - With several instances each node keeps its own counters. A shared limiter, at the reverse proxy
    or in Redis, belongs to the deployment story.
  - The address is the TCP peer, so the same `forward-headers-strategy` caveat applies as in ADR-0014.
- Usernames are matched in lower case. Passwords are never logged (`LoginRequest#toString`).

**Session**
- The session id travels in `AETHER_SESSION`: `HttpOnly`, `SameSite=Strict`, `Path=/`, `Secure`
  when `AETHER_COOKIE_SECURE=true` (required wherever HTTPS is used), cookie tracking only (never in
  URLs). Idle timeout **30 minutes** (OWASP Session Management Cheat Sheet: 15–30 minutes).
- The session id changes at login (session fixation) and the session is invalidated at
  `POST /api/v1/auth/logout` (`204`).
- Roles and permissions are read at login and kept in the session: a change takes effect at the
  user's next login. Acceptable while sessions are short; revisit when IAM-003 (disable account)
  must act immediately.

**CSRF**
- Spring Security's SPA mode (`csrf.spa()`): the `XSRF-TOKEN` cookie (readable by the SPA,
  `SameSite=Strict`) is echoed by Angular's built-in XSRF support as `X-XSRF-TOKEN` on every
  same-origin write. `GET /api/v1/auth/session` hands the token out; it rotates at login.
  Missing or wrong token: `403 CSRF_TOKEN_INVALID`.

**Authorization**
- Deny by default: everything needs a session except login, the session probe, health/info and
  the OpenAPI documents.
- Every endpoint declares its permission with `@PreAuthorize("hasAuthority('…')")`, using the
  codes of the `permission` table (`MISSION_MANAGE`, `CREW_READ`, …); roles are also granted as
  `ROLE_<code>`. `ArchitectureTest` fails the build when an endpoint has no `@PreAuthorize`, so a
  new endpoint cannot ship open by omission (`permitAll()` must be written out).
- `401 AUTHENTICATION_REQUIRED` and `403 ACCESS_DENIED` use the Problem Details contract
  (ADR-0005), without a `WWW-Authenticate` challenge so the browser shows no native dialog.
- Writes are attributed to the signed-in user (`SecurityContextActor` replaces `SystemActor`). The
  `system` account stays for future jobs that run without a user.

**SPA**
- An app initializer asks `GET /auth/session` before the first route; feature routes have a
  `canMatch` guard that sends visitors to `/login?returnUrl=…`; after login only internal paths are
  followed (no open redirect). A 401 on any call ends the local session and shows the login page.
  Links and pages the user has no permission for are hidden: UX only, the server decides.
- No CORS configuration: same origin only. Adding another origin is a new decision.

**Demo data**
- Demo accounts share the documented, demo-only password `Aether-demo-password` (20 characters,
  above the NIST 15-character minimum for single-factor passwords). The demo dataset is never
  loaded outside the `dev`/`demo` profiles (ADR-0007).

## Consequences

- Good: credentials and the session id are out of reach of page scripts; CSRF is covered by token
  plus `SameSite`; no token storage or refresh logic in the SPA; authorization is visible on each
  method and enforced by a build rule.
- Bad: sessions are server state (one node is fine now; several nodes will need a shared session
  store such as Spring Session JDBC). The SPA and the API must share an origin.
- Follow-ups: account administration
  (IAM-001/003); security response headers and Swagger only in development.

## References

- OWASP API Security Top 10 2023: API1, API2, API5.
- OWASP Cheat Sheets: Password Storage, Session Management, Cross-Site Request Forgery Prevention,
  Authentication.
- OWASP ASVS 5.0: V6 Authentication, V7 Session Management, V8 Authorization.
- NIST SP 800-63B-4: password length and failed-attempt limits.
- Spring Security reference: "Cross Site Request Forgery, Single-Page Applications".
