# Add Pre-PR Adversarial Review

> Inserts a mandatory single-pass adversarial review of the branch diff into every git-agent PR-opening flow — fresh-context subagent in interactive skills, inline cold re-read in background agents — against one shared eleven-point checklist.

<!-- generated:start -->

**Status:** Shipped 2026-08-19 **Plan:** [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
**Type:** feature

## What shipped

- Added Step 4.7 to `skills/pr-agent/SKILL.md` that spawns a fresh-context subagent (`code-review:agent-code-reviewer` when available, else `general-purpose`) to review `git diff <base>...HEAD`; confirmed findings become a `fix:` commit + re-push (amend before push, never re-amend), unconfirmed ones land in `## Review Notes`; `Agent` added to `allowed-tools`.
- Upgraded `skills/ship/SKILL.md` Step 4.5 from a four-check inline list to the subagent dispatch, and extracted the full checklist and amend procedure into `skills/ship/references/self-review.md`.
- Updated `skills/ship-autonomous/SKILL.md` so Step 4 names the adversarial review rather than duplicating it — ship-autonomous opens its PR by invoking `pr-agent`, so it inherits Step 4.7.
- Extended `agents/agent-pr.md` and `agents/agent-ship.md` with a report-only inline variant of the same checklist (`disallowedTools` denies edits); findings go to `## Review Notes` and the final report; a proven secret stops the flow and is never named in a PR body.
- Bumped git-agent from 4.19.2 to 4.19.3.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Step 4.7 — review subagent dispatch, fix commit, Review Notes | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Step 4.5 upgraded to subagent dispatch | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Dispatch prompt, eleven-point checklist, amend procedure | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Step 4 names the adversarial review, no duplication | Modified |
| `kit/plugins/git-agent/agents/agent-pr.md` | Report-only inline review, checklist, secret-stops-flow rule | Modified |
| `kit/plugins/git-agent/agents/agent-ship.md` | Report-only inline review, checklist, secret-stops-flow rule | Modified |
| `.claude-plugin/marketplace.json` | git-agent 4.19.2 → 4.19.3 | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v4.19.3 entry | Modified |

## How it works

The 2026-08 usage analysis ranked bots-as-QA as the top friction point: first implementations were shipping with provable defects (no-op edits, vacuous test assertions, self-introduced regressions, unsafe auth/role/key lookups) that only got caught by PR review bots, costing 2–6 review rounds per PR. The root cause is that the author of a diff is the worst-placed reviewer — knowing what an edit was meant to do makes a no-op edit read like a fix. The review therefore runs in a context with no memory of the implementation.

For interactive skills (`pr-agent`, `ship`), the review runs in a fresh-context subagent. The dispatch prompt in `references/self-review.md` instructs the subagent to `git diff <base>...HEAD` as a hostile reviewer with no memory of the implementation, report only defects provable with file:line evidence, and check specifically for eleven categories: no-op edits, vacuous test assertions, self-introduced regressions, unsafe auth/role/key lookups, secrets or tokens in the diff, accessibility regressions, pagination sort tie-breakers, `parseInt`/`Number()` on user input without validation, derived state left stale after client-side updates, timezone-dependent date anchors computed in local time against UTC data, and scripts that continue after a failed step (missing `set -e`, unchecked exit codes).

In `pr-agent`, the review lands at Step 4.7 between Step 4.5 (pre-push preparation) and Step 5 (push). Confirmed findings are fixed and folded into the Step 4 commit with `git commit --amend --no-edit` — that commit is not yet pushed, so amending is safe. Only a single pass runs; the amended diff is never re-reviewed. Unconfirmed findings go into `## Review Notes` in the PR body. The one blocking exception is a confirmed secret: the skill amends it out, tells the user exactly what leaked and where (never in the PR body), and stops — secret rotation is the user's decision.

Background agents (`agent-pr`, `agent-ship`) have `disallowedTools: Write, Edit` and cannot run a subagent, so they use an inline cold re-read variant: the agent reads the same checklist against `git diff <base>...HEAD` with no memory of implementation, and any findings land in `## Review Notes` and the final report. The secret rule is the same: a proven secret stops the flow and is never named in a PR body or report.

`ship-autonomous` opens its PR by invoking `pr-agent` as a skill, so it inherits Step 4.7 without duplication. Its Step 4 names the adversarial review rather than restating it — the `ship-autonomous` core was at the 600-word ceiling enforced by the split test, and one review per PR is the explicit design goal. The `--no-review` opt-out from `ship`'s Step 4.5 is preserved; `pr-agent` offers the same override.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `324cc3c` | 2026-08-19 | feat(git-agent): adversarial pre-PR review in PR-opening flows (4.19.3) (#585) |
| `eab3545` | 2026-09-03 | fix(git-agent,code-review): stop the pre-PR reviewer from stalling the ship (4.20.2, 3.3.6) (#619) |
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |

<!-- generated:end -->

## References

- Plan: [add-pre-pr-adversarial-review.md](plans/add-pre-pr-adversarial-review.md)
