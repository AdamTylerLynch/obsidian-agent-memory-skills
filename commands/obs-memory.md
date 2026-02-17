---
description: "Manage your Obsidian agent memory vault — initialize, write session summaries, scaffold projects, create notes, update TODOs, search vault knowledge, and manage relationships."
argument-hint: "<init|end|project|note|todo|lookup|relate> [args]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git log:*), Bash(git diff:*), Bash(git rev-parse:*), Bash(git branch:*), Bash(basename:*), Bash(obsidian:*), Bash(date:*), Bash(cp:*), Bash(mkdir:*), Bash(cat:*), Bash(touch:*)
---

# /obs-memory — Vault Management Commands (Claude Code)

> **Note:** This is the Claude Code-specific command file providing the `/obs-memory` slash command with Claude Code tool permissions and argument hints. For the agent-agnostic skill definition, see `skills/obs-memory/SKILL.md`.

Dispatch based on `$ARGUMENTS[0]`:

## Vault Resolution

Before any subcommand, resolve the vault path:
1. `$OBSIDIAN_VAULT_PATH` environment variable
2. Parse from project or global CLAUDE.md (look for "Obsidian Knowledge Vault" section)
3. Default: `~/Documents/AgentMemory`

Store as `$VAULT`. Verify `$VAULT/Home.md` exists. If not, suggest running `/obs-memory init` to bootstrap the vault.

Derive `$VAULT_NAME` (for CLI calls):
```bash
VAULT_NAME=$(basename "$VAULT")
```

Detect the current project:
```bash
basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename $(pwd)
```
Store as `$PROJECT`.

---

## `init` — Initialize the Vault

Bootstrap a new Obsidian Agent Memory vault from the bundled template.

### Steps:

1. **Determine vault path**: Use `$ARGUMENTS[1]` if provided, otherwise use the vault resolution chain above. If no path resolves, default to `~/Documents/AgentMemory`.

2. **Check if vault already exists**:
   ```
   Glob: $VAULT/Home.md
   ```
   If it exists, tell the user the vault already exists at that path and offer to open it.

3. **Locate the bundled template**: The template is at `vault-template/` relative to this skill package. Resolve the plugin directory:
   ```bash
   # The plugin is installed at ~/.claude/plugins/cache/obs-memory
   # or symlinked there — find the real path
   PLUGIN_DIR="$(cd "$(dirname "$(readlink -f ~/.claude/plugins/cache/obs-memory/setup.sh 2>/dev/null || echo ~/.claude/plugins/cache/obs-memory/setup.sh)")" && pwd)"
   ```
   If the template directory doesn't exist at `$PLUGIN_DIR/vault-template/`, search for it:
   ```
   Glob: ~/.claude/plugins/**/vault-template/Home.md
   ```

4. **Create the vault**:
   ```bash
   mkdir -p "$VAULT"
   cp -r "$PLUGIN_DIR/vault-template/"* "$VAULT/"
   ```

5. **Create Obsidian config directory**:
   ```bash
   mkdir -p "$VAULT/.obsidian"
   cat > "$VAULT/.obsidian/app.json" << 'EOF'
   {
     "alwaysUpdateLinks": true,
     "newFileLocation": "folder",
     "newFileFolderPath": "inbox",
     "attachmentFolderPath": "attachments"
   }
   EOF
   ```

6. **Create empty directories with .gitkeep**:
   ```bash
   mkdir -p "$VAULT/inbox" && touch "$VAULT/inbox/.gitkeep"
   mkdir -p "$VAULT/attachments" && touch "$VAULT/attachments/.gitkeep"
   ```

7. **Report** the created vault and provide next steps:
   - Open in Obsidian: Vault Switcher → Open folder as vault → `$VAULT`
   - Set the vault path via `OBSIDIAN_VAULT_PATH` environment variable or agent config
   - Start working — the agent will build the knowledge graph as it goes

---

## `end` — Write Session Summary

