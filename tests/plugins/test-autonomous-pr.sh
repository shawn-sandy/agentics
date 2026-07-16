#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CMD="$ROOT/kit/plugins/git-agent/commands/autonomous-pr.md"
FAILURES=0

echo "=== Autonomous PR Command Smoke Test ==="

echo "1. Command file exists..."
if [ -f "$CMD" ]; then
  echo "  PASS"
else
  echo "  FAIL: $CMD not found"
  exit 1
fi

echo "2. Frontmatter carries a description..."
if head -5 "$CMD" | grep -q '^description:'; then
  echo "  PASS"
else
  echo "  FAIL: no 'description:' in frontmatter"
  FAILURES=$((FAILURES + 1))
fi

echo "3. Plan phase invokes implementation-plan..."
if grep -q 'plan-agent:implementation-plan' "$CMD"; then
  echo "  PASS"
else
  echo "  FAIL: does not invoke plan-agent:implementation-plan"
  FAILURES=$((FAILURES + 1))
fi

echo "4. Implement phase invokes tdd-loop..."
if grep -q 'code-testing-agent:tdd-loop' "$CMD"; then
  echo "  PASS"
else
  echo "  FAIL: does not invoke code-testing-agent:tdd-loop"
  FAILURES=$((FAILURES + 1))
fi

echo "5. Ship phase delegates to ship-autonomous..."
if grep -q 'git-agent:ship-autonomous' "$CMD"; then
  echo "  PASS"
else
  echo "  FAIL: does not invoke git-agent:ship-autonomous"
  FAILURES=$((FAILURES + 1))
fi

# This command is the front half only: plan and implement. ship-autonomous
# Step 2.5 already runs the tests and previews the change across both themes,
# blocking on console and server errors. A second verification phase here
# would be a strictly worse copy that drifts from the one that matters.
echo "6. Does not duplicate ship-autonomous's browser verification..."
if grep -q 'preview_start' "$CMD"; then
  echo "  FAIL: found 'preview_start' — verification belongs to ship-autonomous Step 2.5, not this command"
  FAILURES=$((FAILURES + 1))
else
  echo "  PASS"
fi

# The merge decision is the user's, made at ship-autonomous Step 8, which
# re-confirms green and gates on AskUserQuestion. This command hands off to
# that gate; it must never reach around it and merge on its own.
echo "7. Contains no merge invocation of its own..."
if grep -q 'gh pr merge' "$CMD"; then
  echo "  FAIL: found 'gh pr merge' — the merge gate is ship-autonomous Step 8, not this command"
  FAILURES=$((FAILURES + 1))
else
  echo "  PASS"
fi

echo "8. Contains no branch-deletion flag..."
if grep -q -- '--delete-branch' "$CMD"; then
  echo "  FAIL: found '--delete-branch' — branch deletion needs its own explicit approval"
  FAILURES=$((FAILURES + 1))
else
  echo "  PASS"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks PASSED."
  exit 0
else
  echo "$FAILURES check(s) FAILED."
  exit 1
fi
