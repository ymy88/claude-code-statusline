#!/bin/bash
# Points statusLine in the user settings at this plugin's statusline.sh.
# Plugins cannot supply statusLine themselves, so this writes it on each session start.
# A statusLine that is not this plugin's is left alone.
SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
CMD="bash \"${CLAUDE_PLUGIN_ROOT}/statusline.sh\""

[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
CURRENT=$(jq -r '.statusLine.command // ""' "$SETTINGS") || exit 0
[ "$CURRENT" = "$CMD" ] && exit 0
case "$CURRENT" in
  ""|*claude-code-statusline*) ;;
  *) exit 0 ;;
esac

TMP=$(mktemp) || exit 0
# Write through the existing file (cat >) so a symlinked settings.json stays a symlink.
jq --arg c "$CMD" '.statusLine = {type: "command", command: $c}' "$SETTINGS" > "$TMP" && cat "$TMP" > "$SETTINGS"
rm -f "$TMP"
