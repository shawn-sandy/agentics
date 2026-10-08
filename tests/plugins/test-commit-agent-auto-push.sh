#!/usr/bin/env bash
set -euo pipefail

# commit-agent pushes after a direct-invocation commit without asking. The
# Step 6 push prompt was the only gate on that push, so its replacement carries
# the guards: never push the default branch, never force, never reconcile a
# rejected push. Delegated invocation still stops after Step 4 — the caller
# owns the push, and pushing first would turn pr-agent's base-sync rebase into
# a merge.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/git-agent/skills/commit-agent/SKILL.md"
FAILURES=0
check() {
  local name="$1"; shift
  if "$@"; then echo "  PASS: $name"; else echo "  FAIL: $name"; FAILURES=$((FAILURES + 1)); fi
}

# Section body from a heading matching $1 up to the next heading of any level.
section() { awk -v re="$1" '$0 ~ re {f=1; next} f && /^#+ /{exit} f' "$SKILL"; }

PUSH_RE='^## Step 6: Push'
COMMIT_RE='^## Step 4: Commit'
push_body=$(section "$PUSH_RE")
delegated_body=$(section '^## Delegated invocation')
frontmatter=$(awk 'NR==1 && /^---$/ {f=1; next} f && /^---$/ {exit} f' "$SKILL")

echo "=== commit-agent pushes without asking ==="

push_line=$(grep -n -E "$PUSH_RE" "$SKILL" | head -1 | cut -d: -f1 || true)
commit_line=$(grep -n -E "$COMMIT_RE" "$SKILL" | head -1 | cut -d: -f1 || true)
check "Step 6 push heading exists" test -n "$push_line"
check "Step 6 push comes after the Step 4 commit" test "${push_line:-0}" -gt "${commit_line:-0}"
check "Step 6 does not ask before pushing" bash -c '! grep -q "AskUserQuestion" <<<"$1"' _ "$push_body"
check "no 'Don't push' option remains anywhere" bash -c '! grep -qi "don.t push" "$1"' _ "$SKILL"
check "description says it pushes" bash -c 'grep -qiE "^description:.*push" <<<"$1"' _ "$frontmatter"
check "description no longer offers a push choice" bash -c '! grep -qiE "^description:.*whether" <<<"$1"' _ "$frontmatter"
check "Step 6 runs the push command from Step 5" bash -c 'grep -qi "step 5" <<<"$1"' _ "$push_body"
check "Step 6 guards main" bash -c 'grep -q "\`main\`" <<<"$1"' _ "$push_body"
check "Step 6 guards master" bash -c 'grep -q "\`master\`" <<<"$1"' _ "$push_body"
check "Step 6 never forces" bash -c 'grep -qiE "do not force|never force" <<<"$1"' _ "$push_body"
check "Step 6 never reconciles a rejected push" bash -c 'grep -qiE "do not pull" <<<"$1"' _ "$push_body"
check "delegated invocation still stops after Step 4" bash -c 'grep -qi "stop after Step 4" <<<"$1"' _ "$delegated_body"

echo
if [ "$FAILURES" -gt 0 ]; then echo "FAILED: $FAILURES check(s)"; exit 1; fi
echo "All checks passed."
