# claude-2nd-brain setup wizard — Windows (PowerShell)
# Usage: .\setup.ps1

$ErrorActionPreference = "Stop"

Clear-Host

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗"
Write-Host "║       Claude 2nd Brain — Setup Wizard v1.0              ║"
Write-Host "║   Obsidian + Claude Code + Graphify on your machine     ║"
Write-Host "╠══════════════════════════════════════════════════════════╣"
Write-Host "║  This script will:                                       ║"
Write-Host "║  Step 1 — Ask you 4 questions                           ║"
Write-Host "║  Step 2 — Create your Obsidian vault folder structure   ║"
Write-Host "║  Step 3 — Register 2 MCP servers (obsidian + search)    ║"
Write-Host "║  Step 4 — Add hooks to Claude Code (auto session-save)  ║"
Write-Host "║  Step 5 — Install the Graphify skill                    ║"
Write-Host "║  Step 6 — Final instructions                            ║"
Write-Host "║                                                          ║"
Write-Host "║  Prerequisites:                                          ║"
Write-Host "║  ✓ Claude Code  (claude --version)                      ║"
Write-Host "║  ✓ Node.js      (node --version)                        ║"
Write-Host "║  ✓ Python 3.8+  (python --version)                     ║"
Write-Host "║  ✓ Obsidian     (obsidian.md/download)                  ║"
Write-Host "║                                                          ║"
Write-Host "║  Nothing happens until you confirm each step.           ║"
Write-Host "║  Quit anytime with Ctrl+C                               ║"
Write-Host "╚══════════════════════════════════════════════════════════╝"
Write-Host ""

Read-Host "Press ENTER to begin, or Ctrl+C to quit"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── STEP 1: Questions ────────────────────────────────────────────

Write-Host ""
Write-Host "STEP 1 OF 6 — About you" -ForegroundColor White
Write-Host "─────────────────────────────────────────────────────────"

$YourName = Read-Host "Q1: What's your name? (used in vault CLAUDE.md)`n    Default: My Brain`n    Your answer"
if ([string]::IsNullOrWhiteSpace($YourName)) { $YourName = "My Brain" }

Write-Host ""

$DefaultVault = "$env:USERPROFILE\Documents\my-brain"
$VaultPath = Read-Host "Q2: Where should your Obsidian vault live?`n    Default: $DefaultVault`n    Your answer"
if ([string]::IsNullOrWhiteSpace($VaultPath)) { $VaultPath = $DefaultVault }

Write-Host ""

$ExistingVault = Read-Host "Q3: Connect an existing Obsidian vault? (y = connect, n = create new) [n]"
if ([string]::IsNullOrWhiteSpace($ExistingVault)) { $ExistingVault = "n" }

Write-Host ""

$CodePath = Read-Host "Q4: Code project to map with Graphify? (path or ENTER to skip)"

Write-Host ""
Write-Host "─────────────────────────────────────────────────────────"
Write-Host "  Name:   $YourName"
Write-Host "  Vault:  $VaultPath"
Write-Host "  Mode:   $(if ($ExistingVault -eq 'y') { 'Connect existing' } else { 'Create new' })"
if ($CodePath) { Write-Host "  Code:   $CodePath" }
Write-Host ""

# ── STEP 2: Create Vault ─────────────────────────────────────────

