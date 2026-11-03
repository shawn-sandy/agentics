# Harden Review Gates

> Close four gaps so the review gates in this marketplace catch the defect classes that actually escape, and so CI and checkout state are never silently assumed.

<!-- generated:start -->

**Status:** Shipped 2026-08-21  **Plan:** [harden-review-gates.md](plans/harden-review-gates.md)
**Type:** feature

## What shipped

- Added five defect classes to the adversarial pre-PR review checklist in both live copies — `git-agent/skills/pr-agent/SKILL.md` Step 4.7 and `git-agent/skills/ship/references/self-review.md` — covering pagination tie-breakers, unvalidated `parseInt`, stale derived state, timezone-dependent dates, and scripts that do not abort on error (the five classes that escaped to bot reviewers in 133 observed sessions).
- Mirrored the same five classes into `code-review/skills/code-review-agent/references/review-checklist.md` section 2 so the `agent-code-reviewer` subagent reads the same defect list.
- Added a dispatch check to `git-agent/skills/merge/SKILL.md` Step 2 that reports an empty-workflow-list as a billing block rather than reporting CI green.
- Added a stale-checkout guard to `plan-agent/skills/build/references/resolve-plan.md` beside the existing dirty-tree guard, so implementation never starts from a stale premise (without pushing the `build` core past its 600-word ceiling).
- Synced `team-defaults/skills/sync-rules/rules/review-bot-loops.md` forward to the maintainer's current copy, adding the Hard default, the full Triage section, and the replies-are-for-humans rule.
- Bumped git-agent, code-review, plan-agent, and team-defaults with changelog entries.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | PR agent — five new adversarial checklist items | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Self-review reference — byte-identical copy of the adversarial checklist | Modified |
| `kit/plugins/code-review/skills/code-review-agent/references/review-checklist.md` | Code review checklist — five new items in section 2 | Modified |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Merge skill — billing-block dispatch check in Step 2 | Modified |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Build pre-flight reference — stale-checkout guard | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | (see above) | Modified |
| `tests/review-gates.test.mjs` | Objective test — five assertions across four files | Created |

## How it works

The adversarial pre-PR review is a structured checklist that git-agent's `pr-agent` skill applies before opening a PR. Prior to this fix the checklist covered six defect classes, none of which matched the five classes that actually escaped to external reviewers (identified by grepping `git-agent/` and `code-review/` for `tie-break`, `parseInt`, `timezone`, and `derived state` — all returning zero hits). The fix adds checks (g) through (k) directly into Step 4.7 of `pr-agent/SKILL.md` and into `ship/references/self-review.md`, keeping those two blocks byte-identical so a test can assert they cannot drift.

The `code-review` plugin's `review-checklist.md` is the reference the `agent-code-reviewer` subagent reads when dispatched by Step 4.7. Adding the same five classes there ensures the subagent and the inline checklist target the same defects.

The billing-block detection in `merge/SKILL.md` addresses eight-plus sessions spent re-diagnosing the same failure mode. The dispatch check added to Step 2 asks whether any CI job was dispatched at all: when the workflow list is empty or every job produced no log output, the skill reports an external block and never marks CI green. The existing "If any of these fails" paragraph is unchanged — the new check sits before it.

The stale-checkout guard in `resolve-plan.md` adds a `git fetch` + `git status` freshness check alongside the existing dirty-tree guard. It lives in the reference file rather than in `build/SKILL.md` itself because the core is capped at 600 words by `tests/plugins/test-progressive-disclosure.sh` and the core already delegates Steps 0–1 to `resolve-plan.md`.

The `review-bot-loops.md` sync restores the Triage section (including the "drop findings already fixed" rule) and the Hard default that had been stripped from the version shipped with `team-defaults`.

`tests/review-gates.test.mjs` is the objective test: it asserts against the real shipped files that both adversarial prompts contain all five new defect classes, the two prompt blocks are identical, the merge skill contains the never-dispatched rule, `resolve-plan.md` carries the freshness guard, and the bundled `review-bot-loops.md` contains the Triage heading.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 3e849ec | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |

<!-- generated:end -->

## References

- Plan: [harden-review-gates.md](plans/harden-review-gates.md)
