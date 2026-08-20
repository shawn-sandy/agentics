#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/git-agent/skills/ship/SKILL.md"
# Step 4.5's procedure detail lives in a reference file since git-agent v4.8.0 —
# the SKILL.md body is paid in full on every trigger, so the checklist a
# reviewer walks once moved out while the POLICY stayed in the core. The split
# is why checks 5-7 read this file and checks 2-4/8-10 still read SKILL.md:
# where the contract lives may change, that it exists somewhere reachable from
# the core may not. Check 4.5 asserts the reachability.
SELF_REVIEW="$ROOT/kit/plugins/git-agent/skills/ship/references/self-review.md"
FAILURES=0

echo "=== ship Self-Review Smoke Test ==="

echo "1. SKILL.md exists..."
if [ -f "$SKILL" ]; then
  echo "  PASS"
else
  echo "  FAIL: $SKILL not found"
  exit 1
fi

echo "2. Step 4.5 exists..."
# -x as well as -F: the heading is a whole line, so requiring a full-line match
# keeps this strict against a stray mention in prose, without going back to a
# regex where the `.` in "4.5" would match any character.
if grep -qxF "## Step 4.5: Self-Review Before Push" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: Step 4.5 heading not found"
  FAILURES=$((FAILURES + 1))
fi

echo "3. Step 4.5 is ordered between Step 4 and Step 5..."
S4=$(grep -n "^## Step 4: Commit" "$SKILL" | cut -d: -f1)
S45=$(grep -n "^## Step 4\.5:" "$SKILL" | cut -d: -f1)
S5=$(grep -n "^## Step 5: Push" "$SKILL" | cut -d: -f1)
if [ -n "$S4" ] && [ -n "$S45" ] && [ -n "$S5" ] && [ "$S4" -lt "$S45" ] && [ "$S45" -lt "$S5" ]; then
  echo "  PASS"
else
  echo "  FAIL: expected Step 4 < Step 4.5 < Step 5, got $S4 / $S45 / $S5"
  FAILURES=$((FAILURES + 1))
fi

echo "4. Runs by default with a --no-review escape hatch..."
if grep -A2 "^## Step 4\.5:" "$SKILL" | grep -q "by default" &&
   grep -A2 "^## Step 4\.5:" "$SKILL" | grep -q -- "--no-review"; then
  echo "  PASS"
else
  echo "  FAIL: default-on / --no-review opt-out not stated at the top of Step 4.5"
  FAILURES=$((FAILURES + 1))
fi

echo "4.5. Step 4.5 links the self-review reference (a reference nothing links to never loads)..."
# Scoped to the Step 4.5 section, not the whole file: an unscoped grep passes on
# a mention anywhere in SKILL.md, so it would still go green if Step 4.5 stopped
# delegating its procedure. The range ends at the next `## ` heading rather than
# at a hard-coded "Step 5: Push", so renaming the following step cannot silently
# empty the range and turn this into a vacuous pass.
#
# awk, not `sed -n '/a/,/b/{...}'`: that form is a GNU extension. BSD sed (macOS)
# rejects it outright, leaving this variable empty and failing the check for the
# wrong reason on a dev machine while CI's GNU sed passed it — the same
# dev-vs-CI drift the Python word count in test-skill-split-git-social.sh avoids.
STEP_45=$(awk '/^## Step 4\.5:/{f=1;next} f&&/^## /{exit} f' "$SKILL")
if [ -z "$STEP_45" ]; then
  echo "  FAIL: no '## Step 4.5:' section found in SKILL.md (heading renamed?)"
  FAILURES=$((FAILURES + 1))
elif printf '%s\n' "$STEP_45" | grep -qF "references/self-review.md" && [ -f "$SELF_REVIEW" ]; then
  echo "  PASS"
else
  echo "  FAIL: Step 4.5 must link references/self-review.md, and that file must exist"
  FAILURES=$((FAILURES + 1))
fi

