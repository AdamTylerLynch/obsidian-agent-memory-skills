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

2. **Read current TODOs** from `$VAULT/todos/Active TODOs.md`.

3. **Read project overview** from `$VAULT/projects/$PROJECT/$PROJECT.md` (for wikilinks and context).

4. **Write session note** at `$VAULT/sessions/{YYYY-MM-DD} - {title}.md`:
   ```yaml
   ---
   tags: [sessions]
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
   repo: {git remote url if available}
   path: {working directory}
   language: {detected from files}
   created: {YYYY-MM-DD}
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
project: "[[projects/$PROJECT/$PROJECT]]"
created: {YYYY-MM-DD}
---
```
Sections: Purpose, Key Files, Dependencies (Depends On / Depended On By), Gotchas

If a name argument is provided, use it as the component name. Otherwise, ask the user.

### `note adr [title]`

Determine the next ADR number by listing existing ADRs in `$VAULT/projects/$PROJECT/architecture/ADR-*.md`.

Create at `$VAULT/projects/$PROJECT/architecture/ADR-{NNNN} {title}.md`:
```yaml
---
tags: [architecture, decision, project/{short-name}]
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

Search the vault for knowledge. The remaining arguments form the search query.

### Steps:

1. **Search by content**: Search file contents for the query across all `.md` files in `$VAULT`.

2. **Search by tags** (if query looks like a tag, e.g., starts with `#` or `project/`):
   ```bash
   obsidian vault=$VAULT_NAME tags name="$QUERY"
   ```

3. **Search by backlinks** (if query matches a note name):
   ```bash
   obsidian vault=$VAULT_NAME backlinks file="$QUERY"
   ```

4. **Present results**: Show matching notes with their frontmatter (first ~10 lines) so the user can decide which to read in full.

5. **Follow up**: If the user asks to read a specific result, read the full note.
