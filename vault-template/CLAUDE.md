# {{YOUR_NAME}}'s Brain — Vault Standing Orders

You are operating inside {{YOUR_NAME}}'s personal knowledge vault at {{VAULT_PATH}}.

## Vault Structure

| Folder | Purpose |
|---|---|
| 00-Inbox | Raw captures — process weekly |
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

## MCP Tools Available

- `obsidian` MCP — read/write/move notes by path
- `vault-search` MCP — full-text BM25 search across all notes

Always prefer searching before creating to avoid duplicate notes.
