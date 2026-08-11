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

REAL_GIT=$(command -v git)

# Commits everything in $1 so the repo has a HEAD to use as a lint baseline.
# Repos built by make_repo alone are deliberately left unborn — with no HEAD
# there is nothing to compare against, which is what sections 2-14 exercise.
commit_all() {
  git -C "$1" add -A
  git -C "$1" -c user.email=t@t -c user.name=t commit -q -m "base"
}

# A lint script that reports one record per BAD marker found, so the baseline
# comparison sees output that actually varies with the tree it runs against.
# `grep -r` does not descend symlinks, so the linked node_modules is skipped.
write_grep_linter() {
  cat > "$1/lint.sh" <<'SH'
#!/bin/sh
found=$(grep -rn BADCODE . --include='*.js' 2>/dev/null | sort)
[ -n "$found" ] && { echo "$found" >&2; exit 1; }
exit 0
SH
  printf '%s' '{"scripts":{"lint":"sh lint.sh"}}' > "$1/package.json"
  mkdir -p "$1/node_modules"
}

# Fake toolchain binaries, so ecosystem detection is exercised without needing
# ruff/go/cargo actually installed on the machine running the suite.
FAKEBIN="$TMPROOT/fakebin"
mkdir -p "$FAKEBIN"
for tool in ruff flake8 go cargo cargo-clippy; do
  printf '#!/bin/sh\necho "%s_BROKE" >&2\nexit 1\n' "$(printf '%s' "$tool" | tr 'a-z-' 'A-Z_')" \
    > "$FAKEBIN/$tool"
  chmod +x "$FAKEBIN/$tool"
done

# A git that refuses `archive`, so the baseline worktrees cannot be materialized.
NOARCHIVE="$TMPROOT/noarchive"
mkdir -p "$NOARCHIVE"
cat > "$NOARCHIVE/git" <<SH
#!/bin/sh
for a in "\$@"; do [ "\$a" = "archive" ] && exit 1; done
exec "$REAL_GIT" "\$@"
SH
chmod +x "$NOARCHIVE/git"

# fire() with PATH prefixed by \$1. Used to inject fake toolchains and the
# archive-refusing git without leaking either into the rest of the suite.
fire_with_path() {
  local extra="$1"; shift
  local saved="$PATH"
  PATH="$extra:$PATH"
  fire "$@"
  PATH="$saved"
}

# The absent-toolchain assertions are only meaningful when the toolchain really
# is absent. Prefixing the caller's PATH leaves a machine with Go, Cargo, or
# Ruff installed running the *real* tool, so those cases would silently stop
# testing anything (and can fail outright). MINPATH holds only what the hook
# itself needs — git to resolve the repo, python3 because fire() runs the hook
# through it — so every linter is genuinely off the PATH.
MINPATH="$TMPROOT/minpath"
mkdir -p "$MINPATH"
for need in git python3 sh; do
  src=$(command -v "$need" || true)
  [ -n "$src" ] && ln -sf "$src" "$MINPATH/$need"
done
fire_without_toolchain() {
  local saved="$PATH"
  PATH="$MINPATH"
  fire "$@"
  PATH="$saved"
}

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

echo "10. The typecheck gate blocks independently of lint..."
# lint passes, typecheck fails — without this the second gate could regress
# unnoticed, since every other fixture only exercises scripts.lint.
REPO=$(make_repo typecheck '{"scripts":{"lint":"true","typecheck":"echo TYPES_BROKE >&2; exit 1"}}')
fire "git commit -m 'x'" "$REPO"
check_rc 2 "blocks on failing typecheck"
if printf '%s' "$OUT" | grep -q "TYPES_BROKE"; then echo "  PASS: typecheck output is fed back"
else echo "  FAIL: typecheck output missing from block message"; FAILURES=$((FAILURES + 1)); fi
if printf '%s' "$OUT" | grep -q '`typecheck` failed'; then echo "  PASS: block message names the failing script"
else echo "  FAIL: block message does not name typecheck"; FAILURES=$((FAILURES + 1)); fi

