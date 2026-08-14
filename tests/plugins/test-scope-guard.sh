#!/usr/bin/env bash
set -euo pipefail

# Every clause in scope-guard.py is either a block that could over-fire or a
# pass that could under-fire, and an over-firing guard is the failure mode that
# gets the whole hook deleted. Both directions are asserted for every rule.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT/kit/plugins/git-agent/hooks/scope-guard.py"
HOOKS_JSON="$ROOT/kit/plugins/git-agent/hooks.json"
FAILURES=0

echo "=== scope-guard hook smoke test ==="

TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT

# Throwaway git repo. $1 = name, $2 = package.json contents (or empty for none).
make_repo() {
  local dir="$TMPROOT/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q
  if [ -n "${2:-}" ]; then
    printf '%s' "$2" > "$dir/package.json"
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

has_out() { # needle label
  if printf '%s' "$OUT" | grep -qF "$1"; then echo "  PASS: $2"
  else echo "  FAIL: $2 (out=$(printf %q "$OUT"))"; FAILURES=$((FAILURES + 1)); fi
}

blocks() { # command cwd label
  fire "$1" "$2"
  check_rc 2 "blocks: $3"
}

allows() { # command cwd label
  fire "$1" "$2"
  check_rc 0 "allows: $3"
}

WIDE='{"scripts":{"fix:all":"prettier --write ."}}'
SCOPED='{"scripts":{"fix:all":"prettier --write src/"}}'

echo "1. Files exist and the hook is wired into hooks.json..."
for f in "$HOOK" "$HOOKS_JSON"; do
  if [ -f "$f" ]; then echo "  PASS: $f"
  else echo "  FAIL: missing $f"; exit 1; fi
done
# Parse rather than grep: a grep would pass even if the command were registered
# under the wrong event, and the guard would never fire. The lint gate and its
# 480s budget must survive the addition untouched — a shared timeout would let
# the harness kill the lint gate mid-run, which lets the commit through.
if python3 - "$HOOKS_JSON" <<'PY'
import json, sys
cfg = json.load(open(sys.argv[1]))["hooks"]
entries = [e for e in cfg.get("PreToolUse", []) if e.get("matcher") == "Bash"]
hooks = [h for e in entries for h in e.get("hooks", [])]
guard = [h for h in hooks if "${CLAUDE_PLUGIN_ROOT}/hooks/scope-guard.py" in h.get("command", "")]
lint = [h for h in hooks if "${CLAUDE_PLUGIN_ROOT}/hooks/lint-before-commit.py" in h.get("command", "")]
sys.exit(0 if (
    len(guard) == 1 and len(lint) == 1
    and guard[0].get("timeout", 0) <= 30      # a guard, not a lint baseline run
    and lint[0].get("timeout") == 480         # unchanged by this addition
) else 1)
PY
then echo "  PASS: registered under PreToolUse/Bash beside an untouched lint gate"
else echo "  FAIL: hooks.json wiring is wrong"; FAILURES=$((FAILURES + 1)); fi

echo "2. Objective: repo-wide formatter and bare stash pop are blocked, scoped forms are not..."
REPO=$(make_repo objective "$WIDE")
blocks "npm run fix:all" "$REPO" "npm run fix:all resolving to prettier --write ."
has_out "prettier --write ." "the block names the command the script actually runs"
has_out "npx prettier --write <path>" "the block names the scoped alternative"
allows "prettier --write src/app.ts" "$REPO" "prettier --write src/app.ts"
blocks "git stash pop" "$REPO" "git stash pop with no reference"
has_out "git stash list" "the stash block names the listing step"
allows "git stash pop stash@{1}" "$REPO" "git stash pop stash@{1}"

echo "3. Fast bail: nothing that is not an invocation reaches the filesystem..."
REPO=$(make_repo bail "$WIDE")
allows "ls -la" "$REPO" "ls -la"
allows "git status" "$REPO" "git status"
allows 'git commit -m "fixes npm run fix:all"' "$REPO" "a commit message naming a blocked script"
allows 'git commit -m "stop using prettier --write ."' "$REPO" "a commit message naming a blocked command"
allows 'grep -r "prettier --write ." docs/' "$REPO" "grep for a blocked pattern"
allows 'echo "npm run fix:all"' "$REPO" "echo of a blocked command"
allows 'echo "git stash pop"' "$REPO" "echo of a blocked stash pop"
# A non-Bash tool call must not be inspected at all.
set +e
OUT=$(printf '%s' '{"tool_name":"Edit","tool_input":{"file_path":"/x","new_string":"prettier --write ."}}' \
  | python3 "$HOOK" 2>&1)
RC=$?
set -e
check_rc 0 "a non-Bash payload"

# Asserted behaviourally rather than by reading source: this hook runs on every
# Bash call in every repo that installs git-agent, so a filesystem probe ahead
# of the bail is a cost paid by every unrelated command.
if python3 - "$ROOT" "$TMPROOT" <<'PY'
import builtins, importlib.util, io, json, os, sys
spec = importlib.util.spec_from_file_location(
    "guard", os.path.join(sys.argv[1], "kit/plugins/git-agent/hooks/scope-guard.py"))
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)

