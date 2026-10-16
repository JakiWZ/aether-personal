# ADR-0009: Supply chain controls in CI

- **Status:** Accepted
- **Date:** 2026-10-16
- **Issue:** #88

## Context and problem statement

OWASP Top 10:2025 adds *A03 Software Supply Chain Failures*, and ASVS 5.0 (V15, secure coding
and architecture) asks for an inventory of components and timely updates. The 2026-10-16
security review found that we already had
Dependabot and lockfile installs, but no static analysis, no gate on vulnerable dependencies,
GitHub Actions referenced by mutable tags, and a Maven wrapper that downloaded Maven without
verifying it.

## Considered options

1. Keep Dependabot only.
2. **GitHub-native controls**: CodeQL, dependency review, actions pinned by commit SHA, checksum
   for the Maven distribution.
3. Third-party scanners (OWASP Dependency-Check, Snyk, Sonar).

## Decision

Option 2, because the repository is public and these controls are free, maintained by GitHub and
need no secrets.

- **CodeQL** (`codeql.yml`) analyses Java and TypeScript with the `security-extended` query suite
  on every pull request, on `main` and weekly. Build mode `none`, so it does not depend on the
  Maven build.
- **Dependency review** (`dependency-review.yml`) fails a pull request that adds a dependency with
  a known vulnerability of severity `high` or `critical`.
- **Actions pinned by full commit SHA**, with the tag as a comment (`@<sha> # v7`). A tag can be
  moved by whoever controls the action repository; a SHA cannot. Dependabot keeps updating them.
- **Maven wrapper** verifies `distributionSha256Sum` (cross-checked against the SHA-1 and
  SHA-512 published on Maven Central) before running the downloaded Maven.
- Local Docker Compose publishes PostgreSQL on `127.0.0.1` only.

Option 3 adds accounts, tokens or long NVD downloads to every build for little gain over CodeQL
plus the GitHub Advisory Database. It can be reconsidered for the container images (FUT-703).

## Consequences

- Findings appear in the repository's *Security → Code scanning* tab; a new high alert on a pull
  request is treated like a failing test.
- Bumping Maven means updating `distributionUrl` and `distributionSha256Sum` together.
