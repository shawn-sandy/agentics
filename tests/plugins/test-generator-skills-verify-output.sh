#!/usr/bin/env bash
# Objective-verification test for add-verification-to-generator-skills.
#
# Invariant: every skill that generates or publishes HTML carries a check step
# that runs AFTER the write or publish it verifies, and that check has a failure
# branch. A check placed before the write, or one with no failure branch, is
# indistinguishable from no check at all — so both are audited, not just the
# presence of a heading.
#
# Also asserts the four artifact-tools skills declare WebFetch in their
# frontmatter `allowed-tools:` (an undeclared tool stalls the check on a
# permission prompt), and that plans-open is recorded as intentionally exempt
# rather than silently unchecked.
#
# Every assertion is exercised on the negative case at the end of the file: the
# audit is re-run against deliberately broken copies and must reject each one.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAILURES=0
pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# The audit. Takes a SKILL.md and a "wiring" regex naming the write/publish step
# the check must follow. Exits non-zero with a reason on any violation.
# ---------------------------------------------------------------------------
cat > "$TMP/audit.py" <<'PY'
import re, sys

path, wiring = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()

if not re.match(r'---\n.*?\n---\n', text, re.S):
    sys.exit(f"{path}: no opening YAML frontmatter block")

VERIFY = re.compile(r'^#{1,3} .*Verify the (page rendered|index|write)\b', re.M)
FAILURE = re.compile(r'do not report|report the failure|report the mismatch|\*\*STOP\*\*', re.I)

v = VERIFY.search(text)
if not v:
    sys.exit(f"{path}: no post-write check section (expected a 'Verify the ...' heading)")

w = re.search(wiring, text, re.M)
if not w:
    sys.exit(f"{path}: write/publish step not found (wiring regex: {wiring})")
if v.start() < w.start():
    sys.exit(f"{path}: check section precedes the write/publish step it verifies")

# Section body runs to the next h2 or EOF.
rest = text[v.end():]
nxt = re.search(r'^## ', rest, re.M)
body = rest[:nxt.start()] if nxt else rest

if len([ln for ln in body.splitlines() if ln.strip()]) < 2:
    sys.exit(f"{path}: check section is a heading with no instruction under it")
if not FAILURE.search(body):
    sys.exit(f"{path}: check section has no failure branch — it can only pass")

print(f"OK: {path.split('/kit/plugins/')[-1]}")
PY

# ---------------------------------------------------------------------------
# Frontmatter allowed-tools reader.
# ---------------------------------------------------------------------------
cat > "$TMP/tools.py" <<'PY'
import re, sys

text = open(sys.argv[1], encoding="utf-8").read()
m = re.match(r'---\n(.*?)\n---\n', text, re.S)
if not m:
    sys.exit(f"{sys.argv[1]}: no opening YAML frontmatter block")
hit = re.search(r'^allowed-tools:[ \t]*(.*)$', m.group(1), re.M)
if not hit:
    sys.exit(f"{sys.argv[1]}: frontmatter has no `allowed-tools:`")
print("\n".join(t.strip() for t in hit.group(1).split(',') if t.strip()))
PY

audit() { python3 "$TMP/audit.py" "$1" "$2"; }

