#!/bin/bash
# scripts/setup-worktree.sh
BRANCH_NAME="task-$(date +%s)"
WORKTREE_PATH="./worktrees/$BRANCH_NAME"

echo "Creating worktree at $WORKTREE_PATH..."
git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" main

# Copy the agent files into the worktree context if they aren't globally tracked
cp agents/*.md "$WORKTREE_PATH/"

echo "Worktree ready. Initialize Worker loop in $WORKTREE_PATH."