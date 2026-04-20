Save the current session to the Obsidian vault. Execute steps in order — if a step fails, report it and continue to the next one.

**Step 1 — Local backup first (always works, no dependencies)**
Use the Write tool to create `{{BACKUPS_DIR}}/YYYY-MM-DD-HH-MM.md` (use actual date/time). Content: what was built or decided this session, key decisions with reasoning, action items, and what the next session needs to know. This always works regardless of vault connectivity.

**Step 2 — Vault daily note (Write tool, NOT an Obsidian MCP)**
Use the Write tool directly on the file path `{{VAULT_PATH}}/03-Daily/YYYY-MM-DD.md`.
- If the file exists: Read it first, then Write the full content back with a new `## Session HH:MM` section appended.
- If it does not exist: Write a fresh file with a `## Session HH:MM` header.
- Add `[[wikilinks]]` to relevant vault notes where obvious.

**Do not use an `obsidian-mcp` server to write.** It re-indexes the vault on every call and freezes Claude on large vaults. Direct file writes are fast and reliable. Obsidian picks up the new file the next time it opens the vault — no MCP needed.

**Step 3 — Commit + push vault to remote**
Run via Bash:
```
cd {{VAULT_PATH}} && git add -A && (git diff --staged --quiet || (git commit -m "save-session: $(date '+%Y-%m-%d %H:%M')" && git push origin main))
```

**Step 4 — Confirm**
End with exactly: `Session saved — [X] decisions, [Y] actions. Backup: {{BACKUPS_DIR}}/[filename]. Vault: 03-Daily/[date].md [appended/created]. Git: [pushed/no changes].`

---

**Note.** The Stop hook also pushes your vault automatically on every session end (via `scripts/vault-autosave.sh`). `/save-session` is for *rich* captures — decisions with reasoning, action items, multi-paragraph context. For silent sync, just close the session and the Stop hook handles it.