# file|wiring regex the check must follow
SKILLS="\
kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md|^## Step [0-9]+ — Publish
kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md|^## Step [0-9]+ — Publish
kit/plugins/artifact-tools/skills/session-artifact/SKILL.md|^## Step [0-9]+ — Publish
kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md|^## Step [0-9]+ — Publish
kit/plugins/plan-agent/skills/plans-library/SKILL.md|^## Step [0-9]+ — Populate and write
kit/plugins/social-media-tools/skills/media-library/SKILL.md|^## Step [0-9]+ — Build the HTML page
kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md|^## Step [0-9]+ — Offer to write
kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md|\[Verify the write\]\(#verify-the-write\)"

echo "=== generator skills output-check audit ==="

echo "1. Every touched skill has a post-write check with a failure branch..."
while IFS='|' read -r rel wiring; do
  [ -n "$rel" ] || continue
  f="$ROOT/$rel"
  if [ ! -f "$f" ]; then fail "$rel missing"; continue; fi
  if out=$(audit "$f" "$wiring" 2>&1); then echo "  $out"; else fail "$out"; fi
done <<< "$SKILLS"
[ "$FAILURES" -eq 0 ] && pass || true

echo "2. Each artifact-tools skill declares WebFetch in allowed-tools..."
for skill in plan-artifact diff-artifact session-artifact prompt-artifact; do
  f="$ROOT/kit/plugins/artifact-tools/skills/$skill/SKILL.md"
  if python3 "$TMP/tools.py" "$f" | grep -qx 'WebFetch'; then
    echo "  OK: $skill"
  else
    fail "$skill does not declare WebFetch in frontmatter allowed-tools"
  fi
done

echo "3. plans-open is recorded as intentionally exempt..."
OPEN="$ROOT/kit/plugins/plan-agent/skills/plans-open/SKILL.md"
if grep -q 'OUTPUT-CHECK-EXEMPT' "$OPEN" && grep -q 'plans-library' "$OPEN"; then
  pass
else
  fail "plans-open carries no OUTPUT-CHECK-EXEMPT note pointing at plans-library"
fi

# ---------------------------------------------------------------------------
# Negative cases — the audit must reject broken output, not merely accept good.
# ---------------------------------------------------------------------------
SRC="$ROOT/kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md"
WIRING='^## Step [0-9]+ — Publish'
rejects() { # $1=label $2=mutated file
  if audit "$2" "$WIRING" >/dev/null 2>&1; then
    fail "audit accepted $1"
  else
    pass
  fi
}

echo "4. NEGATIVE: a skill whose check section was deleted is rejected..."
python3 - "$SRC" "$TMP/no-check.md" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
v = re.search(r'^#{1,3} .*Verify the page rendered\b', text, re.M)
rest = text[v.end():]
nxt = re.search(r'^## ', rest, re.M)
open(sys.argv[2], "w", encoding="utf-8").write(
    text[:v.start()] + (rest[nxt.start():] if nxt else ""))
PY
rejects "a skill with no check section" "$TMP/no-check.md"

echo "5. NEGATIVE: a check placed before the publish step is rejected..."
awk '/^## Step [0-9]+ — Publish/ && !done {
  print "## Step 0 — Verify the page rendered";
  print "";
  print "Fetch the URL and confirm the title; do not report the publish as successful otherwise.";
  print "";
  done = 1
} { print }' "$SRC" > "$TMP/out-of-order.md"
rejects "a check that runs before the publish it verifies" "$TMP/out-of-order.md"

echo "6. NEGATIVE: a check with no failure branch is rejected..."
grep -v -E 'do not report|report the failure' "$SRC" > "$TMP/no-failure.md"
rejects "a check that can only pass" "$TMP/no-failure.md"

echo "7. NEGATIVE: an artifact skill missing WebFetch is rejected..."
sed 's/^allowed-tools:.*/allowed-tools: Read, Edit, Glob, Skill, Artifact, AskUserQuestion, ToolSearch/' \
  "$SRC" > "$TMP/no-webfetch.md"
if python3 "$TMP/tools.py" "$TMP/no-webfetch.md" | grep -qx 'WebFetch'; then
  fail "allowed-tools reader found WebFetch where none is declared"
else
  pass
fi

echo "8. NEGATIVE: plans-open without the exemption note is rejected..."
grep -v 'OUTPUT-CHECK-EXEMPT' "$OPEN" > "$TMP/no-exempt.md"
if grep -q 'OUTPUT-CHECK-EXEMPT' "$TMP/no-exempt.md"; then
  fail "exemption check passed on a file with no exemption note"
else
  pass
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All generator-skill output-check assertions passed (8 skills audited, 5 negative cases rejected)."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
