# How It Works

## Architecture

```
You                Claude Code           Obsidian
 │                      │                    │
 │  ask anything        │                    │
 ├─────────────────────>│                    │
 │                      │  write daily note  │
 │                      ├──────────────────->│
 │                      │  search past notes │
 │                      ├──────────────────->│
 │                      │  read context      │
 │                      │<───────────────────┤
 │  answer + saves      │                    │
 │<─────────────────────┤                    │
 │  close session       │                    │
 ├─────────────────────>│  Stop hook fires   │
 │                      ├──────────────────->│  03-Daily/today.md
```

## Components

### Obsidian Vault
The vault is a folder of Markdown files organized into 8 folders. Obsidian renders them with backlinks, tags, and graph view. You can use it without Obsidian too — it's just Markdown files.

### MCP Servers
Two MCP (Model Context Protocol) servers connect Claude Code to your vault:

- **obsidian-mcp** — lets Claude read, write, and move notes by file path
- **@bitbonsai/mcpvault** — full-text BM25 search so Claude can find notes by keyword

These run locally as child processes via `npx`. No cloud, no account, no API key.

### Claude Code Hooks
Hooks are shell commands that Claude Code runs automatically on events:

| Hook | Fires when | What it does |
|---|---|---|
| Stop | You close Claude Code | Checks if today's daily note exists. If not, prompts Claude to write one. |
| PreCompact | Context is about to compact | Claude writes full session summary to vault before history is lost. |

The Stop hook uses `asyncRewake` — it wakes Claude back up after you close the session to finish writing the daily note. You see a prompt: "Auto-save needed for YYYY-MM-DD" and Claude handles it.

### Graphify Skill
Graphify is a Claude Code skill that maps any folder into a knowledge graph. It:
1. Extracts entities and relationships from code, docs, PDFs, images
2. Runs community detection to find clusters
3. Writes an Obsidian vault with one note per node + a `.canvas` visual map
4. Saves to `04-Resources/code-topology/` in your vault

Run it with: `/graphify ~/my-project --obsidian --obsidian-dir ~/my-brain/04-Resources/code-topology`

## Data flow

1. Every Claude Code session ends → daily note written to `03-Daily/`
2. Every major decision → note written to `02-Decisions/`
3. Every project mapped → knowledge graph written to `04-Resources/code-topology/`
4. Your vault grows as a side effect of working — no manual capture needed
