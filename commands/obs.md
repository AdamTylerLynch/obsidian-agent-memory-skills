---
description: "Manage your Obsidian agent memory vault — initialize, write session summaries, scaffold projects, create notes, update TODOs, search vault knowledge, and manage relationships."
argument-hint: "<init|recap|project|note|todo|lookup|relate> [args]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git log:*), Bash(git diff:*), Bash(git rev-parse:*), Bash(git branch:*), Bash(git remote:*), Bash(basename:*), Bash(obsidian:*), Bash(date:*), Bash(cp:*), Bash(mkdir:*), Bash(cat:*), Bash(touch:*)
---

# /obs — Vault Management (Claude Code)

Resolve variables, then dispatch to the obs-memory skill procedure.

## Variable Resolution

**$VAULT**: `$OBSIDIAN_VAULT_PATH` env var → parse from CLAUDE.md ("Obsidian Knowledge Vault" section) → `~/Documents/AgentMemory`

**$VAULT_NAME**: `basename "$VAULT"`

**$PROJECT**:
```bash
basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename $(pwd)
```

Verify `$VAULT/Home.md` exists. If not → suggest `/obs init`.

## Dispatch

Execute the matching command procedure from the obs-memory skill (`skills/obs-memory/SKILL.md` § Commands):

| `$ARGUMENTS[0]` | Skill procedure |
|---|---|
| `init` | `init` — pass `$ARGUMENTS[1]` as path |
| `recap` | `recap` |
| `project` | `project` — pass `$ARGUMENTS[1]` as name |
| `note` | `note` — pass `$ARGUMENTS[1]` as type, `$ARGUMENTS[2]` as name |
| `todo` | `todo` — pass `$ARGUMENTS[1..]` as action |
| `lookup` | `lookup` — pass `$ARGUMENTS[1..]` as query |
| `relate` | `relate` — pass `$ARGUMENTS[1..]` as args |
| _(empty)_ | Session Start — Orientation |
