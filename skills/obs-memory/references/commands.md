# Command Reference — Detailed Procedures

This file contains the detailed step-by-step procedures for each obs-memory command. The agent loads this on demand when executing a specific command.

## Vault Resolution (all commands)

Before any command, resolve the vault path:
1. Check `$OBSIDIAN_VAULT_PATH` environment variable
2. Parse from the agent's project or global config (look for "Obsidian Knowledge Vault" section)
3. Default: `~/Documents/AgentMemory`

Store as `$VAULT`. Verify `$VAULT/Home.md` exists. If not, suggest running `init` to bootstrap the vault.

Detect the current project:
```bash
basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename $(pwd)
```
Store as `$PROJECT`.

Derive `$VAULT_NAME` (for CLI calls):
```bash
VAULT_NAME=$(basename "$VAULT")
```

---

## `init` — Initialize the Vault

Bootstrap a new Obsidian Agent Memory vault from the bundled template.

### Steps:

1. **Determine vault path**: Use the first argument if provided, otherwise use the vault resolution chain above. If no path resolves, default to `~/Documents/AgentMemory`.

2. **Check if vault already exists**: Look for `$VAULT/Home.md`. If it exists, tell the user the vault already exists at that path and offer to open it.

3. **Locate the bundled template**: The template is at `vault-template/` relative to the skill package root. Search for the skill package installation directory — it may be in the agent's plugin/skill cache or a local checkout. Look for the `vault-template/Home.md` file to confirm the correct path.

4. **Create the vault**:
   ```bash
   mkdir -p "$VAULT"
   cp -r "$TEMPLATE_DIR/vault-template/"* "$VAULT/"
   ```

5. **Create Obsidian config directory**:
   ```bash
   mkdir -p "$VAULT/.obsidian"
   ```
   Write the following to `$VAULT/.obsidian/app.json`:
   ```json
   {
     "alwaysUpdateLinks": true,
     "newFileLocation": "folder",
     "newFileFolderPath": "inbox",
     "attachmentFolderPath": "attachments"
   }
   ```

6. **Create empty directories**:
   ```bash
   mkdir -p "$VAULT/inbox"
   mkdir -p "$VAULT/attachments"
   ```
   Create `.gitkeep` files in each empty directory.

7. **Report** the created vault and provide next steps:
   - Open in Obsidian: Vault Switcher → Open folder as vault → `$VAULT`
   - Set the vault path via `OBSIDIAN_VAULT_PATH` environment variable or agent config
   - Start working — the agent will build the knowledge graph as it goes

---

## `end` — Write Session Summary

Write a session summary note and update TODOs.

### Steps:

1. **Gather session context** by running:
   ```bash
   git log --oneline -20
   git diff --stat HEAD~5..HEAD 2>/dev/null || git diff --stat
   git branch --show-current
   ```

2. **Read current TODOs** — CLI-first:
   ```bash
   obsidian vault=$VAULT_NAME tasks path="todos" todo verbose
   ```
   Fallback: Read `$VAULT/todos/Active TODOs.md`.

3. **Read project overview** from `$VAULT/projects/$PROJECT/$PROJECT.md` (for wikilinks and context).

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

6. **Update Session Log**: Add an entry to `$VAULT/sessions/Session Log.md` with the date, project, branch, and a one-line summary.

7. **Report** what was written.

---

## `project` — Scaffold New Project

Scaffold a new project in the vault. Uses the first argument as the project name, or defaults to `$PROJECT`.

### Steps:

1. **Determine project name**: Use the argument if provided, otherwise use `$PROJECT`.

2. **Check if project exists**: Look for `$VAULT/projects/{name}/{name}.md`. If it exists, tell the user and offer to open it instead.

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

5. **Update Projects.md**: Add a row to the project table in `$VAULT/projects/Projects.md`.

6. **Report** the scaffolded structure.

---

## `note` — Create a Note from Template

Create a note using a template. The first argument specifies the type: `component`, `adr`, or `pattern`.

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

If a name argument is provided, use it as the component name. Otherwise, ask the user.

### `note adr [title]`

Determine the next ADR number by listing existing ADRs in `$VAULT/projects/$PROJECT/architecture/ADR-*.md`.

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

After creating any note, add a wikilink to it from the project overview.

---

## `todo` — Manage TODOs

Open and update the Active TODOs for the current project.

### Steps:

1. **Read current TODOs** from `$VAULT/todos/Active TODOs.md`.

2. **If no additional arguments**: Display the current TODOs for `$PROJECT` and ask what to update.

3. **If arguments provided**: Parse as a TODO action:
   - Plain text → Add as a new pending item under `$PROJECT`
   - `done: <text>` → Move matching item to Completed
   - `remove: <text>` → Remove matching item

4. **Write back** the updated file.

---

## `lookup` — Search the Vault

Search the vault for knowledge. Supports targeted subcommands and freetext search.

### Subcommands

#### `lookup deps <name>`

