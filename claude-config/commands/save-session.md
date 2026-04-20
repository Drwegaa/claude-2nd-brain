Save the current session to Obsidian. Execute steps in order — if a step fails, report it and continue to the next one.

**Step 1 — Local backup first**
Create a backup file at `~/Documents/session-backups/YYYY-MM-DD-HH-MM.md` (use actual date/time) using the Write tool. Content: what was built or decided this session, key decisions with reasoning, action items, and what the next session needs to know. This always works regardless of vault connectivity.

**Step 2 — Vault daily note (one write, append)**
Using obsidian-mcp, write to `03-Daily/YYYY-MM-DD.md` in the vault at `~/Documents/wegaa-brain/`. If the file already exists (another terminal already saved today), append a new `## Session HH:MM` section with the same content. If it does not exist, create it fresh with a `## Session HH:MM` header. Add [[wikilinks]] to relevant vault notes where obvious. This is ONE write call — do not make multiple obsidian-mcp calls.

**Step 3 — Project CLAUDE.md update**
Using the Edit tool (not obsidian-mcp), update the Phase Roadmap and Pending Manual Actions sections in your project CLAUDE.md — only if something actually changed this session. Skip this step if nothing changed.

**Step 4 — Confirm**
End with exactly: "Session saved — [X] decisions, [Y] actions. Backup: ~/Documents/session-backups/[filename]. Vault: 03-Daily/[date].md [appended/created]"
