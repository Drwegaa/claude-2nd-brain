#!/usr/bin/env bash
# Auto-sync wegaa-brain vault on session end. Runs async via Claude Stop hook.
# 1. Pull overnight changes from remote (brain-sync runs at 3 AM Dubai)
# 2. Append a breadcrumb to today's daily note (lightweight session marker)
# 3. Commit + push any local changes
#
# For rich session capture (decisions, reasoning, action items), run /save-session manually.
set -euo pipefail

VAULT="$HOME/Documents/wegaa-brain"
cd "$VAULT"

echo "[$(date '+%F %T')] vault-autosave start"

git pull --rebase --autostash origin main 2>&1 || echo "[$(date '+%F %T')] pull failed (offline?)"

# --- Breadcrumb: thin session marker into 03-Daily/YYYY-MM-DD.md ---
# Reads hook JSON from stdin to get cwd. Degrades gracefully if jq missing or no stdin.
HOOK_INPUT=""
if [ ! -t 0 ]; then
  HOOK_INPUT=$(cat)
fi

SESSION_CWD=""
if command -v jq >/dev/null 2>&1 && [ -n "$HOOK_INPUT" ]; then
  SESSION_CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
fi
SESSION_DIR=$([ -n "$SESSION_CWD" ] && basename "$SESSION_CWD" || echo "unknown")

TODAY=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M')
DAILY_DIR="$VAULT/03-Daily"
DAILY_NOTE="$DAILY_DIR/$TODAY.md"

mkdir -p "$DAILY_DIR"
if [ ! -f "$DAILY_NOTE" ]; then
  cat > "$DAILY_NOTE" <<EOF
# $TODAY — Session Log

> Auto-generated breadcrumbs from Stop hook. For rich capture run \`/save-session\`.

EOF
fi
echo "- ${TIME} — Claude Code session ended in \`${SESSION_DIR}\`" >> "$DAILY_NOTE"
# --- end breadcrumb ---

if [[ -z "$(git status --porcelain)" ]]; then
  echo "[$(date '+%F %T')] vault clean, skipping commit"
  exit 0
fi

git add -A
git commit -m "autosave: $(date '+%Y-%m-%d %H:%M')" --no-verify
git push origin main 2>&1 || echo "[$(date '+%F %T')] push failed (offline?)"
echo "[$(date '+%F %T')] done"
