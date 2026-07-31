#!/usr/bin/env bash
# Objective test: a completed plan closes its linked tracking ticket.
#
# Two skills own "mark this plan completed" — build's Step 5 gate and
# finalize-plan's Step 5 — and they are documented as having to stay
# consistent. A rule that lands in only one of them is the actual failure mode
# here, so every assertion below is made against BOTH files.
set -euo pipefail
cd "$(dirname "$0")/../.."

SKILLS=(
  "kit/plugins/plan-agent/skills/build/SKILL.md"
  "kit/plugins/plan-agent/skills/finalize-plan/SKILL.md"
)

fail=0
both() { # both <description> <grep-pattern>
  local desc="$1" pat="$2" missing=""
  for f in "${SKILLS[@]}"; do
    grep -qF -- "$pat" "$f" || missing="$missing $f"
  done
  if [ -z "$missing" ]; then echo "ok: $desc"; else echo "FAIL: $desc —missing in$missing"; fail=1; fi
}

both "keyed off the spec's issue: frontmatter" 'issue:'
both "closes a completed plan's GitHub ticket" 'gh issue close <url> --comment'
both "closes a completed plan's GitLab ticket" 'glab issue close <url>'
both "never closes when the plan lands in-progress" 'never close'
both "comments instead on an in-progress plan" 'gh issue comment <url> --body'
both "gates closure behind an explicit question" 'Close it?'

# A ticket that cannot be closed must not strand the plan in a non-completed
# state — the whole point is that plan completion is already decided by then.
both "a CLI failure never blocks completion" 'never blocks'

# The renderer half of the contract: without the plan-issue link there is
# nothing for these steps to act on.
if grep -q 'plan-issue' kit/plugins/plan-agent/scripts/lib/plan-shell.mjs; then
  echo "ok: renderer emits the plan-issue meta tag the closure step reads"
else
  echo "FAIL: renderer no longer emits plan-issue"; fail=1
fi

exit $fail
