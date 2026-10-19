# ADR-001: Monorepo Structure

## Status
Accepted

## Date
2026-10-06

## Context
CivicPulse comprises three distinct applications (Spring Boot backend, Flutter
mobile app, React admin dashboard) plus shared infrastructure (Docker, DB
migrations). We need to decide between a monorepo and multiple separate
repositories.

## Decision
We will use a **single monorepo** containing all three applications as sibling
directories, along with shared infrastructure and documentation.

```
smartcity/
├── civicpulse-backend/
├── civicpulse-app/
├── civicpulse-admin/
├── infrastructure/
└── docs/
```

## Rationale
1. **Atomic cross-cutting changes**: Database schema changes often require
   coordinated updates across backend DTOs and mobile/web models. A monorepo
   allows these to be in a single commit/PR.
2. **Shared Docker Compose**: One `docker-compose.yml` at the root starts all
   services, simplifying local development.
3. **Documentation co-location**: Architecture docs, ADRs, and API specs stay
   adjacent to the code they describe.
4. **CI simplicity**: A single CI pipeline can detect which sub-project changed
   and run only the relevant test suite (path-based triggers).
5. **Team size**: For a team of 1–5 developers, the overhead of multiple repos
   (cross-repo PRs, version pinning) outweighs the benefits.

## Consequences
- CI must use path-based triggering to avoid rebuilding all three projects on
  every commit.
- `.gitignore` must cover Java, Dart, and Node.js artifacts.
- Contributors must be careful with Git operations that affect the entire repo
  (e.g., large rebases).
