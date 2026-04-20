#!/usr/bin/env bash
# claude-2nd-brain setup wizard — Mac / Linux
# Usage: bash setup.sh

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

clear

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║       Claude 2nd Brain — Setup Wizard v1.1              ║"
echo "║   Obsidian + Claude Code + Graphify on your machine     ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  This script will:                                       ║"
echo "║  Step 1 — Ask you 4 questions                           ║"
echo "║  Step 2 — Create your Obsidian vault folder structure   ║"
echo "║  Step 3 — Register 1 MCP server (vault-search)          ║"
echo "║  Step 4 — Install vault-autosave + Stop hook            ║"
echo "║  Step 5 — Install the Graphify skill                    ║"
echo "║  Step 6 — Final instructions                            ║"
echo "║                                                          ║"
echo "║  Prerequisites:                                          ║"
echo "║  ✓ Claude Code  (claude --version)                      ║"
echo "║  ✓ Node.js      (node --version)                        ║"
echo "║  ✓ Python 3.8+  (python3 --version)                    ║"
echo "║  ✓ Git          (git --version)                         ║"
echo "║  ✓ Obsidian     (obsidian.md/download)                  ║"
echo "║                                                          ║"
echo "║  Nothing happens until you confirm each step.           ║"
echo "║  Quit anytime with Ctrl+C                               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

read -rp "Press ENTER to begin, or Ctrl+C to quit. " _

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── STEP 1: Questions ────────────────────────────────────────────

echo ""
echo -e "${BOLD}STEP 1 OF 6 — About you${NC}"
echo "─────────────────────────────────────────────────────────"

read -rp "Q1: What's your name? (used in vault CLAUDE.md)
    Default: My Brain
    Your answer: " YOUR_NAME
YOUR_NAME="${YOUR_NAME:-My Brain}"

echo ""

DEFAULT_VAULT="$HOME/Documents/my-brain"
read -rp "Q2: Where should your Obsidian vault live?
    Default: $DEFAULT_VAULT
    Your answer: " VAULT_PATH
VAULT_PATH="${VAULT_PATH:-$DEFAULT_VAULT}"
VAULT_PATH="${VAULT_PATH/#\~/$HOME}"

echo ""

read -rp "Q3: Connect an existing Obsidian vault? (y = connect existing, n = create new) [n]: " EXISTING_VAULT
EXISTING_VAULT="${EXISTING_VAULT:-n}"

echo ""

read -rp "Q4: Code project to map with Graphify? (path or ENTER to skip): " CODE_PATH
CODE_PATH="${CODE_PATH:-}"
CODE_PATH="${CODE_PATH/#\~/$HOME}"

echo ""
echo "─────────────────────────────────────────────────────────"
echo "  Name:   $YOUR_NAME"
echo "  Vault:  $VAULT_PATH"
echo "  Mode:   $([ "$EXISTING_VAULT" = "y" ] && echo 'Connect existing' || echo 'Create new')"
[ -n "$CODE_PATH" ] && echo "  Code:   $CODE_PATH"
echo ""

# ── STEP 2: Create Vault ─────────────────────────────────────────

if [ "$EXISTING_VAULT" != "y" ]; then
  echo -e "${BOLD}STEP 2 OF 6 — Create vault structure${NC}"
  echo "─────────────────────────────────────────────────────────"
  echo "Will create: $VAULT_PATH/"
  echo "  00-Inbox/  01-Projects/  02-Decisions/  03-Daily/"
  echo "  04-Resources/topics/  04-Resources/code-topology/"
  echo "  05-People/  06-Personal/  07-Sessions/  08-Archive/"
  echo "  CLAUDE.md  ← personalized with \"$YOUR_NAME\""
  echo ""
  read -rp "Proceed? (y/n): " confirm

  if [ "$confirm" = "y" ]; then
    for dir in "00-Inbox" "01-Projects" "02-Decisions" "03-Daily" \
                "04-Resources/topics" "04-Resources/code-topology" \
                "05-People" "06-Personal" "07-Sessions" "08-Archive"; do
      mkdir -p "$VAULT_PATH/$dir"
    done
    sed -e "s|{{YOUR_NAME}}|$YOUR_NAME|g" \
        -e "s|{{VAULT_PATH}}|$VAULT_PATH|g" \
        "$SCRIPT_DIR/vault-template/CLAUDE.md" > "$VAULT_PATH/CLAUDE.md"
    echo -e "${GREEN}✓ Vault created at $VAULT_PATH${NC}"
  else
    echo "Skipped vault creation."
  fi
