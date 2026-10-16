# ADR-0006: Frontend architecture

- **Status:** Accepted
- **Date:** 2026-10-16
- **Issue:** #12 (TASK-006)

## Context and problem statement

TASK-006 asks for a runnable Angular base with routing, an understandable feature structure and a
backend URL that is not hardcoded in components. Five squads will add screens in parallel from
Sprint 2, so the structure must keep their work apart and make the shared rules (loading/empty/
error states, RFC 9457 errors, accessibility) easy to follow.

## Decision

- **Angular 22** (current major) created with the Angular CLI: standalone components, signals,
  **zoneless** change detection and `OnPush` everywhere (enforced by ESLint).
- **Structure by domain, not by type**: `core/` (singletons, no UI), `layout/` (shell),
  `shared/ui/` (presentational components), `features/<domain>/` with one lazy-loaded
  `<domain>.routes.ts` per backend domain (`colonies`, `missions`, `fleet`, `inventory`,
  `incidents`) plus `dashboard` (Mission Control).
- **Configuration**: `src/environments/*` → `APP_CONFIG` injection token. Locally the dev server
  proxies `/api` and `/actuator` to `localhost:8080`, so the SPA and API share an origin and the
  backend needs no CORS setup. Production expects the same layout behind a reverse proxy; a
  different host is a configuration change, not a code change (NFR-008).
- **Errors**: `toApiError()` turns any `HttpErrorResponse` into one `ApiError` shape. Problem
  Details bodies keep their stable `code` and `errors[]`; network failures and non-JSON bodies get
  client codes (`NETWORK_ERROR`, `UNEXPECTED_RESPONSE`) and a generic message, never raw HTML.
- **UI language**: English (`lang="en"`, default `en-US` locale), consistent with code and API
  messages. Texts stay in templates for now; extracting them with `@angular/localize` (NFR-011)
  is deferred until there is a second language to ship.
- **Accessibility** (NFR-010): skip link, labelled navigation with `aria-current`, page titles per
  route, visible focus, `angular-eslint` template accessibility rules in CI.
- **Tooling**: Vitest (Angular CLI default) with jsdom for unit tests, angular-eslint, Prettier.
  Node.js 24 LTS in CI (`frontend/.nvmrc`); Angular 22 needs Node ≥ 22.22.3.

## Consequences

- Positive: squads work in separate feature folders with separate lazy chunks; the shell and the
  domain list are shared in one place; tests prove the configured URL is used.
- Negative: zoneless requires signals or explicit change notification in components, so
  `setTimeout`-style mutations of plain fields will not refresh the view; reviewers watch for it.
- State management stays with signals and services; a store library will need its own ADR if the
  dashboard's cross-domain state outgrows that.
