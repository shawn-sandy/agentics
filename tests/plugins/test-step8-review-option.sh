#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"
FAILURES=0

echo "=== Step 8 Review Option Smoke Test ==="

echo "1. SKILL.md exists..."
if [ -f "$SKILL" ]; then
  echo "  PASS"
else
  echo "  FAIL: $SKILL not found"
  exit 1
fi

echo "2. 'Review the plan' appears in Step 8 option lists..."
if grep -q "Review the plan" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: 'Review the plan' not found in SKILL.md"
  FAILURES=$((FAILURES + 1))
fi

echo "3. No-workflow menu still contains 'Edit the plan'..."
# The no-workflow options block lists: Implement now / Review the plan / Edit the plan / Exit
if grep -A5 "Options (when no workflow prompt)" "$SKILL" | grep -q "Edit the plan"; then
  echo "  PASS"
else
  echo "  FAIL: 'Edit the plan' missing from no-workflow option list"
  FAILURES=$((FAILURES + 1))
fi

echo "4. Workflow menu contains 'Run as workflow'..."
if grep -A5 "Options (when workflow prompt exists)" "$SKILL" | grep -q "Run as workflow"; then
  echo "  PASS"
else
  echo "  FAIL: 'Run as workflow' missing from workflow option list"
  FAILURES=$((FAILURES + 1))
fi

echo "5. Workflow menu contains 'Review the plan'..."
if grep -A6 "Options (when workflow prompt exists)" "$SKILL" | grep -q "Review the plan"; then
  echo "  PASS"
else
  echo "  FAIL: 'Review the plan' missing from workflow option list"
  FAILURES=$((FAILURES + 1))
fi

echo "6. Workflow menu does NOT contain 'Edit the plan' (adaptive swap)..."
# Extract the 6 lines under the workflow-prompt block and confirm no Edit line
if grep -A6 "Options (when workflow prompt exists)" "$SKILL" | grep -q "Edit the plan"; then
  echo "  FAIL: 'Edit the plan' should be absent from workflow option list (adaptive swap)"
  FAILURES=$((FAILURES + 1))
else
  echo "  PASS"
fi

echo "7. Review handler offers a foreground sub-choice..."
if grep -q "Run now (foreground)" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: foreground sub-choice 'Run now (foreground)' not found in handler"
  FAILURES=$((FAILURES + 1))
fi

echo "8. Review handler offers a background sub-choice..."
if grep -q "Background.*Dispatch" "$SKILL" || grep -q '"Background"' "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: background sub-choice not found in handler"
  FAILURES=$((FAILURES + 1))
fi

echo "9. Foreground handler invokes Skill with plan-agent:review-plan..."
if grep -q 'skill: "plan-agent:review-plan"' "$SKILL" || grep -q "plan-agent:review-plan" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: foreground Skill invocation for plan-agent:review-plan not found"
  FAILURES=$((FAILURES + 1))
fi

echo "10. Background handler uses --background flag..."
if grep -q "\-\-background" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: '--background' flag not found in handler"
  FAILURES=$((FAILURES + 1))
fi

echo "11. Handler leaves plan status at 'todo'..."
if grep -A20 "If the user chooses \`Review the plan\`" "$SKILL" | grep -q "todo"; then
  echo "  PASS"
else
  echo "  FAIL: no 'todo' status note in Review handler"
  FAILURES=$((FAILURES + 1))
fi

echo "12. Agent-Teams-unavailable case handled gracefully..."
if grep -A20 "If the user chooses \`Review the plan\`" "$SKILL" | grep -q "unavailable\|gracefully"; then
  echo "  PASS"
else
  echo "  FAIL: no graceful-degradation note in Review handler"
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
