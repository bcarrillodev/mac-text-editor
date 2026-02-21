#!/bin/bash
set -euo pipefail

# Merges a completed worktree branch back into the base branch and removes the worktree.
#
# Usage:
#   ./workflow/hooks/merge-task.sh <worktree-path> [base-branch]
#
# Env:
#   REVIEW_CMD   Command used to run the reviewer agent (default: gemini).
#   SKIP_REVIEW  If set to "1", skips reviewer step.

if [ "${1:-}" = "" ]; then
  echo "Usage: $0 <worktree-path> [base-branch]" >&2
  exit 2
fi

WORKTREE_PATH="$1"
BASE_BRANCH="${2:-main}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd -- "$WORKFLOW_DIR/.." && pwd)"

if [ ! -d "$WORKTREE_PATH/.git" ] && [ ! -f "$WORKTREE_PATH/.git" ]; then
  echo "Not a git worktree: $WORKTREE_PATH" >&2
  exit 2
fi

BRANCH_NAME="$(git -C "$WORKTREE_PATH" branch --show-current || true)"
if [ "$BRANCH_NAME" = "" ]; then
  echo "Could not determine branch name for worktree: $WORKTREE_PATH" >&2
  exit 2
fi

if [ "${SKIP_REVIEW:-0}" != "1" ]; then
  REVIEW_CMD="${REVIEW_CMD:-gemini}"
  if command -v "$REVIEW_CMD" >/dev/null 2>&1; then
    (cd "$REPO_DIR" && "$REVIEW_CMD" --include-directories "$WORKTREE_PATH" \
      "Perform final review of the code in this worktree based on @workflow/agents/reviewer.md.")
  else
    echo "Reviewer command not found: $REVIEW_CMD (set SKIP_REVIEW=1 to bypass)" >&2
    exit 2
  fi
fi

git -C "$REPO_DIR" checkout "$BASE_BRANCH"
if [ -n "$(git -C "$REPO_DIR" status --porcelain)" ]; then
  echo "Base branch has local changes; refusing to merge. Clean your working tree first." >&2
  exit 2
fi

echo "Merging $BRANCH_NAME into $BASE_BRANCH..."
git -C "$REPO_DIR" merge --no-edit --no-ff "$BRANCH_NAME"

echo "Removing worktree at $WORKTREE_PATH..."
git -C "$REPO_DIR" worktree remove "$WORKTREE_PATH"
