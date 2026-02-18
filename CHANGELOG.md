# Changelog

All notable changes to obs-memory are documented here.

## [2.2.0] — 2026-02-17

### Added

- **`analyze` command** — scans the current repo for knowledge sources (CLAUDE.md, README, ADRs, package manifests, CI configs), analyzes project structure, and writes populated vault notes (project overview, components, patterns, ADR imports, domain links) with idempotency to preserve existing manual work
- `Bash(ls:*)` added to allowed-tools (needed by `analyze` for directory listing)
- `type: pattern` added to pattern note frontmatter convention

### Fixed

- Duplicate paragraph in README "Search vault knowledge" section

## [2.1.0] — 2026-02-16

### Breaking Changes

- **Slash command renamed**: `/obs-memory` → `/obs` — shorter, easier to type
- **`end` command renamed to `recap`** — clearer intent, avoids "terminate session" ambiguity
- **Activation triggers tightened** — skill now activates on "obsidian memory", "obsidian vault", "obsidian notes", "/obs commands" instead of overly generic "agent memory", "knowledge graph", "project architecture"

### Added

- **Automatic Behaviors** — agent-agnostic lifecycle that works without explicit commands:
  - **Session start**: auto-orients (TODOs + project overview) without being asked
  - **Session end signals**: detects "done", "wrapping up", etc. and offers to write a recap
  - **Component discovery**: offers to create vault notes when agent deeply analyzes undocumented components
  - **First run**: guides through `init` when no vault exists
- **Enhanced `init`** — three new steps:
  - Generates agent config snippet (CLAUDE.md for Claude Code, env var for others)
  - Auto-scaffolds current project if inside a git repo
  - Concise 5-8 line output
- `Bash(git remote:*)` added to allowed-tools (needed by `project` command)

### Changed

- **Single source of truth** — all command procedures consolidated into `SKILL.md` (~666 lines); command adapter `obs.md` is dispatch-only (~37 lines)
- **Net reduction**: −484 lines of duplication removed (504 insertions, 988 deletions)
- SKILL.md version: `2.1`
- plugin.json version: `2.1.0`

### Removed

- `commands/obs-memory.md` — replaced by `commands/obs.md`
- `skills/obs-memory/references/commands.md` — merged into SKILL.md
- `skills/obs-memory/references/` directory — empty after merge

## [2.0.0] — 2026-02-15

### Added

- **CLI-first relationship engine** — `relate` command with bidirectional relationship management
  - `relate <source> <target> [type]` — creates `depends-on`/`depended-on-by`, `extends`/`extended-by`, `implements`/`implemented-by`, `consumes`/`consumed-by`
  - `relate show <name>` — displays all relationships for a note
  - `relate tree <name> [depth]` — BFS walk of dependency tree
- **Enhanced `lookup`** with structured subcommands:
  - `lookup deps`, `lookup consumers`, `lookup related`, `lookup type`, `lookup layer`, `lookup files`
- CLI-first patterns with file-read fallbacks throughout all commands

## [1.0.0] — 2026-02-15

### Added

- Multi-agent support via Agent Skills specification
- `init` command with bundled vault template
- `end` command for session summaries
- `project` command for vault scaffolding
- `note` command (component, adr, pattern templates)
- `todo` command for TODO management
- `lookup` command for freetext vault search
- Session start orientation (TODOs + project overview)
- Graph navigation with wikilinks
- Token budget rules

## [0.1.0] — 2026-02-15

### Added

- Initial obs-memory skill package
