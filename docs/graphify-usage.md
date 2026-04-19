# Graphify Usage

Graphify turns any folder into a navigable knowledge graph with community detection.

## Basic usage

```bash
# Map a project and write to vault
/graphify ~/my-project --obsidian --obsidian-dir ~/my-brain/04-Resources/code-topology

# Map current directory
/graphify

# Map with deep extraction (more INFERRED edges)
/graphify ~/my-project --mode deep

# Update incrementally after changes (reuses cached extractions)
/graphify ~/my-project --update
```

## Querying the graph

```bash
# Ask a question about the codebase
/graphify query "how does authentication work?"

# Find shortest path between two concepts
/graphify path "UserLogin" "Database"

# Explain a specific concept
/graphify explain "SessionManager"
```

## Outputs

After running, Graphify creates in `graphify-out/`:

| File | What it is |
|---|---|
| `graph.html` | Interactive graph — open in browser |
| `GRAPH_REPORT.md` | Audit report with god nodes, surprises, questions |
| `graph.json` | Raw graph data for further processing |
| `obsidian/` | Obsidian vault (if `--obsidian` flag used) |

## Writing to your vault

Use `--obsidian-dir` to point directly at your vault's code-topology folder:

```bash
/graphify ~/my-project \
  --obsidian \
  --obsidian-dir ~/my-brain/04-Resources/code-topology
```

This writes:
- One `.md` note per node in your vault
- `graph.canvas` — open in Obsidian for structured visual layout
- `_COMMUNITY_*` overview notes per cluster

## Tips

- Run `--update` after adding files — it only re-extracts changed files (saves tokens)
- Run `--cluster-only` to re-label communities without re-extracting
- Add `--wiki` to generate a crawlable wiki (`index.md` + one article per community)
- For code-only projects: first run builds the graph, subsequent `--update` runs are fast (AST-only, no LLM)

## Prerequisites

Graphify installs the `graphifyy` Python package automatically on first run. Requires Python 3.8+.