echo "11. \`git -C <path>\` lints the repo being committed, not the cwd..."
# The commit targets OTHER; linting cwd would check the wrong package — letting
# a real failure through and blocking on an unrelated one.
OUTER=$(make_repo outer_c "$PASSING")
OTHER=$(make_repo other_c "$FAILING")
fire "git -C '$OTHER' commit -m 'x'" "$OUTER"
check_rc 2 "absolute -C path picks up the target repo's failing lint"

# Reversed: failing lint in cwd, passing in the -C target. A hook still reading
# cwd would block here, which is the same bug wearing the opposite mask.
OUTER=$(make_repo outer_c2 "$FAILING")
OTHER=$(make_repo other_c2 "$PASSING")
fire "git -C '$OTHER' commit -m 'x'" "$OUTER"
check_rc 0 "cwd's failing lint does not block a commit aimed elsewhere"

# Relative -C resolves against the payload cwd.
PARENT=$(make_repo parent_c "$PASSING")
mkdir -p "$PARENT/sub" && git -C "$PARENT/sub" init -q
printf '%s' "$FAILING" > "$PARENT/sub/package.json" && mkdir -p "$PARENT/sub/node_modules"
fire "git -C sub commit -m 'x'" "$PARENT"
check_rc 2 "relative -C path resolves against cwd"

echo "12. Bun repos select the bun runner for both lockfile formats..."
# bun.lock is the default since Bun 1.2; bun.lockb is legacy. Missing either
# silently falls back to `npm run`. `bun` may not be installed on this machine,
# so assert on runner selection directly rather than on a real run.
for lock in bun.lock bun.lockb; do
  if python3 - "$ROOT" "$lock" <<'PY'
import importlib.util, os, sys, tempfile
spec = importlib.util.spec_from_file_location(
    "hook", os.path.join(sys.argv[1], "kit/plugins/git-agent/hooks/lint-before-commit.py"))
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
with tempfile.TemporaryDirectory() as d:
    open(os.path.join(d, sys.argv[2]), "w").close()
    sys.exit(0 if mod.runner(d) == ["bun", "run"] else 1)
PY
  then echo "  PASS: $lock selects bun"
  else echo "  FAIL: $lock falls back to npm"; FAILURES=$((FAILURES + 1)); fi
done

echo "13. Per-check timeouts fit inside the declared hook timeout..."
# Worst case is every check failing and paying for its baseline, plus one
# materialization per side. If that exceeds the hooks.json timeout the host kills
# the gate mid-run and the commit slips through.
if python3 - "$ROOT" <<'PY'
import importlib.util, json, os, sys
root = sys.argv[1]
spec = importlib.util.spec_from_file_location(
    "hook", os.path.join(root, "kit/plugins/git-agent/hooks/lint-before-commit.py"))
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)
cfg = json.load(open(os.path.join(root, "kit/plugins/git-agent/hooks.json")))["hooks"]
declared = [h.get("timeout", 0) for e in cfg["PreToolUse"] for h in e["hooks"]
            if "lint-before-commit.py" in h.get("command", "")]
# TOTAL_BUDGET is the deadline the hook actually enforces, so assert that
# rather than re-deriving the sum here — a config naming many commands is
# bounded by it too, which a per-check sum would not catch.
budget = (len(mod.SCRIPTS) * (mod.PER_CHECK_TIMEOUT + mod.BASELINE_TIMEOUT)
          + 2 * mod.MATERIALIZE_TIMEOUT)
sys.exit(0 if declared and budget <= mod.TOTAL_BUDGET <= declared[0] else 1)
PY
then echo "  PASS: combined check budget fits the hook timeout"
else echo "  FAIL: checks can outlast the hook timeout"; FAILURES=$((FAILURES + 1)); fi

echo "14. hooks.json wires the script under PreToolUse without losing the merge hook..."
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

