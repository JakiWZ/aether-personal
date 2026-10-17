# ADR-0013: Security response headers and API documentation only in development

- **Status:** Accepted
- **Date:** 2026-10-17
- **Issue:** #95

## Context and problem statement

The security review found two gaps.
- **Security headers.** Spring Security already sends `X-Content-Type-Options`,
  `X-Frame-Options: DENY`, `Cache-Control: no-store`, and HSTS on HTTPS requests. The backend
  sends no `Content-Security-Policy`, `Referrer-Policy` or `Permissions-Policy`. OWASP Top 10:2025
  A02 (Security Misconfiguration), the OWASP Secure Headers Project and ASVS 5.0 V3.4 ask for these.
- **API documentation.** The OpenAPI description and Swagger UI are public in every environment.
  OWASP API Security Top 10 2023 lists improper inventory management (API9) and security
  misconfiguration (API8): a published API map helps attackers and is not needed outside
  development.

## Decision

**Headers on every backend response** (`SecurityConfig#securityHeaders`):

| Header | Value | Why |
|--------|-------|-----|
| `Content-Security-Policy` | `default-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'` | Responses are JSON: a browser rendering one must load, run and embed nothing |
| `Referrer-Policy` | `no-referrer` | URLs never leak to other sites |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=(), payment=(), usb=()` | Turns off features the app never uses |
| `Cross-Origin-Opener-Policy` / `Cross-Origin-Resource-Policy` | `same-origin` | Isolates the app from other origins (same-origin deployment, ADR-0012) |
| `Strict-Transport-Security` | `max-age=31536000 ; includeSubDomains` (HTTPS requests only) | Browsers stay on HTTPS |

The Spring Security defaults stay, including `X-XSS-Protection: 0`, which OWASP recommends now
that browsers no longer have an XSS filter.

The Swagger UI page is the only HTML the backend serves. It gets
`default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; object-src 'none';
frame-ancestors 'none'; base-uri 'none'`, which lets it load its bundled assets and nothing else.
A browser check shows no CSP violations.

**API documentation only where asked for.** `springdoc.api-docs.enabled` and
`springdoc.swagger-ui.enabled` default to `false` (`AETHER_API_DOCS_ENABLED`). The `dev` profile
(`application-dev.yml`) turns them on. With the documentation off, `/v3/api-docs` and the Swagger
UI answer 404.

**SPA served in production.** The reverse proxy that serves the Angular build must send its own
policy. Recommended:

```
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';
  img-src 'self' data:; connect-src 'self'; object-src 'none'; frame-ancestors 'none';
  base-uri 'self'; form-action 'self'
```

Two caveats:
- Angular adds component styles at runtime, so `style-src` needs `'unsafe-inline'`, or a nonce
  passed through `ngCspNonce`.
- The build's critical-CSS step inlines one small `<script>`. Either allow it by hash or disable
  `optimization.styles.inlineCritical` before enabling a `script-src 'self'` policy.

The proxy also sends HSTS for the SPA. Writing that configuration is part of the deployment work,
not this decision.

## Consequences

- Good: a strict default policy is in place; new endpoints get the headers without extra work;
  the API map is not public by default.
- Bad: developers must use the `dev` profile, or set `AETHER_API_DOCS_ENABLED=true`, to see
  Swagger UI. HSTS behind a TLS-terminating proxy needs forwarded headers (or the proxy itself) to
  take effect.

## References

- OWASP Top 10:2025 A02; OWASP API Security Top 10 2023 API8, API9.
- OWASP Secure Headers Project; OWASP HTTP Headers and Content Security Policy Cheat Sheets.
- OWASP ASVS 5.0 V3.4 (browser security mechanism headers).
- Angular security guide: Content Security Policy.
