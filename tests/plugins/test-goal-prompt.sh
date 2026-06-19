#!/usr/bin/env bash
set -euo pipefail

# Objective smoke test for the outcome-driven Goal prompt in plan-agent HTML plans.
#
# The goal prompt is a third copy-paste prompt alongside the implement and
# workflow prompts: it frames the work as a goal to achieve ("use the plan as
# reference, but optimize for the outcome") rather than steps to execute, and
# is ALWAYS present (no flag, no complexity heuristic). These asserts pin the
# feature to the skeleton and its SKILL.md contract so the three prompt rows
# cannot silently diverge.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKELETON="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html"
PLAN_SKILL="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"
FAILURES=0

echo "=== Goal Prompt Smoke Test ==="

echo "1. SKELETON.html head carries the always-present plan-goal meta tag..."
if grep -q '<meta name="plan-goal" content="{goal-prompt}">' "$SKELETON"; then
  echo "  PASS"
else
  echo "  FAIL: <meta name=\"plan-goal\" content=\"{goal-prompt}\"> not found in SKELETON.html"
  FAILURES=$((FAILURES + 1))
fi

echo "2. Goal prompt markup: .plan-goal details, goal-cmd code, copyGoal() button, summary..."
if grep -q 'class="plan-goal"' "$SKELETON" \
   && grep -q 'id="goal-cmd"' "$SKELETON" \
   && grep -q 'onclick="copyGoal(this)"' "$SKELETON" \
   && grep -q 'aria-label="Copy goal prompt to clipboard"' "$SKELETON" \
   && grep -q 'Pursue as goal' "$SKELETON" \
   && grep -q '{goal-prompt}' "$SKELETON"; then
  echo "  PASS"
else
  echo "  FAIL: .plan-goal markup is missing one of class/id/onclick/aria-label/summary/placeholder"
  FAILURES=$((FAILURES + 1))
fi

echo "3. copyGoal() is defined in the inline script and reads #goal-cmd..."
if awk '/function copyGoal\(/{f=1} f{print} f && /^}/{exit}' "$SKELETON" \
     | grep -q "getElementById('goal-cmd')"; then
  echo "  PASS"
else
  echo "  FAIL: copyGoal() missing or does not read #goal-cmd"
  FAILURES=$((FAILURES + 1))
fi

echo "4. .plan-goal CSS is defined and hidden when completed + in print..."
if grep -q '^  \.plan-goal {' "$SKELETON" \
   && grep -q '\[data-status="completed"\] \.plan-goal { display: none; }' "$SKELETON" \
   && grep -q '@media print { \.plan-goal { display: none !important; } }' "$SKELETON"; then
  echo "  PASS"
else
  echo "  FAIL: .plan-goal CSS block, completed-hide, or print-hide rule not found"
  FAILURES=$((FAILURES + 1))
fi

echo "5. DOM order is implement -> goal -> workflow..."
if python3 - "$SKELETON" << 'PYEOF'
import sys
html = open(sys.argv[1]).read()
i = html.find('class="plan-implement"')
g = html.find('class="plan-goal"')
w = html.find('class="plan-workflow"')
sys.exit(0 if -1 not in (i, g, w) and i < g < w else 1)
PYEOF
then
  echo "  PASS"
else
  echo "  FAIL: prompt rows are not ordered implement -> goal -> workflow in the body"
  FAILURES=$((FAILURES + 1))
fi

echo "6. implementation-plan SKILL.md documents the goal prompt contract..."
if grep -q '{goal-prompt}' "$PLAN_SKILL" \
   && grep -q 'plan-goal' "$PLAN_SKILL" \
   && grep -q 'copyGoal(this)' "$PLAN_SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: SKILL.md does not document {goal-prompt}, the plan-goal element, and copyGoal wiring"
  FAILURES=$((FAILURES + 1))
fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All Goal prompt assertions passed."
else
  echo "$FAILURES assertion(s) failed."
  exit 1
fi
