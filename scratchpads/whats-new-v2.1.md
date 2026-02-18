# obs-memory v2.1 — Shorter Command, Smarter Behaviors, Single Source of Truth

Your agent's memory just got a UX upgrade.

## `/obs-memory` is now `/obs`

Six fewer characters, same power. Every command you know works the same way — just shorter.

```
/obs recap
/obs lookup deps AuthMiddleware
/obs relate show SessionStore
```

## `end` is now `recap`

We renamed the session summary command because "end" sounds like you're terminating something. `recap` says what it actually does — look back at the session and write it down.

```
/obs recap
```

Your agent will gather your git history, write a session note to the vault, and update your TODOs.

## Automatic Behaviors

The biggest change in v2.1 is what your agent does *without being asked*.

**Session start** — Your agent now auto-orients from the vault the moment a session begins. No `/obs` command needed. It reads your TODOs and project overview automatically so it has full context before you even ask your first question.

**Session end detection** — Say "done", "wrapping up", or "that's it" and your agent will offer to write a recap. It asks first — it won't surprise you with vault writes.

**Component discovery** — When your agent deeply analyzes a component that doesn't have a vault note, it'll offer to create one and map its dependencies from the code. Your knowledge graph grows organically as you work.

**First run** — No more manual setup. If the vault doesn't exist, your agent walks you through `init` and auto-scaffolds the current project. One conversation, zero config files to edit.

## Relationship Engine

Your vault notes can now track typed, bidirectional relationships between components — and your agent manages both sides automatically.

```
/obs relate AuthMiddleware SessionStore              # depends-on (default)
/obs relate AuthMiddleware OAuth2Provider implements  # typed relationship
/obs relate show AuthMiddleware                       # view all connections
/obs relate tree AuthMiddleware 3                     # dependency tree, 3 levels deep
```

Four relationship types, each with a forward and inverse property:

| You write | Source gets | Target gets |
|---|---|---|
| `relate A B` | `depends-on: [[B]]` | `depended-on-by: [[A]]` |
| `relate A B extends` | `extends: [[B]]` | `extended-by: [[A]]` |
| `relate A B implements` | `implements: [[B]]` | `implemented-by: [[A]]` |
| `relate A B consumes` | `consumes: [[B]]` | `consumed-by: [[A]]` |

`relate tree` walks the graph via BFS — give it a component name and a depth, and it traces the full dependency chain as an indented tree.

## Structured Lookups

`lookup` is no longer just freetext search. It now has targeted subcommands that query your vault's graph structure:

```
/obs lookup deps AuthMiddleware        # what does it depend on?
/obs lookup consumers AuthMiddleware   # what depends on it?
/obs lookup related AuthMiddleware     # all connections, both directions
/obs lookup type component my-app      # all components in a project
/obs lookup layer api                  # all API-layer components
/obs lookup files AuthMiddleware       # key source files for a component
/obs lookup PKCS12                     # freetext still works
```

Every subcommand uses the Obsidian CLI first (property reads, backlinks, tag queries) and falls back to file reads when the CLI isn't available. This means faster, more targeted results with less token overhead.

## CLI-First Traversal

All vault operations now prefer the Obsidian CLI over file reads. Instead of reading an entire component note to find its dependencies, the agent runs:

```bash
obsidian vault=MyVault property:read file="AuthMiddleware" name="depends-on"
```

This returns just the data needed — no parsing, no wasted tokens. CLI-first applies to property reads, backlinks, outgoing links, tag queries, content search, and note outlines. File reads are the fallback, not the default.

## Enhanced `init`

Speaking of first run — `init` now does more:

- Auto-scaffolds the current project if you're in a git repo
- Generates a config snippet for your agent (CLAUDE.md, env var, etc.)
- Outputs 5-8 lines instead of a wall of text

## Under the Hood: Single Source of Truth

We eliminated ~500 lines of duplication. Previously, command procedures were maintained in three places (SKILL.md summaries, references/commands.md, and the Claude Code command file). Now:

- **`SKILL.md`** — one file with everything (666 lines, down from ~1,233 across 3 files)
- **`obs.md`** — 37-line dispatch table, no duplicated logic

This means faster updates, no drift between agents, and a cleaner package.

## Tighter Activation

The skill no longer activates on generic phrases like "knowledge graph" or "project architecture." It now requires the word **"obsidian"** — as in "obsidian vault", "obsidian memory", or "obsidian notes." This prevents false activations when you're talking about graphs or architecture in general.

## Breaking Changes

If you're upgrading from v2.0:

- `/obs-memory` → `/obs` (old command won't resolve)
- `/obs end` → `/obs recap`
- Reinstall the plugin to re-register the new command name

```bash
claude plugins uninstall obs-memory@local
claude plugins install --local /path/to/obsidian-agent-memory-skills
```

## Full Command Reference

| Command | What it does |
|---|---|
| `/obs init [path]` | Bootstrap a new vault |
| `/obs recap` | Write session summary, update TODOs |
| `/obs project [name]` | Scaffold a project in the vault |
| `/obs note <type> [name]` | Create component, ADR, or pattern note |
| `/obs todo [action]` | View/update TODOs |
| `/obs lookup <query>` | Search by deps, consumers, type, layer, freetext |
| `/obs relate <src> <tgt>` | Create bidirectional relationships |
| `/obs relate show <name>` | View all relationships |
| `/obs relate tree <name>` | Walk the dependency tree |

---

*obs-memory works with any agent supporting the [Agent Skills](https://agentskills.io) spec — Claude Code, Cursor, Cline, Windsurf, GitHub Copilot, and 35+ more.*
