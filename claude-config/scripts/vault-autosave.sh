#!/usr/bin/env bash
# Auto-sync the Obsidian vault on session end. Runs async via Claude Code Stop hook.
# 1. Pull remote changes (picks up any scheduled /brain-sync runs)
# 2. Commit + push any local changes
#
# Install:
#   chmod +x vault-autosave.sh
#   Wire into ~/.claude/settings.json Stop hook (see settings.json.template)
set -euo pipefail

VAULT="{{VAULT_PATH}}"

# Bail if the vault doesn't exist or isn't a git repo — keeps the hook harmless
# for users who haven't wired their vault to a remote yet.
[[ -d "$VAULT/.git" ]] || exit 0

cd "$VAULT"
echo "[$(date '+%F %T')] vault-autosave start"

git pull --rebase --autostash origin main 2>&1 || echo "[$(date '+%F %T')] pull failed (offline or no remote?)"

if [[ -z "$(git status --porcelain)" ]]; then
  echo "[$(date '+%F %T')] vault clean, skipping commit"
  exit 0
fi

git add -A
git commit -m "autosave: $(date '+%Y-%m-%d %H:%M')" --no-verify
git push origin main 2>&1 || echo "[$(date '+%F %T')] push failed (offline or no remote?)"
echo "[$(date '+%F %T')] done"