touched = []
mod.os.path.exists = lambda p: touched.append(("exists", p))
mod.subprocess.run = lambda *a, **k: touched.append(("run", a))
real_open = builtins.open
builtins.open = lambda *a, **k: (touched.append(("open", a)), real_open(*a, **k))[1]
try:
    cases = [
        ("Bash", "ls -la"),
        ("Bash", "git status"),
        ("Bash", 'git commit -m "fixes npm run fix:all"'),
        ("Bash", 'git commit -m "stop using prettier --write ."'),
        ("Bash", 'grep -r "prettier --write ." docs/'),
        ("Bash", 'echo "npm run fix:all"'),
        ("Edit", None),
    ]
    for tool, cmd in cases:
        payload = {"tool_name": tool, "cwd": sys.argv[2]}
        if cmd is not None:
            payload["tool_input"] = {"command": cmd}
        sys.stdin = io.StringIO(json.dumps(payload))
        if mod.main() != 0:
            print("non-zero exit for", tool, cmd); sys.exit(1)
finally:
    builtins.open = real_open
if touched:
    print("filesystem touched before the bail:", touched[:3]); sys.exit(1)
sys.exit(0)
PY
then echo "  PASS: no manifest, opt-out, or repo lookup before the bail"
else echo "  FAIL: the guard probes the filesystem for non-invocations"; FAILURES=$((FAILURES + 1)); fi

echo "4. Script resolution covers all eight runner spellings..."
REPO=$(make_repo resolve_wide "$WIDE")
for runner in npm pnpm yarn bun; do
  blocks "$runner run fix:all" "$REPO" "$runner run fix:all"
  blocks "$runner fix:all" "$REPO" "$runner fix:all (bare form)"
done
# The same eight forms with the script absent must all pass: an unresolved
# script resolves to the typed text, which carries nothing to match.
REPO=$(make_repo resolve_absent '{"scripts":{"build":"tsc"}}')
for runner in npm pnpm yarn bun; do
  allows "$runner run fix:all" "$REPO" "$runner run fix:all with no such script"
  allows "$runner fix:all" "$REPO" "$runner fix:all with no such script"
done

echo "5. The manifest walk: nearest wins, malformed never blocks, the git root is the ceiling..."
REPO=$(make_repo nearest "$SCOPED")
mkdir -p "$REPO/sub"
printf '%s' "$WIDE" > "$REPO/sub/package.json"
blocks "npm run fix:all" "$REPO/sub" "the nested manifest's repo-wide script"
allows "npm run fix:all" "$REPO" "the root manifest's scoped script"
# Composite scripts resolve through one more hop.
REPO=$(make_repo chained '{"scripts":{"fix:all":"npm run format","format":"prettier --write ."}}')
blocks "npm run fix:all" "$REPO" "a script that delegates to another script"
REPO=$(make_repo malformed '{"scripts":{"fix:all": ')
allows "npm run fix:all" "$REPO" "a malformed manifest"
REPO=$(make_repo selfref '{"scripts":{"fix:all":"npm run fix:all"}}')
allows "npm run fix:all" "$REPO" "a self-referential script (depth cap holds)"
# The walk stops at the git root: a parent directory outside the repo must
# never supply the script.
OUTER="$TMPROOT/outer"
mkdir -p "$OUTER"
printf '%s' "$WIDE" > "$OUTER/package.json"
mkdir -p "$OUTER/inner"
git -C "$OUTER/inner" init -q
allows "npm run fix:all" "$OUTER/inner" "a manifest above the git root"

