---
description: "Use proactively at session start to orient from persistent memory, during work to look up architecture/component/pattern notes, and when discoveries are made to write them to the vault. Activate whenever the working directory matches a project in the Obsidian vault."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(obsidian:*), Bash(git rev-parse:*), Bash(basename:*)
---

# Obsidian Agent Memory

You have access to a persistent Obsidian knowledge vault — a graph-structured memory that persists across sessions. Use it to orient yourself, look up architecture and component knowledge, and write back discoveries.

## Vault Discovery

Resolve the vault path using this chain (first match wins):

1. **Environment variable**: `$OBSIDIAN_VAULT_PATH`
2. **CLAUDE.md reference**: Parse the vault path from the project or global CLAUDE.md (look for "Obsidian Knowledge Vault" section with a path like `~/Documents/SomeName/`)
3. **Default**: `~/Documents/AgentMemory`

Store the resolved path as `$VAULT` for all subsequent operations.

Verify the vault exists before proceeding:
```
Glob: $VAULT/Home.md
```
If the vault doesn't exist, inform the user and suggest running the setup from https://github.com/tyler-lynch/obsidian-agent-memory.

## Session Start — Orientation

At the start of every session, orient yourself with **at most 2 file reads**:

### Step 1: Read TODOs
```
Read: $VAULT/todos/Active TODOs.md
```
Know what's pending, in-progress, and recently completed.

### Step 2: Detect current project and read its overview

Auto-detect the project from the current working directory:
```bash
basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename $(pwd)
```

Then check if a matching project exists in the vault:
```
Glob: $VAULT/projects/*/*.md
```

Match the git repo name (or directory name) against `projects/*/` folder names. If a match is found:
```
Read: $VAULT/projects/{matched-name}/{matched-name}.md
```

This project overview contains wikilinks to all components, patterns, architecture decisions, and domains. **Do not read those linked notes yet** — follow them on demand when the current task requires that context.

### What NOT to read at session start
- `Home.md` (only if you're lost and can't find the project)
- `sessions/` (only if the user references prior work)
- Domain indexes (only if you need cross-project knowledge)
- Component notes (only when working on that component)

## During Work — Graph Navigation

**Principle: Navigate the graph, don't dump the vault.** Each note contains wikilinks to related notes. Follow links only when the current task requires that context.

### Follow links, don't glob
- Need to understand a component? The project overview links to it. Read that one note.
- Need an architecture decision? The component note or project overview links to it. Follow the link.
- Need cross-project knowledge? Component/pattern notes link to domain notes. Follow the link.
- Need session history? Only read if you're stuck or the user references prior work.

### Frontmatter-first scanning
When you need to scan multiple notes to find the right one, read just the frontmatter first:
```
Read: $VAULT/projects/{name}/components/{note}.md  (limit=10)
```
The `tags`, `project`, and `status` fields tell you if the note is relevant before reading the full body.

### Use Obsidian CLI for targeted lookups
Instead of reading files, use the CLI when available:
```bash
# What links to this component?
obsidian vault=$VAULT_NAME backlinks file="Component Name"

# All notes tagged for a project
obsidian vault=$VAULT_NAME tags name="project/short-name"

# Search note content without reading files
obsidian vault=$VAULT_NAME search query="search term"

# Note metadata
obsidian vault=$VAULT_NAME file path="projects/name/name.md"
```

Where `$VAULT_NAME` is the vault folder name (basename of `$VAULT`).

### Use Glob for directory listings
Know what exists without consuming tokens:
```
Glob: $VAULT/projects/{name}/**/*.md    → all notes for a project
Glob: $VAULT/domains/{tech}/*.md        → domain knowledge files
```

## Writing to the Vault

Write concisely. Notes are for your future context, not human documentation. Prefer:
- Bullet points over prose
- Wikilinks over repeated explanations (link to it, don't re-state it)
- Frontmatter tags for discoverability over verbose descriptions

### When to write
- **New component discovered**: Create a component note when you deeply understand a part of the codebase
- **Architecture decision made**: Record ADRs when significant design choices are made
- **Pattern identified**: Document recurring patterns that future sessions should follow
- **Domain knowledge learned**: Write to domain notes when you discover cross-project knowledge

### Scoping rules
| Knowledge type | Location | Example |
|---|---|---|
| One project only | `projects/{name}/` | How this API handles auth |
| Shared across projects | `domains/{tech}/` | How Go interfaces work |
| Universal, tech-agnostic | `patterns/` | SOLID principles |
| Session summaries | `sessions/` | What was done and discovered |
| TODOs | `todos/Active TODOs.md` | Grouped by project |

### Frontmatter conventions
Always include in new notes:
```yaml
---
tags: [category, project/short-name]
project: "[[projects/{name}/{name}]]"
created: YYYY-MM-DD
---
```

### Wikilink conventions
- Link to related notes: `[[projects/{name}/components/Component Name|Component Name]]`
- Link to domains: `[[domains/{tech}/{Tech Name}|Tech Name]]`
- Link back to project: `[[projects/{name}/{name}|project-name]]`

### Note templates

**Component Note:**
```yaml
---
tags: [components, project/{short-name}]
project: "[[projects/{name}/{name}]]"
created: {date}
---
```
Sections: Purpose, Key Files, Dependencies (Depends On / Depended On By), Gotchas

**Architecture Decision:**
```yaml
---
tags: [architecture, decision, project/{short-name}]
project: "[[projects/{name}/{name}]]"
status: proposed | accepted | superseded
created: {date}
---
```
Sections: Context, Decision, Alternatives Considered, Consequences

**Session Note:**
```yaml
---
tags: [sessions]
projects:
  - "[[projects/{name}/{name}]]"
created: {date}
branch: {branch-name}
---
```
Sections: Context, Work Done, Discoveries, Decisions, Next Steps

## Token Budget Rules

1. **Session start**: Read at most 2 files (TODOs + project overview)
2. **During work**: Follow wikilinks on demand — never read more than the task requires
3. **Frontmatter first**: When scanning, read 10 lines before committing to full read
4. **CLI over reads**: Use `obsidian` CLI for backlinks, tags, and search when available
5. **Glob before read**: List directory contents before reading files
6. **Write concisely**: Bullet points, links, tags — no prose when bullets suffice

## Vault Structure Reference
```
$VAULT/
├── Home.md                           # Dashboard (read only if lost)
├── projects/{name}/
│   ├── {name}.md                     # Project overview — START HERE
│   ├── architecture/                 # ADRs and design decisions
│   ├── components/                   # Per-component notes
│   └── patterns/                     # Project-specific patterns
├── domains/{tech}/                   # Cross-project knowledge
├── patterns/                         # Universal patterns
├── sessions/                         # Session logs (read only when needed)
├── todos/Active TODOs.md             # Pending work (read at session start)
├── templates/                        # Note templates
└── inbox/                            # Unsorted
```
