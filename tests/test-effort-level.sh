#!/usr/bin/env bash
set -euo pipefail

# Smoke test for the auto-derived effort level on implementation plans.
#
# Locks in the guarantee that every generated plan carries a visible,
# machine-readable effort level:
#   1. reference/SKELETON.html defines a <meta name="plan-effort"> tag.
#   2. The skeleton drives badge colour from a data-effort attribute on <html>.
#   3. All three .effort-badge colour variants (low/medium/high) are present,
#      so the rendered badge always matches the derived level.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKELETON="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html"
FAILURES=0

echo "=== Effort Level Smoke Test ==="

echo "1. Skeleton declares the plan-effort meta tag..."
if [ -f "$SKELETON" ] && grep -q '<meta name="plan-effort"' "$SKELETON"; then
  echo "  PASS"
else
  echo "  FAIL: skeleton missing or has no plan-effort meta tag"
  FAILURES=$((FAILURES + 1))
fi

echo "2. Skeleton drives effort from a data-effort attribute on <html>..."
if [ -f "$SKELETON" ] && grep -Eq '<html[^>]*data-effort=' "$SKELETON"; then
  echo "  PASS"
else
  echo "  FAIL: <html> tag carries no data-effort attribute"
  FAILURES=$((FAILURES + 1))
fi

echo "3. Skeleton defines all three effort-badge colour variants..."
if [ -f "$SKELETON" ] \
  && grep -q '\[data-effort="low"\]' "$SKELETON" \
  && grep -q '\[data-effort="medium"\]' "$SKELETON" \
  && grep -q '\[data-effort="high"\]' "$SKELETON"; then
  echo "  PASS"
else
  echo "  FAIL: skeleton is missing one or more data-effort colour variants"
  FAILURES=$((FAILURES + 1))
fi

echo "4. data-effort and plan-effort use the lowercase {effort-value} placeholder..."
# Guards against reusing the capitalised {effort} display label for the machine
# value, which would emit data-effort="High" and miss the lowercase CSS selectors.
if [ -f "$SKELETON" ] \
  && grep -q 'data-effort="{effort-value}"' "$SKELETON" \
  && grep -q '<meta name="plan-effort" content="{effort-value}"' "$SKELETON"; then
  echo "  PASS"
else
  echo "  FAIL: data-effort / plan-effort must use {effort-value}, not the {effort} display label"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."
  exit 0
fi
echo "$FAILURES check(s) failed."
exit 1