echo "5. All six adversarial checks are present (in references/self-review.md)..."
# The v4.19.3 checklist. Sourced from the usage analysis that motivated the
# adversarial review: these are the defect classes PR bots actually caught.
for term in "no-op edits" "vacuous test assertions" "regressions" "auth/role/key" "secrets or tokens" "accessibility"; do
  if [ -f "$SELF_REVIEW" ] && grep -qi "$term" "$SELF_REVIEW"; then
    echo "  PASS ($term)"
  else
    echo "  FAIL: check '$term' missing from references/self-review.md"
    FAILURES=$((FAILURES + 1))
  fi
done

echo "5.5. The review runs in a fresh context (subagent dispatch)..."
# One-line phrases only: grep -F cannot match across a wrap (see check 5's note
# in test-skill-split-git-social.sh).
if [ -f "$SELF_REVIEW" ] && grep -qF "code-review:agent-code-reviewer" "$SELF_REVIEW" && grep -qi "fresh context" "$SELF_REVIEW"; then
  echo "  PASS"
else
  echo "  FAIL: references/self-review.md must dispatch a fresh-context subagent (code-review:agent-code-reviewer, else general-purpose)"
  FAILURES=$((FAILURES + 1))
fi

echo "6. Fixes fold into the Step 4 commit via amend (in references/self-review.md)..."
if [ -f "$SELF_REVIEW" ] && grep -q "commit --amend --no-edit" "$SELF_REVIEW"; then
  echo "  PASS"
else
  echo "  FAIL: 'git commit --amend --no-edit' not found in references/self-review.md"
  FAILURES=$((FAILURES + 1))
fi

echo "7. Review is single-pass (no re-review loop) (in references/self-review.md)..."
if [ -f "$SELF_REVIEW" ] && grep -q "never dispatch a second review" "$SELF_REVIEW"; then
  echo "  PASS"
else
  echo "  FAIL: no single-pass bound stated in references/self-review.md"
  FAILURES=$((FAILURES + 1))
fi

echo "8. Step 4.5 never blocks the ship..."
if grep -A50 "^## Step 4\.5:" "$SKILL" | grep -q "never blocks the ship"; then
  echo "  PASS"
else
  echo "  FAIL: non-blocking guarantee not stated"
  FAILURES=$((FAILURES + 1))
fi

echo "9. Base detection is delegated to Step 7, not duplicated..."
if grep -A12 "^## Step 4\.5:" "$SKILL" | grep -q "Step 7"; then
  echo "  PASS"
else
  echo "  FAIL: Step 4.5 should reuse Step 7's base-branch procedure"
  FAILURES=$((FAILURES + 1))
fi

echo "10. allowed-tools includes Edit (needed to apply fixes)..."
if grep -m1 "^allowed-tools:" "$SKILL" | grep -q "Edit"; then
  echo "  PASS"
else
  echo "  FAIL: 'Edit' missing from allowed-tools"
  FAILURES=$((FAILURES + 1))
fi

AGENT="$ROOT/kit/plugins/git-agent/agents/agent-ship.md"

echo ""
echo "=== agent-ship Self-Review Smoke Test ==="

echo "11. agent-ship.md exists..."
if [ -f "$AGENT" ]; then
  echo "  PASS"
else
  echo "  FAIL: $AGENT not found"
  exit 1
fi

echo "12. Step 4.5 is ordered between Step 4 and Step 5..."
A4=$(grep -n "^### Step 4: Commit" "$AGENT" | cut -d: -f1)
A45=$(grep -n "^### Step 4\.5:" "$AGENT" | cut -d: -f1)
A5=$(grep -n "^### Step 5: Push" "$AGENT" | cut -d: -f1)
if [ -n "$A4" ] && [ -n "$A45" ] && [ -n "$A5" ] && [ "$A4" -lt "$A45" ] && [ "$A45" -lt "$A5" ]; then
  echo "  PASS"