has_out() { # needle label
  if printf '%s' "$OUT" | grep -q "$1"; then echo "  PASS: $2"
  else echo "  FAIL: $2 (out=$(printf %q "$OUT"))"; FAILURES=$((FAILURES + 1)); fi
}
lacks_out() { # needle label
  if printf '%s' "$OUT" | grep -q "$1"; then
    echo "  FAIL: $2 (out=$(printf %q "$OUT"))"; FAILURES=$((FAILURES + 1))
  else echo "  PASS: $2"; fi
}

echo "15. The nearest package is linted, not the repository root..."
# A commit issued from sub/pkg must run that package's script. Reading only the
# root manifest checks the wrong code and lets the real failure through.
ROOTMARK='{"scripts":{"lint":"echo ROOT_LINT >&2; exit 1"}}'
NESTMARK='{"scripts":{"lint":"echo NESTED_LINT >&2; exit 1"}}'
REPO=$(make_repo mono "$ROOTMARK")
mkdir -p "$REPO/sub/pkg" && printf '%s' "$NESTMARK" > "$REPO/sub/pkg/package.json"
fire "git commit -m 'x'" "$REPO/sub/pkg"
check_rc 2 "commit from sub/pkg blocks"
has_out "NESTED_LINT" "the nested package's script ran"
lacks_out "ROOT_LINT" "the root script did not run"

fire "git commit -m 'x'" "$REPO"
check_rc 2 "commit from the root blocks"
has_out "ROOT_LINT" "the root script ran for a root commit"

# node_modules is routinely hoisted to the workspace root. A nested package with
# no local copy is still installed, and must not fall through to the root script.
REPO=$(make_repo hoisted "$ROOTMARK")
mkdir -p "$REPO/sub/pkg" && printf '%s' "$NESTMARK" > "$REPO/sub/pkg/package.json"
fire "git commit -m 'x'" "$REPO/sub/pkg"
check_rc 2 "hoisted node_modules still resolves the nested package"
has_out "NESTED_LINT" "hoisted deps do not fall through to the root"

# A nested directory with no matching script falls through to the root's.
REPO=$(make_repo fallthrough "$ROOTMARK")
mkdir -p "$REPO/sub/pkg"
printf '%s' '{"scripts":{"build":"true"}}' > "$REPO/sub/pkg/package.json"
fire "git commit -m 'x'" "$REPO/sub/pkg"
check_rc 2 "a nested package without a lint script falls through"
has_out "ROOT_LINT" "fallthrough reaches the root script"

# The git root is the walk's ceiling — escaping it would lint an unrelated
# parent project whose manifest has nothing to do with this repo.
OUTSIDE=$(make_repo outside "$ROOTMARK")
mkdir -p "$OUTSIDE/inner" && git -C "$OUTSIDE/inner" init -q
fire "git commit -m 'x'" "$OUTSIDE/inner"
check_rc 0 "the walk stops at the git root"

echo "16. Non-Node ecosystems are gated too..."
for eco in "pyproject.toml:ruff:RUFF_BROKE" "go.mod:go:GO_BROKE" "Cargo.toml:cargo:CARGO_BROKE"; do
  manifest="${eco%%:*}"; rest="${eco#*:}"; tool="${rest%%:*}"; marker="${rest##*:}"
  REPO=$(make_repo "eco_${tool}" "")
  touch "$REPO/$manifest"
  fire_with_path "$FAKEBIN" "git commit -m 'x'" "$REPO"
  check_rc 2 "$manifest with a failing linter blocks"
  has_out "$marker" "$manifest surfaces the linter's output"

  # Same fixture, toolchain genuinely absent: a missing linter is not a code
  # problem. Run with MINPATH so a machine that has the real tool installed
  # still exercises the absent branch.
  fire_without_toolchain "git commit -m 'x'" "$REPO"
  check_rc 0 "$manifest without its toolchain is a no-op"
done

