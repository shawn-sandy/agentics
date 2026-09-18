#!/usr/bin/env bash
set -euo pipefail

# commit-agent recognises a lint-gate block by the first line of the hook's
# message and forbids the bypass the message offers. Both strings are taken
# from a real block here, so rewording the hook without updating the skill
# (or the reverse) fails this test instead of silently dropping the skill back
# to its generic pre-commit-hook rule.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$ROOT/kit/plugins/git-agent/hooks/lint-before-commit.py"
SKILL="$ROOT/kit/plugins/git-agent/skills/commit-agent/SKILL.md"
FAILURES=0

echo "=== commit-agent lint-gate handling ==="

check() { # check <label> <condition-cmd...>
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  PASS: $label"
  else
    echo "  FAIL: $label"
    FAILURES=$((FAILURES + 1))
  fi
}

TMPROOT=$(mktemp -d)
trap 'rm -rf "$TMPROOT"' EXIT

# An unborn repo with a failing lint script: the gate blocks on the whole
# output, which is the shortest path to a real block message.
REPO="$TMPROOT/repo"
mkdir -p "$REPO/node_modules"
git -C "$REPO" init -q
printf '%s' '{"scripts":{"lint":"echo LINT_BROKE >&2; exit 1"}}' > "$REPO/package.json"

PAYLOAD=$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": "git commit -m x"}, "cwd": sys.argv[1]}))' "$REPO")
set +e
OUT=$(printf '%s' "$PAYLOAD" | python3 "$HOOK" 2>&1)
RC=$?
set -e

if [ "$RC" -ne 2 ]; then
  echo "  FAIL: hook did not block (rc=$RC) — nothing to compare the skill against"
  exit 1
fi

# The label varies per check; the skill names it as a placeholder.
MARKER=$(printf '%s\n' "$OUT" | head -n 1 | sed 's/`[^`]*`/`<check>`/')
OPT_OUT=$(printf '%s\n' "$OUT" | sed -n 's/.*create \([^ ]*\) to disable it.*/\1/p' | head -n 1)

check "hook message carries an opt-out path" test -n "$OPT_OUT"
check "skill quotes the hook's block line ($MARKER)" grep -qF -- "$MARKER" "$SKILL"
check "skill names the opt-out file it must not create ($OPT_OUT)" grep -qF -- "$OPT_OUT" "$SKILL"
# The fix path edits source; without these the skill prompts mid-run.
check "allowed-tools grants Read" grep -qE '^allowed-tools:.*\bRead\b' "$SKILL"
check "allowed-tools grants Edit" grep -qE '^allowed-tools:.*\bEdit\b' "$SKILL"

# The background agents have no user to ask, so they take the skill's
# delegated branch: recognise the block, never switch the gate off, report and
# stop. That branch is only honest while they cannot edit source.
for name in agent-commit agent-ship; do
  AGENT="$ROOT/kit/plugins/git-agent/agents/$name.md"
  check "$name quotes the hook's block line" grep -qF -- "$MARKER" "$AGENT"
  check "$name names the opt-out file it must not create" grep -qF -- "$OPT_OUT" "$AGENT"
  check "$name is still denied Edit" grep -qE '^disallowedTools:.*\bEdit\b' "$AGENT"
done

# ship and ship-autonomous ask, then fix, like commit-agent run directly. Their
# cores sit under a word ceiling, so the handling lives in a reference the core
# points to.
for skill in ship ship-autonomous; do
  DIR="$ROOT/kit/plugins/git-agent/skills/$skill"
  REF="$DIR/references/lint-gate-block.md"
  check "$skill core points to its lint-gate reference" grep -qF 'references/lint-gate-block.md' "$DIR/SKILL.md"
  check "$skill quotes the hook's block line" grep -qF -- "$MARKER" "$REF"
  check "$skill names the opt-out file it must not create" grep -qF -- "$OPT_OUT" "$REF"
  check "$skill allowed-tools grants AskUserQuestion" grep -qE '^allowed-tools:.*\bAskUserQuestion\b' "$DIR/SKILL.md"
  check "$skill allowed-tools grants Edit" grep -qE '^allowed-tools:.*\bEdit\b' "$DIR/SKILL.md"
done

# ship-autonomous commits through commit-agent from more than one step, and not
# all of them live in SKILL.md. Every such step must be one the lint-gate
# reference names, so a new call site fails here until the reference covers it.
SA="$ROOT/kit/plugins/git-agent/skills/ship-autonomous"
UNCOVERED=$(python3 - "$SA" <<'PY'
import os, re, sys
root = sys.argv[1]
refdir = os.path.join(root, "references")
ref = open(os.path.join(refdir, "lint-gate-block.md"), encoding="utf-8").read()
files = [os.path.join(root, "SKILL.md")] + [
    os.path.join(refdir, f) for f in sorted(os.listdir(refdir))
    if f.endswith(".md") and f != "lint-gate-block.md"]
steps = set()
for path in files:
    step = None
    for line in open(path, encoding="utf-8"):
        m = re.match(r"#+\s+Steps?\s+(\d+[a-z]?)", line) or re.match(r"#+\s+(\d+[a-z])\b", line)
        if m:
            step = m.group(1)
        if "git-agent:commit-agent" in line and step:
            steps.add(step)
if not steps:
    print("no-call-sites-found")
print(" ".join(s for s in sorted(steps) if not re.search(r"\b" + re.escape(s) + r"\b", ref)))
PY
)
check "ship-autonomous reference covers every commit-agent step (missing: ${UNCOVERED:-none})" test -z "$UNCOVERED"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks PASSED."
else
  echo "$FAILURES check(s) FAILED."
  exit 1
fi
