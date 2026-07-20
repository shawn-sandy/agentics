#!/usr/bin/env bash
set -euo pipefail

# Smoke test for the `build` skill: it exists, ships (is not gitignored), is
# well-formed, owns the three implementation gates, and implementation-plan
# delegates to it instead of carrying a second copy of the loop.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL_DIR="$ROOT/kit/plugins/plan-agent/skills/build"
SKILL="$SKILL_DIR/SKILL.md"
IMPL="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"
MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"
FAILURES=0

echo "=== build Skill Smoke Test ==="

if [ ! -f "$SKILL" ]; then
  echo "FATAL: $SKILL does not exist — every check below would cascade."
  exit 1
fi

echo "1. SKILL.md exists with name: build..."
if grep -q "^name: build$" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: missing name line"
  FAILURES=$((FAILURES + 1))
fi

echo "2. The skill is tracked by git (it must actually ship)..."
# Regression guard: an unanchored `build/` in .gitignore silently excluded this
# whole directory, so every local test passed while the skill was never
# committed and never reached the published dist. `check-ignore` alone does not
# express that — it passes for an untracked-and-unignored file, which is the
# broken state. Tracked-ness is the invariant; check-ignore only explains why
# when it fails. (build-dist.mjs copies from the filesystem, so a local dist
# build is not evidence: only the git path reveals this.)
if git -C "$ROOT" ls-files --error-unmatch "$SKILL" >/dev/null 2>&1; then
  echo "  PASS"
else
  echo "  FAIL: $SKILL is not tracked by git — it would not reach the published dist."
  if git -C "$ROOT" check-ignore -q "$SKILL" 2>/dev/null; then
    echo "        cause: $(git -C "$ROOT" check-ignore -v "$SKILL")"
  else
    echo "        cause: not ignored, just never 'git add'ed."
  fi
  FAILURES=$((FAILURES + 1))
fi

echo "3. description is three-part (<=200 total, first sentence <=80, 'Use when')..."
if python3 - "$SKILL" <<'PY'
import re, sys
# Tolerant of unquoted and single-quoted YAML, like tests/plugins/test-build-proposal.sh.
m = re.search(r'^description:\s*"?(.*?)"?\s*$', open(sys.argv[1]).read(), re.M)
if not m:
    sys.exit(1)
d = m.group(1)
s = re.search(r"(?<=[.!?])\s", d)
first = len(d[: s.start()] if s else d)
sys.exit(0 if len(d) <= 200 and first <= 80 and "use when" in d.lower() else 1)
PY
then
  echo "  PASS"
else
  echo "  FAIL: description must be <=200 total, first sentence <=80, and contain 'Use when'"
  FAILURES=$((FAILURES + 1))
fi

echo "4. allowed-tools declares ToolSearch and ExitPlanMode (deferred-tool bootstrap)..."
ATLINE="$(grep -m1 '^allowed-tools:' "$SKILL" || true)"
if echo "$ATLINE" | grep -qw ToolSearch && echo "$ATLINE" | grep -qw ExitPlanMode \
  && grep -q "select:ExitPlanMode" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: ToolSearch/ExitPlanMode missing from allowed-tools or the body bootstrap"
  FAILURES=$((FAILURES + 1))
fi

echo "5. Body carries all three gates plus the re-render command..."
if grep -q "Acceptance criteria gate" "$SKILL" \
  && grep -q "End-to-end verification gate" "$SKILL" \
  && grep -q "Completion checklist gate" "$SKILL" \
  && grep -q "build-plan-html.mjs" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: a gate heading or the re-render command is missing"
  FAILURES=$((FAILURES + 1))
fi

echo "6. Spec-is-source-of-truth rules survived the lift, in their owning sections..."
# Each of these was an explicit instruction in the block that moved. Checking
# the whole file was too weak: a mutation that replaced all five rules and
# appended a decoy paragraph containing the phrases still passed. Each pattern
# is therefore scoped to the section that must carry it.
# Newlines squeezed to spaces: this file is hard-wrapped, so any phrase longer
# than a few words can straddle a line break and defeat line-based grep.
flatten() { tr '\n' ' ' | tr -s ' '; }
SOT="$(sed -n '/^\*\*The markdown spec is the source of truth/,/^## Invocation/p' "$SKILL" | flatten)"
GATES="$(sed -n '/^## Step 3 —/,/^## Step 6 —/p' "$SKILL" | flatten)"
MISSING=""
printf '%s' "$GATES" | grep -q 'flip back to `- \[ \]`' || MISSING="$MISSING undo-rule"
printf '%s' "$SOT" | grep -qi "browser-only persistence" || MISSING="$MISSING browser-persistence-ban"
printf '%s' "$GATES" | grep -qi "delete the section" || MISSING="$MISSING completion-report-teardown"
printf '%s' "$GATES" | grep -qi "three status representations" || MISSING="$MISSING status-representations"
printf '%s' "$GATES" | grep -qi "no per-card run command" || MISSING="$MISSING per-card-run-note"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: lifted rules missing from their sections in build/SKILL.md:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "7. status: completed is gated behind end-to-end verification, not the criteria gate..."
if grep -q 'Do not set `status: completed` here' "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: the criteria gate does not forbid marking completed before Step 4 runs"
  FAILURES=$((FAILURES + 1))
fi

echo "8. implementation-plan delegates and carries no second copy of any gate..."
# Looks for the gate *heading* form ("<name> gate (mandatory"), not any mention:
# the delegation prose legitimately names the gates it hands off, and an
# any-mention grep turned that sentence into three false positives. Newlines are
# squeezed to spaces first because this file is hard-wrapped at ~72 columns, so
# a re-inlined heading can straddle a line break.
FLAT="$(tr '\n' ' ' < "$IMPL" | tr -s ' ')"
DUPES=""
for gate in "acceptance criteria gate (mandatory" "end-to-end verification gate (mandatory" "completion checklist gate (mandatory"; do
  printf '%s' "$FLAT" | grep -qi "$gate" && DUPES="$DUPES [$gate]"
done
if grep -q 'Skill(skill: "plan-agent:build"' "$IMPL" && [ -z "$DUPES" ]; then
  echo "  PASS"
else
  echo "  FAIL: missing delegation, or implementation-plan re-inlined gates:$DUPES"
  FAILURES=$((FAILURES + 1))
fi

echo "9. marketplace.json is valid JSON and its plan-agent description names every shipped skill..."
# Structural, not lexical: the invariant is "every skill directory is
# discoverable in the blurb the marketplace surfaces", so a copy-edit that
# rewords the build clause does not turn this red. The version-regression guard
# deliberately lives in scripts/check-plugin-versions.mjs instead — that one is
# PR-gated and compares against origin/main properly.
if python3 - "$MARKETPLACE" "$ROOT" <<'PY'
import json, os, sys
doc = json.load(open(sys.argv[1]))          # raises on malformed JSON
entry = [p for p in doc["plugins"] if p["name"] == "plan-agent"][0]
desc = entry["description"]
skills = sorted(
    d for d in os.listdir(os.path.join(sys.argv[2], "kit/plugins/plan-agent/skills"))
    if not d.startswith(".")
)
missing = [s for s in skills if s not in desc]
if missing:
    print("  missing from description:", ", ".join(missing))
sys.exit(1 if missing else 0)
PY
then
  echo "  PASS"
else
  echo "  FAIL: marketplace.json is malformed, or its plan-agent description omits a shipped skill"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All build-skill checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
