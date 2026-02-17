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
type: project
repo: my-api
path: ~/code/my-api
language: TypeScript
framework: Express 4.x
created: 2026-02-10
status: active
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
type: component
project: "[[projects/my-api/my-api]]"
created: 2026-02-10
status: active
layer: middleware
depends-on:
  - "[[projects/my-api/components/User Service|User Service]]"
depended-on-by:
  - "[[projects/my-frontend/components/Login Form|Login Form]]"
key-files:
  - src/middleware/auth.ts
  - src/middleware/auth.test.ts
  - src/config/jwt.ts
---

# Auth Middleware

JWT validation middleware for Express routes.

## Purpose

Extracts and validates JWT tokens from incoming requests. Attaches decoded user context to the request object. Handles token refresh within the refresh window.

## Gotchas

- Token refresh window is 5 minutes before expiry — see `REFRESH_WINDOW_MS` in jwt.ts
- Rate limiter shares state via Redis, not in-memory — fails open if Redis is down
```

## Example: Session Note

```markdown
---
tags: [sessions, project/my-api, project/my-frontend]
type: session
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

## CLI-Based Graph Traversal

Starting from `Auth Middleware`, the agent can reach all related notes using CLI queries:

```bash
# What does Auth Middleware depend on?
$ obsidian vault=AgentMemory property:read file="Auth Middleware" name="depends-on"
→ ["[[projects/my-api/components/User Service|User Service]]"]

# What depends on Auth Middleware?
$ obsidian vault=AgentMemory property:read file="Auth Middleware" name="depended-on-by"
→ ["[[projects/my-frontend/components/Login Form|Login Form]]"]

# What are the key source files?
$ obsidian vault=AgentMemory property:read file="Auth Middleware" name="key-files"
→ ["src/middleware/auth.ts", "src/middleware/auth.test.ts", "src/config/jwt.ts"]

# What links to Auth Middleware? (catches references not in properties)
$ obsidian vault=AgentMemory backlinks file="Auth Middleware"
→ projects/my-api/my-api.md
→ sessions/2026-02-14 - Cross-Project Auth Integration.md

# Full relationship view
$ obsidian vault=AgentMemory links file="Auth Middleware"
→ projects/my-api/components/User Service.md
→ projects/my-frontend/components/Login Form.md
→ projects/my-api/my-api.md
```

Each CLI call returns targeted data without reading the full note. The agent only reads a file when it needs the body content (Purpose, Gotchas, etc.).

## Command Examples

### `relate` — Creating relationships

```
# Create a dependency: Auth Middleware depends on User Service
> relate "Auth Middleware" "User Service"

Reading depends-on for Auth Middleware...
Current: []
Setting depends-on to: ["[[projects/my-api/components/User Service|User Service]]"]
Setting depended-on-by on User Service to: ["[[projects/my-api/components/Auth Middleware|Auth Middleware]]"]
✓ Auth Middleware → depends-on → User Service (bidirectional)

# Show all relationships for a component
> relate show "Auth Middleware"

depends-on:
  - User Service
depended-on-by:
  - Login Form
links: my-api (project), User Service, Login Form
backlinks: my-api (project overview), Session 2026-02-14

# Walk the dependency tree
> relate tree "Login Form" 2

Login Form
├── Auth Middleware (depends-on)
│   └── User Service (depends-on)
└── Dashboard (related via backlinks)
```

### `lookup` — Searching the vault

```
# Find all components in my-api
> lookup type component my-api

Auth Middleware (middleware layer)
User Service (service layer)
Database Layer (data layer)

# Find dependencies of a component
> lookup deps "Auth Middleware"

depends-on:
  - User Service — Token payload includes user role

# Find what uses a component
> lookup consumers "User Service"

depended-on-by:
  - Auth Middleware
backlinks:
  - Session 2026-02-14

# Search for JWT-related knowledge
> lookup JWT

projects/my-api/components/Auth Middleware.md (3 matches)
projects/my-api/architecture/Auth Migration to JWT.md (5 matches)
sessions/2026-02-14 - Cross-Project Auth Integration.md (2 matches)
```
