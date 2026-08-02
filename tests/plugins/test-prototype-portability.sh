#!/usr/bin/env bash
set -euo pipefail

# Objective smoke test for /plan-agent:prototype. Asserts a generated prototype
# is self-contained, escapes hostile input, renders via textContent, is
# accessible, and lands (escaped) in the gallery built by build-prototypes-index.sh.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKEL="$ROOT/kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html"
FIXTURE="$ROOT/tests/fixtures/plan-agent/sample-prototype.html"
BUILDER="$ROOT/kit/plugins/plan-agent/hooks/build-prototypes-index.sh"
FAILURES=0

pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== prototype portability smoke test ==="

echo "1. Skeleton and fixture exist..."
{ [ -f "$SKEL" ] && [ -f "$FIXTURE" ]; } && pass || fail "missing skeleton or fixture"

echo "2. No external http(s):// resource references (skeleton + fixture)..."
if ! grep -Eq 'https?://' "$SKEL" "$FIXTURE"; then pass; else fail "external URL reference found"; fi

echo "3. Inline application/json #seed block present (attribute-order-independent)..."
seed_block() { grep -Eq '<script[^>]*application/json' "$1" && grep -Eq '<script[^>]*id="seed"' "$1"; }
if seed_block "$SKEL" && seed_block "$FIXTURE"; then
  pass; else fail "missing inline #seed block"; fi

echo "4. Renders via textContent/createTextNode, never innerHTML..."
if grep -q 'createTextNode' "$SKEL" && grep -q 'createTextNode' "$FIXTURE" \
   && ! grep -q 'innerHTML' "$SKEL" && ! grep -q 'innerHTML' "$FIXTURE"; then
  pass; else fail "innerHTML used, or createTextNode missing"; fi

echo "5. Hostile input is inert (escaped title + script-breakout-safe seed)..."
if grep -q '<title>Workout Log &lt;demo&gt;</title>' "$FIXTURE" \
   && grep -q '<\\/script>' "$FIXTURE"; then
  pass; else fail "title not escaped or seed closing tag not escaped"; fi

echo "6. Skeleton a11y affordances: aria-live region + real Reset/submit buttons..."
if grep -q 'aria-live="polite"' "$SKEL" \
   && grep -Eq '<button[^>]*type="submit"' "$SKEL" \
   && grep -Eq '<button[^>]*id="reset-btn"' "$SKEL"; then
  pass; else fail "missing aria-live region or real buttons in skeleton"; fi

echo "7. Every fixture input has an associated <label for>..."
if python3 - "$FIXTURE" <<'PY'
import re, sys
html = open(sys.argv[1]).read()
ids  = set(re.findall(r'<input[^>]*\bid="([^"]+)"', html))
fors = set(re.findall(r'<label[^>]*\bfor="([^"]+)"', html))
missing = ids - fors
sys.exit(0 if ids and not missing else 1)
PY
then pass; else fail "an input lacks a matching <label for>"; fi

echo "8. Builder lists the fixture in the gallery with its title escaped..."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/docs/prototypes" "$TMP/kit/plugins/plan-agent/templates"
cp "$ROOT/kit/plugins/plan-agent/templates/prototypes-gallery.html" "$TMP/kit/plugins/plan-agent/templates/"
cp "$FIXTURE" "$TMP/docs/prototypes/sample-prototype.html"
bash "$BUILDER" "$TMP" </dev/null >/dev/null
OUT="$TMP/docs/prototypes/index.html"
# The builder unescapes the <title> to plain text, then escapes exactly once at
# render — so the entity-escaped form is what lands in the gallery. Asserting
# the double-escaped &amp;lt; would demand the pre-unescape behavior, which
# renders a literal "&lt;demo&gt;" to the reader. The negative grep keeps the
# check honest: escaped-once, never raw.
if [ -f "$OUT" ] && grep -q 'sample-prototype.html' "$OUT" && grep -q 'Workout Log' "$OUT" \
   && grep -q '&lt;demo&gt;' "$OUT" && ! grep -q '<demo>' "$OUT"; then
  pass; else fail "fixture not listed, or title not escaped in gallery"; fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All prototype portability checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
