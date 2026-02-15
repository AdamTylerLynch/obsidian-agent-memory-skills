#!/usr/bin/env bash
# setup.sh — Bootstrap an Obsidian Agent Memory vault
#
# Usage:
#   ./setup.sh [vault-path]
#
# Examples:
#   ./setup.sh ~/Documents/AgentMemory
#   ./setup.sh                           # defaults to ~/Documents/AgentMemory

set -euo pipefail

VAULT_PATH="${1:-$HOME/Documents/AgentMemory}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/vault-template"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
    echo "Error: Template directory not found: $TEMPLATE_DIR" >&2
    echo "Run this script from the obs-memory skill package directory." >&2
    exit 1
fi

echo "=== Obsidian Agent Memory Setup ==="
echo ""

# Check if vault already exists
if [[ -d "$VAULT_PATH/.obsidian" ]]; then
    echo "Vault already exists at: $VAULT_PATH"
    echo "To reset, delete the directory and run again."
    exit 0
fi

# Create vault
echo "Creating vault at: $VAULT_PATH"
mkdir -p "$VAULT_PATH"

# Copy template
echo "Copying template files..."
cp -r "$TEMPLATE_DIR"/* "$VAULT_PATH/"

# Create .obsidian directory to mark as vault
mkdir -p "$VAULT_PATH/.obsidian"
cat > "$VAULT_PATH/.obsidian/app.json" << 'EOF'
{
  "alwaysUpdateLinks": true,
  "newFileLocation": "folder",
  "newFileFolderPath": "inbox",
  "attachmentFolderPath": "attachments"
}
EOF

# Create .gitkeep files for empty dirs
mkdir -p "$VAULT_PATH/inbox"
touch "$VAULT_PATH/inbox/.gitkeep"
mkdir -p "$VAULT_PATH/attachments"
touch "$VAULT_PATH/attachments/.gitkeep"

echo ""
echo "Vault created successfully!"
echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Open in Obsidian:"
echo "   Vault Switcher → Open folder as vault → $VAULT_PATH"
echo ""
echo "2. Set the vault path (choose one):"
echo ""
echo "   a) Environment variable (add to shell profile):"
echo "      export OBSIDIAN_VAULT_PATH=\"$VAULT_PATH\""
echo ""
echo "   b) Add to your agent's config (e.g., ~/.claude/CLAUDE.md):"
echo "      See: skills/obs-memory/SKILL.md for the instruction set"
echo ""
echo "3. Start a session — the agent will begin building the knowledge graph"
echo "   as it works on your code."
echo ""
