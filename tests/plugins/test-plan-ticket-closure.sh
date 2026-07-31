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
both "closes a completed plan's GitHub ticket" 'gh issue close "<url>"'
both "closes a completed plan's GitLab ticket" 'glab issue close "<url>"'
both "never closes when the plan lands in-progress" 'never close'
both "comments instead on an in-progress plan" 'gh issue comment "<url>" --body-file'
both "gates closure behind an explicit question" 'Close it?'

# The summary is plan-derived text: Completion Report bullets routinely carry
# backticks naming a file, and `$(...)`/`$VAR` in a plan would expand before
# the CLI saw them. Both skills must route it through a file, never a shell
# string — assert the safe form is present and the unsafe one is gone.
both "passes the summary to gh as a file, not a shell string" '--body-file'
both "quotes the GitLab summary via command substitution" '-m "$(cat'

# The ticket URL is frontmatter too, and it becomes a shell argument. Both
# skills must vet it before use and quote it, so an unsupported tracker is
# skipped rather than handed to whichever CLI happened to be the fallback.
both "validates the ticket URL is https before using it" 'https://'
both "quotes the ticket URL in the command" '"<url>"'
both "never asks about closing a plan that landed in-progress" 'never ask'
for f in "${SKILLS[@]}"; do
  if grep -qF -- '--comment "<summary>"' "$f" || grep -qF -- '--body "<summary>"' "$f"; then
    echo "FAIL: $f still interpolates the summary into a shell string"; fail=1
  fi
done
echo "ok: neither skill interpolates the summary into a shell string"

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
