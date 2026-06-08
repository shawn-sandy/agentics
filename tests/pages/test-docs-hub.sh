#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INDEX="$ROOT/docs/index.html"
FAILURES=0

echo "=== Docs Hub Smoke Test ==="

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

echo "3. Links to Plans gallery via relative href..."
if grep -q 'href="plans/index.html"' "$INDEX"; then
  echo "  PASS"
else
  echo "  FAIL: no relative href to plans/index.html"
  FAILURES=$((FAILURES + 1))
fi

echo "4. Links to Social gallery via relative href..."
if grep -q 'href="media/social/index.html"' "$INDEX"; then
  echo "  PASS"
else
  echo "  FAIL: no relative href to media/social/index.html"
  FAILURES=$((FAILURES + 1))
fi

echo "5. No absolute-root links (href=\"/\")..."
if grep -q 'href="/' "$INDEX"; then
  echo "  FAIL: absolute-root link found"
  FAILURES=$((FAILURES + 1))
else
  echo "  PASS"
fi

echo "6. Contains CSS accent token (#2563eb)..."
if grep -qE '\-\-accent:.*#2563eb' "$INDEX"; then
  echo "  PASS"
else
  echo "  FAIL: CSS accent token not found"
  FAILURES=$((FAILURES + 1))
fi

echo "7. deploy-pages.yml exists..."
if [ -f "$ROOT/.github/workflows/deploy-pages.yml" ]; then
  echo "  PASS"
else
  echo "  FAIL: deploy-pages.yml not found"
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