else
  echo "  FAIL: expected Step 4 < Step 4.5 < Step 5, got $A4 / $A45 / $A5"
  FAILURES=$((FAILURES + 1))
fi

echo "13. Background ship has no opt-out (always runs)..."
if grep -A2 "^### Step 4\.5:" "$AGENT" | grep -q "no opt-out"; then
  echo "  PASS"
else
  echo "  FAIL: agent-ship must state the self-review always runs"
  FAILURES=$((FAILURES + 1))
fi

echo "14. agent-ship does NOT offer --no-review (no user to pass it)..."
if grep -q -- "--no-review" "$AGENT"; then
  echo "  FAIL: '--no-review' has no meaning in a background agent"
  FAILURES=$((FAILURES + 1))
else
  echo "  PASS"
fi

echo "15. All six adversarial checks are present..."
for term in "no-op edits" "vacuous test assertions" "regressions" "auth/role/key" "secrets or tokens" "accessibility"; do
  if grep -A30 "^### Step 4\.5:" "$AGENT" | grep -qi "$term"; then
    echo "  PASS ($term)"
  else
    echo "  FAIL: check '$term' missing from agent Step 4.5"
    FAILURES=$((FAILURES + 1))
  fi
done

echo "16. Background self-review is report-only (does NOT amend)..."
if grep -A40 "^### Step 4\.5:" "$AGENT" | grep -q "report-only" &&
   ! grep -A40 "^### Step 4\.5:" "$AGENT" | grep -q "commit --amend"; then
  echo "  PASS"
else
  echo "  FAIL: agent Step 4.5 must be report-only — it cannot edit files (see check 19)"
  FAILURES=$((FAILURES + 1))
fi

echo "17. Non-blocking guarantee present..."
if grep -A40 "^### Step 4\.5:" "$AGENT" | grep -q "never blocks the ship"; then
  echo "  PASS"
else
  echo "  FAIL: non-blocking guarantee missing"
  FAILURES=$((FAILURES + 1))
fi

echo "18. Findings surface in the returned report..."
if grep -q "self-review findings" "$AGENT"; then
  echo "  PASS"
else
  echo "  FAIL: agent must report findings back to the parent session"
  FAILURES=$((FAILURES + 1))
fi

# Checks 19-21 guard the effective permission, not just the allow line.
# `disallowedTools` overrides `tools`, so asserting `tools:` contains Edit
# would pass while the agent is still denied Edit at runtime.
echo "19. Edit is effectively DENIED (disallowedTools wins over tools)..."
if grep -m1 "^disallowedTools:" "$AGENT" | grep -q "Edit"; then
  echo "  PASS"
else
  echo "  FAIL: background ship agents must deny Edit — safety invariant since v3.5.0"
  FAILURES=$((FAILURES + 1))
fi

echo "20. tools does not falsely advertise Edit..."
if grep -m1 "^tools:" "$AGENT" | grep -q "Edit"; then
  echo "  FAIL: 'tools' lists Edit but 'disallowedTools' denies it — misleading"
  FAILURES=$((FAILURES + 1))
else
  echo "  PASS"
fi

echo "21. Step 4.5 forbids routing around the deny list via Bash..."
if grep -A40 "^### Step 4\.5:" "$AGENT" | grep -q "sed -i"; then
  echo "  PASS"
else
  echo "  FAIL: no explicit prohibition on Bash-based file rewriting"
  FAILURES=$((FAILURES + 1))
fi

echo "22. Deny-list invariant holds across all git-agent background agents..."
BG_FAIL=0
for a in "$ROOT"/kit/plugins/git-agent/agents/agent-*.md; do
  if ! grep -m1 "^disallowedTools:" "$a" | grep -q "Edit"; then
    echo "  FAIL: $(basename "$a") does not deny Edit"
    BG_FAIL=1
  fi
done
if [ "$BG_FAIL" -eq 0 ]; then
  echo "  PASS"
else
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks PASSED."
  exit 0
else
  echo "$FAILURES check(s) FAILED."
  exit 1
fi