if ($ExistingVault -ne "y") {
    Write-Host "STEP 2 OF 6 — Create vault structure" -ForegroundColor White
    Write-Host "─────────────────────────────────────────────────────────"
    Write-Host "Will create: $VaultPath\"
    Write-Host "  00-Inbox  01-Projects  02-Decisions  03-Daily"
    Write-Host "  04-Resources\topics  04-Resources\code-topology"
    Write-Host "  05-People  06-Personal  07-Sessions  08-Archive"
    Write-Host "  CLAUDE.md  <- personalized with '$YourName'"
    Write-Host ""
    $confirm = Read-Host "Proceed? (y/n)"

    if ($confirm -eq "y") {
        $folders = @(
            "00-Inbox", "01-Projects", "02-Decisions", "03-Daily",
            "04-Resources\topics", "04-Resources\code-topology",
            "05-People", "06-Personal", "07-Sessions", "08-Archive"
        )
        foreach ($folder in $folders) {
            New-Item -ItemType Directory -Force -Path "$VaultPath\$folder" | Out-Null
        }
        $claudeMd = Get-Content "$ScriptDir\vault-template\CLAUDE.md" -Raw
        $claudeMd = $claudeMd.Replace("{{YOUR_NAME}}", $YourName).Replace("{{VAULT_PATH}}", $VaultPath)
        Set-Content -Path "$VaultPath\CLAUDE.md" -Value $claudeMd -Encoding UTF8
        Write-Host "✓ Vault created at $VaultPath" -ForegroundColor Green
    } else {
        Write-Host "Skipped vault creation."
    }
} else {
    Write-Host "STEP 2 OF 6 — Connecting to existing vault at $VaultPath"
    $claudeMd = Get-Content "$ScriptDir\vault-template\CLAUDE.md" -Raw
    $claudeMd = $claudeMd.Replace("{{YOUR_NAME}}", $YourName).Replace("{{VAULT_PATH}}", $VaultPath)
    Set-Content -Path "$VaultPath\CLAUDE.md" -Value $claudeMd -Encoding UTF8
    Write-Host "✓ CLAUDE.md written to $VaultPath" -ForegroundColor Green
}

Write-Host ""

# ── STEP 3: MCP Servers ──────────────────────────────────────────

Write-Host "STEP 3 OF 6 — Register MCP servers" -ForegroundColor White
Write-Host "─────────────────────────────────────────────────────────"
Write-Host "Will register in ~\.claude.json:"
Write-Host "  obsidian-mcp        — read/write notes in your vault"
Write-Host "  @bitbonsai/mcpvault — full-text search across vault"
Write-Host ""
$confirm = Read-Host "Proceed? (y/n)"

if ($confirm -eq "y") {
    $pythonCmd = if (Get-Command python -ErrorAction SilentlyContinue) { "python" } else { "python3" }
    $claudeJson = "$env:USERPROFILE\.claude.json"
    if (-not (Test-Path $claudeJson)) { Set-Content $claudeJson "{}" }

    $pyScript = @"
import json, os
vault_path = r'$VaultPath'
claude_json = r'$claudeJson'
with open(claude_json, 'r') as f:
    cfg = json.load(f)
cfg.setdefault('mcpServers', {})
cfg['mcpServers']['vault-search'] = {
    'type': 'stdio', 'command': 'npx',
    'args': ['-y', '@bitbonsai/mcpvault', vault_path], 'env': {}
}
cfg['mcpServers']['obsidian'] = {
    'type': 'stdio', 'command': 'npx',
    'args': ['-y', 'obsidian-mcp', vault_path], 'env': {}
}
with open(claude_json, 'w') as f:
    json.dump(cfg, f, indent=2)
print('Registered in .claude.json')
"@
    & $pythonCmd -c $pyScript
    Write-Host "✓ MCP servers registered" -ForegroundColor Green
}

Write-Host ""

# ── STEP 4: Hooks ────────────────────────────────────────────────

Write-Host "STEP 4 OF 6 — Add Claude Code hooks" -ForegroundColor White
Write-Host "─────────────────────────────────────────────────────────"
Write-Host "Will add to ~\.claude\settings.json (non-destructive):"
Write-Host "  Stop hook   — prompts Claude to write today's daily note"
Write-Host "  PreCompact  — saves session summary before context compacts"
Write-Host ""
Write-Host "Note: The Stop hook uses bash commands. On Windows this requires"
Write-Host "Git Bash or WSL. The PreCompact hook works on all platforms."
Write-Host ""
$confirm = Read-Host "Proceed? (y/n)"