else
  echo "STEP 2 OF 6 — Connecting to existing vault at $VAULT_PATH"
  if [ -f "$SCRIPT_DIR/vault-template/CLAUDE.md" ]; then
    sed -e "s|{{YOUR_NAME}}|$YOUR_NAME|g" \
        -e "s|{{VAULT_PATH}}|$VAULT_PATH|g" \
        "$SCRIPT_DIR/vault-template/CLAUDE.md" > "$VAULT_PATH/CLAUDE.md"
    echo -e "${GREEN}✓ CLAUDE.md written to $VAULT_PATH${NC}"
  fi
fi

echo ""

# ── STEP 3: MCP Servers ──────────────────────────────────────────

echo -e "${BOLD}STEP 3 OF 6 — Register MCP server${NC}"
echo "─────────────────────────────────────────────────────────"
echo "Will register in ~/.claude.json:"
echo "  @bitbonsai/mcpvault — full-text BM25 search across vault"
echo ""
echo "Note: obsidian-mcp is intentionally NOT installed. It re-indexes the"
echo "entire vault on every call and freezes sessions on large vaults."
echo "Vault writes use Claude Code's native Write/Edit/Read tools instead."
echo ""
read -rp "Proceed? (y/n): " confirm

if [ "$confirm" = "y" ]; then
  if ! command -v node &>/dev/null; then
    echo -e "${RED}✗ Node.js not found. Install from https://nodejs.org then re-run.${NC}"
    exit 1
  fi
  if ! command -v python3 &>/dev/null; then
    echo -e "${RED}✗ Python 3 not found. Install from https://python.org then re-run.${NC}"
    exit 1
  fi

  [ ! -f "$HOME/.claude.json" ] && echo '{}' > "$HOME/.claude.json"

  VAULT_PATH="$VAULT_PATH" python3 - <<'PYEOF'
import json, os

vault_path = os.environ["VAULT_PATH"]
claude_json = os.path.expanduser("~/.claude.json")

with open(claude_json, "r") as f:
    cfg = json.load(f)

cfg.setdefault("mcpServers", {})
cfg["mcpServers"]["vault-search"] = {
    "type": "stdio", "command": "npx",
    "args": ["-y", "@bitbonsai/mcpvault", vault_path], "env": {}
}
# Explicitly remove obsidian-mcp if it's left over from a v1.0 install.
cfg["mcpServers"].pop("obsidian", None)

with open(claude_json, "w") as f:
    json.dump(cfg, f, indent=2)
print("Registered vault-search in ~/.claude.json")
print("Removed obsidian-mcp if it was present")
PYEOF

  echo -e "${GREEN}✓ vault-search MCP registered${NC}"
fi

echo ""

# ── STEP 4: Autosave script + Stop hook ──────────────────────────

echo -e "${BOLD}STEP 4 OF 6 — Install vault-autosave + Stop hook${NC}"
echo "─────────────────────────────────────────────────────────"
echo "Will install:"
echo "  ~/.claude/scripts/vault-autosave.sh"
echo "    — Runs on every session end: git pull → commit → push"
echo "    — Silent if vault isn't a git repo yet (safe to install early)"
echo "  Stop + PreCompact hooks in ~/.claude/settings.json"
echo ""
echo "To actually push to GitHub you'll need to:"
echo "  (a) cd $VAULT_PATH && git init"
echo "  (b) Create a private repo on GitHub"
echo "  (c) git remote add origin <url> && git push -u origin main"
echo "Until then the hook runs silently on every session end (no-op)."
echo ""
read -rp "Proceed? (y/n): " confirm

if [ "$confirm" = "y" ]; then
  mkdir -p "$HOME/.claude"
  mkdir -p "$HOME/.claude/scripts"
  [ ! -f "$HOME/.claude/settings.json" ] && echo '{}' > "$HOME/.claude/settings.json"

  # Install vault-autosave.sh with {{VAULT_PATH}} substituted
  sed -e "s|{{VAULT_PATH}}|$VAULT_PATH|g" \
      "$SCRIPT_DIR/claude-config/scripts/vault-autosave.sh" \
      > "$HOME/.claude/scripts/vault-autosave.sh"
  chmod +x "$HOME/.claude/scripts/vault-autosave.sh"
  echo -e "${GREEN}✓ vault-autosave.sh installed${NC}"

  # Merge Stop + PreCompact hooks (non-destructive)
  VAULT_PATH="$VAULT_PATH" \
  SCRIPTS_DIR="$HOME/.claude/scripts" \
  USER_HOME="$HOME" \
  SCRIPT_DIR="$SCRIPT_DIR" python3 - <<'PYEOF'
