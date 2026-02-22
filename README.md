# mac-text-editor
Text editor for macOS featuring tabs and numbered lines.

## Orchestrated Multi-Agent Workflow

This project is wired for isolated role execution under `.workflow/`:

- `agents/` role specs
- `contracts/` JSON schemas
- `hooks/` orchestration scripts
- `runs/<run-id>/` per-role artifacts and worker shards

Bootstrap or refresh workflow assets from the shared workflow repo:

```bash
<path-to-workflow>/hooks/bootstrap-project.sh <path-to-this-repo> [run-id]
```

Example:

```bash
../workflow/hooks/bootstrap-project.sh "$(pwd)"
```

`run-id` auto-generates when omitted, and worker count comes from Architect via:
`.workflow/runs/<run-id>/architect/data_contract.json` (`worker_count`).