Write a session summary note and update TODOs.

### Steps:

1. **Gather session context:**
   ```bash
   git log --oneline -20
   git diff --stat HEAD~5..HEAD 2>/dev/null || git diff --stat
   git branch --show-current
   ```

2. **Read current TODOs** — CLI-first:
   ```bash
   obsidian vault=$VAULT_NAME tasks path="todos" todo verbose
   ```
   Fallback:
   ```
   Read: $VAULT/todos/Active TODOs.md
   ```

3. **Read project overview** (for wikilinks and context):
   ```
   Read: $VAULT/projects/$PROJECT/$PROJECT.md
   ```

4. **Write session note** — CLI-first:
   ```bash
   obsidian vault=$VAULT_NAME create path="sessions/{YYYY-MM-DD} - {title}" template="Session Note" silent
   obsidian vault=$VAULT_NAME property:set path="sessions/{YYYY-MM-DD} - {title}" name="type" value="session" type="text"
   obsidian vault=$VAULT_NAME property:set path="sessions/{YYYY-MM-DD} - {title}" name="branch" value="{current-branch}" type="text"
   obsidian vault=$VAULT_NAME property:set path="sessions/{YYYY-MM-DD} - {title}" name="projects" value="[[projects/$PROJECT/$PROJECT]]" type="list"
   ```
   Then append body content:
   ```bash
   obsidian vault=$VAULT_NAME append path="sessions/{YYYY-MM-DD} - {title}" content="..."
   ```
   Fallback: Write the file directly at `$VAULT/sessions/{YYYY-MM-DD} - {title}.md`:
   ```yaml
   ---
   tags: [sessions]
   type: session
   projects:
     - "[[projects/$PROJECT/$PROJECT]]"
   created: {YYYY-MM-DD}
   branch: {current-branch}
   ---
   ```
   Sections to fill:
   - **Context**: What was being worked on (from git log context)
   - **Work Done**: Numbered list of accomplishments (from commits and diffs)
   - **Discoveries**: Technical findings worth remembering
   - **Decisions**: Design choices made during this session
   - **Next Steps**: What should happen next (checkboxes)

5. **Update TODOs**: Edit `$VAULT/todos/Active TODOs.md`:
   - Move completed items to Completed section
   - Add new items discovered during the session
   - Keep items grouped by project

6. **Update Session Log**: Add an entry to `$VAULT/sessions/Session Log.md`

7. **Report** what was written.

---

## `project` — Scaffold New Project

Scaffold a new project in the vault. Uses `$ARGUMENTS[1]` as the project name, or defaults to `$PROJECT`.

### Steps:

1. **Determine project name**: `$ARGUMENTS[1]` or `$PROJECT`

2. **Check if project exists**:
   ```
   Glob: $VAULT/projects/{name}/{name}.md
   ```
   If it exists, tell the user and offer to open it instead.

3. **Create directory structure**:
   - `$VAULT/projects/{name}/`
   - `$VAULT/projects/{name}/architecture/`
   - `$VAULT/projects/{name}/components/`
   - `$VAULT/projects/{name}/patterns/`

4. **Create project overview** at `$VAULT/projects/{name}/{name}.md`:
   ```yaml
   ---
   aliases: []
   tags: [project/{short-name}]
   type: project
   repo: {git remote url if available}
   path: {working directory}
   language: {detected from files}
   framework:
   created: {YYYY-MM-DD}
   status: active
   ---
   ```
   Sections: Architecture, Components, Project Patterns, Architecture Decisions, Domains

   Auto-detect and fill:
   - Language from file extensions in the repo
   - Repo URL from `git remote get-url origin`
   - Link to relevant domains that exist in `$VAULT/domains/`

5. **Update Projects.md**: Add a row to the project table in `$VAULT/projects/Projects.md`

6. **Report** the scaffolded structure.

---

## `note` — Create a Note from Template

Create a note using a template. `$ARGUMENTS[1]` specifies the type: `component`, `adr`, or `pattern`.

