# Claude 2nd Brain

Personal knowledge system: Obsidian vault + Claude Code hooks (auto pull + commit + push on every session end) + Graphify (code-to-knowledge-graph). Clone and run one script — everything configures itself.

## Prerequisites

| Tool | Check | Install |
|---|---|---|
| Claude Code | `claude --version` | [claude.ai/code](https://claude.ai/code) |
| Node.js 18+ | `node --version` | [nodejs.org](https://nodejs.org) |
| Python 3.8+ | `python3 --version` | [python.org](https://python.org) |
| Git | `git --version` | [git-scm.com](https://git-scm.com) |
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

- **Obsidian vault** at the path you choose — 8 folders, ready to open, initialized as a git repo
- **One MCP server** registered in Claude Code:
  - `vault-search` — full-text BM25 search across all your notes
- **Writes go through Claude Code's native tools** (Write / Edit / Read on direct file paths). No Obsidian MCP is installed — it's slow on large vaults and the native tools are faster and more reliable.
- **Stop hook (vault-autosave):** every time you close Claude Code, the hook runs `git pull --rebase` then commits + pushes any changes. You never manually commit.
- **`/save-session` command:** run this when you want a rich capture — writes a structured daily note with decisions, reasoning, and action items, then pushes.
- **`/brain-sync` command:** processes your inbox, adds frontmatter, links, and fixes broken wikilinks. Schedule it via Claude Code's `/schedule` skill to run automatically every few days — don't run it inside a work session.
- **Graphify skill** — run `/graphify <folder>` to map any code project into a navigable knowledge graph that writes directly to your vault.

## Vault structure

```
your-brain/
├── 00-Inbox/          ← raw captures, processed by scheduled /brain-sync
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

## Why no Obsidian MCP?

Earlier versions of this template installed `obsidian-mcp` to let Claude create, read, and edit notes over MCP. On vaults larger than a few hundred notes, that server re-indexed on every call and froze Claude sessions. **We removed it.** All vault writes now use Claude Code's native Write / Edit / Read tools on direct file paths. Obsidian reads the file the next time it opens — no MCP needed.

`vault-search` stays — it uses a BM25 index and is fast.

## Using Graphify

```bash
# Map any project to your vault
/graphify ~/my-project --obsidian --obsidian-dir ~/my-brain/04-Resources/code-topology

# Query the graph
/graphify query "how does authentication work?"
```

See [docs/graphify-usage.md](docs/graphify-usage.md) for full usage.

## Scheduled maintenance

The `/brain-sync` command (inbox processing, wikilinks, broken-link audit) is designed to run on a schedule, not interactively. Use Claude Code's `/schedule` skill to create a remote trigger — example cadence: every 3 days at 3 AM local time. The remote agent clones your vault, processes the inbox, and pushes back. Your local vault picks up the changes on the next session via the Stop hook's `git pull`.

## Docs

- [How it works](docs/how-it-works.md)
- [MCP servers](docs/mcp-servers.md)
- [Graphify usage](docs/graphify-usage.md)

## After install

1. Open Obsidian → **Open folder as vault** → pick your vault path
2. Open any terminal → start Claude Code
3. Your sessions auto-save (pull + commit + push) when you close Claude Code
4. Run `/graphify <path>` to map any project
5. (Recommended) Use `/schedule` to run `/brain-sync` every 3 days on Anthropic's remote agent infrastructure

## Windows note

The Stop hook uses bash. On Windows it requires **Git Bash** or **WSL**. The MCP server and Graphify skill work natively on Windows with no extra setup. See [docs/mcp-servers.md](docs/mcp-servers.md).
