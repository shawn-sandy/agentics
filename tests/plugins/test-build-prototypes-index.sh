#!/usr/bin/env bash
set -euo pipefail

# Unit test for build-prototypes-index.sh — meta parsing, newest-first ordering,
# escaping, index.html exclusion, and the empty-dir empty-state path.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILDER="$ROOT/kit/plugins/plan-agent/hooks/build-prototypes-index.sh"
FAILURES=0

pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

proto() { # $1=file $2=title $3=created
  cat > "$1" <<HTML
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<meta name="proto-created" content="$3">
<meta name="proto-source" content="docs/plans/src.html">
<title>$2</title></head><body><p>x</p></body></html>
HTML
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PD="$TMP/docs/prototypes"
mkdir -p "$PD" "$TMP/kit/plugins/plan-agent/templates"
cp "$ROOT/kit/plugins/plan-agent/templates/prototypes-gallery.html" "$TMP/kit/plugins/plan-agent/templates/"

echo "=== build-prototypes-index unit test ==="

proto "$PD/alpha.html" 'Alpha plan'        '2026-06-01'
proto "$PD/gamma.html" 'Gamma & "y" plan'  '2026-06-10'
proto "$PD/index.html" 'SHOULD BE IGNORED' '2099-01-01'

echo "1. Builder exits 0 and writes index.html..."
bash "$BUILDER" "$TMP" </dev/null >/dev/null && [ -f "$PD/index.html" ] && pass || fail "builder failed or no index.html"

OUT="$PD/index.html"

echo "2. Newest-first ordering (Gamma before Alpha)..."
if [ "$(grep -n 'Gamma' "$OUT" | head -1 | cut -d: -f1)" -lt "$(grep -n 'Alpha' "$OUT" | head -1 | cut -d: -f1)" ]; then
  pass; else fail "ordering not newest-first"; fi

echo "3. Card title itself is escaped (not just any entity present)..."
if grep -q 'Gamma &amp; &quot;y&quot; plan' "$OUT"; then pass; else fail "card title not escaped"; fi

echo "4. index.html is not listed as a card..."
if ! grep -q 'SHOULD BE IGNORED' "$OUT"; then pass; else fail "index.html listed as a prototype"; fi

echo "5. Empty dir → empty-state gallery, exit 0..."
rm -f "$PD"/*.html
bash "$BUILDER" "$TMP" </dev/null >/dev/null && [ -f "$PD/index.html" ] \
  && ! grep -q 'class="gallery-card"' "$PD/index.html" \
  && pass || fail "empty-dir path did not produce an empty-state index"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All build-prototypes-index checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
