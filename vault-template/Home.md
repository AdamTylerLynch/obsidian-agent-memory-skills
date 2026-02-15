---
aliases: [MOC, Index, Dashboard]
tags: [meta/index]
created: {{date}}
---

# Agent Memory

Persistent knowledge graph for coding agent sessions.

## Navigation

### Active Work
- [[todos/Active TODOs]] — Current work items and blockers
- [[sessions/Session Log]] — Chronological session notes

### Projects
- [[projects/Projects]] — All projects by status

### Domains
- [[domains/Domains]] — Cross-cutting technical knowledge

### Patterns
- [[patterns/Universal Patterns]] — Language/framework-agnostic patterns

## Structure

```
projects/{name}/          → Project-scoped: architecture, components, patterns
domains/{tech}/           → Cross-project domain knowledge
patterns/                 → Universal patterns (SOLID, testing strategies, etc.)
sessions/                 → Chronological session logs (tagged by project)
todos/                    → Active work items (tagged by project)
```

## Conventions

- **Project-scoped knowledge** lives under `projects/{name}/`
- **Domain knowledge** lives under `domains/{tech}/`
- **Universal patterns** live under `patterns/`
- **Wikilinks** for all cross-references: `[[note name]]`
- **Tags** include project scope: `#project/{short-name}`, `#domain/{tech}`
- **Frontmatter** on every note: `created`, `tags`, `project`
