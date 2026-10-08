#!/usr/bin/env bash
set -euo pipefail

# commit-agent pushes after a direct-invocation commit without asking. The old
# push prompt was the only gate on that push, so its replacement carries the
# guards: never push the default branch, always name the branch in the push
# (a branch cut from origin/main tracks origin/main, so a bare `git push` would
# target the base or fail), never force, never reconcile a rejected push.
# Delegated invocation still stops after Step 4 — the caller owns the push —
# and every skill that invokes commit-agent says it is delegating, so a WIP or
# failing-test commit is never pushed by accident.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/git-agent/skills/commit-agent/SKILL.md"
FAILURES=0
check() {
  local name="$1"; shift
  if "$@"; then echo "  PASS: $name"; else echo "  FAIL: $name"; FAILURES=$((FAILURES + 1)); fi
}

# Section body from a heading matching $1 up to the next heading of any level.
section() { awk -v re="$1" '$0 ~ re {f=1; next} f && /^#+ /{exit} f' "$SKILL"; }
# First line number in stdin matching ERE $1, or empty.
line_of() { grep -n -E "$1" | head -1 | cut -d: -f1 || true; }

PUSH_RE='^## Step 5: Push$'
COMMIT_RE='^## Step 4: Commit$'
push_body=$(section "$PUSH_RE")
delegated_body=$(section '^## Delegated invocation$')
frontmatter=$(awk 'NR==1 && /^---$/ {f=1; next} f && /^---$/ {exit} f' "$SKILL")

echo "=== commit-agent pushes without asking ==="

push_line=$(line_of "$PUSH_RE" < "$SKILL")
commit_line=$(line_of "$COMMIT_RE" < "$SKILL")
check "Step 4 commit heading exists" test -n "$commit_line"
check "Step 5 push heading exists" test -n "$push_line"
check "push step comes after the commit step" test "${push_line:-0}" -gt "${commit_line:-999999}"
check "push step says not to ask" bash -c 'grep -qi "do not ask" <<<"$1"' _ "$push_body"
check "push step has no AskUserQuestion" bash -c '! grep -q "AskUserQuestion" <<<"$1"' _ "$push_body"
check "no 'Don't push' option remains anywhere" bash -c '! grep -qi "don.t push" "$1"' _ "$SKILL"
check "description says it pushes" bash -c 'grep -qiE "^description:.*then pushes" <<<"$1"' _ "$frontmatter"

guard_line=$(line_of 'If the current branch is the default branch.*STOP' <<<"$push_body")
cmd_line=$(line_of 'git push -u origin <current-branch>' <<<"$push_body")
check "push names the branch explicitly" test -n "$cmd_line"
check "push step never runs a bare git push" bash -c '! grep -qE "\`git push\`" <<<"$1"' _ "$push_body"
check "default-branch guard stops the push" test -n "$guard_line"
check "guard comes before the push command" test "${guard_line:-999999}" -lt "${cmd_line:-0}"
check "guard resolves the remote default branch" bash -c 'grep -q "refs/remotes/origin/HEAD" <<<"$1"' _ "$push_body"
check "guard always covers main" bash -c 'grep -q "\`main\`" <<<"$1"' _ "$push_body"
check "guard always covers master" bash -c 'grep -q "\`master\`" <<<"$1"' _ "$push_body"
check "push never forces" bash -c 'grep -qiE "do not force|never force" <<<"$1"' _ "$push_body"
check "push never reconciles a rejected push" bash -c 'grep -qiE "do not pull" <<<"$1"' _ "$push_body"
check "delegated invocation still stops after Step 4" bash -c 'grep -qi "stop after Step 4" <<<"$1"' _ "$delegated_body"

echo "=== every caller delegates ==="

callers=$(grep -rn -E '^Invoke .*commit-agent' "$ROOT/kit/plugins" --include='*.md' || true)
check "at least one caller found" test -n "$callers"
undelegated=$(grep -v -i 'delegated' <<<"$callers" || true)
check "every 'Invoke ... commit-agent' line says delegated" test -z "$undelegated"
[ -n "$undelegated" ] && echo "$undelegated" | sed 's/^/    /'

echo
if [ "$FAILURES" -gt 0 ]; then echo "FAILED: $FAILURES check(s)"; exit 1; fi
echo "All checks passed."
