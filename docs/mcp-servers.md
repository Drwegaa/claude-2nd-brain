# MCP Servers

Two MCP servers are registered during setup. Both run locally via `npx` — no cloud, no account, no API key.

## obsidian-mcp

Package: `obsidian-mcp`  
Source: [github.com/calclavia/obsidian-mcp](https://github.com/calclavia/obsidian-mcp)

Tools it gives Claude:
- Read a note by path
- Write a note by path (creates if not exists)
- List directory contents
- Move/rename notes

## @bitbonsai/mcpvault

Package: `@bitbonsai/mcpvault`  
Source: [github.com/bitbonsai/mcpvault](https://github.com/bitbonsai/mcpvault)

Tools it gives Claude:
- Full-text BM25 search across all notes
- Tag filtering
- Frontmatter queries

## Manual registration

If setup.sh failed or you want to register manually, add this to `~/.claude.json`:

```json
{
  "mcpServers": {
    "vault-search": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@bitbonsai/mcpvault", "/absolute/path/to/your/vault"],
      "env": {}
    },
    "obsidian": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "obsidian-mcp", "/absolute/path/to/your/vault"],
      "env": {}
    }
  }
}
```

Replace `/absolute/path/to/your/vault` with your actual vault path (e.g. `/Users/yourname/Documents/my-brain`).

## Windows

On Windows, replace the vault path with a Windows-style path:

```json
"args": ["-y", "obsidian-mcp", "C:\\Users\\yourname\\Documents\\my-brain"]
```

## Verify they're working

In Claude Code, ask: _"Use the obsidian MCP to list the contents of my vault root."_  
If it lists your folders, both servers are working.

## Troubleshooting

**"MCP server not found"** — Run `npx -y obsidian-mcp` manually in terminal. If it fails, check Node.js is installed.

**"Vault path not found"** — Make sure the path in `~/.claude.json` matches the actual vault folder exactly (case-sensitive on Mac/Linux).

**"Permission denied"** — Run `chmod +x ~/.claude.json` and try again.
