#!/bin/bash
set -euo pipefail

# Runs project tests for the current repo/worktree and emits a JSON control message.
# Intended for use in an agent "fix until green" loop.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd -- "$WORKFLOW_DIR/.." && pwd)"

run_tests() {
  # mac-text-editor is a SwiftPM package in TextEditor/
  if [ -f "$REPO_DIR/TextEditor/Package.swift" ]; then
    # Keep caches within the repo when running under restricted environments.
    local workflow_cache_dir="$REPO_DIR/.workflow_cache"
    mkdir -p "$workflow_cache_dir/xdg" "$workflow_cache_dir/clang/ModuleCache"

    local xdg_cache_home="${XDG_CACHE_HOME:-$workflow_cache_dir/xdg}"
    local clang_module_cache_path="${CLANG_MODULE_CACHE_PATH:-$workflow_cache_dir/clang/ModuleCache}"

    (cd "$REPO_DIR/TextEditor" && env \
      XDG_CACHE_HOME="$xdg_cache_home" \
      CLANG_MODULE_CACHE_PATH="$clang_module_cache_path" \
      swift test)
    return $?
  fi

  if [ -f "$REPO_DIR/package.json" ]; then
    (cd "$REPO_DIR" && npm test)
    return $?
  fi

  if [ -f "$REPO_DIR/pyproject.toml" ] || [ -f "$REPO_DIR/pytest.ini" ]; then
    (cd "$REPO_DIR" && pytest)
    return $?
  fi

  echo "No known test runner detected (expected TextEditor/Package.swift, package.json, or pytest config)." >&2
  return 2
}

if run_tests; then
  echo '{"decision":"stop","reason":"Tests passed. Worker loop complete."}'
else
  status=$?
  if [ "$status" -eq 2 ]; then
    echo '{"decision":"stop","reason":"No test runner detected."}'
  else
    echo '{"decision":"continue","systemMessage":"Tests failed. Review the output and fix the code."}'
  fi
fi
