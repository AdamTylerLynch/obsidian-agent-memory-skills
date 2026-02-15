---
name: obs-memory
description: "Persistent Obsidian-based memory for coding agents. Use at session start to orient from a knowledge vault, during work to look up architecture/component/pattern notes, and when discoveries are made to write them back. Activate when the user mentions Obsidian vault, agent memory, session notes, knowledge graph, or project architecture. Provides commands: init, end, project, note, todo, lookup."
metadata:
  author: adamtylerlynch
  version: "1.1"
license: MIT
---

# Obsidian Agent Memory

You have access to a persistent Obsidian knowledge vault — a graph-structured memory that persists across sessions. Use it to orient yourself, look up architecture and component knowledge, and write back discoveries.

For detailed step-by-step procedures for each command, see [commands reference](references/commands.md).

## Vault Discovery

Resolve the vault path using this chain (first match wins):

1. **Environment variable**: `$OBSIDIAN_VAULT_PATH`
2. **Agent config reference**: Parse the vault path from the agent's project or global config (look for "Obsidian Knowledge Vault" section with a path like `~/Documents/SomeName/`)
3. **Default**: `~/Documents/AgentMemory`

Store the resolved path as `$VAULT` for all subsequent operations.

Verify the vault exists by checking for `$VAULT/Home.md`. If the vault doesn't exist, inform the user and suggest running the `init` command to bootstrap a new vault from the bundled template.

## Session Start — Orientation

At the start of every session, orient yourself with **at most 2 file reads**:

### Step 1: Read TODOs

Read the file at `$VAULT/todos/Active TODOs.md`. Know what's pending, in-progress, and recently completed.

### Step 2: Detect current project and read its overview

Auto-detect the project from the current working directory:
```bash
basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename $(pwd)
```

Then check if a matching project exists by listing files in `$VAULT/projects/*/`. Match the git repo name (or directory name) against project folder names. If a match is found, read the project overview at `$VAULT/projects/{matched-name}/{matched-name}.md`.

This project overview contains wikilinks to all components, patterns, architecture decisions, and domains. **Do not read those linked notes yet** — follow them on demand when the current task requires that context.

### What NOT to read at session start
- `Home.md` (only if you're lost and can't find the project)
- `sessions/` (only if the user references prior work)
- Domain indexes (only if you need cross-project knowledge)
- Component notes (only when working on that component)

## During Work — Graph Navigation

**Principle: Navigate the graph, don't dump the vault.** Each note contains wikilinks to related notes. Follow links only when the current task requires that context.

### Follow links, don't bulk-read
- Need to understand a component? The project overview links to it. Read that one note.
- Need an architecture decision? The component note or project overview links to it. Follow the link.
- Need cross-project knowledge? Component/pattern notes link to domain notes. Follow the link.
- Need session history? Only read if you're stuck or the user references prior work.

### Frontmatter-first scanning
When you need to scan multiple notes to find the right one, read just the first ~10 lines of each file. The `tags`, `project`, and `status` fields in the frontmatter tell you if the note is relevant before reading the full body.

### Use Obsidian CLI for targeted lookups
Instead of reading files, use the CLI when available:
```bash
obsidian vault=$VAULT_NAME backlinks file="Component Name"
obsidian vault=$VAULT_NAME tags name="project/short-name"
obsidian vault=$VAULT_NAME search query="search term"
obsidian vault=$VAULT_NAME file path="projects/name/name.md"
```
Where `$VAULT_NAME` is the vault folder name (basename of `$VAULT`).

### Directory listing before reading
List directory contents before reading files — know what exists without consuming tokens:
- `$VAULT/projects/{name}/**/*.md` — all notes for a project
- `$VAULT/domains/{tech}/*.md` — domain knowledge files

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

## Commands

The following commands are available for vault management. For detailed step-by-step procedures, see [commands reference](references/commands.md).

### `init` — Initialize the Vault

Bootstrap a new Obsidian Agent Memory vault from the bundled template.

Usage: `init [path]`

1. Determine vault path from the argument or the vault resolution chain (default: `~/Documents/AgentMemory`)
2. Check if a vault already exists at that path
3. Locate the bundled `vault-template/` directory relative to this skill package
4. Copy the template contents to the vault path
5. Create Obsidian config directory (`.obsidian/`) with default settings
6. Create empty `inbox/` and `attachments/` directories
7. Report the created vault with next steps (open in Obsidian, configure the vault path)

### `end` — Write Session Summary

Write a session summary note and update TODOs based on what was accomplished.

Usage: `end`

1. Gather context from git log, diffs, and current branch
2. Read current TODOs and project overview
3. Write a session note at `$VAULT/sessions/{date} - {title}.md` with: Context, Work Done, Discoveries, Decisions, Next Steps
4. Update `$VAULT/todos/Active TODOs.md` — move completed items, add new ones
5. Add an entry to `$VAULT/sessions/Session Log.md`

### `project` — Scaffold New Project

Create a new project structure in the vault.

Usage: `project [name]` (defaults to current git repo or directory name)

1. Check if the project already exists in the vault
2. Create directory structure: `projects/{name}/`, with `architecture/`, `components/`, `patterns/` subdirectories
3. Create a project overview at `projects/{name}/{name}.md` with auto-detected language, repo URL, and domain links
4. Update the project index at `projects/Projects.md`

### `note` — Create a Note from Template

Create a note using a template.

Usage: `note <component|adr|pattern> [name]`

- **`note component [name]`** — Create at `projects/$PROJECT/components/{name}.md`
- **`note adr [title]`** — Create at `projects/$PROJECT/architecture/ADR-{NNNN} {title}.md` (auto-numbered)
- **`note pattern [name]`** — Create at `projects/$PROJECT/patterns/{name}.md`

After creating any note, link it from the project overview.

### `todo` — Manage TODOs

View and update the Active TODOs for the current project.

Usage: `todo [action]`

- No arguments: Display current TODOs for the project
- Plain text: Add as a new pending item
- `done: <text>`: Move matching item to Completed
- `remove: <text>`: Remove matching item

### `lookup` — Search the Vault

Search the vault for knowledge.

Usage: `lookup <query>`

1. Search file contents matching the query across all `.md` files in `$VAULT`
2. If the query looks like a tag (starts with `#` or `project/`), search by tags
3. If the query matches a note name, search by backlinks
4. Present results with frontmatter context so the user can choose which to read in full

## Token Budget Rules

1. **Session start**: Read at most 2 files (TODOs + project overview)
2. **During work**: Follow wikilinks on demand — never read more than the task requires
3. **Frontmatter first**: When scanning, read ~10 lines before committing to full read
4. **CLI over reads**: Use `obsidian` CLI for backlinks, tags, and search when available
5. **List before read**: List directory contents before reading files
6. **Write concisely**: Bullet points, links, tags — no prose when bullets suffice

## Error Handling

- If the vault doesn't exist → suggest running the `init` command to bootstrap it
- If the project doesn't exist in the vault → offer to run `project` to scaffold it
- If a note already exists → show it instead of overwriting, offer to edit
- If no git repo is detected → use current directory name as project name

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
