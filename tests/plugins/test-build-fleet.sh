#!/usr/bin/env bash
set -euo pipefail

# Structural smoke test for the build-fleet skill
# (docs/plans/add-plan-backlog-fleet-skill.md). The objective check is #4:
# build-fleet must stay a dispatcher. Every regression this test exists to
# catch is the same one — someone inlining work that build or ship-autonomous
# already does, which is how the fleet drifts out of sync with the solo path.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/plan-agent/skills/build-fleet/SKILL.md"
README="$ROOT/kit/plugins/plan-agent/README.md"
CHANGELOG="$ROOT/kit/plugins/plan-agent/CHANGELOG.md"
FAILURES=0

echo "=== build-fleet Skill Smoke Test ==="

echo "1. SKILL.md exists, named, model-invocable..."
if [ -f "$SKILL" ] \
  && grep -q "^name: build-fleet$" "$SKILL" \
  && ! grep -q "disable-model-invocation" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: missing SKILL.md, name line, or carries disable-model-invocation"
  FAILURES=$((FAILURES + 1))
fi

echo "2. allowed-tools declares Agent, AskUserQuestion, ToolSearch, ExitPlanMode..."
ATLINE="$(grep -m1 '^allowed-tools:' "$SKILL" || true)"
MISSING=""
for t in Agent AskUserQuestion ToolSearch ExitPlanMode; do
  echo "$ATLINE" | grep -qw "$t" || MISSING="$MISSING $t"
done
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: allowed-tools missing:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "3. plan-mode guard present verbatim (skill dispatches state-mutating work)..."
if grep -qF '**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.' "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: guard line missing or reworded"
  FAILURES=$((FAILURES + 1))
fi

echo "4. OBJECTIVE: dispatches to build + ship-autonomous, never reimplements them..."
OBJ_FAIL=""
grep -q 'plan-agent:build' "$SKILL" || OBJ_FAIL="$OBJ_FAIL no-build-delegation"
grep -q 'git-agent:ship-autonomous' "$SKILL" || OBJ_FAIL="$OBJ_FAIL no-ship-delegation"
grep -q 'isolation: "worktree"' "$SKILL" || OBJ_FAIL="$OBJ_FAIL no-harness-isolation"
# Prohibitions, not uses: a "Never `git worktree add`" line is the point, an
# unqualified one means the skill grew its own worktree bookkeeping.
if grep 'git worktree add' "$SKILL" | grep -qv 'Never'; then
  OBJ_FAIL="$OBJ_FAIL hand-rolled-worktree"
fi
if grep -qi 'gh pr merge' "$SKILL"; then
  OBJ_FAIL="$OBJ_FAIL inlined-merge"
fi
if [ -z "$OBJ_FAIL" ]; then
  echo "  PASS"
else
  echo "  FAIL:$OBJ_FAIL"
  FAILURES=$((FAILURES + 1))
fi

echo "5. blast-radius guards: confirmation gate, --max default 3, stops at green..."
GUARD_FAIL=""
grep -qF 'Never dispatch without the Step 2 confirmation' "$SKILL" || GUARD_FAIL="$GUARD_FAIL no-confirm-gate"
grep -qF '`--max` defaults to 3' "$SKILL" || GUARD_FAIL="$GUARD_FAIL no-max-default"
grep -qF 'The fleet stops at green' "$SKILL" || GUARD_FAIL="$GUARD_FAIL no-merge-stop"
if [ -z "$GUARD_FAIL" ]; then
  echo "  PASS"
else
  echo "  FAIL:$GUARD_FAIL"
  FAILURES=$((FAILURES + 1))
fi

echo "6. documented in the plugin README table and CHANGELOG..."
if grep -q '| `build-fleet` | Skill |' "$README" \
  && grep -q '### `build-fleet` Skill' "$README" \
  && grep -q 'build-fleet' "$CHANGELOG"; then
  echo "  PASS"
else
  echo "  FAIL: missing README table row, README section, or CHANGELOG entry"
  FAILURES=$((FAILURES + 1))
fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "=== PASSED (6 of 6 checks) ==="
  exit 0
fi
echo "=== FAILED ($FAILURES check(s)) ==="
exit 1
