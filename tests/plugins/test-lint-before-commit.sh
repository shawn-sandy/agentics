#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT/kit/plugins/git-agent/hooks/lint-before-commit.py"
HOOKS_JSON="$ROOT/kit/plugins/git-agent/hooks.json"
FAILURES=0

echo "=== lint-before-commit hook smoke test ==="

# Scratch repos live here; removed on exit so a failed run leaves nothing behind.
TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT

# Builds a throwaway git repo. $1 = name, $2 = package.json contents (or empty
# for none). Creates node_modules/ so the deps-installed guard sees a ready repo
# — the fresh-clone case is exercised explicitly in section 9.
make_repo() {
  local dir="$TMPROOT/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q
  if [ -n "${2:-}" ]; then
    printf '%s' "$2" > "$dir/package.json"
    mkdir -p "$dir/node_modules"
  fi
  printf '%s' "$dir"
}

# Fires the hook with a Bash PreToolUse payload. $1 = command, $2 = cwd.
fire() {
  local payload
  payload=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": sys.argv[1]}, "cwd": sys.argv[2]}))' "$1" "$2")
  set +e
  OUT=$(printf '%s' "$payload" | python3 "$HOOK" 2>&1)
  RC=$?
  set -e
}

check_rc() { # expected label
  if [ "$RC" -eq "$1" ]; then echo "  PASS: $2"
  else echo "  FAIL: $2 (rc=$RC, expected $1) out=$(printf %q "$OUT")"; FAILURES=$((FAILURES + 1)); fi
}

PASSING='{"scripts":{"lint":"true"}}'
FAILING='{"scripts":{"lint":"echo LINT_BROKE >&2; exit 1"}}'

echo "1. Files exist and hook is executable..."
for f in "$HOOK" "$HOOKS_JSON"; do
  if [ -f "$f" ]; then echo "  PASS: $f"
  else echo "  FAIL: missing $f"; exit 1; fi
done

echo "2. Failing lint blocks the commit with exit 2..."
REPO=$(make_repo failing "$FAILING")
fire "git commit -m 'x'" "$REPO"
check_rc 2 "blocks on failing lint"
if printf '%s' "$OUT" | grep -q "LINT_BROKE"; then echo "  PASS: lint output is fed back"
else echo "  FAIL: lint output missing from block message"; FAILURES=$((FAILURES + 1)); fi
if printf '%s' "$OUT" | grep -q "no-lint-gate"; then echo "  PASS: block message names the escape hatch"
else echo "  FAIL: block message does not mention the opt-out"; FAILURES=$((FAILURES + 1)); fi

echo "3. Passing lint lets the commit through..."
REPO=$(make_repo passing "$PASSING")
fire "git commit -m 'x'" "$REPO"
check_rc 0 "allows on passing lint"

echo "4. The opt-out file disables the gate..."
REPO=$(make_repo optout "$FAILING")
mkdir -p "$REPO/.claude" && touch "$REPO/.claude/no-lint-gate"
fire "git commit -m 'x'" "$REPO"
check_rc 0 "failing lint is skipped when .claude/no-lint-gate exists"

echo "5. Repos with no package.json / no lint script are a no-op..."
REPO=$(make_repo nopkg "")
fire "git commit -m 'x'" "$REPO"
check_rc 0 "no package.json"
REPO=$(make_repo noscript '{"scripts":{"build":"exit 1"}}')
fire "git commit -m 'x'" "$REPO"
check_rc 0 "package.json without a lint script"

echo "6. Non-commit Bash calls never trigger lint..."
REPO=$(make_repo noncommit "$FAILING")
# `git log --grep commit` is the trap: "commit" appears as a flag value, not a
# subcommand. Matching it would run lint on every history search.
for cmd in "git status" "git log --oneline" "ls -la" "echo done" \
           "git checkout -b foo" "git log --grep commit" "git commit-tree x"; do
  fire "$cmd" "$REPO"
  check_rc 0 "ignores $(printf %q "$cmd")"
