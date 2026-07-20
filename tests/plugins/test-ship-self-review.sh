#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/git-agent/skills/ship/SKILL.md"
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
if grep -q "^## Step 4.5: Self-Review Before Push" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: Step 4.5 heading not found"
  FAILURES=$((FAILURES + 1))
fi

echo "3. Step 4.5 is ordered between Step 4 and Step 5..."
S4=$(grep -n "^## Step 4: Commit" "$SKILL" | cut -d: -f1)
S45=$(grep -n "^## Step 4.5:" "$SKILL" | cut -d: -f1)
S5=$(grep -n "^## Step 5: Push" "$SKILL" | cut -d: -f1)
if [ -n "$S4" ] && [ -n "$S45" ] && [ -n "$S5" ] && [ "$S4" -lt "$S45" ] && [ "$S45" -lt "$S5" ]; then
  echo "  PASS"
else
  echo "  FAIL: expected Step 4 < Step 4.5 < Step 5, got $S4 / $S45 / $S5"
  FAILURES=$((FAILURES + 1))
fi

echo "4. Runs by default with a --no-review escape hatch..."
if grep -A2 "^## Step 4.5:" "$SKILL" | grep -q "by default" &&
   grep -A2 "^## Step 4.5:" "$SKILL" | grep -q -- "--no-review"; then
  echo "  PASS"
else
  echo "  FAIL: default-on / --no-review opt-out not stated at the top of Step 4.5"
  FAILURES=$((FAILURES + 1))
fi

echo "5. All four regression checks are present..."
for term in "accessibility" "escaping" "truncation" "Responsive"; do
  if grep -A30 "^## Step 4.5:" "$SKILL" | grep -qi "$term"; then
    echo "  PASS ($term)"
  else
    echo "  FAIL: check '$term' missing from Step 4.5"
    FAILURES=$((FAILURES + 1))
  fi
done

echo "6. Fixes fold into the Step 4 commit via amend..."
if grep -A45 "^## Step 4.5:" "$SKILL" | grep -q "commit --amend --no-edit"; then
  echo "  PASS"
else
  echo "  FAIL: 'git commit --amend --no-edit' not found in Step 4.5"
  FAILURES=$((FAILURES + 1))
fi

echo "7. Re-check is bounded (no unbounded loop)..."
if grep -A45 "^## Step 4.5:" "$SKILL" | grep -q "Do not loop a third time"; then
  echo "  PASS"
else
  echo "  FAIL: no loop bound stated in Step 4.5"
  FAILURES=$((FAILURES + 1))
fi

echo "8. Step 4.5 never blocks the ship..."
if grep -A50 "^## Step 4.5:" "$SKILL" | grep -q "never blocks the ship"; then
  echo "  PASS"
else
  echo "  FAIL: non-blocking guarantee not stated"
  FAILURES=$((FAILURES + 1))
fi

echo "9. Base detection is delegated to Step 7, not duplicated..."
if grep -A12 "^## Step 4.5:" "$SKILL" | grep -q "Step 7"; then
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
A45=$(grep -n "^### Step 4.5:" "$AGENT" | cut -d: -f1)
A5=$(grep -n "^### Step 5: Push" "$AGENT" | cut -d: -f1)
if [ -n "$A4" ] && [ -n "$A45" ] && [ -n "$A5" ] && [ "$A4" -lt "$A45" ] && [ "$A45" -lt "$A5" ]; then
  echo "  PASS"
else
  echo "  FAIL: expected Step 4 < Step 4.5 < Step 5, got $A4 / $A45 / $A5"
  FAILURES=$((FAILURES + 1))
fi

echo "13. Background ship has no opt-out (always runs)..."
if grep -A2 "^### Step 4.5:" "$AGENT" | grep -q "no opt-out"; then
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

echo "15. All four regression checks are present..."
for term in "accessibility" "escaping" "truncation" "Responsive"; do
  if grep -A30 "^### Step 4.5:" "$AGENT" | grep -qi "$term"; then
    echo "  PASS ($term)"
  else
    echo "  FAIL: check '$term' missing from agent Step 4.5"
    FAILURES=$((FAILURES + 1))
  fi
done

echo "16. Background self-review is report-only (does NOT amend)..."
if grep -A40 "^### Step 4.5:" "$AGENT" | grep -q "report-only" &&
   ! grep -A40 "^### Step 4.5:" "$AGENT" | grep -q "commit --amend"; then
  echo "  PASS"
else
  echo "  FAIL: agent Step 4.5 must be report-only — it cannot edit files (see check 19)"
  FAILURES=$((FAILURES + 1))
fi

echo "17. Non-blocking guarantee present..."
if grep -A40 "^### Step 4.5:" "$AGENT" | grep -q "never blocks the ship"; then
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
if grep -A40 "^### Step 4.5:" "$AGENT" | grep -q "sed -i"; then
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
