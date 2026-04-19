# Claude 2nd Brain

Personal knowledge system: Obsidian vault + Claude Code hooks (auto session-save) + Graphify (code-to-knowledge-graph). Clone and run one script — everything configures itself.

## Prerequisites

| Tool | Check | Install |
|---|---|---|
| Claude Code | `claude --version` | [claude.ai/code](https://claude.ai/code) |
| Node.js 18+ | `node --version` | [nodejs.org](https://nodejs.org) |
| Python 3.8+ | `python3 --version` | [python.org](https://python.org) |
| Obsidian | open app | [obsidian.md](https://obsidian.md) |

## Install

**Mac / Linux**
```bash
git clone https://github.com/Drwegaa/claude-2nd-brain.git
cd claude-2nd-brain
bash setup.sh
```

**Windows (PowerShell)**
```powershell
git clone https://github.com/Drwegaa/claude-2nd-brain.git
cd claude-2nd-brain
.\setup.ps1
```

The wizard walks you through each step and asks for confirmation before doing anything.

## What you get

After setup:

- **Obsidian vault** at the path you choose — 8 folders, ready to open
- **Two MCP servers** registered in Claude Code:
  - `obsidian` — read/write notes directly from Claude
  - `vault-search` — full-text BM25 search across all your notes
- **Two Claude Code hooks:**
  - *Stop hook* — when you close Claude Code, checks if today's daily note exists. If not, prompts Claude to write one.
  - *PreCompact hook* — before context compaction, Claude auto-saves the session summary to your vault
- **Graphify skill** — run `/graphify <folder>` to map any code project into a navigable knowledge graph that writes directly to your vault

## Vault structure

```
your-brain/
├── 00-Inbox/          ← raw captures, process weekly
├── 01-Projects/       ← one note per active project
├── 02-Decisions/      ← ADRs with date, decision, why
├── 03-Daily/          ← auto-logged session summaries
├── 04-Resources/
│   ├── topics/        ← MOC hubs (you fill these)
│   └── code-topology/ ← Graphify output (auto-generated)
├── 05-People/         ← team, clients, contacts
├── 06-Personal/       ← personal notes, research
├── 07-Sessions/       ← optional: historical chat ingestion
└── 08-Archive/        ← done or paused
```

## Using Graphify

```bash
# Map any project to your vault
/graphify ~/my-project --obsidian --obsidian-dir ~/my-brain/04-Resources/code-topology

# Query the graph
/graphify query "how does authentication work?"
```

See [docs/graphify-usage.md](docs/graphify-usage.md) for full usage.

## Docs

- [How it works](docs/how-it-works.md)
- [MCP servers](docs/mcp-servers.md)
- [Graphify usage](docs/graphify-usage.md)

## After install

1. Open Obsidian → **Open folder as vault** → pick your vault path
2. Open any terminal → start Claude Code
3. Your sessions auto-save when you close Claude Code
4. Run `/graphify <path>` to map any project

## Windows note

The Stop and PreCompact hooks use bash commands. On Windows they require **Git Bash** or **WSL**. The MCP servers and Graphify skill work natively on Windows with no extra setup. See [docs/mcp-servers.md](docs/mcp-servers.md) for Windows-specific instructions.
