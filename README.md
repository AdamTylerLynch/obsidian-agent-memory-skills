# obs-memory — Claude Code Skill Package

A Claude Code skill package that gives your agent persistent memory via an [Obsidian](https://obsidian.md) knowledge vault.

Your agent automatically orients itself at session start, navigates project architecture through graph traversal, writes discoveries back to the vault, and can be commanded to create session summaries, scaffold projects, and search vault knowledge.

## Prerequisites

1. **Obsidian vault** — Set up using the [obsidian-agent-memory](https://github.com/tyler-lynch/obsidian-agent-memory) vault template
2. **Claude Code** — [claude.ai/code](https://claude.ai/code)

## Installation

### From the plugin directory

```bash
# Clone into your plugins cache
git clone https://github.com/tyler-lynch/obsidian-agent-memory-skills.git \
  ~/.claude/plugins/cache/obs-memory

# Or symlink from a local checkout
ln -s /path/to/obsidian-agent-memory-skills ~/.claude/plugins/cache/obs-memory
```

### Vault path configuration

The skill resolves your vault path automatically:

1. `OBSIDIAN_VAULT_PATH` environment variable (highest priority)
2. Path parsed from your CLAUDE.md (looks for "Obsidian Knowledge Vault" section)
3. `~/Documents/AgentMemory` (default)

To set the environment variable, add to your shell profile:
```bash
export OBSIDIAN_VAULT_PATH="$HOME/Documents/AgentMemory"
```

## What's Included

### Proactive Skill: `obs-memory`

Loaded automatically when Claude detects vault-relevant context. Handles:

- **Session start orientation** — reads TODOs + project overview (2 files max)
- **Project auto-detection** — matches git repo name to vault projects
- **Graph navigation** — follows wikilinks on demand, never bulk-reads
- **Knowledge writing** — creates component notes, ADRs, patterns, domain knowledge
- **Token optimization** — frontmatter-first scanning, CLI lookups, scoped reads

### User Command: `/obs-memory`

Manually invoked for vault management operations.

| Subcommand | Description |
|---|---|
| `/obs-memory end` | Write a session summary from git history, update TODOs |
| `/obs-memory project [name]` | Scaffold a new project in the vault |
| `/obs-memory note component [name]` | Create a component note from template |
| `/obs-memory note adr [title]` | Create an architecture decision record |
| `/obs-memory note pattern [name]` | Create a pattern note |
| `/obs-memory todo [action]` | View and update project TODOs |
| `/obs-memory lookup [query]` | Search the vault by content, tags, or backlinks |

## Usage Examples

### Automatic orientation (proactive)

Start a Claude Code session in any project directory. If the project has notes in the vault, Claude will automatically:
1. Read your active TODOs
2. Read the project overview
3. Have full context about architecture, components, and patterns

### End-of-session summary

```
/obs-memory end
```

Claude will examine your git log and diffs, write a session note with what was done/discovered/decided, and update your TODOs.

### Scaffold a new project

```
/obs-memory project my-new-app
```

Creates the full project structure in the vault:
```
projects/my-new-app/
├── my-new-app.md          # Project overview (auto-filled)
├── architecture/
├── components/
└── patterns/
```

### Search vault knowledge

```
/obs-memory lookup PKCS12
```

Searches across all notes for the query, showing matching notes with frontmatter context.

## How It Works

```
┌─────────────────────────────────────────────────┐
│ Session Start                                    │
│   Agent reads: TODOs → Project Overview          │
│   (2 files, ~100 lines — minimal token cost)     │
├─────────────────────────────────────────────────┤
│ During Work                                      │
│   Project Overview ──link──→ Component Note      │
│        │                         │               │
│        └──link──→ Pattern   ──link──→ Domain     │
│                    Note             Knowledge     │
│   Agent follows links ON DEMAND                  │
├─────────────────────────────────────────────────┤
│ Session End (/obs-memory end)                    │
│   Agent writes: Session summary, updates TODOs,  │
│   creates/updates component and pattern notes    │
└─────────────────────────────────────────────────┘
```

## Vault Structure

This skill expects the vault structure from [obsidian-agent-memory](https://github.com/tyler-lynch/obsidian-agent-memory):

```
AgentMemory/
├── Home.md
├── projects/{name}/
│   ├── {name}.md              # Project overview — agent starts here
│   ├── architecture/          # ADRs and design decisions
│   ├── components/            # Per-component notes
│   └── patterns/              # Project-specific patterns
├── domains/{tech}/            # Cross-project knowledge
├── patterns/                  # Universal patterns
├── sessions/                  # Session logs
├── todos/Active TODOs.md      # Current work items
├── templates/                 # Note templates
└── inbox/                     # Unsorted
```

## License

MIT
