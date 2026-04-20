# claude-2nd-brain setup wizard — Windows (PowerShell)
# Usage: .\setup.ps1

$ErrorActionPreference = "Stop"

Clear-Host

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗"
Write-Host "║       Claude 2nd Brain — Setup Wizard v1.1              ║"
Write-Host "║   Obsidian + Claude Code + Graphify on your machine     ║"
Write-Host "╠══════════════════════════════════════════════════════════╣"
Write-Host "║  This script will:                                       ║"
Write-Host "║  Step 1 — Ask you 4 questions                           ║"
Write-Host "║  Step 2 — Create your Obsidian vault folder structure   ║"
Write-Host "║  Step 3 — Register 1 MCP server (vault-search)          ║"
Write-Host "║  Step 4 — Install vault-autosave + Stop hook            ║"
Write-Host "║  Step 5 — Install the Graphify skill                    ║"
Write-Host "║  Step 6 — Final instructions                            ║"
Write-Host "║                                                          ║"
Write-Host "║  Prerequisites:                                          ║"
Write-Host "║  ✓ Claude Code  (claude --version)                      ║"
Write-Host "║  ✓ Node.js      (node --version)                        ║"
Write-Host "║  ✓ Python 3.8+  (python --version)                     ║"
Write-Host "║  ✓ Git          (git --version)                         ║"
Write-Host "║  ✓ Git Bash     (for the Stop hook)                     ║"
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

Write-Host "STEP 3 OF 6 — Register MCP server" -ForegroundColor White
Write-Host "─────────────────────────────────────────────────────────"
Write-Host "Will register in ~\.claude.json:"
Write-Host "  @bitbonsai/mcpvault — full-text BM25 search across vault"
Write-Host ""
Write-Host "Note: obsidian-mcp is intentionally NOT installed. It re-indexes the"
Write-Host "entire vault on every call and freezes sessions on large vaults."
Write-Host "Vault writes use Claude Code's native Write/Edit/Read tools instead."
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
# Remove obsidian-mcp if it's left over from a v1.0 install
cfg['mcpServers'].pop('obsidian', None)
with open(claude_json, 'w') as f:
    json.dump(cfg, f, indent=2)
print('Registered vault-search in .claude.json')
print('Removed obsidian-mcp if present')
"@
    & $pythonCmd -c $pyScript
    Write-Host "✓ vault-search MCP registered" -ForegroundColor Green
}

Write-Host ""

# ── STEP 4: Autosave script + Stop hook ──────────────────────────

Write-Host "STEP 4 OF 6 — Install vault-autosave + Stop hook" -ForegroundColor White
Write-Host "─────────────────────────────────────────────────────────"
Write-Host "Will install:"
Write-Host "  ~\.claude\scripts\vault-autosave.sh"
Write-Host "    — Runs on every session end: git pull → commit → push"
Write-Host "    — Silent if vault isn't a git repo yet (safe to install early)"
Write-Host "  Stop + PreCompact hooks in ~\.claude\settings.json"
Write-Host ""
Write-Host "Note: the autosave script is bash. On Windows it runs via Git Bash."
Write-Host "Make sure Git for Windows is installed (includes Git Bash)."
Write-Host ""
Write-Host "To actually push to GitHub you'll need to:"
Write-Host "  (a) cd $VaultPath ; git init"
Write-Host "  (b) Create a private repo on GitHub"
Write-Host "  (c) git remote add origin <url> ; git push -u origin main"
Write-Host "Until then the hook runs silently on every session end (no-op)."
Write-Host ""
$confirm = Read-Host "Proceed? (y/n)"

if ($confirm -eq "y") {
    $claudeDir   = "$env:USERPROFILE\.claude"
    $scriptsDir  = "$claudeDir\scripts"
    if (-not (Test-Path $claudeDir))  { New-Item -ItemType Directory -Path $claudeDir  | Out-Null }
    if (-not (Test-Path $scriptsDir)) { New-Item -ItemType Directory -Path $scriptsDir | Out-Null }

    # Install vault-autosave.sh with {{VAULT_PATH}} substituted.
    # Bash-on-Windows expects POSIX paths. Convert C:\Users\... to /c/Users/...
    $posixVault = $VaultPath -replace '^([A-Za-z]):', '/$1' -replace '\\', '/'
    $posixVault = $posixVault.ToLower().Substring(0,2) + $posixVault.Substring(2)
    $autosaveTemplate = Get-Content "$ScriptDir\claude-config\scripts\vault-autosave.sh" -Raw
    $autosaveScript   = $autosaveTemplate.Replace("{{VAULT_PATH}}", $posixVault)
    # Write as UTF8 without BOM and with LF line endings for bash compatibility
    $autosaveScript = $autosaveScript -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText("$scriptsDir\vault-autosave.sh", $autosaveScript, [System.Text.UTF8Encoding]::new($false))
    Write-Host "✓ vault-autosave.sh installed" -ForegroundColor Green

    $settingsPath = "$claudeDir\settings.json"
    if (-not (Test-Path $settingsPath)) { Set-Content $settingsPath "{}" }

    $templatePath = "$ScriptDir\claude-config\settings.json.template"
    $pythonCmd = if (Get-Command python -ErrorAction SilentlyContinue) { "python" } else { "python3" }

    # For the hook command strings, use POSIX paths so Git Bash can exec them.
    $posixHome = "$env:USERPROFILE" -replace '^([A-Za-z]):', '/$1' -replace '\\', '/'
    $posixHome = $posixHome.ToLower().Substring(0,2) + $posixHome.Substring(2)
    $posixScripts = "$posixHome/.claude/scripts"

    $pyScript = @"
import json, os
vault_path   = r'$posixVault'
scripts_dir  = r'$posixScripts'
user_home    = r'$posixHome'
template_path = r'$templatePath'
settings_path = r'$settingsPath'

with open(template_path, 'r', encoding='utf-8') as f:
    template_str = f.read()
template_str = (template_str
                .replace('{{VAULT_PATH}}', vault_path)
                .replace('{{SCRIPTS_DIR}}', scripts_dir)
                .replace('{{HOME}}', user_home))
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
    Write-Host "✓ Stop + PreCompact hooks installed" -ForegroundColor Green
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
Write-Host "✓ MCP:       vault-search registered (obsidian-mcp removed)" -ForegroundColor Green
Write-Host "✓ Autosave:  ~\.claude\scripts\vault-autosave.sh" -ForegroundColor Green
Write-Host "✓ Hooks:     Stop + PreCompact added to Claude Code" -ForegroundColor Green
Write-Host "✓ Graphify:  /graphify skill installed" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open Obsidian -> 'Open folder as vault' -> pick $VaultPath"
Write-Host "  2. (Optional, to enable GitHub auto-push):"
Write-Host "     cd $VaultPath"
Write-Host "     git init ; git add -A ; git commit -m 'initial vault'"
Write-Host "     # create a private repo at github.com/new"
Write-Host "     git remote add origin <your-repo-url>"
Write-Host "     git push -u origin main"
Write-Host "  3. Open Claude Code in any terminal"
Write-Host "  4. Sessions auto-save (and auto-push, once git is wired) when you close Claude Code"
Write-Host "  5. Run /graphify <folder> to map any project to your vault"
if ($CodePath) {
    Write-Host ""
    Write-Host "  Your code project: $CodePath"
    Write-Host "  Run: /graphify $CodePath --obsidian --obsidian-dir $VaultPath\04-Resources\code-topology"
}
Write-Host ""
Write-Host "Enjoy your 2nd brain."
Write-Host ""
