# {{YOUR_NAME}}'s Brain — Vault Standing Orders

You are operating inside {{YOUR_NAME}}'s personal knowledge vault at {{VAULT_PATH}}.

## Vault Structure

| Folder | Purpose |
|---|---|
| 00-Inbox | Raw captures — process on a schedule, not during sessions |
| 01-Projects | One note per active project |
| 02-Decisions | ADRs: date, decision, why, alternatives |
| 03-Daily | Auto-logged session summaries |
| 04-Resources/topics | MOC hubs linking related ideas |
| 04-Resources/code-topology | Graphify knowledge graph output |
| 05-People | Team, clients, contacts |
| 06-Personal | Personal notes, research, ideas |
| 07-Sessions | Historical chat ingestion (optional) |
| 08-Archive | Everything done or paused |

## Rules

- Always write to the correct folder
- Decisions → `02-Decisions/YYYY-MM-DD-topic.md`
- Daily notes → `03-Daily/YYYY-MM-DD.md`
- Never delete — archive instead (move to 08-Archive)
- Use [[wikilinks]] to connect related notes
- When capturing from a conversation, include: date, context, key decisions, next actions

## Vault Context Protocol (recommended)

The vault is NOT auto-loaded at session start — only your `CLAUDE.md` + `MEMORY.md` are. To make Claude actually use the vault, add this decision tree to your global `~/.claude/CLAUDE.md` (or keep it here if you work inside the vault):

1. **Check loaded context first** (CLAUDE.md + MEMORY.md) — free, already in context
2. **If the question references past work, decisions, people, projects, or captured notes AND it's not in step 1 → search the vault** with `mcp__vault-search__search_notes` before answering
3. **If the vault doesn't have it either → say so explicitly.** Never fabricate from training data when the question is about the user's own history

**Don't search the vault for:** generic coding tasks, questions already answered by loaded context, or real-time external lookups.

**When unsure, search.** Missed search = wrong answer. Extra search = ~500 tokens. Err toward searching.

## How to Write to the Vault

**Use the Write/Edit/Read tools directly on file paths.** Do not use an Obsidian MCP server for writes — on large vaults it re-indexes on every call and can freeze sessions. Obsidian reads the file from disk the next time it opens, so no MCP is needed to create or modify notes.

For search, use the `vault-search` MCP — it uses a BM25 index and is fast. Always search before creating a new note to avoid duplicates.

## Auto-save

A Stop hook (`scripts/vault-autosave.sh`) runs on every session end:
1. `git pull --rebase --autostash` — picks up any overnight changes from the remote
2. Commits local changes with message `autosave: <timestamp>`
3. Pushes to origin/main

You do not need to commit manually. If you make changes and close the session, they sync automatically. If you want a rich capture (decisions + reasoning), run `/save-session` before closing.

## Scheduled Maintenance

`/brain-sync` runs on a schedule (every few days) via a remote agent — it processes `00-Inbox`, adds frontmatter + wikilinks, fixes broken links, then pushes back to the remote. **Do not run `/brain-sync` manually inside a work session** — it is maintenance, not session-save. The Stop hook pulls the results the next time you open Claude Code.
