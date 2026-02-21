#!/usr/bin/env bash
set -euo pipefail

echo "Building package..."
swift build

echo ""
echo "Running package tests..."
swift test
