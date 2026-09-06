# Earn every NEVER — baseline first, then prune

> Removed process-reminder imperatives from the five most over-constrained SKILL.md files in `plan-agent`, `git-agent`, and `skill-reviewer`, after committing behavioral baselines that proved the pruning changed nothing load-bearing.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
**Type:** refactor

## What shipped

- Classified all 118 imperatives across the five target skills as KEEP or DROP using the discriminator "violating it fails silently and expensively", and wrote the KEEP set to `tests/fixtures/imperative-baselines/keep-phrases.txt` as machine-checkable `<skill path>\t<literal phrase>` pairs.
- Built `tests/plugins/test-skill-behavior-baselines.sh` with per-skill fixed-input scenarios and structural (not prose) baselines — file paths written, gates fired, refusals emitted — and confirmed the harness exits 1 rather than skipping when the `claude` CLI is absent.
- Wrote the objective test `tests/plugins/test-imperative-pruning.sh` asserting four things: every KEEP phrase is present, each `description:` line is byte-identical to the baseline, all five `.expected` manifests exist, and the behavioral harness passes when the CLI is available.
- Committed the classification, scenarios, recorded manifests, harness, and objective test as one commit that touched no file under `kit/plugins/` (making it the unambiguous green reference point).
- Pruned DROP-classified imperatives from all five skills: removed Step 0 plan-mode rationale sentences, per-step re-render reminders, the `branch-agent` duplicate ordering sentence, and `optimizing-skill-frontmatter`'s "Follow these steps exactly" and "Count carefully"; retained every KEEP guard verbatim.
- Wired `test-imperative-pruning.sh` into `.github/workflows/check-plugin-versions.yml` as a named step.
- Bumped plan-agent, git-agent, and skill-reviewer in `.claude-plugin/marketplace.json` (shipped as plan-agent 7.2.0, git-agent 4.9.0, skill-reviewer 2.4.0 — the spec's target versions were already met or exceeded on `main`) and added CHANGELOG entries naming the baselines.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `tests/fixtures/imperative-baselines/keep-phrases.txt` | KEEP classification — one literal guard phrase per line with skill path prefix | Created |
| `tests/plugins/test-skill-behavior-baselines.sh` | Local-only behavioral harness; exits 1 when `claude` CLI is absent | Created |
| `tests/plugins/test-imperative-pruning.sh` | CI-wired structural gate — asserts KEEP phrases, description stability, and baseline existence | Created |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Pruned: Step 0 plan-mode rationale, Step 2 spec-edits aside, per-step re-render reminders; KEEP guards intact | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Pruned: plan-mode mutation rationale, Step 4 Rename restatement; `## Scope Constraint — Plans Only` untouched | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Pruned: "Run Steps 0–5 in strict order"; merge-on-green, `--delete-branch`, review-dismissal guards retained | Modified |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Pruned: "Follow these steps in strict order." opening and Step 0 mutation rationale; stash and no-force guards retained | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Pruned: "Follow these steps exactly", "Count carefully", Step 0 plan-mode rationale; `disable-model-invocation: false` prohibition retained | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI — new step running `test-imperative-pruning.sh` | Modified |
| `.claude-plugin/marketplace.json` | Version bumps: plan-agent 7.2.0, git-agent 4.9.0, skill-reviewer 2.4.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.2.0 release entry | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.9.0 release entry | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | 2.4.0 release entry | Modified |

## How it works

The plan's sequencing is itself the safety mechanism. Baselines were captured and committed — touching no shipped plugin file — before a single imperative was removed. This ordering is what makes a later behavioral divergence a regression rather than model nondeterminism.

Step 1 produced `keep-phrases.txt` by applying the central discriminator to all 118 imperatives: keep a constraint only if violating it fails silently and expensively. Guards retained include `ship-autonomous`'s "Never merge on anything but green", the `--delete-branch` guard phrased as "never pass that flag on the strength of a merge", "Never dismiss a review on your own initiative", `branch-agent`'s "Do not retry. Do not force." and its stash guard, `implementation-plan`'s entire `## Scope Constraint — Plans Only` block, `build`'s gate guards, and `optimizing-skill-frontmatter`'s "Never write `disable-model-invocation: false`". Process scaffolding — ordering sentences, plan-mode rationale text, step re-render reminders — was classified as DROP.

Steps 2 and 3 built the behavioral harness. Each skill received one fixed-input scenario: a known plan spec for `build`, a known objective for `implementation-plan`, a throwaway `git init` sandbox for the two git skills (dry-running to the pre-flight guard only), and a known SKILL.md copy for `optimizing-skill-frontmatter`. The harness records only structural facts — files written and their paths, gates fired, refusals emitted — never prose wording, which is nondeterministic. A critical detail: the harness stdin was redirected from `/dev/null` to prevent headless runs from blocking on an inherited pipe, and the timeout watchdog was fixed to avoid holding the manifest pipe open for the full 900-second timeout.

Step 4 wrote `test-imperative-pruning.sh` as the single command a reviewer runs to decide whether the prune was safe. It asserts: every `keep-phrases.txt` entry is found verbatim by `grep -F` in its named file; each `description:` frontmatter line matches the golden file at `tests/fixtures/imperative-baselines/descriptions.expected` (not `origin/main`, which would block all future description updates); all five `.expected` manifests exist and are non-empty; and the behavioral harness passes when the CLI is available.

Steps 6 through 8 performed the actual pruning in plugin order. The Completion Report documents that the spec's pre-split word counts were already stale — `ship-autonomous` had shrunk from 2,448 to 597 words due to earlier refactors — so the real DROP set was five items producing 7 insertions and 14 deletions across five files, not the 118 originally counted. The abort condition (restore any imperative whose removal cannot be explained within one fix attempt) was never invoked. Behavioral baselines were reproduced 5/5 both before and after the prune.

## How to use it

The objective gate runs as part of CI:

```bash
bash tests/plugins/test-imperative-pruning.sh
```

Expected output: exit 0 with a per-skill line for all five targets and a `baselines: 5/5 match` summary. To confirm the gate is not a tautology, delete the merge-on-green guard line from `ship-autonomous/SKILL.md` and re-run — it must exit 1 naming that phrase. Restore with `git checkout -- <path>` and the test returns to green.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |

<!-- generated:end -->

## References

- Plan: [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
