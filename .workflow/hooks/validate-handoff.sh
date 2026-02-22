#!/bin/bash
# workflow/hooks/validate-handoff.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTRACTS_DIR="${CONTRACTS_DIR:-$WORKFLOW_ROOT/contracts}"
BASE_BRANCH="${BASE_BRANCH:-main}"
ALLOWLIST_IGNORE_PREFIXES="${ALLOWLIST_IGNORE_PREFIXES:-.workflow/}"

MODE="${1:-}"
JSON_PATH="${2:-}"
WORKTREE_PATH="${3:-}"

if [ -z "$MODE" ] || [ -z "$JSON_PATH" ]; then
  echo "Usage: $0 <feature_request|structured_feature_request|data_contract|review_report|allowlist> <json-path> [worktree-path]" >&2
  exit 1
fi

if [ ! -f "$JSON_PATH" ]; then
  echo "Missing JSON file: $JSON_PATH" >&2
  exit 1
fi

resolve_base_ref() {
  local git_path="$1"
  if git -C "$git_path" rev-parse --verify --quiet "$BASE_BRANCH" >/dev/null; then
    echo "$BASE_BRANCH"
    return 0
  fi
  if git -C "$git_path" rev-parse --verify --quiet "origin/$BASE_BRANCH" >/dev/null; then
    echo "origin/$BASE_BRANCH"
    return 0
  fi
  return 1
}

validate_against_schema() {
  local schema_path="$1"
  if [ ! -f "$schema_path" ]; then
    echo "Missing schema file: $schema_path" >&2
    exit 1
  fi
  python3 "$SCRIPT_DIR/validate-json.py" "$schema_path" "$JSON_PATH"
}

require_feature_request_type() {
  local required_type="$1"
  python3 - "$JSON_PATH" "$required_type" <<'PY'
import json
import sys

payload = json.load(open(sys.argv[1]))
required = sys.argv[2]
actual = payload.get("type")
if actual != required:
    print(
        f"feature_request type must be {required!r}, got {actual!r}",
        file=sys.stderr,
    )
    sys.exit(1)
PY
}

if [ "$MODE" = "allowlist" ]; then
  if [ -z "$WORKTREE_PATH" ]; then
    echo "allowlist mode requires worktree path" >&2
    exit 1
  fi
  if [ ! -d "$WORKTREE_PATH" ]; then
    echo "Missing worktree path: $WORKTREE_PATH" >&2
    exit 1
  fi
  validate_against_schema "$CONTRACTS_DIR/data_contract.schema.json"
  compare_ref="$(resolve_base_ref "$WORKTREE_PATH")" || {
    echo "Base branch '$BASE_BRANCH' was not found in worktree refs." >&2
    exit 1
  }
  python3 - "$JSON_PATH" "$WORKTREE_PATH" "$compare_ref" "$ALLOWLIST_IGNORE_PREFIXES" <<'PY'
import json
import subprocess
import sys

def normalize(path: str) -> str:
    return path.strip().removeprefix("./")

def should_ignore(path: str, ignored_prefixes: list[str]) -> bool:
    return any(path.startswith(prefix) for prefix in ignored_prefixes)

contract = json.load(open(sys.argv[1]))
worktree_path = sys.argv[2]
compare_ref = sys.argv[3]
ignored_prefixes = [item.strip() for item in sys.argv[4].split(",") if item.strip()]
allowed = {normalize(path) for path in contract.get("allowed_files", [])}
changed = set()

commands = [
    ["git", "-C", worktree_path, "diff", "--name-only", f"{compare_ref}...HEAD"],
    ["git", "-C", worktree_path, "diff", "--name-only"],
    ["git", "-C", worktree_path, "diff", "--name-only", "--cached"],
    ["git", "-C", worktree_path, "ls-files", "--others", "--exclude-standard"],
]

for command in commands:
    output = subprocess.check_output(command, text=True).splitlines()
    for path in output:
        normalized = normalize(path)
        if normalized:
            changed.add(normalized)

violations = sorted(path for path in changed if path not in allowed)
violations = [path for path in violations if not should_ignore(path, ignored_prefixes)]
if violations:
    print("Changed files outside allowlist:", ", ".join(violations), file=sys.stderr)
    sys.exit(1)
PY
  exit 0
fi

case "$MODE" in
  feature_request)
    validate_against_schema "$CONTRACTS_DIR/feature_request.schema.json"
    ;;
  structured_feature_request)
    validate_against_schema "$CONTRACTS_DIR/feature_request.schema.json"
    require_feature_request_type "STRUCTURED_REQUIREMENT"
    ;;
  data_contract)
    validate_against_schema "$CONTRACTS_DIR/data_contract.schema.json"
    ;;
  review_report)
    validate_against_schema "$CONTRACTS_DIR/review_report.schema.json"
    ;;
  *)
    echo "unknown validation mode: $MODE" >&2
    exit 1
    ;;
esac
