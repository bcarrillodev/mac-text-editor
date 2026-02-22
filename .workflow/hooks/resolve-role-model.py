#!/usr/bin/env python3
"""Resolve a model assignment for a workflow role.

Reads workflow config TOML with:
  [models]
  [role_models]

`role_models.<role>` may point to a key in `[models]` (alias) or a direct model string.
Prints the resolved model string to stdout.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

try:
    import tomllib  # py311+
except ModuleNotFoundError:  # pragma: no cover
    print("Python 3.11+ (tomllib) is required", file=sys.stderr)
    sys.exit(1)


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: resolve-role-model.py <role> [config-path]", file=sys.stderr)
        return 1

    role = sys.argv[1].strip()
    if not role:
        print("Role must be non-empty", file=sys.stderr)
        return 1

    default_config = Path(__file__).resolve().parents[1] / "config.toml"
    config_path = Path(sys.argv[2]) if len(sys.argv) > 2 else default_config
    if not config_path.is_file():
        print(f"Missing config file: {config_path}", file=sys.stderr)
        return 1

    with config_path.open("rb") as handle:
        data = tomllib.load(handle)

    role_models = data.get("role_models", {})
    model_aliases = data.get("models", {})
    assigned = role_models.get(role)

    if not isinstance(assigned, str) or not assigned.strip():
        print(f"No model configured for role: {role}", file=sys.stderr)
        return 1

    assigned = assigned.strip()
    resolved = model_aliases.get(assigned, assigned)
    if not isinstance(resolved, str) or not resolved.strip():
        print(f"Invalid model mapping for role: {role}", file=sys.stderr)
        return 1

    print(resolved.strip())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
