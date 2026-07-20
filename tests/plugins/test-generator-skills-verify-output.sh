#!/usr/bin/env bash
# Objective-verification test for add-verification-to-generator-skills.
#
# Invariant: every skill that generates or publishes HTML carries a check step
# that runs AFTER the write it verifies, names the artifact of that write, tells
# the model to actually inspect it, and has a failure branch.
#
# The audit deliberately does NOT match stock phrases. An earlier version keyed
# on a heading plus any one of four boilerplate phrases, and passed on a section
# whose body read "Skip this step." — while failing on harmless rewording. So it
# now requires three independent things in the body: an inspection verb, a
# reference to the thing produced by the write (the URL, the index, the target
# path), and a failure branch. Nonsense satisfies none of them; a reworded but
# behaviourally identical step satisfies all three.
#
# Also asserts the four artifact-tools skills declare WebFetch in their
# frontmatter `allowed-tools:` (an undeclared tool stalls the check on a
# permission prompt), and that plans-open is recorded as intentionally exempt.
#
# Every assertion is exercised on the negative case: the audit is re-run against
# deliberately broken copies and must reject each one.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FAILURES=0
pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# The audit.
#   argv: <skill.md> <mode> <wiring regex> <evidence regex>
#   mode "order" — the check heading must appear after the wiring (write) match.
#   mode "ref"   — the skill has one shared check section referenced from each
#                  write site; require at least two references plus the section.
# ---------------------------------------------------------------------------
cat > "$TMP/audit.py" <<'PY'
import re, sys

path, mode, wiring, evidence = sys.argv[1:5]
text = open(path, encoding="utf-8").read()

if not re.match(r'---\n.*?\n---\n', text, re.S):
    sys.exit(f"{path}: no opening YAML frontmatter block")

VERIFY = re.compile(r'^#{1,3} .*\b(Verify|Confirm|Check)\b[^\n]*\b(rendered|index|write)\b', re.M | re.I)
# What the check must tell the model to DO. Reporting alone is not inspecting.
INSPECT = re.compile(r'\b(fetch|confirm|assert|count|diff|parse|re-?read|compare)\w*\b', re.I)
# What it must do when the inspection fails.
FAILURE = re.compile(r'do not report|report the failure|report the mismatch|\*\*STOP\*\*', re.I)
# Explicit opt-out defeats the whole point.
SKIP = re.compile(r'\bskip this step\b', re.I)

v = VERIFY.search(text)
if not v:
    sys.exit(f"{path}: no post-write check section (expected a 'Verify the ...' heading)")

if mode == "order":
    w = re.search(wiring, text, re.M)
    if not w:
        sys.exit(f"{path}: write/publish step not found (wiring regex: {wiring})")
    if v.start() < w.start():
        sys.exit(f"{path}: check section precedes the write/publish step it verifies")
elif mode == "ref":
    refs = list(re.finditer(wiring, text, re.M))
    if len(refs) < 2:
        sys.exit(f"{path}: shared check section is referenced from only "
                 f"{len(refs)} write site(s) (expected >= 2, regex: {wiring})")
    if v.start() < refs[-1].start():
        sys.exit(f"{path}: shared check section is defined above the write sites "
                 f"that reference it — a check placed before the write is no check")
else:
    sys.exit(f"{path}: unknown audit mode {mode!r}")

# Section body runs to the next h2 or EOF.
rest = text[v.end():]
nxt = re.search(r'^## ', rest, re.M)
body = rest[:nxt.start()] if nxt else rest

if len([ln for ln in body.splitlines() if ln.strip()]) < 2:
    sys.exit(f"{path}: check section is a heading with no instruction under it")
if SKIP.search(body):
    sys.exit(f"{path}: check section tells the model to skip it")
if not INSPECT.search(body):
    sys.exit(f"{path}: check section never inspects anything — no fetch/confirm/"
             f"assert/count/diff/parse instruction in the body")
if not re.search(evidence, body, re.I):
    sys.exit(f"{path}: check section never names what the write produced "
             f"(expected a reference matching {evidence})")
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

# ---------------------------------------------------------------------------
# plans-open exemption detector. Two conditions, so stripping one is a real
# negative rather than a grep-for-what-we-just-deleted tautology.
# ---------------------------------------------------------------------------
exempt_ok() { # $1 = plans-open SKILL.md
  grep -qiE 'generates no output|no output check of its own' "$1" \
    && grep -qF 'plans-library' "$1"
}

audit() { python3 "$TMP/audit.py" "$1" "$2" "$3" "$4"; }