# flake8 is the documented fallback when ruff is absent.
REPO=$(make_repo eco_flake8 "")
touch "$REPO/pyproject.toml"
mkdir -p "$TMPROOT/flakeonly" && cp "$FAKEBIN/flake8" "$TMPROOT/flakeonly/"
fire_with_path "$TMPROOT/flakeonly" "git commit -m 'x'" "$REPO"
check_rc 2 "pyproject.toml falls back to flake8 when ruff is absent"
has_out "FLAKE8_BROKE" "flake8 output is fed back"

# package.json wins where a directory carries more than one manifest.
REPO=$(make_repo eco_both "$FAILING")
touch "$REPO/go.mod"
fire_with_path "$FAKEBIN" "git commit -m 'x'" "$REPO"
check_rc 2 "package.json + go.mod still blocks"
has_out "LINT_BROKE" "package.json wins over go.mod"
lacks_out "GO_BROKE" "go vet did not also run"

echo "17. .claude/lint-gate.json replaces built-in detection..."
REPO=$(make_repo cfg "$PASSING")
mkdir -p "$REPO/.claude"
printf '%s' '{"commands":["echo CONFIG_BROKE >&2; exit 1"]}' > "$REPO/.claude/lint-gate.json"
fire "git commit -m 'x'" "$REPO"
check_rc 2 "a failing config command blocks even though package.json lint passes"
has_out "CONFIG_BROKE" "config command output is fed back"

# Replacement, not addition: the package.json script must not also run.
REPO=$(make_repo cfg_replaces "$FAILING")
mkdir -p "$REPO/.claude"
printf '%s' '{"commands":["true"]}' > "$REPO/.claude/lint-gate.json"
fire "git commit -m 'x'" "$REPO"
check_rc 0 "a passing config command suppresses the failing built-in script"

# Malformed config disables the gate rather than silently falling back to the
# detection the author meant to replace.
REPO=$(make_repo cfg_bad "$FAILING")
mkdir -p "$REPO/.claude"
printf '%s' '{ not json' > "$REPO/.claude/lint-gate.json"
fire "git commit -m 'x'" "$REPO"
check_rc 0 "a malformed config is a silent no-op"

REPO=$(make_repo cfg_optout "$PASSING")
mkdir -p "$REPO/.claude"
printf '%s' '{"commands":["echo CONFIG_BROKE >&2; exit 1"]}' > "$REPO/.claude/lint-gate.json"
touch "$REPO/.claude/no-lint-gate"
fire "git commit -m 'x'" "$REPO"
check_rc 0 ".claude/no-lint-gate still overrides the config"

echo "18. Only failures the commit introduces block it..."
# HEAD already fails. An unrelated commit must land — this is the defect that
# made the gate untrustworthy in any repo it did not grow up in.
REPO=$(make_repo base_pre "")
write_grep_linter "$REPO"
mkdir -p "$REPO/src" && printf 'var a = BADCODE;\n' > "$REPO/src/a.js"
commit_all "$REPO"
printf 'var ok = 1;\n' > "$REPO/src/clean.js"
git -C "$REPO" add -A
fire "git commit -m 'x'" "$REPO"
check_rc 0 "a pre-existing failure does not block an unrelated commit"

# The same repo, now staging a genuinely new failure.
printf 'var b = BADCODE;\n' > "$REPO/src/b.js"
git -C "$REPO" add -A
fire "git commit -m 'x'" "$REPO"
check_rc 2 "a newly-staged failure blocks"
has_out "b\.js" "the block message names the new failure"
lacks_out "a\.js" "the pre-existing failure is not reported as new"

# Editing above a pre-existing error shifts its line number. A naive text diff
# reads every shifted record as new; the digit-masked counts must not.
REPO=$(make_repo base_shift "")
write_grep_linter "$REPO"
mkdir -p "$REPO/src" && printf 'var a = 1;\nvar b = BADCODE;\n' > "$REPO/src/a.js"
commit_all "$REPO"
printf '// header\n// header2\nvar a = 1;\nvar b = BADCODE;\n' > "$REPO/src/a.js"
git -C "$REPO" add -A
fire "git commit -m 'x'" "$REPO"
check_rc 0 "a line-number shift is not mistaken for a new failure"

