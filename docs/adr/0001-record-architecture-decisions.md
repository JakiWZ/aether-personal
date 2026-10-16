# ADR-0001: Record architecture decisions

- **Status:** Accepted
- **Date:** 2026-10-16
- **Issue:** #60

## Context and problem statement

The client requirements (capitolato §1.2, deliverable D-06) explicitly ask the team to *justify*
its choices: data model, constraints, backend structure, API contracts, security, deployment.
Decisions taken in chat or in someone's head are lost and cannot be reviewed.

## Decision

We record every architecturally significant decision as a Markdown ADR in `docs/adr/`, using the
[MADR](https://adr.github.io/madr/) structure (context → options → decision → consequences).

- Files are numbered sequentially: `NNNN-kebab-case-title.md`. Numbers are never reused.
- An ADR is added in the same PR that implements the decision.
- Accepted ADRs are immutable; to change a decision, write a new ADR that supersedes the old one
  and update the old one's status to `Superseded by ADR-XXXX`.

## Consequences

- Reviewers can evaluate the *why* next to the *what*.
- New contributors (and AI agents, via `CLAUDE.md`) can learn the architecture from `docs/adr/`.
- Small overhead per decision; acceptable given the explicit client requirement.
