#!/bin/bash
# workflow/hooks/worker-loop.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RUN_ID="${RUN_ID:-run-$(date +%Y%m%d%H%M%S)}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-$WORKFLOW_ROOT/artifacts/$RUN_ID}"
LOG_FILE="$ARTIFACTS_DIR/worker-loop.log"
mkdir -p "$ARTIFACTS_DIR"
: > "$LOG_FILE"

MAX_RETRIES="${MAX_RETRIES:-3}"
RETRY_STATE_FILE="$ARTIFACTS_DIR/retry-count"
if ! [[ "$MAX_RETRIES" =~ ^[0-9]+$ ]] || [ "$MAX_RETRIES" -lt 1 ]; then
  echo "MAX_RETRIES must be an integer >= 1 (received: $MAX_RETRIES)" >&2
  exit 1
fi
retry_count=0
if [ -f "$RETRY_STATE_FILE" ]; then
  retry_count="$(cat "$RETRY_STATE_FILE")"
  if ! [[ "$retry_count" =~ ^[0-9]+$ ]]; then
    retry_count=0
  fi
fi
retry_count=$((retry_count + 1))
echo "$retry_count" > "$RETRY_STATE_FILE"

DATA_CONTRACT_PATH="${DATA_CONTRACT_PATH:-./contracts/data_contract.json}"

LINT_CMD="${LINT_CMD:-npm run -s lint}"
TYPECHECK_CMD="${TYPECHECK_CMD:-npm run -s typecheck}"
TEST_CMD="${TEST_CMD:-npm test -- --coverage --coverageReporters=json-summary}"
COVERAGE_SUMMARY_FILE="${COVERAGE_SUMMARY_FILE:-coverage/coverage-summary.json}"

LINT_REQUIRED_DEFAULT=1
TYPECHECK_REQUIRED_DEFAULT=1
TESTS_REQUIRED_DEFAULT=1
COVERAGE_REQUIRED_DEFAULT=1
COVERAGE_THRESHOLD_DEFAULT=80

if [ -f "$DATA_CONTRACT_PATH" ]; then
  while IFS='=' read -r key value; do
    case "$key" in
      LINT_REQUIRED_DEFAULT) LINT_REQUIRED_DEFAULT="$value" ;;
      TYPECHECK_REQUIRED_DEFAULT) TYPECHECK_REQUIRED_DEFAULT="$value" ;;
      TESTS_REQUIRED_DEFAULT) TESTS_REQUIRED_DEFAULT="$value" ;;
      COVERAGE_REQUIRED_DEFAULT) COVERAGE_REQUIRED_DEFAULT="$value" ;;
      COVERAGE_THRESHOLD_DEFAULT) COVERAGE_THRESHOLD_DEFAULT="$value" ;;
    esac
  done < <(
    python3 - "$DATA_CONTRACT_PATH" <<'PY'
import json
import sys

payload = json.load(open(sys.argv[1], "r", encoding="utf-8"))
gates = payload.get("quality_gates", {})

def bool_to_int(value, default):
    if value is None:
        return default
    return 1 if bool(value) else 0

print(f"LINT_REQUIRED_DEFAULT={bool_to_int(gates.get('lint_required'), 1)}")
print(f"TYPECHECK_REQUIRED_DEFAULT={bool_to_int(gates.get('typecheck_required'), 1)}")
tests_required = bool_to_int(gates.get('tests_required'), 1)
print(f"TESTS_REQUIRED_DEFAULT={tests_required}")
print(f"COVERAGE_REQUIRED_DEFAULT={tests_required}")
print(f"COVERAGE_THRESHOLD_DEFAULT={gates.get('coverage_threshold', 80)}")
PY
  )
fi

LINT_REQUIRED="${LINT_REQUIRED:-$LINT_REQUIRED_DEFAULT}"
TYPECHECK_REQUIRED="${TYPECHECK_REQUIRED:-$TYPECHECK_REQUIRED_DEFAULT}"
TESTS_REQUIRED="${TESTS_REQUIRED:-$TESTS_REQUIRED_DEFAULT}"
COVERAGE_REQUIRED="${COVERAGE_REQUIRED:-$COVERAGE_REQUIRED_DEFAULT}"
COVERAGE_THRESHOLD="${COVERAGE_THRESHOLD:-$COVERAGE_THRESHOLD_DEFAULT}"

emit_decision() {
  local decision="$1"
  local reason="$2"
  local failed_gate_value="$3"
  python3 - "$decision" "$reason" "$RUN_ID" "$retry_count" "$failed_gate_value" "$LOG_FILE" <<'PY'
import json
import sys

decision, reason, run_id, retry_count, failed_gate, log_file = sys.argv[1:7]
payload = {
    "decision": decision,
    "reason": reason,
    "run_id": run_id,
    "retry_count": int(retry_count),
    "log_file": log_file,
}
if failed_gate:
    payload["failed_gate"] = failed_gate
if decision == "continue":
    payload["systemMessage"] = f"Gate failed: {failed_gate}. Review logs and fix code."
print(json.dumps(payload))
PY
}

failed_gate=""

run_gate() {
  local gate_name="$1"
  local gate_cmd="$2"
  local is_required="$3"
  if [ "$is_required" -ne 1 ]; then
    return 0
  fi
  printf '[%s] Running gate %s: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$gate_name" "$gate_cmd" >> "$LOG_FILE"
  if ! bash -o pipefail -c "$gate_cmd" >> "$LOG_FILE" 2>&1; then
    failed_gate="$gate_name"
    return 1
  fi
}

for toggle_name in LINT_REQUIRED TYPECHECK_REQUIRED TESTS_REQUIRED COVERAGE_REQUIRED; do
  toggle_value="${!toggle_name}"
  if ! [[ "$toggle_value" =~ ^[01]$ ]]; then
    echo "$toggle_name must be 0 or 1 (received: $toggle_value)" >&2
    exit 1
  fi
done

if [ "$TESTS_REQUIRED" -ne 1 ] && [ "$COVERAGE_REQUIRED" -eq 1 ]; then
  COVERAGE_REQUIRED=0
  echo "[info] Disabling coverage gate because TESTS_REQUIRED=0." >> "$LOG_FILE"
fi

if ! run_gate "lint" "$LINT_CMD" "$LINT_REQUIRED"; then
  :
elif ! run_gate "typecheck" "$TYPECHECK_CMD" "$TYPECHECK_REQUIRED"; then
  :
elif ! run_gate "tests" "$TEST_CMD" "$TESTS_REQUIRED"; then
  :
elif [ "$COVERAGE_REQUIRED" -eq 1 ]; then
  if [ ! -f "$COVERAGE_SUMMARY_FILE" ]; then
    failed_gate="coverage_missing"
  else
    coverage_value="$(python3 -c 'import json,sys; data=json.load(open(sys.argv[1])); print(data.get("total",{}).get("lines",{}).get("pct","nan"))' "$COVERAGE_SUMMARY_FILE")"
    if ! python3 -c 'import math,sys; cov=float(sys.argv[1]); th=float(sys.argv[2]); sys.exit(0 if not math.isnan(cov) and cov >= th else 1)' "$coverage_value" "$COVERAGE_THRESHOLD"; then
      failed_gate="coverage_threshold"
    fi
  fi
fi

if [ -z "$failed_gate" ]; then
  emit_decision "stop" "Quality gates passed." ""
  exit 0
fi

if [ "$retry_count" -ge "$MAX_RETRIES" ]; then
  emit_decision "stop" "MAX_ITERATIONS" "$failed_gate"
  exit 2
fi

emit_decision "continue" "QUALITY_GATE_FAILED" "$failed_gate"
