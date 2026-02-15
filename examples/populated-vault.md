# Example: Populated Vault

This shows what a vault looks like after a few sessions of real work across two projects.

## File Tree

```
AgentMemory/
├── Home.md
├── projects/
│   ├── Projects.md
│   ├── my-api/
│   │   ├── my-api.md
│   │   ├── architecture/
│   │   │   └── Auth Migration to JWT.md
│   │   ├── components/
│   │   │   ├── Auth Middleware.md
│   │   │   ├── User Service.md
│   │   │   └── Database Layer.md
│   │   └── patterns/
│   │       └── Error Handling.md
│   └── my-frontend/
│       ├── my-frontend.md
│       ├── components/
│       │   ├── Login Form.md
│       │   └── Dashboard.md
│       └── patterns/
│           └── State Management.md
├── domains/
│   ├── Domains.md
│   ├── typescript/
│   │   └── TypeScript.md
│   ├── react/
│   │   └── React.md
│   └── postgresql/
│       └── PostgreSQL.md
├── patterns/
│   └── Universal Patterns.md
├── sessions/
│   ├── Session Log.md
│   ├── 2026-02-10 - API Auth Refactor.md
│   ├── 2026-02-12 - Frontend Login Flow.md
│   └── 2026-02-14 - Cross-Project Auth Integration.md
├── todos/
│   └── Active TODOs.md
└── templates/
    └── ...
```

## Example: Project Overview

```markdown
---
aliases: [my-api]
tags: [project/my-api]
repo: my-api
path: ~/code/my-api
language: TypeScript
framework: Express 4.x
created: 2026-02-10
---

# my-api

REST API for the platform. Express + TypeScript + PostgreSQL.

## Components

| Component | Notes |
|---|---|
| [[projects/my-api/components/Auth Middleware|Auth Middleware]] | JWT validation, rate limiting |
| [[projects/my-api/components/User Service|User Service]] | CRUD, password hashing, sessions |
| [[projects/my-api/components/Database Layer|Database Layer]] | Knex migrations, connection pooling |

## Project Patterns

| Pattern | Notes |
|---|---|
| [[projects/my-api/patterns/Error Handling|Error Handling]] | Centralized error classes, async wrapper |

## Architecture Decisions

- [[projects/my-api/architecture/Auth Migration to JWT|Auth Migration to JWT]] — Moving from session cookies to JWT

## Domains

This project spans: [[domains/typescript/TypeScript|TypeScript]], [[domains/postgresql/PostgreSQL|PostgreSQL]]
```

## Example: Component Note

```markdown
---
tags: [components, project/my-api]
project: "[[projects/my-api/my-api]]"
created: 2026-02-10
---

# Auth Middleware

JWT validation middleware for Express routes.

## Key Files

- `src/middleware/auth.ts` — Main middleware, token extraction
- `src/middleware/auth.test.ts` — Unit tests
- `src/config/jwt.ts` — Secret rotation config

## Dependencies

### Depends On
- [[projects/my-api/components/User Service|User Service]] — Token payload includes user role from User Service
- [[domains/typescript/TypeScript|TypeScript]] — Uses discriminated unions for auth result types

### Depended On By
- [[projects/my-frontend/components/Login Form|Login Form]] — Consumes JWT tokens this middleware validates

## Gotchas
- Token refresh window is 5 minutes before expiry — see `REFRESH_WINDOW_MS` in jwt.ts
- Rate limiter shares state via Redis, not in-memory — fails open if Redis is down
```

## Example: Session Note

```markdown
---
tags: [sessions, project/my-api, project/my-frontend]
projects:
  - "[[projects/my-api/my-api]]"
  - "[[projects/my-frontend/my-frontend]]"
created: 2026-02-14
branch: feat/jwt-auth
---

# 2026-02-14 — Cross-Project Auth Integration

## Context

Wiring JWT auth from [[projects/my-api/my-api|my-api]] into [[projects/my-frontend/my-frontend|my-frontend]].

## Work Done

1. Added token refresh interceptor to frontend API client
2. Fixed CORS headers for Authorization header passthrough
3. Updated [[projects/my-frontend/components/Login Form|Login Form]] to store JWT in httpOnly cookie

## Discoveries

- Express CORS middleware doesn't expose `Authorization` by default — need `exposedHeaders: ['Authorization']`
- Frontend interceptor must queue concurrent requests during refresh to avoid race conditions

## Decisions

- Store JWT in httpOnly cookie (not localStorage) for XSS protection
- Refresh token rotation: each refresh invalidates the previous token

## Next Steps

- [ ] Add token revocation endpoint to API
- [ ] Wire up logout flow in frontend
```

## Graph Traversal Example

Starting from `Auth Middleware`, the agent can reach:

```
Auth Middleware
├──→ User Service (depends on)
├──→ Login Form (depended on by — cross-project!)
├──→ TypeScript domain (language patterns)
├──→ Auth Migration to JWT (architecture decision, via project overview)
└──→ Session 2026-02-14 (recent work context, via backlinks)
```

Each hop is one file read. The agent only follows links relevant to the current task.
