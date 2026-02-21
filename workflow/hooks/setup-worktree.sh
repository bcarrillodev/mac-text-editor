#!/bin/bash
set -euo pipefail

# Creates a git worktree for an isolated feature/task branch.
#
# Usage:
#   ./workflow/hooks/setup-worktree.sh [branch-name] [base-ref]
#
# Defaults:
#   branch-name: task-<epoch>
#   base-ref:    main

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd -- "$WORKFLOW_DIR/.." && pwd)"

BRANCH_NAME="${1:-task-$(date +%s)}"
BASE_REF="${2:-main}"
WORKTREES_DIR="$REPO_DIR/worktrees"
WORKTREE_PATH="$WORKTREES_DIR/$BRANCH_NAME"

mkdir -p "$WORKTREES_DIR"

echo "Creating worktree at $WORKTREE_PATH (branch: $BRANCH_NAME, base: $BASE_REF)..."
git -C "$REPO_DIR" worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$BASE_REF"

echo "Worktree ready at $WORKTREE_PATH."
