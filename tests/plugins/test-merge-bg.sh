#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AGENT="$ROOT/kit/plugins/git-agent/agents/agent-merge.md"
CMD="$ROOT/kit/plugins/git-agent/commands/merge-bg.md"
FAILURES=0

echo "=== merge-bg Smoke Test ==="

check() { # check <label> <condition-cmd...>
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  PASS: $label"
  else
    echo "  FAIL: $label"
    FAILURES=$((FAILURES + 1))
  fi
}

for f in "$AGENT" "$CMD"; do
  if [ ! -f "$f" ]; then
    echo "  FAIL: $f not found"
    exit 1
  fi
done

check "agent runs in background" grep -q "^background: true" "$AGENT"
check "agent denies Write" grep -q "^disallowedTools:.*Write" "$AGENT"
check "agent denies Edit" grep -q "^disallowedTools:.*\bEdit" "$AGENT"
check "agent denies NotebookEdit" grep -q "^disallowedTools:.*NotebookEdit" "$AGENT"
check "agent refuses --delete-branch" grep -q -- "--delete-branch" "$AGENT"
check "agent merges with a head-pinned squash" \
  grep -qF 'gh pr merge <pr-url> --squash --match-head-commit <headRefOid>' "$AGENT"
check "agent prefers the dispatched PR over the current branch" \
  grep -q "dispatch prompt names" "$AGENT"
check "agent replaces the skill's approval prompt" grep -q "AskUserQuestion.*does not apply" "$AGENT"
check "agent stops rather than guessing when not green" grep -qF "**report and STOP**" "$AGENT"
check "command dispatches agent-merge" grep -q "git-agent:agent-merge" "$CMD"
check "command dispatches in background" grep -q "run_in_background: true" "$CMD"
check "command restricts tools to Agent" grep -q "^allowed-tools: Agent$" "$CMD"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks PASSED."
else
  echo "$FAILURES check(s) FAILED."
  exit 1
fi