import json, os

vault_path  = os.environ["VAULT_PATH"]
scripts_dir = os.environ["SCRIPTS_DIR"]
user_home   = os.environ["USER_HOME"]
script_dir  = os.environ["SCRIPT_DIR"]

template_path = os.path.join(script_dir, "claude-config", "settings.json.template")
settings_path = os.path.expanduser("~/.claude/settings.json")

with open(template_path, "r") as f:
    template_str = f.read()
template_str = (template_str
                .replace("{{VAULT_PATH}}", vault_path)
                .replace("{{SCRIPTS_DIR}}", scripts_dir)
                .replace("{{HOME}}", user_home))
template = json.loads(template_str)

with open(settings_path, "r") as f:
    settings = json.load(f)

settings.setdefault("hooks", {})

for event, groups in template.get("hooks", {}).items():
    if event not in settings["hooks"]:
        settings["hooks"][event] = groups
        continue
    # Non-destructive: only append hooks not already present
    for new_hook in groups[0]["hooks"]:
        key = (new_hook.get("command", "") + new_hook.get("prompt", ""))[:80]
        exists = any(
            (h.get("command", "") + h.get("prompt", ""))[:80] == key
            for grp in settings["hooks"][event]
            for h in grp.get("hooks", [])
        )
        if not exists:
            settings["hooks"][event][0]["hooks"].append(new_hook)

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
print("Hooks merged into ~/.claude/settings.json")
PYEOF

  echo -e "${GREEN}✓ Stop + PreCompact hooks installed${NC}"
fi

echo ""

# ── STEP 5: Graphify Skill ───────────────────────────────────────

echo -e "${BOLD}STEP 5 OF 6 — Install Graphify skill${NC}"
echo "─────────────────────────────────────────────────────────"
echo "Will copy to ~/.claude/skills/graphify/"
echo "After install: /graphify <folder> maps any project to your vault."
echo ""
read -rp "Proceed? (y/n): " confirm

if [ "$confirm" = "y" ]; then
  mkdir -p "$HOME/.claude/skills/graphify"
  cp "$SCRIPT_DIR/skills/graphify/SKILL.md" "$HOME/.claude/skills/graphify/SKILL.md"
  echo -e "${GREEN}✓ Graphify installed at ~/.claude/skills/graphify/${NC}"
fi

echo ""

# ── STEP 6: Done ─────────────────────────────────────────────────

echo -e "${BOLD}STEP 6 OF 6 — You're ready${NC}"
echo "─────────────────────────────────────────────────────────"
echo -e "${GREEN}✓ Vault:      $VAULT_PATH${NC}"
echo -e "${GREEN}✓ MCP:        vault-search registered (obsidian-mcp removed)${NC}"
echo -e "${GREEN}✓ Autosave:   ~/.claude/scripts/vault-autosave.sh${NC}"
echo -e "${GREEN}✓ Hooks:      Stop + PreCompact added to Claude Code${NC}"
echo -e "${GREEN}✓ Graphify:   /graphify skill installed${NC}"
echo ""
echo "Next steps:"
echo "  1. Open Obsidian → 'Open folder as vault' → pick $VAULT_PATH"
echo "  2. (Optional, to enable GitHub auto-push):"
echo "     cd $VAULT_PATH"
echo "     git init && git add -A && git commit -m 'initial vault'"
echo "     # create a private repo at github.com/new"
echo "     git remote add origin <your-repo-url>"
echo "     git push -u origin main"
echo "  3. Open Claude Code in any terminal"
echo "  4. Sessions auto-save (and auto-push, once git is wired) when you close Claude Code"
echo "  5. Run /graphify <folder> to map any project to your vault"
if [ -n "$CODE_PATH" ]; then
  echo ""
  echo "  Your code project: $CODE_PATH"
  echo "  Run: /graphify $CODE_PATH --obsidian --obsidian-dir $VAULT_PATH/04-Resources/code-topology"
fi
echo ""
echo "Enjoy your 2nd brain."
echo ""
