#!/usr/bin/env bash
set -euo pipefail

# Unit test for build-designs-index.sh — one card per canvas DIRECTORY,
# newest-first ordering, escaping, artboard-count meta, index.html exclusion,
# idempotent re-runs, and the empty-state path.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILDER="$ROOT/kit/plugins/plan-agent/hooks/build-designs-index.sh"
FAILURES=0

pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

artboard() { # $1=file $2=title $3=touch stamp (YYYYMMDDhhmm)
  mkdir -p "$(dirname "$1")"
  cat > "$1" <<HTML
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<title>$2</title></head><body><section class="artboard">x</section></body></html>
HTML
  touch -t "$3" "$1"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
DD="$TMP/docs/designs"
mkdir -p "$DD" "$TMP/kit/plugins/plan-agent/templates"
cp "$ROOT/kit/plugins/plan-agent/templates/designs-gallery.html" "$TMP/kit/plugins/plan-agent/templates/"

echo "=== build-designs-index unit test ==="

# Two canvases: alpha (2 artboards, older) and gamma (1 artboard, newer).
artboard "$DD/alpha-canvas/01-home.dc.html"   'Alpha canvas'       202606010900
artboard "$DD/alpha-canvas/02-detail.dc.html" 'Alpha detail'       202606011000
artboard "$DD/gamma-canvas/01-hero.dc.html"   'Gamma & "y" canvas' 202606101200
# A sibling directory with no *.dc.html is not a canvas.
mkdir -p "$DD/notes"
echo '<title>SHOULD BE IGNORED</title>' > "$DD/notes/draft.html"

OUT="$DD/index.html"

echo "1. Builder exits 0 and writes index.html..."
bash "$BUILDER" "$TMP" </dev/null >/dev/null && [ -f "$OUT" ] && pass || fail "builder failed or no index.html"

echo "2. One card per canvas directory (2 cards)..."
CARDS="$(grep -c 'class="gallery-card"' "$OUT" || true)"
if [ "$CARDS" -eq 2 ]; then pass; else fail "expected 2 cards, got $CARDS"; fi

echo "3. Newest-first ordering (Gamma before Alpha)..."
if [ "$(grep -n 'Gamma' "$OUT" | head -1 | cut -d: -f1)" -lt "$(grep -n 'Alpha' "$OUT" | head -1 | cut -d: -f1)" ]; then
  pass; else fail "ordering not newest-first"; fi

echo "4. Card title itself is escaped (not just any entity present)..."
if grep -q 'Gamma &amp; &quot;y&quot; canvas' "$OUT"; then pass; else fail "card title not escaped"; fi

echo "5. href opens the first artboard; meta counts artboards..."
if grep -q 'href="alpha-canvas/01-home.dc.html"' "$OUT" \
   && grep -q '>2 artboards<' "$OUT" \
   && grep -q '>1 artboard<' "$OUT"; then
  pass; else fail "href or artboard-count meta wrong"; fi

echo "6. A directory with no .dc.html file produces no card..."
if ! grep -q 'SHOULD BE IGNORED' "$OUT" && ! grep -q 'notes/' "$OUT"; then
  pass; else fail "non-canvas directory listed as a card"; fi

# The generated index.html now exists in docs/designs/. A second run must not
# pick it up as a card, and must escape the title exactly once again — a
# re-escape would drift 'Gamma &amp;' to 'Gamma &amp;amp;'.
TITLE_RUN1="$(grep -c 'Gamma &amp; &quot;y&quot; canvas' "$OUT" || true)"

echo "7. Re-run stays idempotent and never lists its own index.html..."
bash "$BUILDER" "$TMP" </dev/null >/dev/null
CARDS2="$(grep -c 'class="gallery-card"' "$OUT" || true)"
TITLE_RUN2="$(grep -c 'Gamma &amp; &quot;y&quot; canvas' "$OUT" || true)"
if [ "$CARDS2" -eq 2 ] \
   && ! grep -q 'href="index.html"' "$OUT" \
   && ! grep -q '&amp;amp;' "$OUT" \
   && [ "$TITLE_RUN2" -eq "$TITLE_RUN1" ]; then
  pass; else fail "re-run drifted (cards=$CARDS2, title matches $TITLE_RUN1 -> $TITLE_RUN2)"; fi

echo "8. No artboards anywhere → empty-state gallery, exit 0..."
rm -rf "$DD/alpha-canvas" "$DD/gamma-canvas"
bash "$BUILDER" "$TMP" </dev/null >/dev/null && [ -f "$OUT" ] \
  && ! grep -q 'class="gallery-card"' "$OUT" \
  && pass || fail "empty dir path did not produce an empty-state index"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All build-designs-index checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
