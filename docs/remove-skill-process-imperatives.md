# Earn every NEVER — baseline first, then prune

> Five plan-agent, git-agent, and skill-reviewer skills carried 118 hard imperatives across 13,758 words. Process-reminder imperatives were pruned after recording behavioral baselines, with no safety guard removed and no regression observed.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
**Type:** refactor

## What shipped

- Classified all 118 imperatives in the five target SKILL.md files as KEEP or DROP using the discriminator "violating it fails silently and expensively"; wrote the KEEP set to `tests/fixtures/imperative-baselines/keep-phrases.txt` as `<skill-path>\t<literal-phrase>` lines for machine-checking.
- Built `tests/plugins/test-skill-behavior-baselines.sh` and fixed two harness defects: stdin inheritance that wedged runs, and a watchdog subshell that held a pipe open for the full 900s timeout regardless of when the work finished.
- Wrote `tests/plugins/test-imperative-pruning.sh` asserting all four conditions: every KEEP phrase present verbatim, all five `description:` lines byte-identical to a golden file, all five `.expected` manifests exist and are non-empty, and the behavioral harness passes when the `claude` CLI is available.
- Committed the classification, scenarios, recorded manifests, harness, and objective test as one baseline commit (`ed6b854`) that touches no file under `kit/plugins/` — baselines recorded from already-pruned skills prove nothing.
- Pruned DROP-classified imperatives from `build`, `implementation-plan`, `ship-autonomous`, `branch-agent`, and `optimizing-skill-frontmatter`; retained all KEEP guards verbatim, including the merge-on-green guard, both stash guards, the Scope Constraint block, and the `disable-model-invocation: false` prohibition.
- Bumped plan-agent to 7.2.0, git-agent to 4.9.0, skill-reviewer to 2.4.0 in `.claude-plugin/marketplace.json` (the spec named 5.1.0/4.8.0/2.3.0 but those versions were already on `main` by implementation time; the bump targets were raised to exceed `main`).
- Wired `tests/plugins/test-imperative-pruning.sh` into `.github/workflows/check-plugin-versions.yml`.
- Fixed a description comparison strategy: rather than comparing against `git show origin/main:<path>` (which would block any future legitimate description update), the assertion compares against `tests/fixtures/imperative-baselines/descriptions.expected`, allowing deliberate changes to update one file.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `tests/fixtures/imperative-baselines/keep-phrases.txt` | Machine-checkable KEEP classification, one phrase per target file | Created |
| `tests/fixtures/imperative-baselines/scenarios/` | Fixed input scenarios per skill for behavioral testing | Created |
| `tests/fixtures/imperative-baselines/*.expected` | Recorded structural manifests for behavioral comparison | Created |
| `tests/fixtures/imperative-baselines/descriptions.expected` | Golden file for description drift detection | Created |
| `tests/plugins/test-skill-behavior-baselines.sh` | Local-only behavioral harness; exits 1 when `claude` CLI absent | Created |
| `tests/plugins/test-imperative-pruning.sh` | CI-wired structural gate; checks KEEP phrases, descriptions, manifests | Created |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Removed Step 0 plan-mode rationale, Step 2 aside, per-step re-render reminders | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Removed plan-mode rationale, Step 4 kebab-case restatement | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Removed "Run Steps 0–5 in strict order"; kept merge-on-green and branch guards | Modified |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Removed "Follow these steps in strict order." opening; kept stash and no-force guards | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Removed "Follow these steps exactly", "Count carefully"; kept prohibitions | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 7.2.0, git-agent 4.9.0, skill-reviewer 2.4.0 | Modified |
| `.github/workflows/check-plugin-versions.yml` | Added step running `test-imperative-pruning.sh` | Modified |

## How it works

The plan's central discriminator was behavioral, not cosmetic: keep an imperative only if violating it fails silently and expensively. This distinguishes safety guards (`ship-autonomous`'s "Never merge on anything but green", `branch-agent`'s "Do not drop the stash before staging resolved files") from process scaffolding ("Run Steps 0–5 in strict order") that a Claude 5 generation model infers from the surrounding steps.

Sequencing was the safety mechanism. Baselines had to be recorded from the unmodified skills and committed before any SKILL.md edit — a baseline recorded from an already-pruned file proves nothing. The baseline commit (`ed6b854`) was verified by `git show --stat HEAD | grep -c 'kit/plugins/'` printing 0.

By implementation time three of the five targets had already shrunk ~80% from earlier work (PRs #487/#489 split them into cores plus references). The real DROP set was five items rather than 118, making the prune 7 insertions and 14 deletions across five files. The plan's own honest accounting had predicted the smallest return of the context-engineering set; the actual figure was smaller still.

Behavioral baselines were reproduced 5/5 before editing and 5/5 after. The load-bearing properties all held: `implementation-plan` wrote nothing outside the plans directory; `branch-agent`'s stash/pop returned every file with an empty `git stash list` and no new commit; `build` promoted `status:` to `completed` and created only the plan file; `optimizing-skill-frontmatter` never emitted `disable-model-invocation: false`; `ship-autonomous` left HEAD, branch, and working tree unchanged.

The abort condition (restore a guard if one fix attempt does not explain a baseline failure) was never invoked.

Two harness defects were caught and fixed during implementation: stdin inheritance wedged headless runs when the harness itself ran non-interactively, and a watchdog subshell held the manifest pipe open for the full 900s timeout. The fixes were verified with run times dropping from 900s pinned to 84s measured.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
