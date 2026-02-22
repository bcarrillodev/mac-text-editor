#!/usr/bin/env python3
"""Lightweight JSON Schema validator for workflow contracts.

Supports the subset used by contracts/*.schema.json:
- type
- required
- properties
- additionalProperties: false
- const
- enum
- minLength
- minItems / maxItems
- items
- minimum / maximum
- allOf
- if / then
"""

from __future__ import annotations

import json
import math
import sys
from typing import Any


def type_matches(value: Any, expected: str) -> bool:
    if expected == "object":
        return isinstance(value, dict)
    if expected == "array":
        return isinstance(value, list)
    if expected == "string":
        return isinstance(value, str)
    if expected == "number":
        return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(float(value))
    if expected == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if expected == "boolean":
        return isinstance(value, bool)
    if expected == "null":
        return value is None
    return False


def validate(instance: Any, schema: Any, path: str, errors: list[str]) -> None:
    if schema is True:
        return
    if schema is False:
        errors.append(f"{path}: value is not allowed by schema")
        return
    if not isinstance(schema, dict):
        errors.append(f"{path}: invalid schema node type {type(schema).__name__}")
        return

    expected_type = schema.get("type")
    if expected_type is not None:
        if isinstance(expected_type, list):
            if not any(type_matches(instance, item_type) for item_type in expected_type):
                errors.append(f"{path}: expected one of {expected_type}, got {type(instance).__name__}")
                return
        elif not type_matches(instance, expected_type):
            errors.append(f"{path}: expected {expected_type}, got {type(instance).__name__}")
            return

    if "const" in schema and instance != schema["const"]:
        errors.append(f"{path}: expected constant value {schema['const']!r}")

    if "enum" in schema and instance not in schema["enum"]:
        errors.append(f"{path}: expected one of {schema['enum']!r}")

    if isinstance(instance, str):
        min_length = schema.get("minLength")
        if isinstance(min_length, int) and len(instance) < min_length:
            errors.append(f"{path}: string length must be >= {min_length}")

    if isinstance(instance, list):
        min_items = schema.get("minItems")
        max_items = schema.get("maxItems")
        if isinstance(min_items, int) and len(instance) < min_items:
            errors.append(f"{path}: array length must be >= {min_items}")
        if isinstance(max_items, int) and len(instance) > max_items:
            errors.append(f"{path}: array length must be <= {max_items}")
        if "items" in schema:
            for index, item in enumerate(instance):
                validate(item, schema["items"], f"{path}[{index}]", errors)

    if isinstance(instance, (int, float)) and not isinstance(instance, bool):
        minimum = schema.get("minimum")
        maximum = schema.get("maximum")
        if minimum is not None and float(instance) < float(minimum):
            errors.append(f"{path}: number must be >= {minimum}")
        if maximum is not None and float(instance) > float(maximum):
            errors.append(f"{path}: number must be <= {maximum}")

    if isinstance(instance, dict):
        required = schema.get("required", [])
        if isinstance(required, list):
            for key in required:
                if key not in instance:
                    errors.append(f"{path}: missing required key {key!r}")

        properties = schema.get("properties", {})
        if isinstance(properties, dict):
            for key, value in instance.items():
                if key in properties:
                    validate(value, properties[key], f"{path}.{key}", errors)

            if schema.get("additionalProperties") is False:
                extras = sorted(key for key in instance if key not in properties)
                for key in extras:
                    errors.append(f"{path}: additional property {key!r} is not allowed")

    for subschema in schema.get("allOf", []):
        validate(instance, subschema, path, errors)

    if_schema = schema.get("if")
    then_schema = schema.get("then")
    if if_schema is not None and then_schema is not None:
        condition_errors: list[str] = []
        validate(instance, if_schema, path, condition_errors)
        if not condition_errors:
            validate(instance, then_schema, path, errors)


def load_json(path: str) -> Any:
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: validate-json.py <schema-path> <json-path>", file=sys.stderr)
        return 2

    schema_path, json_path = sys.argv[1], sys.argv[2]
    try:
        schema = load_json(schema_path)
    except FileNotFoundError:
        print(f"Schema file not found: {schema_path}", file=sys.stderr)
        return 1
    except json.JSONDecodeError as exc:
        print(f"Invalid schema JSON at {schema_path}: {exc}", file=sys.stderr)
        return 1

    try:
        payload = load_json(json_path)
    except FileNotFoundError:
        print(f"JSON file not found: {json_path}", file=sys.stderr)
        return 1
    except json.JSONDecodeError as exc:
        print(f"Invalid JSON at {json_path}: {exc}", file=sys.stderr)
        return 1

    errors: list[str] = []
    validate(payload, schema, "$", errors)
    if errors:
        print(f"Schema validation failed for {json_path} against {schema_path}:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