# The verdict is the staged index, not the working tree.
REPO=$(make_repo base_unstaged "")
write_grep_linter "$REPO"
mkdir -p "$REPO/src" && printf 'var ok = 1;\n' > "$REPO/src/a.js"
commit_all "$REPO"
printf 'var b = BADCODE;\n' > "$REPO/src/unstaged.js"   # written, never staged
fire "git commit -m 'x'" "$REPO"
check_rc 0 "an unstaged failure does not block"

git -C "$REPO" add -A
fire "git commit -m 'x'" "$REPO"
check_rc 2 "the same failure blocks once staged"

# Baseline unavailable: fall back to whole-project blocking, never to skipping.
# Silently passing here would be the one degradation that hides real failures.
REPO=$(make_repo base_nowt "")
write_grep_linter "$REPO"
mkdir -p "$REPO/src" && printf 'var a = BADCODE;\n' > "$REPO/src/a.js"
commit_all "$REPO"
fire_with_path "$NOARCHIVE" "git commit -m 'x'" "$REPO"
check_rc 2 "an unusable baseline blocks rather than passing"
has_out "baseline could not be established" "the fallback says why it blocked"

echo "19. A degraded baseline never silently passes a real failure..."
# Both cases below reached exit 0 before this section existed. They are the one
# failure mode that makes the gate worthless: the commit is broken, HEAD was
# fine, and the gate waves it through.

# Dependencies are gitignored in every real repo, so `git archive` never carries
# them — only link_deps can. Linking fewer directories than deps_installed
# accepts means the materialized tree fails on a missing binary, and that 127
# reads as "could not run". Two layouts: hoisted to the root, and installed at
# an intermediate workspace directory.
for layout in root:../../node_modules intermediate:../node_modules; do
  where="${layout%%:*}"; marker="${layout##*:}"
  REPO=$(make_repo "deps_$where" "")
  mkdir -p "$REPO/packages/api/src"
  printf 'node_modules/\n' > "$REPO/.gitignore"
  case "$where" in
    root) mkdir -p "$REPO/node_modules"; echo m > "$REPO/node_modules/.marker" ;;
    intermediate) mkdir -p "$REPO/packages/node_modules"; echo m > "$REPO/packages/node_modules/.marker" ;;
  esac
  cat > "$REPO/packages/api/lint.sh" <<SH
#!/bin/sh
[ -f $marker/.marker ] || { echo "deps missing" >&2; exit 127; }
found=\$(grep -rn BADCODE src --include='*.js' 2>/dev/null | sort)
[ -n "\$found" ] && { echo "\$found" >&2; exit 1; }
exit 0
SH
  printf '%s' '{"scripts":{"lint":"sh lint.sh"}}' > "$REPO/packages/api/package.json"
  printf 'var ok = 1;\n' > "$REPO/packages/api/src/a.js"
  commit_all "$REPO"
  printf 'var b = BADCODE;\n' > "$REPO/packages/api/src/bad.js"
  git -C "$REPO" add -A
  echo scratch > "$REPO/untracked.txt"   # forces the index to be materialized
  fire "git commit -m 'x'" "$REPO/packages/api"
  check_rc 2 "deps $where: a new failure blocks when deps are gitignored"
  has_out "bad\.js" "deps $where: the new failure is named, not a missing-binary error"
done

# A check that passed at HEAD and fails now was broken by this commit, whatever
# its output looks like. Both cases below produce nothing the record comparison
# can call new: one fails silently, the other differs only in a masked digit.
REPO=$(make_repo flip_silent "")
printf 'exit 0\n' > "$REPO/lint.sh"
printf '%s' '{"scripts":{"lint":"sh lint.sh"}}' > "$REPO/package.json"
mkdir -p "$REPO/node_modules"
commit_all "$REPO"
printf 'exit 1\n' > "$REPO/lint.sh"
git -C "$REPO" add -A
fire "git commit -m 'x'" "$REPO"
check_rc 2 "a silently-failing check that passed at HEAD blocks"
has_out '`lint` failed' "the block message names the check that broke"

