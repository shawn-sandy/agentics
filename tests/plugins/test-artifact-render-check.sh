#!/usr/bin/env bash
set -euo pipefail

# E2E test for the publish / fetch-back / assert flow that plan-artifact's
# "Step 4 — Verify the page rendered" describes.
#
# SCOPE — read this before trusting a green run. The skill's step is prose for
# the model, not code, so there is nothing to extract and execute. Both the
# transport AND the assertion are stood in for here: fixture HTML replaces the
# fetched page, and render_check() below is this test's own model of what the
# step asks for. Assertions 4-7 therefore exercise render_check(), not the
# skill. Only assertions 1-3 bind to the shipped SKILL.md, and they bind to its
# structure and semantics rather than its exact wording.
#
# What that means in practice: this suite proves the assertion LOGIC is sound
# and catches the blank-page case. It cannot prove the model performs it. The
# plan's manual step — publish a real plan, open the URL in light and dark
# themes — remains the only end-to-end proof, and is still outstanding.
#
# The marker is looked for in body text only, never in the raw source or the
# <title> tag — an artifact whose body is a single empty div still ships a
# <title>, which is exactly the blank-page-with-a-URL case the check exists to
# catch.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md"
FAILURES=0

pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Stand-in for "WebFetch the returned URL, assert the marker is on the page".
# Exits 0 when the marker is in the rendered body text, 1 otherwise.
render_check() { # $1=fetched page $2=expected marker
  python3 - "$1" "$2" <<'PYEOF'
import sys
from html.parser import HTMLParser

class BodyText(HTMLParser):
    def __init__(self):
        super().__init__()
        self.inbody = False
        self.skip = 0
        self.parts = []
    def handle_starttag(self, tag, attrs):
        if tag == "body":
            self.inbody = True
        elif tag in ("script", "style"):
            self.skip += 1
    def handle_endtag(self, tag):
        if tag == "body":
            self.inbody = False
        elif tag in ("script", "style") and self.skip:
            self.skip -= 1
    def handle_data(self, data):
        if self.inbody and not self.skip:
            self.parts.append(data)

page, marker = sys.argv[1], sys.argv[2]
p = BodyText()
p.feed(open(page, encoding="utf-8").read())
text = " ".join("".join(p.parts).split())
if not text:
    print(f"BLANK: fetched page has no rendered body text; marker {marker!r} not confirmed")
    sys.exit(1)
if marker not in text:
    print(f"MISSING: marker {marker!r} not found in rendered body text")
    sys.exit(1)
print(f"OK: marker {marker!r} found in rendered body text")
PYEOF
}

MARKER='Give the HTML-generating skills a check'

cat > "$TMP/published.html" <<HTML
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<title>$MARKER</title></head>
<body><main><h1>$MARKER</h1><p>Step 1 of 6.</p></main></body></html>
HTML

# The failure this whole step exists for: publish returned a URL, the page is
# blank. The <title> is still present, so a naive grep over the source passes.
cat > "$TMP/empty-body.html" <<HTML
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<title>$MARKER</title></head>
<body><div></div></body></html>
HTML

echo "=== plan-artifact render-check E2E test ==="

echo "1. plan-artifact declares WebFetch in allowed-tools..."
if grep -q '^allowed-tools:.*WebFetch' "$SKILL"; then pass
else fail "WebFetch missing from allowed-tools: — the check would stall on a permission prompt"; fi

echo "2. SKILL.md carries a post-publish verify step..."
if grep -qiE '^## Step [0-9]+ — (Verify|Confirm|Check) .*render' "$SKILL"; then pass
else fail "no 'Verify the page rendered' step heading in plan-artifact SKILL.md"; fi

echo "3. Verify step reports failure with the URL instead of reporting success..."
if grep -qiE 'do not report|not report .* as success' "$SKILL" \
   && grep -qiE 'report the failure[^.]*URL|URL[^.]*so the user can open' "$SKILL"; then pass
else fail "verify step does not require reporting the failure with the URL"; fi

echo "4. Verify step actually inspects the page rather than opting out..."
if grep -A12 -iE '^## Step [0-9]+ — (Verify|Confirm|Check) .*render' "$SKILL" | grep -qi 'skip this step'; then
  fail "verify step tells the model to skip it"
elif grep -A12 -iE '^## Step [0-9]+ — (Verify|Confirm|Check) .*render' "$SKILL" \
     | grep -qiE '\b(fetch|retrieve|confirm|compare|assert)\w*\b'; then
  pass
else
  fail "verify step never instructs the model to fetch or confirm anything"
fi

echo "5. A published plan's marker is found in the fetched page..."
if OUT="$(render_check "$TMP/published.html" "$MARKER")" && [ "${OUT#OK:}" != "$OUT" ]; then pass
else fail "render check did not confirm the marker on a good page: ${OUT:-<no output>}"; fi

echo "6. An empty-body artifact is reported as a failure, not a success..."
set +e
OUT="$(render_check "$TMP/empty-body.html" "$MARKER")"; RC=$?
set -e
if [ "$RC" -ne 0 ] && [ "${OUT#BLANK:}" != "$OUT" ]; then pass
else fail "empty-body artifact passed the render check (rc=$RC, out=${OUT:-<none>})"; fi

echo "7. The render check inspects rendered text, not page source..."
# A naive source grep passes on the blank artifact because the marker survives in
# <title>. The render check must disagree. If it ever degrades into a source
# grep the two will agree and this assertion fails.
set +e
grep -q "$MARKER" "$TMP/empty-body.html"; NAIVE_RC=$?
render_check "$TMP/empty-body.html" "$MARKER" >/dev/null; CHECK_RC=$?
set -e
if [ "$NAIVE_RC" -eq 0 ] && [ "$CHECK_RC" -ne 0 ]; then pass
else fail "source grep (rc=$NAIVE_RC) and render check (rc=$CHECK_RC) agree on the blank artifact — the check is not reading rendered text"; fi

echo "8. A page that rendered someone else's plan is reported as a failure..."
set +e
OUT="$(render_check "$TMP/published.html" "Some other plan title")"; RC=$?
set -e
if [ "$RC" -ne 0 ] && [ "${OUT#MISSING:}" != "$OUT" ]; then pass
else fail "wrong-marker page passed the render check (rc=$RC, out=${OUT:-<none>})"; fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All plan-artifact render-check assertions passed."
  exit 0
else
  echo "$FAILURES assertion(s) failed."
  exit 1
fi
