#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKFLOW="$ROOT/.github/workflows/deploy-pages.yml"
NOJEKYLL="$ROOT/docs/.nojekyll"
FAILURES=0

echo "=== Workflow Config Test ==="

echo "1. Workflow file exists..."
if [ -f "$WORKFLOW" ]; then
  echo "  PASS"
else
  echo "  FAIL: $WORKFLOW not found"
  exit 1
fi

echo "2. docs/.nojekyll exists..."
if [ -f "$NOJEKYLL" ]; then
  echo "  PASS"
else
  echo "  FAIL: docs/.nojekyll not found"
  FAILURES=$((FAILURES + 1))
fi

echo "3. Triggers on push to main with docs/** path..."
if grep -q 'branches: \[main\]' "$WORKFLOW" && grep -q "docs/\*\*" "$WORKFLOW"; then
  echo "  PASS"
else
  echo "  FAIL: push trigger or docs/** path filter missing"
  FAILURES=$((FAILURES + 1))
fi

echo "4. Path filter includes the workflow file itself..."
if grep -q 'deploy-pages.yml' "$WORKFLOW"; then
  echo "  PASS"
else
  echo "  FAIL: workflow self-trigger path missing"
  FAILURES=$((FAILURES + 1))
fi

echo "5. Declares pages: write permission..."
if grep -q 'pages: write' "$WORKFLOW"; then
  echo "  PASS"
else
  echo "  FAIL: pages: write permission missing"
  FAILURES=$((FAILURES + 1))
fi

echo "6. Declares id-token: write permission..."
if grep -q 'id-token: write' "$WORKFLOW"; then
  echo "  PASS"
else
  echo "  FAIL: id-token: write permission missing"
  FAILURES=$((FAILURES + 1))
fi

echo "7. Has build job uploading artifact path 'docs'..."
if grep -q 'path: docs' "$WORKFLOW"; then
  echo "  PASS"
else
  echo "  FAIL: upload artifact path 'docs' not found"
  FAILURES=$((FAILURES + 1))
fi

echo "8. Has deploy job with environment: github-pages..."
if grep -q 'name: github-pages' "$WORKFLOW"; then
  echo "  PASS"
else
  echo "  FAIL: environment github-pages not found"
  FAILURES=$((FAILURES + 1))
fi

echo "9. Uses deploy-pages action..."
if grep -q 'actions/deploy-pages' "$WORKFLOW"; then
  echo "  PASS"
else
  echo "  FAIL: actions/deploy-pages not found"
  FAILURES=$((FAILURES + 1))
fi

echo "10. All uses: are SHA-pinned (40-char hex)..."
unpinned=$(grep -E '^\s+uses:' "$WORKFLOW" | grep -vE '@[0-9a-f]{40}' || true)
if [ -z "$unpinned" ]; then
  echo "  PASS"
else
  echo "  FAIL: unpinned actions found:"
  echo "$unpinned"
  FAILURES=$((FAILURES + 1))
fi

echo "11. Build job asserts .nojekyll exists..."
if grep -q 'test -f docs/.nojekyll' "$WORKFLOW"; then
  echo "  PASS"
else
  echo "  FAIL: .nojekyll assertion not found in build job"
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
