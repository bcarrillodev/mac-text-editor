#!/bin/bash
# workflow/hooks/merge-task.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

WORKTREE_PATH="${1:-}"
DATA_CONTRACT_PATH="${2:-$WORKTREE_PATH/contracts/data_contract.json}"
REVIEW_REPORT_PATH="${3:-$WORKTREE_PATH/.workflow/review_report.json}"
BASE_BRANCH="${BASE_BRANCH:-main}"
DELETE_BRANCH_ON_MERGE="${DELETE_BRANCH_ON_MERGE:-1}"
REVIEWER_BIN="${REVIEWER_BIN:-gemini}"
REVIEWER_MODEL="${REVIEWER_MODEL:-}"
REVIEWER_MODEL_FLAG="${REVIEWER_MODEL_FLAG:-}"
ROLE_MODEL_RESOLVER="${ROLE_MODEL_RESOLVER:-$SCRIPT_DIR/resolve-role-model.py}"
RUN_ID="${RUN_ID:-run-$(date +%Y%m%d%H%M%S)}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$WORKFLOW_ROOT/artifacts/$RUN_ID}"
mkdir -p "$ARTIFACTS_DIR"

if [ -z "$WORKTREE_PATH" ]; then
  echo "Usage: $0 <worktree-path> [data-contract-path] [review-report-path]" >&2
  exit 1
fi

if [ ! -d "$WORKTREE_PATH" ]; then
  echo "Worktree path does not exist: $WORKTREE_PATH" >&2
  exit 1
fi

if ! REPO_ROOT="$(git -C "$WORKFLOW_ROOT" rev-parse --show-toplevel 2>/dev/null)"; then
  echo "merge-task.sh must run inside a git repository." >&2
  exit 1
fi

repo_common_dir="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir)"
worktree_common_dir="$(git -C "$WORKTREE_PATH" rev-parse --path-format=absolute --git-common-dir)"
if [ "$repo_common_dir" != "$worktree_common_dir" ]; then
  echo "Worktree does not belong to the same repository as $REPO_ROOT." >&2
  exit 1
fi

if [ ! -x "$SCRIPT_DIR/validate-handoff.sh" ]; then
  echo "Missing executable hook: $SCRIPT_DIR/validate-handoff.sh" >&2
  exit 1
fi

if [ ! -x "$SCRIPT_DIR/validate-json.py" ] || [ ! -x "$SCRIPT_DIR/extract-json.py" ]; then
  echo "Missing executable helper scripts in $SCRIPT_DIR" >&2
  exit 1
fi

if ! command -v "$REVIEWER_BIN" >/dev/null 2>&1; then
  echo "Reviewer command not found on PATH: $REVIEWER_BIN" >&2
  exit 1
fi

if [ -z "$REVIEWER_MODEL" ] && [ -x "$ROLE_MODEL_RESOLVER" ]; then
  REVIEWER_MODEL="$("$ROLE_MODEL_RESOLVER" reviewer 2>/dev/null || true)"
fi

current_branch="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"
if [ "$current_branch" != "$BASE_BRANCH" ]; then
  echo "Current branch is '$current_branch'. Checkout '$BASE_BRANCH' before merging." >&2
  exit 1
fi

if [ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]; then
  echo "Refusing to merge with uncommitted changes in $REPO_ROOT." >&2
  exit 1
fi

cleanup_worktree() {
  local exit_code=$?
  if [ "$exit_code" -eq 0 ]; then
    if ! git -C "$REPO_ROOT" worktree remove --force "$WORKTREE_PATH"; then
      echo "Warning: failed to remove worktree $WORKTREE_PATH" >&2
    fi
    if [ "$DELETE_BRANCH_ON_MERGE" -eq 1 ]; then
      git -C "$REPO_ROOT" branch -d "$BRANCH_NAME" >/dev/null 2>&1 || true
    fi
  fi
}
trap cleanup_worktree EXIT

BRANCH_NAME="$(git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD)"
if [ "$BRANCH_NAME" = "$BASE_BRANCH" ]; then
  echo "Worktree branch cannot be the same as base branch '$BASE_BRANCH'." >&2
  exit 1
fi

mkdir -p "$(dirname "$REVIEW_REPORT_PATH")"

# Run the Reviewer and convert mixed stdout into strict JSON.
reviewer_prompt="Perform final review of the code in this worktree based on @.workflow/agents/reviewer.md. Return ONLY a single JSON object that conforms to contracts/review_report.schema.json."
reviewer_log_path="$ARTIFACTS_DIR/reviewer-output.log"
reviewer_cmd=("$REVIEWER_BIN")
if [ -n "$REVIEWER_MODEL" ] && [ -n "$REVIEWER_MODEL_FLAG" ]; then
  reviewer_cmd+=("$REVIEWER_MODEL_FLAG" "$REVIEWER_MODEL")
fi
reviewer_cmd+=(--include-directories "$WORKTREE_PATH" "$reviewer_prompt")
"${reviewer_cmd[@]}" > "$reviewer_log_path"
python3 "$SCRIPT_DIR/extract-json.py" "$reviewer_log_path" "$REVIEW_REPORT_PATH"

# Validate review report, data contract, and changed-file allowlist before merge.
BASE_BRANCH="$BASE_BRANCH" "$SCRIPT_DIR/validate-handoff.sh" review_report "$REVIEW_REPORT_PATH"
BASE_BRANCH="$BASE_BRANCH" "$SCRIPT_DIR/validate-handoff.sh" data_contract "$DATA_CONTRACT_PATH"
BASE_BRANCH="$BASE_BRANCH" "$SCRIPT_DIR/validate-handoff.sh" allowlist "$DATA_CONTRACT_PATH" "$WORKTREE_PATH"

decision="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["decision"])' "$REVIEW_REPORT_PATH")"
if [ "$decision" != "MERGE_APPROVED" ]; then
  echo "Merge rejected by reviewer decision: $decision" >&2
  exit 1
fi

if ! git -C "$REPO_ROOT" merge --ff-only "$BRANCH_NAME"; then
  echo "Fast-forward merge failed. Rebase/retry the worker branch before merging." >&2
  exit 1
fi

echo "Merge completed for branch $BRANCH_NAME into $BASE_BRANCH."
