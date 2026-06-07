#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INDEX="$ROOT/docs/index.html"
FAILURES=0

echo "=== Root Redirect Test ==="

echo "1. docs/index.html exists..."
if [ -f "$INDEX" ]; then
  echo "  PASS"
else
  echo "  FAIL: docs/index.html not found"
  exit 1
fi

echo "2. Contains redirect to plans/index.html..."
if grep -q 'plans/index.html' "$INDEX"; then
  echo "  PASS"
else
  echo "  FAIL: no reference to plans/index.html"
  FAILURES=$((FAILURES + 1))
fi

echo "3. Redirect target is relative (no leading / or http)..."
redirect_target=$(grep -o 'url=[^"]*' "$INDEX" | sed 's/url=//' | head -1)
if echo "$redirect_target" | grep -qE '^(/|http)'; then
  echo "  FAIL: redirect target is absolute ($redirect_target)"
  FAILURES=$((FAILURES + 1))
else
  echo "  PASS ($redirect_target)"
fi

fallback_href=$(grep -o 'href="[^"]*"' "$INDEX" | sed 's/href="//;s/"//' | head -1)
if echo "$fallback_href" | grep -qE '^(/|http)'; then
  echo "  FAIL: fallback href is absolute ($fallback_href)"
  FAILURES=$((FAILURES + 1))
else
  echo "  PASS (fallback href is relative: $fallback_href)"
fi

echo "4. Visible fallback anchor present..."
if grep -q '<a href="plans/index.html"' "$INDEX"; then
  echo "  PASS"
else
  echo "  FAIL: no visible fallback link"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "ALL PASSED"
  exit 0
else
  echo "FAILED ($FAILURES failures)"
  exit 1
fi