### `note component [name]`

Create at `$VAULT/projects/$PROJECT/components/{name}.md`:
```yaml
---
tags: [components, project/{short-name}]
type: component
project: "[[projects/$PROJECT/$PROJECT]]"
created: {YYYY-MM-DD}
status: active
layer: ""
depends-on: []
depended-on-by: []
key-files: []
---
```
Sections: Purpose, Gotchas

If `$ARGUMENTS[2]` is provided, use it as the component name. Otherwise, ask the user.

### `note adr [title]`

Determine the next ADR number by listing existing ADRs:
```
Glob: $VAULT/projects/$PROJECT/architecture/ADR-*.md
```

Create at `$VAULT/projects/$PROJECT/architecture/ADR-{NNNN} {title}.md`:
```yaml
---
tags: [architecture, decision, project/{short-name}]
type: adr
project: "[[projects/$PROJECT/$PROJECT]]"
status: proposed
created: {YYYY-MM-DD}
---
```
Sections: Context, Decision, Alternatives Considered, Consequences

### `note pattern [name]`

Create at `$VAULT/projects/$PROJECT/patterns/{name}.md`:
```yaml
---
tags: [patterns, project/{short-name}]
project: "[[projects/$PROJECT/$PROJECT]]"
created: {YYYY-MM-DD}
---
```
Sections: Pattern, When to Use, Implementation, Examples

After creating any note, link it from the project overview.

---

## `todo` — Manage TODOs

Open and update the Active TODOs for the current project.

### Steps:

1. **Read current TODOs**:
   ```
   Read: $VAULT/todos/Active TODOs.md
   ```

2. **If no additional arguments**: Display the current TODOs for `$PROJECT` and ask what to update.

3. **If arguments provided** (`$ARGUMENTS[1..]`): Parse as a TODO action:
   - Plain text → Add as a new pending item under `$PROJECT`
   - `done: <text>` → Move matching item to Completed
   - `remove: <text>` → Remove matching item

4. **Write back** the updated file.

---

## `lookup` — Search the Vault

Search the vault for knowledge. `$ARGUMENTS[1..]` specifies the subcommand or search query.

### Subcommands

#### `lookup deps <name>`

Query what a component depends on.
```bash
obsidian vault=$VAULT_NAME property:read file="<name>" name="depends-on"
```
Fallback: Read the component note and parse `depends-on` from frontmatter.

#### `lookup consumers <name>`

Query reverse dependencies.
```bash
obsidian vault=$VAULT_NAME property:read file="<name>" name="depended-on-by"
obsidian vault=$VAULT_NAME backlinks file="<name>"
```
Combine results. Fallback: Read the component note and Grep for backlinks.

#### `lookup related <name>`

All connected notes (both directions).
```bash
obsidian vault=$VAULT_NAME links file="<name>"
obsidian vault=$VAULT_NAME backlinks file="<name>"
```
Fallback: Read the note for wikilinks, Grep for `[[<name>` across vault.

#### `lookup type <type> [project]`

Find notes by type (component, adr, session, project).
```bash
obsidian vault=$VAULT_NAME tag verbose name="<type>"
```
With project filter:
```bash
obsidian vault=$VAULT_NAME search query="type: <type>" path="projects/<project>"
```
Fallback:
```
Grep: pattern="type: <type>", path=$VAULT, glob="*.md"
```

#### `lookup layer <layer> [project]`

Find components by architectural layer.
```bash
obsidian vault=$VAULT_NAME search query="layer: <layer>" path="projects/<project>"
```
Fallback:
```
Grep: pattern="layer: <layer>", path=$VAULT/projects/, glob="*.md"
```

#### `lookup files <component>`

Key files for a component.
```bash
obsidian vault=$VAULT_NAME property:read file="<component>" name="key-files"
```
Fallback: Read the component note and parse `key-files` from frontmatter.

#### `lookup <freetext>`