Query what a component depends on.

```bash
obsidian vault=$VAULT_NAME property:read file="<name>" name="depends-on"
```
Fallback: Read the component note and parse the `depends-on` frontmatter list.

#### `lookup consumers <name>`

Query what depends on a component (reverse dependencies).

```bash
obsidian vault=$VAULT_NAME property:read file="<name>" name="depended-on-by"
obsidian vault=$VAULT_NAME backlinks file="<name>"
```
Combine results — `depended-on-by` gives explicit relationships, `backlinks` catches implicit references. Fallback: Read the component note and search for backlinks via Grep.

#### `lookup related <name>`

Query all notes connected to a given note (both directions).

```bash
obsidian vault=$VAULT_NAME links file="<name>"
obsidian vault=$VAULT_NAME backlinks file="<name>"
```
Fallback: Read the note and extract wikilinks, then Grep for `[[<name>` across the vault.

#### `lookup type <type> [project]`

Find all notes of a given type (component, adr, session, project).

```bash
obsidian vault=$VAULT_NAME tag verbose name="<type>"
```
If `[project]` is specified, filter results to notes also tagged `project/<short-name>`:
```bash
obsidian vault=$VAULT_NAME search query="type: <type>" path="projects/<project>"
```
Fallback: Grep for `type: <type>` across `$VAULT`.

#### `lookup layer <layer> [project]`

Find all components in a specific layer.

```bash
obsidian vault=$VAULT_NAME search query="layer: <layer>" path="projects/<project>"
```
If no project specified, search across all projects:
```bash
obsidian vault=$VAULT_NAME search query="layer: <layer>" path="projects"
```
Fallback: Grep for `layer: <layer>` across `$VAULT/projects/`.

#### `lookup files <component>`

Query key files for a component.

```bash
obsidian vault=$VAULT_NAME property:read file="<component>" name="key-files"
```
Fallback: Read the component note and parse the `key-files` frontmatter list.

#### `lookup <freetext>`

General search across the vault.

```bash
obsidian vault=$VAULT_NAME search format=json query="<freetext>" matches limit=10
```
Fallback: Search file contents for the query across all `.md` files in `$VAULT`.

If the query looks like a tag (starts with `#` or `project/`):
```bash
obsidian vault=$VAULT_NAME tags name="<query>"
```

If the query matches a note name:
```bash
obsidian vault=$VAULT_NAME backlinks file="<query>"
```

**Present results**: Show matching notes with their frontmatter (first ~10 lines) so the user can decide which to read in full.

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

Create a bidirectional relationship between two notes. Default type is `depends-on`/`depended-on-by`.

#### Steps:

1. **Resolve note names**: Use `file=` parameter for note display names. If ambiguity is possible (same name, different folders), use `path=` with full vault-relative path.

2. **Read current property on source** (forward direction):
   ```bash
   obsidian vault=$VAULT_NAME property:read file="<source>" name="<forward-property>"
   ```
   Fallback: Read the source note frontmatter.

3. **Check if relationship already exists**: If `<target>` (as a wikilink) is already in the list, skip and report "already related".

4. **Append to source** (forward direction):
   Build the new list locally by appending `[[<target>]]` to the current values, then set:
   ```bash
   obsidian vault=$VAULT_NAME property:set file="<source>" name="<forward-property>" value="<full-list>" type="list"
   ```
   Fallback: Edit the source note's frontmatter directly.

5. **Read current property on target** (inverse direction):
   ```bash
   obsidian vault=$VAULT_NAME property:read file="<target>" name="<inverse-property>"
   ```

6. **Append to target** (inverse direction):
   ```bash
   obsidian vault=$VAULT_NAME property:set file="<target>" name="<inverse-property>" value="<full-list>" type="list"
   ```

7. **Report** the created relationship.

**Safety**: Always read-then-set. Never blind-append. The full list is constructed locally and set atomically.

### `relate show <name>`

Display all relationships for a note.

#### Steps:

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
   Fallback: Read the note frontmatter and parse all relationship properties.

2. **Query structural links**:
   ```bash
   obsidian vault=$VAULT_NAME links file="<name>"
   obsidian vault=$VAULT_NAME backlinks file="<name>"
   ```

3. **Present results** grouped by relationship type. Show explicit (property) relationships first, then structural (wikilink) relationships that aren't already covered.

### `relate tree <name> [depth]`

Walk the dependency tree via BFS. Default depth is 2.

#### Steps:

1. **Initialize BFS**: Start with `<name>` at depth 0. Maintain a visited set and a queue.

2. **For each node in the queue**:
   ```bash
   obsidian vault=$VAULT_NAME property:read file="<current>" name="depends-on"
   ```
   Fallback: Read the note and parse `depends-on` from frontmatter.

3. **Add unvisited dependencies** to the queue at `current_depth + 1`. Stop when `depth` limit is reached.

4. **Present** the tree as an indented list showing the dependency chain.
