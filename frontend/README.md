# AETHER frontend

Angular 22 · standalone components · signals · zoneless · OnPush · Vitest · ESLint.
Decisions: [ADR-0002](../docs/adr/0002-technology-stack.md), [ADR-0006](../docs/adr/0006-frontend-architecture.md).

## Run locally

Prerequisites: Node.js 24 LTS (see `.nvmrc`; Angular 22 also accepts Node ≥ 22.22.3).

```bash
cd frontend
npm ci
npm start          # http://localhost:4200
```

`npm start` forwards `/api` and `/actuator` to the backend on `http://localhost:8080`
(`proxy.conf.json`), so start the backend first (see [`backend/README.md`](../backend/README.md)).
Without it the app still runs and the header shows "Backend unreachable".

## Scripts

| Command                | What                                                                   |
| ---------------------- | ---------------------------------------------------------------------- |
| `npm start`            | Dev server with live reload and API proxy                              |
| `npm run build`        | Production build in `dist/aether-frontend`                             |
| `npm test`             | Unit tests once (Vitest + jsdom); `npm run test:watch` for watch mode  |
| `npm run lint`         | ESLint (angular-eslint, template accessibility rules, OnPush enforced) |
| `npm run format:check` | Prettier check (`npm run format` fixes)                                |

CI runs `lint`, `format:check`, `test` and `build`.

## Configuration

Backend URLs live **only** in `src/environments/` and reach code through the `APP_CONFIG`
injection token (`core/config/app-config.ts`). Components and services never hardcode them.

| Key          | Default            | Meaning                 |
| ------------ | ------------------ | ----------------------- |
| `apiBaseUrl` | `/api/v1`          | REST API base URL       |
| `healthUrl`  | `/actuator/health` | Backend health endpoint |

Production assumes the SPA and the API share an origin behind a reverse proxy; to target another
host change `environment.ts`, not the code.

## Code layout

```text
src/app/
  core/          app-wide singletons, no UI
    auth/          session, login/logout, route guards, 401 interceptor (ADR-0012)
    config/        APP_CONFIG token
    http/          RFC 9457 Problem Details → ApiError mapping (ADR-0005)
    health/        backend health check
    navigation/    domain list, page-title strategy
  layout/        shell (header, navigation, skip link) and backend status indicator
  shared/ui/     reusable presentational components
  features/      one lazy-loaded folder per domain, mirroring backend packages
    dashboard/     Mission Control (CROSS)
    colonies/      ARES       missions/   PHOENIX     fleet/   TITAN
    inventory/     ORION      incidents/  HELIOS      not-found/
    login/         sign-in page
  testing/       test helpers (test config, page envelope, `signIn`)
```

A feature exposes a `<feature>.routes.ts` with its routes; `app.routes.ts` lazy-loads it with
`loadChildren`. New screens go inside their feature folder (`<feature>/pages`, `<feature>/data`
for API services), never in `core`.

Rules from [`CLAUDE.md`](../CLAUDE.md): every data view handles loading, empty and error states;
forms are typed reactive forms; server errors are shown through `toApiError()`; client validation is
for UX only.
