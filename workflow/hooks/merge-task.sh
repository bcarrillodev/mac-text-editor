#!/bin/bash
# scripts/merge-task.sh
WORKTREE_PATH=$1

# Run the Reviewer agent via CLI
gemini --include-directories "$WORKTREE_PATH" "Perform final review of the code in this worktree based on @reviewer.md."

# If approved, merge and cleanup
git merge "$BRANCH_NAME"
git worktree remove "$WORKTREE_PATH"