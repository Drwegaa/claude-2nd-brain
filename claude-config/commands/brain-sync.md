Process and organize the Obsidian vault at {{VAULT_PATH}}/. Execute ALL steps in order:

1. **Inbox Processing** — Read ALL files in `00-Inbox/`. For each one: add frontmatter (tags, date, related links), add relevant `[[wikilinks]]` to other vault notes, and move it to the correct folder (`01-Projects/`, `04-Resources/`, `05-People/`, `06-Personal/`, etc).

2. **Personal Notes Scan** — Scan `06-Personal/` for any notes missing frontmatter or [[links]]. Tag and link them.

3. **Stale Links Check** — Identify any broken `[[wikilinks]]` across the vault and flag them for review (do not auto-delete).

4. **Push to GitHub** — Run: `cd {{VAULT_PATH}} && git add -A && git diff --staged --quiet || git commit -m "brain-sync: $(date '+%Y-%m-%d %H:%M')" && git push origin main`

5. **Confirmation** — End with: "Brain sync complete. [X] inbox notes filed, [Y] personal notes updated, [Z] broken links flagged. Pushed to GitHub."
