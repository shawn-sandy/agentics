# Earn every NEVER — baseline first, then prune

> Removed process-reminder imperatives from the five most over-constrained SKILL.md files in plan-agent, git-agent, and skill-reviewer after capturing behavioral baselines that prove the pruning changed nothing safety-critical, with every retained safety guard still literally present and verified falsifiable.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
**Type:** refactor

## What shipped

- Classified all 118 imperatives across five target skills as KEEP or DROP using the discriminator "violating it fails silently and expensively", and wrote the KEEP set to `tests/fixtures/imperative-baselines/keep-phrases.txt` as `<skill path>\t<literal phrase>` lines.
- Built `tests/plugins/test-skill-behavior-baselines.sh` — a local-only behavioral harness running each skill headless against fixed scenario inputs and asserting structural facts (files written, gates fired, refusals emitted) rather than prose output.
- Wrote `tests/plugins/test-imperative-pruning.sh` — the CI-wired objective test checking: every KEEP phrase is literally present in its named file, description lines are byte-identical to a committed golden file, all five `.expected` manifests exist and are non-empty, and the behavioral harness passes when the `claude` CLI is available.
- Committed the classification, scenarios, recorded manifests, harness, and objective test as one commit (`ed6b854`) touching no file under `kit/plugins/` — establishing a clean pre-prune baseline.
- Pruned DROP-classified imperatives from five SKILL.md files: removed Step 0 plan-mode rationale sentences, ordering-reminders already stated elsewhere, and per-step re-render pointers that merely re-referenced the subroutine section, while leaving `## Scope Constraint — Plans Only`, all stash guards, the merge-on-green and `--delete-branch` guards, and the `disable-model-invocation: false` prohibition verbatim.
- Bumped plan-agent to 7.2.0, git-agent to 4.9.0, skill-reviewer to 2.4.0 with CHANGELOG entries noting that behavior baselines were recorded before the prune.
- Wired `test-imperative-pruning.sh` into `.github/workflows/check-plugin-versions.yml`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `tests/fixtures/imperative-baselines/keep-phrases.txt` | KEEP classification: one phrase per line with skill path | Created |
| `tests/plugins/test-skill-behavior-baselines.sh` | Local behavioral harness; exits 1 when claude CLI is absent | Created |
| `tests/plugins/test-imperative-pruning.sh` | CI-wired objective test: KEEP phrases, description drift, baselines present | Created |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | DROP-classified imperatives removed | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | DROP-classified imperatives removed; Scope Constraint intact | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | DROP-classified imperatives removed; merge-on-green guard intact | Modified |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | DROP-classified imperatives removed; stash guards intact | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | DROP-classified imperatives removed; disable-model-invocation prohibition intact | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 7.2.0, git-agent 4.9.0, skill-reviewer 2.4.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.2.0 entry | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.9.0 entry | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | 2.4.0 entry | Modified |
| `.github/workflows/check-plugin-versions.yml` | New step running test-imperative-pruning.sh | Modified |

## How it works

**The central discriminator separates safety from process.** The classification rule is: keep an imperative only if violating it fails silently and expensively. Safety guards — `ship-autonomous`'s "Never merge on anything but green", the `--delete-branch` guard, `branch-agent`'s stash guards, `implementation-plan`'s `## Scope Constraint — Plans Only`, `build`'s "Never resolve a gate by picking for the user", and `optimizing-skill-frontmatter`'s "Never write `disable-model-invocation: false`" — all stay because their failure modes are irreversible (a destroyed working tree, an unreviewed merge, source files written by a plan-authoring skill). Process reminders — "Run Steps 0–5 in strict order", Step 0 mutation-rationale sentences, per-step re-render pointers to the subroutine section already named above them — are dropped because a current model infers them from the surrounding context, and their presence costs tokens on every invocation.

**The premise was partially stale at execution time.** The spec was written before PRs #487 and #489 split these skills into cores plus reference files. Three of five targets had already shrunk roughly 80%: `ship-autonomous` from 2,448 to 597 words, `branch-agent` from 1,515 to 582, `optimizing-skill-frontmatter` from 3,153 to 579. Several named DROP targets were already gone, and the KEEP guard "Do not drop the stash before staging resolved files" had moved into `branch-agent/references/stash-and-recovery.md`. The real remaining DROP set was five items rather than 118, producing 7 insertions and 14 deletions across five files — the smallest return of the context-engineering set.

**Baselines are committed before the first edit.** The behavioral harness records structural facts per skill: `implementation-plan` writes nothing outside `docs/plans/`; `branch-agent`'s stash/pop returns every modified file with `git stash list` empty; `build` promotes `status:` to `completed` and creates only the file its plan named; `optimizing-skill-frontmatter` never emits `disable-model-invocation: false`; `ship-autonomous` leaves HEAD, branch, and working tree unchanged. Structural facts are the only assertions that stay trustworthy across model updates — prose output is nondeterministic. The harness exits 1 rather than skipping when the `claude` CLI is absent, because a harness that silently passes when it cannot run is worse than no harness.

**The objective test gates three independent failures.** Check 1: every `keep-phrases.txt` entry is found verbatim by `grep -F` in its named file — fails if any safety guard is accidentally removed. Check 2: each of the five `description:` frontmatter lines matches `tests/fixtures/imperative-baselines/descriptions.expected` — fails if a prune silently changes how a skill activates. Check 3: all five `.expected` manifests exist and are non-empty — fails if the baseline commit was skipped. Check 4: when the `claude` CLI is present, the behavioral harness must pass — fails if any pruned skill changes a load-bearing structural fact. The description comparison was changed from `git show origin/main:<path>` (correct for the PR, wrong as a permanent gate) to a committed golden file, so deliberate future changes to descriptions surface in review as an explicit file edit rather than a CI block with no clear path to pass.

**Two harness defects were found and fixed during execution.** The behavioral harness inherited stdin from its caller; in a non-interactive session stdin is a pipe nobody closes, causing the `claude` process to hang after exiting. Fixed by redirecting from `/dev/null`. The timeout watchdog subshell inherited stdout (the write end of a `scenario_fn | sort` pipe), orphaning a `sleep` that kept the descriptor open and blocking every run for the full `RUN_TIMEOUT` of 900 seconds. Fixed by closing the descriptor in the watchdog. A run that always takes fifteen minutes is a gate that gets switched off.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |
| `9277c9f` | 2026-09-18 | feat(git-agent): commit and ship paths handle lint-gate blocks (4.21.0) (#635) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `4f72700` | 2026-08-27 | feat(git-agent): add a context guard to ship-autonomous (#608) |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |

<!-- generated:end -->

## References

- Plan: [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