# The same flip through a config command, which carries no runner banner, so the
# output really is empty and the message has nothing but the exit status to
# report. `test` is silent by design: HEAD has no src/bad.js, the index does.
REPO=$(make_repo flip_empty "$PASSING")
mkdir -p "$REPO/.claude" "$REPO/src"
printf '%s' '{"commands":["test ! -f src/bad.js"]}' > "$REPO/.claude/lint-gate.json"
commit_all "$REPO"
printf 'var b = 1;\n' > "$REPO/src/bad.js"
git -C "$REPO" add -A
fire "git commit -m 'x'" "$REPO"
check_rc 2 "a check failing with genuinely empty output still blocks"
has_out "no output" "the block message reports the exit status when there is no output"

REPO=$(make_repo flip_digits "")
mkdir -p "$REPO/src" "$REPO/node_modules"
cat > "$REPO/lint.sh" <<'SH'
#!/bin/sh
n=$(grep -rc BADCODE src/*.js 2>/dev/null | awk -F: '{s+=$2} END {print s+0}')
echo "$n problems found"
[ "$n" -gt 0 ] && exit 1
exit 0
SH
printf '%s' '{"scripts":{"lint":"sh lint.sh"}}' > "$REPO/package.json"
printf 'var ok = 1;\n' > "$REPO/src/a.js"
commit_all "$REPO"
printf 'var b = BADCODE;\n' > "$REPO/src/bad.js"
git -C "$REPO" add -A
fire "git commit -m 'x'" "$REPO"
check_rc 2 "a summary-only linter blocks when its count rises from zero"

# The exit-status shortcut must not swallow the whole point of the gate: when
# HEAD was already failing, a commit that adds nothing new still lands.
REPO=$(make_repo flip_preexisting "")
write_grep_linter "$REPO"
mkdir -p "$REPO/src" && printf 'var a = BADCODE;\n' > "$REPO/src/a.js"
commit_all "$REPO"
printf 'var ok = 1;\n' > "$REPO/src/clean.js"
git -C "$REPO" add -A
fire "git commit -m 'x'" "$REPO"
check_rc 0 "a check already failing at HEAD still allows an unrelated commit"

echo "20. Which files decide the verdict are read from the index too..."
# Contents and *selection* are the same lever: an unstaged edit that empties the
# config or drops scripts.lint would otherwise switch the gate off for a commit
# whose staged version still enables it. The command is silent by design, so
# only the exit-status path can catch it.
REPO=$(make_repo pin_cfg "$PASSING")
mkdir -p "$REPO/.claude" "$REPO/src"
printf '%s' '{"commands":["test ! -f src/bad.js"]}' > "$REPO/.claude/lint-gate.json"
commit_all "$REPO"
printf 'var b = 1;\n' > "$REPO/src/bad.js"
git -C "$REPO" add -A
printf '%s' '{ not json at all' > "$REPO/.claude/lint-gate.json"   # unstaged only
fire "git commit -m 'x'" "$REPO"
check_rc 2 "an unstaged config edit cannot disable the gate"

# Same lever through package.json: the staged manifest still declares lint.
REPO=$(make_repo pin_pkg "")
write_grep_linter "$REPO"
mkdir -p "$REPO/src" && printf 'var ok = 1;\n' > "$REPO/src/a.js"
commit_all "$REPO"
printf 'var b = BADCODE;\n' > "$REPO/src/bad.js"
git -C "$REPO" add -A
printf '%s' '{"scripts":{}}' > "$REPO/package.json"                # unstaged only
fire "git commit -m 'x'" "$REPO"
check_rc 2 "an unstaged package.json edit cannot disable the gate"

# Absent from the index means two opposite things, and only one of them should
# fall back to disk. A config staged for deletion still sits in the working
# tree, and reading it there let a file the commit *removes* pick the checks —
# here a passing `true` that suppressed the real, newly-failing lint script.
REPO=$(make_repo pin_deleted "")
write_grep_linter "$REPO"
mkdir -p "$REPO/.claude" "$REPO/src"
printf '%s' '{"commands":["true"]}' > "$REPO/.claude/lint-gate.json"
printf 'var ok = 1;\n' > "$REPO/src/a.js"
commit_all "$REPO"
printf 'var b = BADCODE;\n' > "$REPO/src/bad.js"
git -C "$REPO" add -A
git -C "$REPO" rm --cached -q .claude/lint-gate.json   # deleted in index, still on disk
fire "git commit -m 'x'" "$REPO"
check_rc 2 "a config staged for deletion stops selecting the checks"
has_out "bad\.js" "detection applies once the config is gone from the index"

# The opposite case must still work: a genuinely untracked config is honoured,
# since there is no staged version to prefer.
REPO=$(make_repo pin_untracked "$FAILING")
mkdir -p "$REPO/.claude"
commit_all "$REPO"
printf '%s' '{"commands":["true"]}' > "$REPO/.claude/lint-gate.json"   # never tracked
fire "git commit -m 'x'" "$REPO"
check_rc 0 "an untracked config still replaces detection"

# A project virtualenv is where ruff usually lives, and it is not on PATH.
REPO=$(make_repo venv_ruff "")
touch "$REPO/pyproject.toml"
mkdir -p "$REPO/.venv/bin"
printf '#!/bin/sh\necho "VENV_RUFF_BROKE" >&2\nexit 1\n' > "$REPO/.venv/bin/ruff"
chmod +x "$REPO/.venv/bin/ruff"
fire_without_toolchain "git commit -m 'x'" "$REPO"
check_rc 2 "ruff installed only in .venv is still found"
has_out "VENV_RUFF_BROKE" "the venv linter's output is fed back"

# Guard the guard: MINPATH must really hide a toolchain, or every
# absent-toolchain assertion above silently stops testing anything.
if PATH="$MINPATH" command -v ruff >/dev/null 2>&1 || \
   PATH="$MINPATH" command -v go >/dev/null 2>&1 || \
   PATH="$MINPATH" command -v cargo-clippy >/dev/null 2>&1; then
  echo "  FAIL: MINPATH leaks a real toolchain"; FAILURES=$((FAILURES + 1))
else echo "  PASS: MINPATH hides every probed toolchain"; fi

echo "21. The commit regex bails before any filesystem probing..."
# This hook runs on every Bash call in every repo, so detection must never move
# ahead of the cheap bail. Asserted behaviourally rather than by reading source.
if python3 - "$ROOT" <<'PY'
import importlib.util, io, json, os, subprocess, sys
spec = importlib.util.spec_from_file_location(
    "hook", os.path.join(sys.argv[1], "kit/plugins/git-agent/hooks/lint-before-commit.py"))
mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)

touched = []
mod.os.path.exists = lambda p: touched.append(("exists", p))
mod.subprocess.run = lambda *a, **k: touched.append(("run", a))
real_open = mod.open if hasattr(mod, "open") else open
import builtins
builtins_open = builtins.open
builtins.open = lambda *a, **k: (touched.append(("open", a)), builtins_open(*a, **k))[1]
try:
    for cmd in ["git status", "ls -la", "git log --grep commit", "git commit-tree x"]:
        sys.stdin = io.StringIO(json.dumps(
            {"tool_name": "Bash", "tool_input": {"command": cmd}, "cwd": sys.argv[1]}))
        if mod.main() != 0:
            print("non-zero exit for", cmd); sys.exit(1)
finally:
    builtins.open = builtins_open
if touched:
    print("filesystem touched before the bail:", touched[:3]); sys.exit(1)
sys.exit(0)
PY
then echo "  PASS: a non-commit payload touches no manifest, config, or worktree"
else echo "  FAIL: the gate probes the filesystem before the commit regex bails"; FAILURES=$((FAILURES + 1)); fi

echo
if [ "$FAILURES" -eq 0 ]; then echo "All checks passed."; exit 0
else echo "$FAILURES check(s) failed."; exit 1; fi
