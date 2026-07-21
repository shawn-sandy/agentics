#!/usr/bin/env bash
# Smoke test for agent-ship-ci — the background CI watcher.
#
# It exists precisely because it is NOT ship-autonomous in a subagent. Every
# check below guards a promise that, if it silently eroded, would turn an
# unattended agent into one that merges or edits source without a human.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AGENT="$ROOT/kit/plugins/git-agent/agents/agent-ship-ci.md"
CMD="$ROOT/kit/plugins/git-agent/commands/ship-ci-bg.md"
fails=0

pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; fails=$((fails + 1)); }

echo "=== agent-ship-ci Smoke Test ==="

echo "1. agent and command files exist..."
if [ -f "$AGENT" ] && [ -f "$CMD" ]; then pass; else fail "missing agent or command file"; fi

echo "2. runs in background as a subagent..."
if grep -q "^background: true" "$AGENT"; then pass; else fail "background: true not set"; fi

echo "3. Write/Edit/NotebookEdit are denied (v3.5.0 invariant)..."
deny=$(grep -m1 "^disallowedTools:" "$AGENT")
if echo "$deny" | grep -q "Write" && echo "$deny" | grep -q "Edit" && echo "$deny" | grep -q "NotebookEdit"; then
  pass
else
  fail "disallowedTools must deny Write, Edit, and NotebookEdit"
fi

echo "4. tools does not falsely advertise Edit..."
if grep -m1 "^tools:" "$AGENT" | grep -qw "Edit"; then
  fail "'tools' lists Edit but disallowedTools denies it — misleading"
else
  pass
fi

echo "5. forbids routing around the deny list via Bash..."
if grep -q "sed -i" "$AGENT" && grep -q "git apply" "$AGENT"; then pass; else fail "must name the Bash escape hatches it forbids"; fi

echo "6. never merges..."
if grep -qi "Never merge" "$AGENT"; then pass; else fail "must state it never merges"; fi

echo "7. never marks a draft ready or deletes a branch..."
if grep -qi "ready" "$AGENT" && grep -qi "delete a branch" "$AGENT"; then pass; else fail "must forbid gh pr ready and branch deletion"; fi

echo "8. never replies to, resolves, or dismisses reviews..."
if grep -qi "Never reply to, resolve, or dismiss" "$AGENT"; then pass; else fail "must forbid acting on reviews"; fi

echo "9. requires an existing PR — does not create one..."
if grep -q "No pull request found" "$AGENT" && grep -qi "dispatch agent-ship first" "$AGENT"; then
  pass
else
  fail "must stop and point at agent-ship when no PR exists"
fi

echo "10. typecheck and test failures are report-only (they need source edits)..."
if grep -q '`typecheck`' "$AGENT" && grep -qi "Report only" "$AGENT"; then pass; else fail "typecheck must be report-only"; fi

echo "11. autofix is one attempt per check, not a retry loop..."
if grep -qi "One attempt per failing check" "$AGENT"; then pass; else fail "must cap autofix at one attempt"; fi

echo "12. lint autofix only runs a --fix script the project already defines..."
if grep -q "do not append the flag yourself" "$AGENT"; then pass; else fail "must refuse to synthesize a --fix invocation"; fi

echo "13. peer-deps reinstall verifies the diff is lockfile-only..."
if grep -q "git checkout -- ." "$AGENT"; then pass; else fail "must revert a reinstall that touches source"; fi

echo "14. --watch is bounded so it cannot exceed a command timeout..."
if grep -q "timeout 540 gh pr checks" "$AGENT"; then pass; else fail "gh pr checks --watch must be wrapped in a timeout"; fi

echo "15. uses gh pr checks 'state', never the nonexistent 'conclusion' field..."
if grep -q "has no \`conclusion\`" "$AGENT"; then pass; else fail "must warn that gh pr checks has no conclusion field"; fi

echo "16. command dispatches the right subagent in the background..."
if grep -q 'subagent_type: "git-agent:agent-ship-ci"' "$CMD" && grep -q "run_in_background: true" "$CMD"; then
  pass
else
  fail "command must dispatch agent-ship-ci with run_in_background: true"
fi

echo
if [ "$fails" -eq 0 ]; then
  echo "All checks PASSED."
  exit 0
fi
echo "$fails check(s) FAILED."
exit 1
