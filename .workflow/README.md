# Multi-Agent Workflow

This workflow is designed to run strict role isolation:

1. **Analyst** -> produces `feature_request.json`
2. **Architect** -> produces `data_contract.json` + `PROMPT.md`
3. **QA** -> produces tests from the architect contract
4. **Worker** (one or many) -> implements only allowlisted files
5. **Reviewer** -> produces `review_report.json`
6. **Orchestrator** -> validates handoffs and decides merge/retry

## Reproducible Setup For Any Repository

Run:

```bash
./hooks/bootstrap-project.sh /absolute/path/to/target-repo [run-id]
```

Example:

```bash
./hooks/bootstrap-project.sh /Users/brandon/Repos/mac-text-editor tab-layout-run
```

This installs workflow assets into `target-repo/.workflow/` and scaffolds:

- `.workflow/agents/`
- `.workflow/contracts/`
- `.workflow/hooks/`
- `.workflow/runs/<run-id>/analyst`
- `.workflow/runs/<run-id>/architect`
- `.workflow/runs/<run-id>/qa`
- `.workflow/runs/<run-id>/workers/worker-01..N`
- `.workflow/runs/<run-id>/reviewer`
- `.workflow/runs/<run-id>/orchestrator`

`run-id` is optional and auto-generated if omitted.

Worker count is determined from Architect output by setting `worker_count` in:

` .workflow/runs/<run-id>/architect/data_contract.json `

You can still override by passing explicit `[worker-count]` as a third argument.

## Context Boundaries By Role

- **Analyst instance input**: raw feature request + read-only project context.
- **Architect instance input**: validated `feature_request.json`.
- **QA instance input**: validated `data_contract.json` + `PROMPT.md`.
- **Worker instance input**: one worktree + allowlisted files + QA tests.
- **Reviewer instance input**: `git diff` + `PROMPT.md` + validated contracts.
- **Orchestrator instance input**: state + artifact paths + validation outputs.

Each role should receive only its stage artifacts and required files.

## Required Validation Gates

Use `validate-handoff.sh` before every transition:

```bash
.workflow/hooks/validate-handoff.sh feature_request .workflow/runs/<run-id>/analyst/feature_request.json
.workflow/hooks/validate-handoff.sh structured_feature_request .workflow/runs/<run-id>/analyst/feature_request.json
.workflow/hooks/validate-handoff.sh data_contract .workflow/runs/<run-id>/architect/data_contract.json
.workflow/hooks/validate-handoff.sh review_report .workflow/runs/<run-id>/reviewer/review_report.json
.workflow/hooks/validate-handoff.sh allowlist .workflow/runs/<run-id>/architect/data_contract.json <worker-worktree-path>
```

The `structured_feature_request` gate is the hard stop before Architect. It fails unless
the Analyst output is a schema-valid `feature_request.json` with `"type": "STRUCTURED_REQUIREMENT"`.

## Underspecified Requests (Required Path)

If the user asks to run the workflow but does not provide a concrete feature, the Orchestrator must:

1. Run Analyst first.
2. Return the Analyst's `CLARIFICATION_REQUIRED` questions to the user.
3. Wait for the user's answers.
4. Re-run Analyst to produce `STRUCTURED_REQUIREMENT`.
5. Validate with `structured_feature_request` before Architect starts.

Process rule: No Architect stage without a validated `feature_request.json` of type `STRUCTURED_REQUIREMENT`.

## Orchestrator Preflight (Architect Gate)

Use the dedicated preflight hook immediately before Architect:

```bash
.workflow/hooks/orchestrator-preflight.sh .workflow/runs/<run-id>/analyst/feature_request.json
```

Exit codes:
- `0`: Analyst output is a validated `STRUCTURED_REQUIREMENT` and Architect may proceed
- `2`: Analyst returned `CLARIFICATION_REQUIRED`; stop and ask the user
- other non-zero: invalid handoff or tooling error; do not proceed

## Per-Role Model Routing (Recommended)

Use a stronger model tier for:
- Analyst
- Architect
- Reviewer

Use a faster/lower-cost model tier for:
- QA
- Worker

Shared workflow templates can define this in `config.toml` under `[models]` and `[role_models]`.
The `resolve-role-model.py` hook resolves a role to a concrete model string.

## Multi-Worker Pattern

1. Architect defines worker shards (file/path slices) and allowlists per shard.
2. Orchestrator provisions one worktree per shard with `setup-worktree.sh`.
3. Run Workers in parallel, each in a separate instance and worktree.
4. Reviewer evaluates each shard independently.
5. Merge approved shards only; rejected shards loop through Worker -> Reviewer again.