done

echo "7. Commit variants are still caught..."
REPO=$(make_repo variants "$FAILING")
for cmd in "git commit --amend --no-edit" "git -C . commit -m 'x'" "git add -A && git commit -m 'x'"; do
  fire "$cmd" "$REPO"
  check_rc 2 "catches $(printf %q "$cmd")"
done

echo "8. Non-Bash tools and malformed payloads are a silent no-op..."
for payload in \
  '{"tool_name":"Write","tool_input":{"command":"git commit -m x"}}' \
  '{"tool_name":"Bash","tool_input":{"command":null}}' \
  '{"tool_name":"Bash"}' '{}' 'not json at all' ''; do
  set +e
  OUT=$(printf '%s' "$payload" | python3 "$HOOK" 2>&1); RC=$?
  set -e
  if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
    echo "  PASS: silent exit 0 on $(printf %q "$payload")"
  else
    echo "  FAIL: rc=$RC out=$(printf %q "$OUT") on $(printf %q "$payload")"
    FAILURES=$((FAILURES + 1))
  fi
done

echo "9. A check that cannot run never blocks the commit..."
# Fresh clone: lint is declared but dependencies were never installed. Blocking
# here would report a code problem that does not exist.
REPO=$(make_repo freshclone "$FAILING")
rmdir "$REPO/node_modules"
fire "git commit -m 'x'" "$REPO"
check_rc 0 "no node_modules — gate skipped, not failed"

# Deps installed, but the lint binary itself is absent. npm/pnpm/yarn pass the
# shell's 127 straight through, which is how we tell "could not run" from "found
# problems" — a real lint failure exits 1.
REPO=$(make_repo missingbin '{"scripts":{"lint":"definitely-not-installed-linter ."}}')
fire "git commit -m 'x'" "$REPO"
check_rc 0 "linter binary missing (exit 127) — gate skipped, not failed"

# Yarn PnP resolves bins without ever creating node_modules, so the deps guard
# must not read that as an unbuilt repo and silently drop the gate.
REPO=$(make_repo yarnpnp "$FAILING")
rmdir "$REPO/node_modules" && touch "$REPO/.pnp.cjs"
fire "git commit -m 'x'" "$REPO"
check_rc 2 "Yarn PnP (.pnp.cjs, no node_modules) — gate still active"

echo "10. hooks.json wires the script under PreToolUse without losing the merge hook..."
if python3 -m json.tool "$HOOKS_JSON" >/dev/null; then echo "  PASS: valid JSON"
else echo "  FAIL: invalid JSON"; FAILURES=$((FAILURES + 1)); fi
# Parse rather than grep: a grep would pass even if the command were registered
# under the wrong event, and the gate would never fire.
if python3 - "$HOOKS_JSON" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))["hooks"]
pre = [h.get("command", "") for e in cfg.get("PreToolUse", []) for h in e.get("hooks", [])]
ups = [h.get("command", "") for e in cfg.get("UserPromptSubmit", []) for h in e.get("hooks", [])]
matchers = [e.get("matcher") for e in cfg.get("PreToolUse", [])]
sys.exit(0 if (
    any("${CLAUDE_PLUGIN_ROOT}/hooks/lint-before-commit.py" in c for c in pre)
    and "Bash" in matchers
    and any("${CLAUDE_PLUGIN_ROOT}/hooks/merge-shorthand.py" in c for c in ups)
) else 1)
PY
then echo "  PASS: PreToolUse/Bash wiring intact, merge-shorthand preserved"
else echo "  FAIL: hooks.json wiring is wrong"; FAILURES=$((FAILURES + 1)); fi

echo
if [ "$FAILURES" -eq 0 ]; then echo "All checks passed."; exit 0
else echo "$FAILURES check(s) failed."; exit 1; fi