if ($confirm -eq "y") {
    $claudeDir = "$env:USERPROFILE\.claude"
    if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir | Out-Null }
    $settingsPath = "$claudeDir\settings.json"
    if (-not (Test-Path $settingsPath)) { Set-Content $settingsPath "{}" }

    $templatePath = "$ScriptDir\claude-config\settings.json.template"
    $pythonCmd = if (Get-Command python -ErrorAction SilentlyContinue) { "python" } else { "python3" }

    $pyScript = @"
import json, os
vault_path = r'$VaultPath'
template_path = r'$templatePath'
settings_path = r'$settingsPath'

with open(template_path, 'r', encoding='utf-8') as f:
    template_str = f.read().replace('{{VAULT_PATH}}', vault_path)
template = json.loads(template_str)

with open(settings_path, 'r', encoding='utf-8') as f:
    settings = json.load(f)

settings.setdefault('hooks', {})

for event, groups in template.get('hooks', {}).items():
    if event not in settings['hooks']:
        settings['hooks'][event] = groups
        continue
    for new_hook in groups[0]['hooks']:
        key = (new_hook.get('command', '') + new_hook.get('prompt', ''))[:80]
        exists = any(
            (h.get('command', '') + h.get('prompt', ''))[:80] == key
            for grp in settings['hooks'][event]
            for h in grp.get('hooks', [])
        )
        if not exists:
            settings['hooks'][event][0]['hooks'].append(new_hook)

with open(settings_path, 'w', encoding='utf-8') as f:
    json.dump(settings, f, indent=2)
print('Hooks merged into settings.json')
"@
    & $pythonCmd -c $pyScript
    Write-Host "✓ Hooks added to Claude Code" -ForegroundColor Green
}

Write-Host ""

# ── STEP 5: Graphify Skill ───────────────────────────────────────

Write-Host "STEP 5 OF 6 — Install Graphify skill" -ForegroundColor White
Write-Host "─────────────────────────────────────────────────────────"
Write-Host "Will copy to ~\.claude\skills\graphify\"
Write-Host "After install: /graphify <folder> maps any project to your vault."
Write-Host ""
$confirm = Read-Host "Proceed? (y/n)"

if ($confirm -eq "y") {
    $skillDest = "$env:USERPROFILE\.claude\skills\graphify"
    New-Item -ItemType Directory -Force -Path $skillDest | Out-Null
    Copy-Item "$ScriptDir\skills\graphify\SKILL.md" "$skillDest\SKILL.md" -Force
    Write-Host "✓ Graphify installed at $skillDest" -ForegroundColor Green
}

Write-Host ""

# ── STEP 6: Done ─────────────────────────────────────────────────

Write-Host "STEP 6 OF 6 — You're ready" -ForegroundColor White
Write-Host "─────────────────────────────────────────────────────────"
Write-Host "✓ Vault:     $VaultPath" -ForegroundColor Green
Write-Host "✓ MCP:       obsidian-mcp + vault-search registered" -ForegroundColor Green
Write-Host "✓ Hooks:     Stop + PreCompact added to Claude Code" -ForegroundColor Green
Write-Host "✓ Graphify:  /graphify skill installed" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open Obsidian -> 'Open folder as vault' -> pick $VaultPath"
Write-Host "  2. Open Claude Code in any terminal"
Write-Host "  3. Sessions auto-save to 03-Daily/ when you close Claude Code"
Write-Host "  4. Run /graphify <folder> to map any project to your vault"
if ($CodePath) {
    Write-Host ""
    Write-Host "  Your code project: $CodePath"
    Write-Host "  Run: /graphify $CodePath --obsidian --obsidian-dir $VaultPath\04-Resources\code-topology"
}
Write-Host ""
Write-Host "Enjoy your 2nd brain."
Write-Host ""
