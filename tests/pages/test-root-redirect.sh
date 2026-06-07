#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INDEX="$ROOT/docs/index.html"
FAILURES=0

echo "=== Root Index Test (hub, no redirect) ==="

echo "1. docs/index.html exists..."
if [ -f "$INDEX" ]; then
  echo "  PASS"
else
  echo "  FAIL: docs/index.html not found"
  exit 1
fi

echo "2. No meta-refresh redirect..."
if grep -q 'http-equiv="refresh"' "$INDEX"; then
  echo "  FAIL: meta-refresh redirect still present"
  FAILURES=$((FAILURES + 1))
else
  echo "  PASS"
fi

echo "3. Contains link to plans/index.html..."
if grep -q 'plans/index.html' "$INDEX"; then
  echo "  PASS"
else
  echo "  FAIL: no reference to plans/index.html"
  FAILURES=$((FAILURES + 1))
fi

echo "4. All links are relative (no leading / or http)..."
if grep -q 'href="/' "$INDEX"; then
  echo "  FAIL: absolute-root link found"
  FAILURES=$((FAILURES + 1))
else
  echo "  PASS"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "ALL PASSED"
  exit 0
else
  echo "FAILED ($FAILURES failures)"
  exit 1
fi
