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
echo "║       Claude 2nd Brain — Setup Wizard v1.0              ║"
echo "║   Obsidian + Claude Code + Graphify on your machine     ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  This script will:                                       ║"
echo "║  Step 1 — Ask you 4 questions                           ║"
echo "║  Step 2 — Create your Obsidian vault folder structure   ║"
echo "║  Step 3 — Register 2 MCP servers (obsidian + search)    ║"
echo "║  Step 4 — Add hooks to Claude Code (auto session-save)  ║"
echo "║  Step 5 — Install the Graphify skill                    ║"
echo "║  Step 6 — Final instructions                            ║"
echo "║                                                          ║"
echo "║  Prerequisites:                                          ║"
echo "║  ✓ Claude Code  (claude --version)                      ║"
echo "║  ✓ Node.js      (node --version)                        ║"
echo "║  ✓ Python 3.8+  (python3 --version)                    ║"
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

echo -e "${BOLD}STEP 3 OF 6 — Register MCP servers${NC}"
echo "─────────────────────────────────────────────────────────"
echo "Will register in ~/.claude.json:"
echo "  obsidian-mcp        — read/write notes in your vault"
echo "  @bitbonsai/mcpvault — full-text search across vault"
echo "Both are open source, free, no account required."
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
cfg["mcpServers"]["obsidian"] = {
    "type": "stdio", "command": "npx",
    "args": ["-y", "obsidian-mcp", vault_path], "env": {}
}

with open(claude_json, "w") as f:
    json.dump(cfg, f, indent=2)
print("Registered in ~/.claude.json")
PYEOF

  echo -e "${GREEN}✓ MCP servers registered${NC}"
fi

echo ""

# ── STEP 4: Hooks ────────────────────────────────────────────────

echo -e "${BOLD}STEP 4 OF 6 — Add Claude Code hooks${NC}"
echo "─────────────────────────────────────────────────────────"
echo "Will add to ~/.claude/settings.json (non-destructive):"
echo "  Stop hook     — prompts Claude to write today's daily note"
echo "  PreCompact    — saves session summary before context compacts"
echo ""
read -rp "Proceed? (y/n): " confirm

if [ "$confirm" = "y" ]; then
  mkdir -p "$HOME/.claude"
  [ ! -f "$HOME/.claude/settings.json" ] && echo '{}' > "$HOME/.claude/settings.json"

  VAULT_PATH="$VAULT_PATH" SCRIPT_DIR="$SCRIPT_DIR" python3 - <<'PYEOF'
import json, os

vault_path = os.environ["VAULT_PATH"]
script_dir = os.environ["SCRIPT_DIR"]
template_path = os.path.join(script_dir, "claude-config", "settings.json.template")
settings_path = os.path.expanduser("~/.claude/settings.json")

with open(template_path, "r") as f:
    template_str = f.read().replace("{{VAULT_PATH}}", vault_path)
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

  echo -e "${GREEN}✓ Hooks added to Claude Code${NC}"
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
echo -e "${GREEN}✓ MCP:        obsidian-mcp + vault-search registered${NC}"
echo -e "${GREEN}✓ Hooks:      Stop + PreCompact added to Claude Code${NC}"
echo -e "${GREEN}✓ Graphify:   /graphify skill installed${NC}"
echo ""
echo "Next steps:"
echo "  1. Open Obsidian → 'Open folder as vault' → pick $VAULT_PATH"
echo "  2. Open Claude Code in any terminal"
echo "  3. Sessions auto-save to 03-Daily/ when you close Claude Code"
echo "  4. Run /graphify <folder> to map any project to your vault"
if [ -n "$CODE_PATH" ]; then
  echo ""
  echo "  Your code project: $CODE_PATH"
  echo "  Run: /graphify $CODE_PATH --obsidian --obsidian-dir $VAULT_PATH/04-Resources/code-topology"
fi
echo ""
echo "Enjoy your 2nd brain."
echo ""
