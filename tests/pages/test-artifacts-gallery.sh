#!/usr/bin/env bash
# Smoke test: the standalone Artifacts gallery.
# Verifies the objective — saved artifacts are published to docs/artifacts/ and
# rendered in their own gallery, and never leak into the Plans gallery.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_ARTIFACTS="$ROOT/kit/plugins/plan-agent/hooks/build-artifacts-index.sh"
BUILD_INDEX="$ROOT/kit/plugins/plan-agent/hooks/build-index.sh"
TEMPLATE="$ROOT/kit/plugins/plan-agent/templates/plans-gallery.html"
FAILURES=0

echo "=== Artifacts Gallery Smoke Test ==="

# ── Build an isolated temp project that vendors the plugin template ────────────
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/kit/plugins/plan-agent/templates" "$TMP/.claude/artifacts" "$TMP/docs/plans"
cp "$TEMPLATE" "$TMP/kit/plugins/plan-agent/templates/plans-gallery.html"

art='demo-artifact-2026-01-15.html'
printf '<!doctype html><html><head><title>Demo Artifact</title></head><body>hi</body></html>' \
  > "$TMP/.claude/artifacts/$art"

echo "1. Publisher copies the inbox artifact into docs/artifacts/ ..."
bash "$BUILD_ARTIFACTS" "$TMP" >/dev/null 2>&1 || true
if [ -f "$TMP/docs/artifacts/$art" ]; then echo "  PASS"; else echo "  FAIL: artifact not published"; FAILURES=$((FAILURES+1)); fi

echo "2. docs/artifacts/index.html lists the artifact ..."
if [ -f "$TMP/docs/artifacts/index.html" ] && grep -q "href=\"$art\"" "$TMP/docs/artifacts/index.html"; then
  echo "  PASS"; else echo "  FAIL: artifact card missing from gallery"; FAILURES=$((FAILURES+1)); fi

echo "3. Gallery heading reads 'Artifacts', not 'Plans' ..."
if grep -q '<h1>Artifacts Library</h1>' "$TMP/docs/artifacts/index.html"; then
  echo "  PASS"; else echo "  FAIL: heading is not 'Artifacts Library'"; FAILURES=$((FAILURES+1)); fi

echo "4. Empty inbox writes no gallery (empty-guard) ..."
TMP2="$(mktemp -d)"; mkdir -p "$TMP2/kit/plugins/plan-agent/templates" "$TMP2/.claude/artifacts"
cp "$TEMPLATE" "$TMP2/kit/plugins/plan-agent/templates/plans-gallery.html"
bash "$BUILD_ARTIFACTS" "$TMP2" >/dev/null 2>&1 || true
if [ ! -f "$TMP2/docs/artifacts/index.html" ]; then echo "  PASS"; else echo "  FAIL: gallery written for empty inbox"; FAILURES=$((FAILURES+1)); fi
rm -rf "$TMP2"

echo "5. Plans gallery excludes a stray docs/plans/artifacts/ file ..."
mkdir -p "$TMP/docs/plans/artifacts"
printf '<!doctype html><html><head><title>Plan: A</title><meta name="plan-created" content="2026-01-10"></head><body></body></html>' \
  > "$TMP/docs/plans/a-plan.html"
printf '<!doctype html><html><head><title>Stray</title></head><body></body></html>' \
  > "$TMP/docs/plans/artifacts/stray.html"
bash "$BUILD_INDEX" "$TMP" >/dev/null 2>&1 || true
if [ -f "$TMP/docs/plans/index.html" ] \
   && grep -q 'href="a-plan.html"' "$TMP/docs/plans/index.html" \
   && ! grep -q 'href="artifacts/' "$TMP/docs/plans/index.html"; then
  echo "  PASS"; else echo "  FAIL: plans gallery leaked an artifact card"; FAILURES=$((FAILURES+1)); fi

echo "6. Already-published artifacts survive an empty-inbox rebuild ..."
# The inbox is gitignored, so a clean checkout has none — publishing a new one
# must not drop artifacts already committed under docs/artifacts/.
rm -f "$TMP/.claude/artifacts/"*.html
bash "$BUILD_ARTIFACTS" "$TMP" >/dev/null 2>&1 || true
if grep -q "href=\"$art\"" "$TMP/docs/artifacts/index.html"; then
  echo "  PASS"; else echo "  FAIL: published artifact dropped when inbox was empty"; FAILURES=$((FAILURES+1)); fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."; exit 0
else
  echo "$FAILURES check(s) failed."; exit 1
fi
