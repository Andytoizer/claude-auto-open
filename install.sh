#!/usr/bin/env bash
# Install claude-auto-open hooks into ~/.claude/settings.json.
# Idempotent: detects if already installed and bails safely.
# Backs up existing settings before modifying.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_JSON="$SCRIPT_DIR/hooks.json"
SETTINGS="$HOME/.claude/settings.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required." >&2
  echo "  macOS:  brew install jq" >&2
  echo "  Linux:  sudo apt install jq   (or your package manager's equivalent)" >&2
  exit 1
fi

if [ ! -f "$HOOKS_JSON" ]; then
  echo "Error: hooks.json not found next to install.sh ($HOOKS_JSON)" >&2
  exit 1
fi

mkdir -p "$(dirname "$SETTINGS")"
if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
  echo "Created empty $SETTINGS"
fi

# Validate existing settings is valid JSON before touching it
if ! jq -e '.' "$SETTINGS" >/dev/null 2>&1; then
  echo "Error: $SETTINGS is not valid JSON. Fix it first; I won't overwrite broken settings." >&2
  exit 1
fi

# Already installed?
if jq -e '[.hooks.PostToolUse[]?.hooks[]?.command, .hooks.Stop[]?.hooks[]?.command] | map(select(. != null)) | any(contains("claude-pending-opens"))' "$SETTINGS" >/dev/null 2>&1; then
  echo "claude-auto-open is already installed in $SETTINGS."
  echo "To reinstall, run ./uninstall.sh first."
  exit 0
fi

# Backup
BACKUP="$SETTINGS.bak-$(date +%Y%m%d-%H%M%S)"
cp "$SETTINGS" "$BACKUP"
echo "Backed up existing settings to: $BACKUP"

# Merge
TMP="$(mktemp)"
jq --slurpfile new "$HOOKS_JSON" '
  .hooks.PostToolUse = ((.hooks.PostToolUse // []) + ($new[0].hooks.PostToolUse // []))
  | .hooks.Stop = ((.hooks.Stop // []) + ($new[0].hooks.Stop // []))
' "$SETTINGS" > "$TMP"

# Sanity check the merge produced valid JSON
if ! jq -e '.' "$TMP" >/dev/null 2>&1; then
  echo "Error: merge produced invalid JSON. Leaving settings untouched." >&2
  rm -f "$TMP"
  exit 1
fi

mv "$TMP" "$SETTINGS"

echo ""
echo "Installed claude-auto-open hooks."
echo ""
echo "Activate: run /hooks inside Claude Code, or restart it."
echo "(The settings watcher only picks up new hooks on session start or /hooks reload.)"
