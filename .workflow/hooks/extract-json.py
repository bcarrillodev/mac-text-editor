#!/usr/bin/env python3
"""Extract the first valid JSON object from mixed text output."""

from __future__ import annotations

import json
import re
import sys
from json import JSONDecodeError


def decode_json_object(candidate: str):
    text = candidate.strip()
    if not text:
        return None
    try:
        value = json.loads(text)
    except JSONDecodeError:
        return None
    if isinstance(value, dict):
        return value
    return None


def extract_json(text: str):
    direct = decode_json_object(text)
    if direct is not None:
        return direct

    fenced_blocks = re.findall(r"```(?:json)?\s*(\{.*?\})\s*```", text, flags=re.DOTALL | re.IGNORECASE)
    for block in fenced_blocks:
        value = decode_json_object(block)
        if value is not None:
            return value

    decoder = json.JSONDecoder()
    for index, char in enumerate(text):
        if char != "{":
            continue
        try:
            value, _ = decoder.raw_decode(text[index:])
        except JSONDecodeError:
            continue
        if isinstance(value, dict):
            return value
    return None


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: extract-json.py <input-path> <output-path>", file=sys.stderr)
        return 2

    input_path, output_path = sys.argv[1], sys.argv[2]
    with open(input_path, "r", encoding="utf-8") as handle:
        source = handle.read()

    payload = extract_json(source)
    if payload is None:
        print("Failed to extract a valid JSON object from reviewer output.", file=sys.stderr)
        return 1

    with open(output_path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
