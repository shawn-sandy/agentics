#!/usr/bin/env bash
set -euo pipefail

# Portability smoke test for attribute-based plan checkbox state.
#
# Locks in the guarantee that a plan's completion state travels with the file:
#   1. reference/SKELETON.html carries no browser-only storage layer, and
#      still defines updateProgress() as the attribute-driven progress source.
#   2. The fixture's `checked` attributes and step `.completed` class live in
#      the file bytes — a fresh read (the proxy for a different machine, with no
#      shared localStorage) still sees them.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKELETON="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html"
FIXTURE="$ROOT/tests/fixtures/checkbox-portability/fixture.html"
FAILURES=0

echo "=== Checkbox Portability Smoke Test ==="

echo "1. Skeleton carries no browser-storage APIs..."
if [ -f "$SKELETON" ] \
  && [ "$(grep -c -E 'localStorage|STORAGE_KEY|saveState|restoreState' "$SKELETON")" -eq 0 ] \
  && grep -q 'updateProgress' "$SKELETON"; then
  echo "  PASS"
else
  echo "  FAIL: skeleton missing, still references storage APIs, or lost updateProgress()"
  FAILURES=$((FAILURES + 1))
fi

echo "2. Fixture criteria carry the checked attribute in the file..."
if [ -f "$FIXTURE" ] \
  && grep -Eq '<input[^>]*(id="ac1"[^>]*checked|checked[^>]*id="ac1")[^>]*>' "$FIXTURE" \
  && grep -Eq '<input[^>]*(id="ac2"[^>]*checked|checked[^>]*id="ac2")[^>]*>' "$FIXTURE"; then
  echo "  PASS"
else
  echo "  FAIL: fixture missing or does not carry both pre-checked criteria (ac1, ac2)"
  FAILURES=$((FAILURES + 1))
fi

echo "3. Fixture step completion travels as the .completed class..."
if [ -f "$FIXTURE" ] && grep -Eq 'class="[^"]*(step-card[^"]*completed|completed[^"]*step-card)[^"]*"' "$FIXTURE"; then
  echo "  PASS"
else
  echo "  FAIL: fixture step is not pre-marked with the completed class"
  FAILURES=$((FAILURES + 1))
fi

echo "4. Fixture itself uses no browser-only storage..."
if [ -f "$FIXTURE" ] \
  && [ "$(grep -c -E 'localStorage|STORAGE_KEY|saveState|restoreState' "$FIXTURE")" -eq 0 ]; then
  echo "  PASS"
else
  echo "  FAIL: fixture references browser-only storage"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."
  exit 0
fi
echo "$FAILURES check(s) failed."
exit 1