# file|mode|wiring regex|evidence the check must name
SKILLS="\
kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md|order|^## Step [0-9]+ — Publish|\burl\b
kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md|order|^## Step [0-9]+ — Publish|\burl\b
kit/plugins/artifact-tools/skills/session-artifact/SKILL.md|order|^## Step [0-9]+ — Publish|\burl\b
kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md|order|^## Step [0-9]+ — Publish|\burl\b
kit/plugins/plan-agent/skills/plans-library/SKILL.md|order|^## Step [0-9]+ — Populate and write|SOURCE_COUNT
kit/plugins/social-media-tools/skills/media-library/SKILL.md|order|^## Step [0-9]+ — Build the HTML page|SOURCE_COUNT
kit/plugins/memory-tools/skills/agentic-memory-management/SKILL.md|order|^## Step [0-9]+ — Offer to write|TARGET
kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md|ref|^.*run \[Verify the write\]\(#verify-the-write\)|TARGET"

echo "=== generator skills output-check audit ==="

echo "1. Every touched skill has a post-write check that inspects its output..."
while IFS='|' read -r rel mode wiring evidence; do
  [ -n "$rel" ] || continue
  f="$ROOT/$rel"
  if [ ! -f "$f" ]; then fail "$rel missing"; continue; fi
  if out=$(audit "$f" "$mode" "$wiring" "$evidence" 2>&1); then echo "  $out"; else fail "$out"; fi
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
if exempt_ok "$OPEN"; then pass; else
  fail "plans-open does not state it generates no output and point at plans-library"
fi

# ---------------------------------------------------------------------------
# Negative cases — the audit must reject broken output, not merely accept good.
# ---------------------------------------------------------------------------
SRC="$ROOT/kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md"
WIRING='^## Step [0-9]+ — Publish'
rejects() { # $1=label $2=mutated file
  if audit "$2" order "$WIRING" '\burl\b' >/dev/null 2>&1; then
    fail "audit accepted $1"
  else
    pass
  fi
}

# Replace the check section's body, keeping its heading.
regut() { # $1=dest $2=replacement body
  BODY="$2" python3 - "$SRC" "$1" <<'PY'
import os, re, sys
text = open(sys.argv[1], encoding="utf-8").read()
v = re.search(r'^#{1,3} .*\b(Verify|Confirm|Check)\b[^\n]*\brender[^\n]*$', text, re.M | re.I)
rest = text[v.end():]
nxt = re.search(r'^## ', rest, re.M)
tail = rest[nxt.start():] if nxt else ""
open(sys.argv[2], "w", encoding="utf-8").write(
    text[:v.end()] + "\n\n" + os.environ["BODY"] + "\n\n" + tail)
PY
}

echo "4. NEGATIVE: a skill whose check section was deleted is rejected..."
python3 - "$SRC" "$TMP/no-check.md" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
v = re.search(r'^#{1,3} .*\b(Verify|Confirm|Check)\b[^\n]*\brender', text, re.M | re.I)
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
regut "$TMP/no-failure.md" 'Fetch the returned URL and confirm the page contains the plan title.
The title is set from the plan spec, so it always renders.'
rejects "a check that can only pass" "$TMP/no-failure.md"

echo "7. NEGATIVE: a check that tells the model to skip it is rejected..."
regut "$TMP/opt-out.md" 'Skip this step. Publishing already returned a URL.
If anything goes wrong, report the failure **with the URL** and do not report success.'
rejects "a check whose body opts out" "$TMP/opt-out.md"

echo "8. NEGATIVE: a check that reports but never inspects is rejected..."
regut "$TMP/no-inspect.md" 'If the publish went badly, report the failure with the URL.
Do not report the publish as successful in that case.'
rejects "a check that never inspects the published page" "$TMP/no-inspect.md"

echo "9. NEGATIVE: a check that never names the published URL is rejected..."
regut "$TMP/no-evidence.md" 'Confirm the page looks right before saying anything.
Otherwise report the failure and do not report the publish as successful.'
rejects "a check that never names what the publish produced" "$TMP/no-evidence.md"

echo "10. POSITIVE: a reworded but behaviourally identical check is accepted..."
regut "$TMP/reworded.md" 'Retrieve the returned URL and compare the page text against the plan title.
Should the title be absent, report the failure (including the URL) and do not report the publish as successful.'
if audit "$TMP/reworded.md" order "$WIRING" '\burl\b' >/dev/null 2>&1; then
  pass
else
  fail "audit rejected a reworded check that still fetches, compares, and reports"
fi

echo "11. NEGATIVE: an artifact skill missing WebFetch is rejected..."
sed 's/^allowed-tools:.*/allowed-tools: Read, Edit, Glob, Skill, Artifact, AskUserQuestion, ToolSearch/' \
  "$SRC" > "$TMP/no-webfetch.md"
if python3 "$TMP/tools.py" "$TMP/no-webfetch.md" | grep -qx 'WebFetch'; then
  fail "allowed-tools reader found WebFetch where none is declared"
else
  pass
fi

echo "12. NEGATIVE: plans-open naming plans-library but claiming a check of its own..."
sed 's/generates no output, so it has no output check of its own/writes the gallery and checks it/' \
  "$OPEN" > "$TMP/half-exempt.md"
if exempt_ok "$TMP/half-exempt.md"; then
  fail "exemption detector accepted a note that claims plans-open does its own check"
else
  pass
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All generator-skill output-check assertions passed (8 skills audited, 8 negative cases rejected, 2 positive controls)."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
