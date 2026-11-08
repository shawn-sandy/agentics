# Harden Review Gates

> Close four observed gaps in the marketplace's review gates: missing defect classes in adversarial checklists, silent CI billing-block false-negatives, absent stale-checkout guard, and a drifted bundled rule.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [harden-review-gates.md](plans/harden-review-gates.md)
**Type:** feature

## What shipped

- Added five report-identified defect classes (pagination tie-breakers, unvalidated `parseInt`, stale derived state, timezone-dependent dates, scripts that don't abort) to the adversarial review checklist in both `git-agent/skills/pr-agent/SKILL.md` Step 4.7 and `git-agent/skills/ship/references/self-review.md` (kept byte-identical to each other).
- Mirrored the same five defect classes into `code-review/skills/code-review-agent/references/review-checklist.md` section 2 so the subagent the reviewer dispatches reads matching criteria.
- Added a dispatch check to `git-agent/skills/merge/SKILL.md` Step 2: when every CI job produced no log, the skill reports the billing block rather than calling the run green.
- Added a stale-checkout guard to `plan-agent/skills/build/references/resolve-plan.md` beside the existing dirty-tree guard — no extra words to the core, which was already at its progressive-disclosure ceiling.
- Synced `team-defaults/skills/sync-rules/rules/review-bot-loops.md` forward to include the missing Hard default, full Triage section, and replies-are-for-humans rule.
- Bumped `git-agent`, `code-review`, `plan-agent`, and `team-defaults` versions in `.claude-plugin/marketplace.json` with matching CHANGELOG entries.
- Shipped `tests/review-gates.test.mjs` asserting all five contracts as a runnable regression guard.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Adversarial review checklist (Step 4.7) | Modified |
| `kit/plugins/git-agent/skills/ship/references/self-review.md` | Self-review checklist, kept identical to pr-agent copy | Modified |
| `kit/plugins/code-review/skills/code-review-agent/references/review-checklist.md` | Code-review agent checklist, section 2 | Modified |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Merge skill with billing-block dispatch check | Modified |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Build pre-flight reference with stale-checkout guard | Modified |
| `tests/review-gates.test.mjs` | Objective-verification test | Created |

## How it works

The 2026-08-21 insights report identified five defect classes that had escaped to bot reviewers across 115 buggy-code friction events, yet none appeared in the adversarial review prompts. The fix adds a check block covering pagination tie-breakers, unvalidated `parseInt`, stale derived state, timezone-dependent dates, and scripts that don't abort to both live copies of the checklist — `pr-agent/SKILL.md` Step 4.7 and `ship/references/self-review.md`. A test asserts the two prompt blocks remain byte-identical, preventing future drift.

The same five classes were added to `code-review/skills/code-review-agent/references/review-checklist.md` section 2, because that is the file the `agent-code-reviewer` subagent reads when Step 4.7 dispatches it. Without this mirror the gate existed but aimed at different targets on each side.

The billing-block gap was addressed in `git-agent/skills/merge/SKILL.md` Step 2. When `gh workflow list` returns nothing or every job produced no log, the merge skill now explicitly reports "CI jobs never dispatched" rather than interpreting empty output as green. This removes the repeated re-diagnosis sessions the report counted at eight or more.

The stale-checkout guard landed in `plan-agent/skills/build/references/resolve-plan.md`, not the core `build/SKILL.md`. The core was already at its 600-word progressive-disclosure ceiling; `resolve-plan.md` is loaded at exactly Step 1 when the guard is needed. The guard sits before plans-directory resolution, so a stale tree is caught before any context is laid down.

`team-defaults/skills/sync-rules/rules/review-bot-loops.md` was behind the maintainer's own copy by the entire Triage section. The sync forward brought the Hard default rule, the "drop findings already fixed" triage note, and the replies-are-for-humans constraint into the bundled copy.

`tests/review-gates.test.mjs` asserts all five properties against the real shipped files: both adversarial prompts name each defect class, the two prompt blocks are identical, `merge/SKILL.md` contains the never-dispatched rule, `resolve-plan.md` carries the freshness guard while the core does not, and the bundled `review-bot-loops.md` contains the Triage heading.

## How to use it

The changes are passive guards — they fire whenever the existing skills run. No new commands or invocation syntax were added.

- **Adversarial review** runs as part of `/git-agent:ship` Step 4 and `/git-agent:pr-agent`. The checklist it reads now includes the five new defect classes.
- **Merge billing-block check** fires when `/git-agent:merge` queries CI status. When all jobs dispatched zero logs, it reports the block verbatim rather than passing.
- **Stale-checkout guard** runs as part of `/plan-agent:build` Step 1 pre-flight via `references/resolve-plan.md`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `da54ec1` | 2026-08-27 | fix(git-agent): stop a zero-byte CI log reporting as "never dispatched" (4.19.5) (#607) |
| `eab3545` | 2026-09-03 | fix(git-agent,code-review): stop the pre-PR reviewer from stalling the ship (4.20.2, 3.3.6) (#619) |
| `56a2ea3` | 2026-09-11 | fix(git-agent): close a completed plan's ticket when its PR merges (#630) |
| `5e1b3c2` | 2026-09-26 | feat(git-agent): sync with the base branch before pushing (4.22.0) (#639) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `8a8a392` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |

<!-- generated:end -->

## References

- Plan: [harden-review-gates.md](plans/harden-review-gates.md)
