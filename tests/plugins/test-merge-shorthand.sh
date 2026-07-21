#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT/kit/plugins/git-agent/hooks/merge-shorthand.py"
HOOKS_JSON="$ROOT/kit/plugins/git-agent/hooks.json"
SKILL="$ROOT/kit/plugins/git-agent/skills/merge/SKILL.md"
FAILURES=0

echo "=== merge? shorthand smoke test ==="

# Runs the hook on a prompt. Captures stdout in OUT and the exit status in RC —
# a nonzero UserPromptSubmit exit blocks the user's prompt, so both matter.
fire() {
  local payload
  payload=$(python3 -c 'import json,sys; print(json.dumps({"prompt": sys.argv[1]}))' "$1")
  set +e
  OUT=$(printf '%s' "$payload" | python3 "$HOOK" 2>&1)
  RC=$?
  set -e
}

# Same, but for raw JSON payloads (malformed / null prompt).
fire_raw() {
  set +e
  OUT=$(printf '%s' "$1" | python3 "$HOOK" 2>&1)
  RC=$?
  set -e
}

expect_rc0() {
  if [ "$RC" -ne 0 ]; then
    echo "  FAIL: hook exited $RC on $(printf %q "$1") — a nonzero UserPromptSubmit exit blocks the prompt"
    FAILURES=$((FAILURES + 1))
    return 1
  fi
}

expect_fires() {
  fire "$1"
  expect_rc0 "$1" || return 0
  if [ -n "$OUT" ]; then echo "  PASS: fires on $(printf %q "$1")"
  else echo "  FAIL: silent on $(printf %q "$1")"; FAILURES=$((FAILURES + 1)); fi
}

expect_silent() {
  fire "$1"
  expect_rc0 "$1" || return 0
  if [ -z "$OUT" ]; then echo "  PASS: silent on $(printf %q "$1")"
  else echo "  FAIL: fired on $(printf %q "$1")"; FAILURES=$((FAILURES + 1)); fi
}

echo "1. Files exist..."
for f in "$HOOK" "$HOOKS_JSON" "$SKILL"; do
  if [ -f "$f" ]; then echo "  PASS: $f"
  else echo "  FAIL: missing $f"; exit 1; fi
done

echo "2. Hook fires on the shorthand..."
expect_fires "merge?"
expect_fires "  merge?  "
expect_fires "MERGE?"

echo "3. Hook stays silent on near-misses..."
expect_silent "merge"
expect_silent "please merge?"
expect_silent "merge? now"
expect_silent "can you merge this?"
expect_silent "I asked merge? earlier but never mind"

echo "4. Malformed payloads are a silent no-op, never a traceback..."
for payload in '{"prompt": null}' '{}' '{"prompt": 42}' 'not json at all' ''; do
  fire_raw "$payload"
  if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
    echo "  PASS: silent exit 0 on $(printf %q "$payload")"
  else
    echo "  FAIL: rc=$RC out=$(printf %q "$OUT") on $(printf %q "$payload")"
    FAILURES=$((FAILURES + 1))
  fi
done

echo "5. Routing context names the skill..."
fire "merge?"
if printf '%s' "$OUT" | grep -q "git-agent:merge"; then echo "  PASS"
else echo "  FAIL: routing context does not reference git-agent:merge"; FAILURES=$((FAILURES + 1)); fi

echo "6. hooks.json is valid and wires the script under UserPromptSubmit..."
if python3 -m json.tool "$HOOKS_JSON" >/dev/null; then echo "  PASS: valid JSON"
else echo "  FAIL: invalid JSON"; FAILURES=$((FAILURES + 1)); fi
# Parse rather than grep: two independent greps would pass even if the command
# were registered under the wrong event, and the shorthand would never fire.
if python3 - "$HOOKS_JSON" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))
cmds = [
    h.get("command", "")
    for entry in cfg.get("hooks", {}).get("UserPromptSubmit", [])
    for h in entry.get("hooks", [])
]
sys.exit(0 if any("${CLAUDE_PLUGIN_ROOT}/hooks/merge-shorthand.py" in c for c in cmds) else 1)
PY
then echo "  PASS: UserPromptSubmit wiring via CLAUDE_PLUGIN_ROOT"
else echo "  FAIL: merge-shorthand.py not wired under UserPromptSubmit"; FAILURES=$((FAILURES + 1)); fi

echo "7. SKILL.md pins the merge contract..."
check_skill() { # pattern label
  if grep -q -- "$1" "$SKILL"; then echo "  PASS: $2"
  else echo "  FAIL: $2"; FAILURES=$((FAILURES + 1)); fi
}
check_skill "MERGEABLE" "MERGEABLE readiness gate"
check_skill "--match-head-commit" "merge pinned to verified head commit"
check_skill "AskUserQuestion" "explicit approval before merging"
check_skill 'test("^lint")' "lint gate detection"
check_skill "Run the first match" "lint gate actually executes the script"
check_skill "--required" "blocking gate uses required checks only"
check_skill "--remove-source-branch" "GitLab branch deletion forbidden"
check_skill "Never auto-apply" "no auto --fix"
check_skill "Never pass \`--delete-branch\`" "branch deletion forbidden"
# Distinctive phrasing, not the substring "and ask" — that appears in several
# unrelated sentences and would pass even if this gate were deleted outright.
# Flattened copy: SKILL.md is hard-wrapped, so phrases that matter straddle
# line breaks and a plain grep would miss them.
SKILL_FLAT=$(tr '\n' ' ' < "$SKILL" | tr -s ' ')
if printf '%s' "$SKILL_FLAT" | grep -qF -- 'and ask what to do**. Do not merge.'; then
  echo "  PASS: readiness-gate failure asks and blocks the merge"
else
  echo "  FAIL: Step 2 no longer both asks and blocks on a failed readiness gate"
  FAILURES=$((FAILURES + 1))
fi

echo "8. Every branch-deletion flag is only ever mentioned as a prohibition..."
for flag in '--delete-branch' '--remove-source-branch'; do
  total=$(grep -c -- "$flag" "$SKILL" || true)
  banned=$(grep -- "$flag" "$SKILL" | grep -c -i 'never' || true)
  if [ "$total" -gt 0 ] && [ "$total" -eq "$banned" ]; then
    echo "  PASS: $flag — $total mention(s), all prohibitions"
  else
    echo "  FAIL: $flag — $total mention(s), only $banned are prohibitions"
    FAILURES=$((FAILURES + 1))
  fi
done

echo "9. allowed-tools covers the tools the steps actually use..."
FM=$(sed -n '/^allowed-tools:/p' "$SKILL")
for tool in "AskUserQuestion" "Bash(git \*)" "Bash(gh \*)" "Bash(glab \*)" \
            "Bash(jq \*)" "ToolSearch" "ExitPlanMode"; do
  if printf '%s' "$FM" | grep -qF -- "${tool//\\/}"; then
    echo "  PASS: declares ${tool//\\/}"
  else
    echo "  FAIL: allowed-tools missing ${tool//\\/}"; FAILURES=$((FAILURES + 1))
  fi
done

echo
if [ "$FAILURES" -eq 0 ]; then echo "All checks passed."; exit 0
else echo "$FAILURES check(s) failed."; exit 1; fi
