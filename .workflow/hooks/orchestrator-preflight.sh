#!/usr/bin/env bash
# workflow/hooks/orchestrator-preflight.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATE_HANDOFF_SH="${VALIDATE_HANDOFF_SH:-$SCRIPT_DIR/validate-handoff.sh}"

FEATURE_REQUEST_JSON="${1:-}"

if [ -z "$FEATURE_REQUEST_JSON" ]; then
  echo "Usage: $0 <feature-request-json-path>" >&2
  exit 1
fi

if [ ! -x "$VALIDATE_HANDOFF_SH" ]; then
  echo "Missing executable validator: $VALIDATE_HANDOFF_SH" >&2
  exit 1
fi

"$VALIDATE_HANDOFF_SH" feature_request "$FEATURE_REQUEST_JSON"

feature_type="$(
  python3 - "$FEATURE_REQUEST_JSON" <<'PY'
import json
import sys
print(json.load(open(sys.argv[1], "r", encoding="utf-8")).get("type", ""))
PY
)"

case "$feature_type" in
  STRUCTURED_REQUIREMENT)
    "$VALIDATE_HANDOFF_SH" structured_feature_request "$FEATURE_REQUEST_JSON"
    echo "Preflight OK: Analyst output is a validated STRUCTURED_REQUIREMENT. Architect may proceed."
    ;;
  CLARIFICATION_REQUIRED)
    echo "Preflight blocked: Analyst output requests user clarification. Do not invoke Architect yet." >&2
    exit 2
    ;;
  *)
    echo "Preflight failed: Unknown feature_request type '$feature_type'." >&2
    exit 1
    ;;
esac
