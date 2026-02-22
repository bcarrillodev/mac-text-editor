#!/bin/bash
# workflow/hooks/setup-worktree.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FEATURE_ID_RAW="${1:-$(date +%s)}"
FEATURE_ID="$(printf '%s' "$FEATURE_ID_RAW" | tr -cs '[:alnum:]._-' '-' | sed -e 's/^-*//' -e 's/-*$//')"
if [ -z "$FEATURE_ID" ]; then
  echo "Feature ID produced an empty branch suffix after sanitization." >&2
  exit 1
fi

BASE_BRANCH="${BASE_BRANCH:-main}"
BRANCH_PREFIX="${BRANCH_PREFIX:-task}"
BRANCH_NAME="$BRANCH_PREFIX-$FEATURE_ID"
if ! REPO_ROOT="$(git -C "$WORKFLOW_ROOT" rev-parse --show-toplevel 2>/dev/null)"; then
  echo "setup-worktree.sh must run inside a git repository." >&2
  exit 1
fi
WORKTREE_PATH="${2:-$REPO_ROOT/worktrees/$BRANCH_NAME}"
RUN_ID="${RUN_ID:-run-$(date +%Y%m%d%H%M%S)}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$WORKFLOW_ROOT/artifacts/$RUN_ID}"
mkdir -p "$ARTIFACTS_DIR"

resolve_base_ref() {
  if git -C "$REPO_ROOT" rev-parse --verify --quiet "$BASE_BRANCH" >/dev/null; then
    echo "$BASE_BRANCH"
    return 0
  fi
  if git -C "$REPO_ROOT" rev-parse --verify --quiet "origin/$BASE_BRANCH" >/dev/null; then
    echo "origin/$BASE_BRANCH"
    return 0
  fi
  return 1
}

BASE_REF="$(resolve_base_ref)" || {
  echo "Base branch '$BASE_BRANCH' was not found locally or as origin/$BASE_BRANCH." >&2
  exit 1
}

if git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
  echo "Branch already exists: $BRANCH_NAME" >&2
  exit 1
fi

if [ -e "$WORKTREE_PATH" ] && [ -n "$(ls -A "$WORKTREE_PATH" 2>/dev/null)" ]; then
  echo "Worktree path already exists and is not empty: $WORKTREE_PATH" >&2
  exit 1
fi

cleanup_on_error() {
  local exit_code=$?
  if [ "$exit_code" -ne 0 ] && [ -d "$WORKTREE_PATH" ]; then
    git -C "$REPO_ROOT" worktree remove --force "$WORKTREE_PATH"
  fi
}
trap cleanup_on_error EXIT

echo "Creating worktree at $WORKTREE_PATH..."
git -C "$REPO_ROOT" worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$BASE_REF"

# Copy workflow metadata into an isolated context folder inside the worktree.
mkdir -p "$WORKTREE_PATH/.workflow/agents"
cp "$WORKFLOW_ROOT"/agents/*.md "$WORKTREE_PATH/.workflow/agents/"
cp -R "$WORKFLOW_ROOT/contracts" "$WORKTREE_PATH/.workflow/contracts"

cat > "$ARTIFACTS_DIR/setup-metadata.json" <<EOF
{"run_id":"$RUN_ID","feature_id":"$FEATURE_ID","branch":"$BRANCH_NAME","base_ref":"$BASE_REF","worktree":"$WORKTREE_PATH"}
EOF

echo "Worktree ready. Initialize Worker loop in $WORKTREE_PATH (run_id=$RUN_ID)."
