# ADR-0011: Paginated list endpoints

- **Status:** Accepted
- **Date:** 2026-10-16
- **Issue:** #92

## Context and problem statement

`GET /colonies`, `/crew-members` and `/missions` returned whole tables as JSON arrays. That breaks
NFR-003/NFR-004 as data grows and is OWASP API Security Top 10 2023 API4 (*Unrestricted Resource
Consumption*): one request could make the server load and serialise every row. The search
stories (PHX-206, ARES-106) need a list contract to build on.

## Considered options

1. Keep arrays and add `Link` headers (RFC 8288) for the next page.
2. Spring Data's `PagedModel` (`{content, page:{size, number, totalElements, totalPages}}`).
3. **A small page envelope of our own**, `{items, page, size, totalItems, totalPages}`.

## Decision

Option 3: one shape for every list endpoint, documented in OpenAPI by a plain record
(`PageResponse`), with no Spring Data type in the API contract and no headers to parse.

- Query parameters `page` (zero-based, at most 10 000) and `size` (default 20, at most 100),
  bound to `PageQuery` and validated: out of range or not a number is `400 VALIDATION_FAILED`.
  The server never returns more than 100 items per request.
- Each endpoint keeps its documented, stable order (code, or planned start then code), so pages
  do not overlap. A page past the last one is `200` with no items and the real totals.
- Paging happens in the database (`LIMIT/OFFSET` plus a `count`). Collections are never fetched
  together with a limit (Hibernate would page in memory). Mission objectives are batch-loaded for
  the whole page in one query (`@BatchSize`).
- The frontend shows a shared `Pager` (previous / next, "page x of y") under each table. Base
  dropdowns ask for the largest page (100), which covers the planned number of bases. A real
  autocomplete replaces them if that ever stops being true.

## Consequences

- Breaking change for API clients that expected an array; the only client is our frontend,
  changed in the same pull request.
- Deep offsets stay bounded (`page` ≤ 10 000); large result sets are narrowed with filters
  (search stories), not by paging further.
- Sorting chosen by the client and keyset pagination are left to the stories that need them.
