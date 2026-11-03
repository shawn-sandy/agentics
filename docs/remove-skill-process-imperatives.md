# Remove process-reminder imperatives from skills

> Prunes DROP-classified process-reminder imperatives from five SKILL.md files after establishing behavioral baselines first, keeping every safety and scope guard intact.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [remove-skill-process-imperatives](plans/remove-skill-process-imperatives.md)
**Type:** refactor

## What shipped

- Established behavioral baseline tests for all five target SKILL.md files before making any changes (red-green pattern)
- Pruned DROP-classified process-reminder imperatives from five SKILL.md files: `implementation-plan`, `finalize-plan`, `review-plan`, `create-branch`, and `ship-it`
- Retained all safety, scope, and irreversibility guards: NEVER-merge-on-non-green, stash guards, scope constraint annotations
- Created `tests/plugins/test-skill-behavior-baselines.sh` capturing the behavioral contracts each skill must still satisfy post-prune
- Created `tests/plugins/test-imperative-pruning.sh` verifying the specific imperatives that were removed are absent from the files
- Wired `test-imperative-pruning.sh` into `.github/workflows/check-plugin-versions.yml` so re-additions are caught in CI
- Bumped plan-agent to 7.2.0, git-agent to 4.9.0, skill-reviewer to 2.4.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill — DROP imperatives removed | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill — DROP imperatives removed | Modified |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Skill — DROP imperatives removed | Modified |
| `kit/plugins/git-agent/skills/create-branch/SKILL.md` | Skill — DROP imperatives removed | Modified |
| `kit/plugins/git-agent/skills/ship-it/SKILL.md` | Skill — DROP imperatives removed | Modified |
| `tests/plugins/test-skill-behavior-baselines.sh` | Smoke test — behavioral contracts | Created |
| `tests/plugins/test-imperative-pruning.sh` | Smoke test — removed imperatives absent | Created |
| `.github/workflows/check-plugin-versions.yml` | CI — pruning test added | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — version bumps | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — 7.2.0 | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release history — 4.9.0 | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Release history — 2.4.0 | Modified |

## How it works

Process-reminder imperatives are phrases like "remember to", "make sure you", "always check", "don't forget" — instructions that remind the model to do something it would do anyway as part of correct execution. A skill audit identified 118 candidate phrases across the codebase; after filtering for DROP classification (imperatives that are redundant with base model behavior and add noise without adding constraint), five files carried imperatives worth removing.

The actual count of removed items was five, not 118: the audit's candidate list included many phrases that on closer inspection were either scope constraints ("never merge on non-green CI"), irreversibility guards ("stash untracked files before checkout"), or non-process behavioral rules. Those were all kept. Only phrases that were genuinely redundant with default model behavior — and that a future reader would recognize as noise — were dropped.

The baseline-first approach: `test-skill-behavior-baselines.sh` was written and run against the current (pre-prune) files to establish what each skill's outputs must look like. Only once the tests passed on the unchanged files were the imperatives pruned. `test-imperative-pruning.sh` then ran against the pruned files to confirm the target phrases are gone. This red-green pattern means the test suite distinguishes "safe prune" from "accidental behavior removal".

`test-imperative-pruning.sh` joins CI in `check-plugin-versions.yml` so any future addition of the pruned phrases to these files fails the pipeline before merge. The list of removed phrases is embedded in the test as negative assertions, making it self-documenting.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [remove-skill-process-imperatives](plans/remove-skill-process-imperatives.md)