General search.
```bash
obsidian vault=$VAULT_NAME search format=json query="<freetext>" matches limit=10
```
Fallback:
```
Grep: pattern=$QUERY, path=$VAULT, glob="*.md"
```

If query looks like a tag:
```bash
obsidian vault=$VAULT_NAME tags name="<query>"
```

If query matches a note name:
```bash
obsidian vault=$VAULT_NAME backlinks file="<query>"
```

**Present results**: Show matching notes with frontmatter (first 10 lines) so the user can decide which to read in full.

---

## `relate` — Manage Relationships

Create and query bidirectional relationships between notes via frontmatter properties.

### Supported relationship types

| Forward property | Inverse property |
|---|---|
| `depends-on` | `depended-on-by` |
| `extends` | `extended-by` |
| `implements` | `implemented-by` |
| `consumes` | `consumed-by` |

### `relate <source> <target> [type]`

Create a bidirectional relationship. Default type: `depends-on`/`depended-on-by`.

#### Steps:

1. **Resolve note names**: Use `file=` for display names. Use `path=` for disambiguation.

2. **Read current property on source**:
   ```bash
   obsidian vault=$VAULT_NAME property:read file="<source>" name="<forward-property>"
   ```
   Fallback: Read source note frontmatter.

3. **Check for existing relationship**: If target already in list, report "already related".

4. **Set on source** (forward):
   Build full list locally (current values + new entry), then:
   ```bash
   obsidian vault=$VAULT_NAME property:set file="<source>" name="<forward-property>" value="<full-list>" type="list"
   ```
   Fallback: Edit source note frontmatter directly.

5. **Read current property on target**:
   ```bash
   obsidian vault=$VAULT_NAME property:read file="<target>" name="<inverse-property>"
   ```

6. **Set on target** (inverse):
   ```bash
   obsidian vault=$VAULT_NAME property:set file="<target>" name="<inverse-property>" value="<full-list>" type="list"
   ```

7. **Report** the created relationship.

**Safety**: Always read-then-set. Never blind-append.

### `relate show <name>`

Display all relationships for a note.

1. **Query all 8 relationship properties**:
   ```bash
   obsidian vault=$VAULT_NAME property:read file="<name>" name="depends-on"
   obsidian vault=$VAULT_NAME property:read file="<name>" name="depended-on-by"
   obsidian vault=$VAULT_NAME property:read file="<name>" name="extends"
   obsidian vault=$VAULT_NAME property:read file="<name>" name="extended-by"
   obsidian vault=$VAULT_NAME property:read file="<name>" name="implements"
   obsidian vault=$VAULT_NAME property:read file="<name>" name="implemented-by"
   obsidian vault=$VAULT_NAME property:read file="<name>" name="consumes"
   obsidian vault=$VAULT_NAME property:read file="<name>" name="consumed-by"
   ```
   Fallback: Read note frontmatter.

2. **Query structural links**:
   ```bash
   obsidian vault=$VAULT_NAME links file="<name>"
   obsidian vault=$VAULT_NAME backlinks file="<name>"
   ```

3. **Present** grouped by relationship type.

### `relate tree <name> [depth]`

BFS walk of the dependency tree. Default depth: 2.

1. **Initialize**: Start with `<name>` at depth 0. Maintain visited set and queue.

2. **For each node**:
   ```bash
   obsidian vault=$VAULT_NAME property:read file="<current>" name="depends-on"
   ```
   Fallback: Read note, parse `depends-on`.

3. **Add unvisited deps** to queue at `current_depth + 1`. Stop at depth limit.

4. **Present** as indented tree.

---

## Error Handling

- If the vault doesn't exist → suggest running `/obs-memory init` to bootstrap it
- If the project doesn't exist in the vault → offer to run `/obs-memory project` to scaffold it
- If a note already exists → show it instead of overwriting, offer to edit
- If no git repo is detected → use current directory name as project name
- If CLI command fails → fall back to file read for the same data
