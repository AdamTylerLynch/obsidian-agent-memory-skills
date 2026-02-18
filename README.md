# obs-memory — Persistent Agent Memory via Obsidian

Give your coding agent persistent memory across sessions using an [Obsidian](https://obsidian.md) knowledge vault.

Your agent automatically orients itself at session start, navigates project architecture through graph traversal, writes discoveries back to the vault, and can be commanded to create session summaries, scaffold projects, and search vault knowledge.

Works with **any agent** that supports the [Agent Skills](https://agentskills.io) specification — Claude Code, Cursor, Cline, Windsurf, GitHub Copilot, and [35+ more](https://agentskills.io/compatible-products).

## Installation

### Via skills.sh (recommended)

```bash
npx skills add adamtylerlynch/obsidian-agent-memory-skills
```

This installs the skill for your agent and makes it available immediately.

### Via Claude Code plugin (Claude Code only)

```bash
git clone https://github.com/adamtylerlynch/obsidian-agent-memory-skills.git \
  ~/.claude/plugins/cache/obs-memory

# Or symlink from a local checkout
ln -s /path/to/obsidian-agent-memory-skills ~/.claude/plugins/cache/obs-memory
```

### Initialize the vault

Once installed, ask your agent to initialize the vault:

```
Initialize my Obsidian memory vault
```

Or in Claude Code:

```
/obs init
```

Or use the setup script directly:

```bash
./setup.sh ~/Documents/AgentMemory
```

This creates the vault with the required structure, templates, and Obsidian configuration. Then open the vault folder in Obsidian.

### Vault path configuration

The skill resolves your vault path automatically:

1. `OBSIDIAN_VAULT_PATH` environment variable (highest priority)
2. Path parsed from agent config (looks for "Obsidian Knowledge Vault" section)
3. `~/Documents/AgentMemory` (default)

To set the environment variable, add to your shell profile:
```bash
export OBSIDIAN_VAULT_PATH="$HOME/Documents/AgentMemory"
```

## What's Included

### Proactive Skill: `obs-memory`

Loaded automatically when the agent detects vault-relevant context. Handles:

- **Session start orientation** — reads TODOs + project overview (2 files max)
- **Project auto-detection** — matches git repo name to vault projects
- **Graph navigation** — follows wikilinks on demand, never bulk-reads
- **Knowledge writing** — creates component notes, ADRs, patterns, domain knowledge
- **Token optimization** — frontmatter-first scanning, CLI lookups, scoped reads

### Commands

| Command | Description |
|---|---|
| `init [path]` | Initialize a new vault from the bundled template |
| `end` | Write a session summary from git history, update TODOs |
| `project [name]` | Scaffold a new project in the vault |
| `note component [name]` | Create a component note from template |
| `note adr [title]` | Create an architecture decision record |
| `note pattern [name]` | Create a pattern note |
| `todo [action]` | View and update project TODOs |
| `lookup [query]` | Search the vault by content, tags, or backlinks |

In Claude Code, these are available as `/obs <command>`. In other agents, use natural language (e.g., "write a session summary to the vault").

## Agent Compatibility

| Agent | How it works |
|---|---|
| **Claude Code** | Full support — proactive skill + `/obs` slash command |
| **Cursor** | Skill loaded via skills.sh, responds to natural language commands |
| **Cline** | Skill loaded via skills.sh, responds to natural language commands |
| **Windsurf** | Skill loaded via skills.sh, responds to natural language commands |
| **GitHub Copilot** | Skill loaded via skills.sh, responds to natural language commands |
| **Others** | Any agent supporting [Agent Skills spec](https://agentskills.io/specification) |

For agents without skills.sh support, you can manually add the contents of `skills/obs-memory/SKILL.md` to your agent's instructions file (e.g., `.cursorrules`, `.windsurfrules`, `.clinerules`).

## Usage Examples

### Automatic orientation (proactive)

Start a session in any project directory. If the project has notes in the vault, the agent will automatically:
1. Read your active TODOs
2. Read the project overview
3. Have full context about architecture, components, and patterns

### End-of-session summary

Ask your agent to write a session summary (or use `/obs end` in Claude Code). The agent examines your git log and diffs, writes a session note, and updates your TODOs.

### Scaffold a new project

Ask the agent to create a project in your vault (or use `/obs project my-app` in Claude Code). Creates:
```
projects/my-app/
├── my-app.md          # Project overview (auto-filled)
├── architecture/
├── components/
└── patterns/
```

### Search vault knowledge

Ask the agent to search your vault for a topic (or use `/obs lookup PKCS12` in Claude Code). Searches across all notes, showing matches with frontmatter context.

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
│ Session End                                      │
│   Agent writes: Session summary, updates TODOs,  │
│   creates/updates component and pattern notes    │
└─────────────────────────────────────────────────┘
```

## Vault Structure

The vault is initialized with this structure:

```
AgentMemory/
├── Home.md                           # Dashboard
├── projects/
│   ├── Projects.md                   # Project index
│   └── {name}/
│       ├── {name}.md                 # Project overview — agent starts here
│       ├── architecture/             # ADRs and design decisions
│       ├── components/               # Per-component notes
│       └── patterns/                 # Project-specific patterns
├── domains/
│   ├── Domains.md                    # Domain index
│   └── {tech}/                       # Cross-project knowledge
├── patterns/
│   └── Universal Patterns.md         # Language-agnostic patterns
├── sessions/
│   └── Session Log.md                # Session chronology
├── todos/
│   └── Active TODOs.md               # Current work items
├── templates/                        # Note templates
│   ├── Project.md
│   ├── Component Note.md
│   ├── Session Note.md
│   └── Architecture Decision.md
└── inbox/                            # Unsorted
```

## Package Contents

```
obsidian-agent-memory-skills/
├── .claude-plugin/
│   └── plugin.json                   # Plugin metadata (Claude Code + skills.sh)
├── skills/
│   └── obs-memory/
│       ├── SKILL.md                  # Agent-agnostic skill definition
│       └── references/
│           └── commands.md           # Detailed command procedures
├── commands/
│   └── obs.md                        # Claude Code slash command (/obs)
├── vault-template/                   # Bundled vault template
│   ├── Home.md
│   ├── projects/Projects.md
│   ├── domains/Domains.md
│   ├── patterns/Universal Patterns.md
│   ├── sessions/Session Log.md
│   ├── todos/Active TODOs.md
│   └── templates/
│       ├── Project.md
│       ├── Component Note.md
│       ├── Session Note.md
│       └── Architecture Decision.md
├── setup.sh                          # Shell-based vault setup
└── examples/
    └── populated-vault.md            # Example of a vault after real use
```

## License

MIT
