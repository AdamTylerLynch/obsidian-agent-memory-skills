---
description: "Manage your Obsidian agent memory vault — write session summaries, scaffold projects, create notes, update TODOs, and search vault knowledge."
argument-hint: "<end|project|note|todo|lookup> [args]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(git log:*), Bash(git diff:*), Bash(git rev-parse:*), Bash(git branch:*), Bash(basename:*), Bash(obsidian:*), Bash(date:*)
---

# /obs-memory — Vault Management Commands

Dispatch based on `$ARGUMENTS[0]`:

## Vault Resolution

Before any subcommand, resolve the vault path:
1. `$OBSIDIAN_VAULT_PATH` environment variable
2. Parse from project or global CLAUDE.md (look for "Obsidian Knowledge Vault" section)
3. Default: `~/Documents/AgentMemory`

Store as `$VAULT`. Verify `$VAULT/Home.md` exists. If not, tell the user to set up the vault first.

Detect the current project:
```bash
basename $(git rev-parse --show-toplevel 2>/dev/null) 2>/dev/null || basename $(pwd)
```
Store as `$PROJECT`.

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

2. **Read current TODOs:**
   ```
   Read: $VAULT/todos/Active TODOs.md
   ```

3. **Read project overview** (for wikilinks and context):
   ```
   Read: $VAULT/projects/$PROJECT/$PROJECT.md
   ```

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
project: "[[projects/$PROJECT/$PROJECT]]"
created: {YYYY-MM-DD}
---
```
Sections: Purpose, Key Files, Dependencies (Depends On / Depended On By), Gotchas

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

Search the vault for knowledge. `$ARGUMENTS[1..]` is the search query.

### Steps:

1. **Search by content**:
   ```
   Grep: pattern=$QUERY, path=$VAULT, glob="*.md"
   ```

2. **Search by tags** (if query looks like a tag, e.g., starts with `#` or `project/`):
   ```bash
   obsidian vault=$VAULT_NAME tags name="$QUERY"
   ```

3. **Search by backlinks** (if query matches a note name):
   ```bash
   obsidian vault=$VAULT_NAME backlinks file="$QUERY"
   ```

4. **Present results**: Show matching notes with their frontmatter (first 10 lines) so the user can decide which to read in full.

5. **Follow up**: If the user asks to read a specific result, read the full note.

---

## Error Handling

- If the vault doesn't exist → suggest setup from https://github.com/tyler-lynch/obsidian-agent-memory
- If the project doesn't exist in the vault → offer to run `/obs-memory project` to scaffold it
- If a note already exists → show it instead of overwriting, offer to edit
- If no git repo is detected → use current directory name as project name
