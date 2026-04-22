#!/usr/bin/env bash
# Uninstall claude-auto-open hooks from ~/.claude/settings.json.
# Only removes hooks containing the "claude-pending-opens" marker.
# Other hooks and settings are left untouched. Backs up first.

set -euo pipefail

SETTINGS="$HOME/.claude/settings.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required." >&2
  exit 1
fi

if [ ! -f "$SETTINGS" ]; then
  echo "No settings file at $SETTINGS — nothing to uninstall."
  exit 0
fi

if ! jq -e '.' "$SETTINGS" >/dev/null 2>&1; then
  echo "Error: $SETTINGS is not valid JSON. Fix it first." >&2
  exit 1
fi

if ! jq -e '[.hooks.PostToolUse[]?.hooks[]?.command, .hooks.Stop[]?.hooks[]?.command] | map(select(. != null)) | any(contains("claude-pending-opens"))' "$SETTINGS" >/dev/null 2>&1; then
  echo "claude-auto-open is not installed in $SETTINGS. Nothing to remove."
  exit 0
fi

BACKUP="$SETTINGS.bak-$(date +%Y%m%d-%H%M%S)"
cp "$SETTINGS" "$BACKUP"
echo "Backed up existing settings to: $BACKUP"

TMP="$(mktemp)"
jq '
  def strip_event(arr):
    [ arr[]?
      | .hooks = [ .hooks[]? | select((.command // "") | contains("claude-pending-opens") | not) ]
      | select(.hooks | length > 0)
    ];
  .hooks.PostToolUse = strip_event(.hooks.PostToolUse // [])
  | .hooks.Stop = strip_event(.hooks.Stop // [])
  | if (.hooks.PostToolUse | length) == 0 then del(.hooks.PostToolUse) else . end
  | if (.hooks.Stop | length) == 0 then del(.hooks.Stop) else . end
  | if (.hooks // {}) == {} then del(.hooks) else . end
' "$SETTINGS" > "$TMP"

if ! jq -e '.' "$TMP" >/dev/null 2>&1; then
  echo "Error: uninstall produced invalid JSON. Leaving settings untouched." >&2
  rm -f "$TMP"
  exit 1
fi

mv "$TMP" "$SETTINGS"
echo ""
echo "Removed claude-auto-open hooks. Other hooks and settings were not touched."