echo "6. Formatter rule boundaries..."
REPO=$(make_repo formatter "")
blocks "prettier --write ." "$REPO" "prettier --write ."
blocks "npx prettier --write ./" "$REPO" "npx prettier --write ./"
blocks "eslint --fix" "$REPO" "eslint --fix with no operand"
blocks "biome format --write ." "$REPO" "biome format --write ."
allows "prettier --write src/app.ts" "$REPO" "an explicit file"
allows "npx prettier --write kit/" "$REPO" "an explicit directory"
allows "prettier --check ." "$REPO" "a check-only invocation"
allows "prettier --write .prettierrc" "$REPO" "a dotfile is not the dot operand"
allows "prettier --write ./src" "$REPO" "a scoped path beginning with ./"
allows "eslint --fix-type problem src/" "$REPO" "--fix-type is not --fix"
allows "eslint --fix --ext .js src/" "$REPO" "an extension argument is not a path operand"

echo "7. Stash rule boundaries..."
REPO=$(make_repo stash "")
blocks "git stash apply" "$REPO" "git stash apply with no reference"
blocks "git -C $REPO stash pop" "$REPO" "a bare pop behind a global -C option"
blocks "git stash pop --index" "$REPO" "a bare pop with only flags"
allows "git stash apply stash@{2}" "$REPO" "an explicit stash reference"
allows "git stash pop 2" "$REPO" "an explicit stash index"
allows "git stash list" "$REPO" "git stash list"
allows "git stash push -m wip" "$REPO" "git stash push"

echo "8. Out-of-scope commands are never blocked..."
REPO=$(make_repo scope "$WIDE")
allows "rm -rf build" "$REPO" "rm"
allows "curl https://example.com" "$REPO" "curl"
allows "git reset --hard origin/main" "$REPO" "git reset --hard"
allows "git checkout -- ." "$REPO" "git checkout -- ."
allows "npm test" "$REPO" "npm test"
allows "npm run build" "$REPO" "npm run build"

echo "9. The opt-out disables every rule..."
REPO=$(make_repo optout "$WIDE")
blocks "npm run fix:all" "$REPO" "the formatter rule before the opt-out exists"
blocks "git stash pop" "$REPO" "the stash rule before the opt-out exists"
mkdir -p "$REPO/.claude"
touch "$REPO/.claude/no-scope-guard"
allows "npm run fix:all" "$REPO" "the formatter rule with .claude/no-scope-guard present"
allows "git stash pop" "$REPO" "the stash rule with .claude/no-scope-guard present"
if [ -z "$OUT" ]; then echo "  PASS: the opt-out exits silently"
else echo "  FAIL: the opt-out still wrote output ($(printf %q "$OUT"))"; FAILURES=$((FAILURES + 1)); fi

echo "10. Every block names the rule, the command, and its safe alternative..."
REPO=$(make_repo message "$WIDE")
# The PreToolUse contract returns *stderr* to the model as actionable feedback;
# a message on stdout would block with nothing to act on.
STDOUT=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": "npm run fix:all"}, "cwd": sys.argv[1]}))' "$REPO" \
  | python3 "$HOOK" 2>/dev/null || true)
if [ -z "$STDOUT" ]; then echo "  PASS: the block writes nothing to stdout"
else echo "  FAIL: the block wrote to stdout ($(printf %q "$STDOUT"))"; FAILURES=$((FAILURES + 1)); fi
blocks "npm run fix:all" "$REPO" "the formatter rule"
has_out "npm run fix:all" "the formatter block quotes the typed command"
has_out "Rule:" "the formatter block names the rule"
has_out "no-scope-guard" "the formatter block names the escape hatch"
blocks "git stash pop" "$REPO" "the stash rule"
has_out "git stash pop" "the stash block quotes the typed command"
has_out "Rule:" "the stash block names the rule"
has_out "no-scope-guard" "the stash block names the escape hatch"

echo
if [ "$FAILURES" -eq 0 ]; then echo "All checks passed."; exit 0
else echo "$FAILURES check(s) failed."; exit 1; fi
