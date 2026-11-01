# Earn every NEVER — baseline first, then prune

> Pruned process-reminder imperatives from five over-constrained skills after capturing behavioral baselines, with explicit abort conditions for any regression.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
**Type:** refactor

## What shipped

- Classified all 118 imperatives across five target SKILL.md files (`build`, `implementation-plan`, `ship-autonomous`, `branch-agent`, `optimizing-skill-frontmatter`) as KEEP or DROP, writing the KEEP set to `tests/fixtures/imperative-baselines/keep-phrases.txt` as machine-checkable data (one literal guard phrase per file path).
- Built a behavioral baseline harness (`tests/plugins/test-skill-behavior-baselines.sh`) plus fixed scenario inputs under `tests/fixtures/imperative-baselines/scenarios/`, running each skill headless and recording structural facts (files written, gates fired, refusals emitted) as `.expected` manifests.
- Added an objective test (`tests/plugins/test-imperative-pruning.sh`) asserting every KEEP phrase is present, every `description:` line is byte-identical to its golden file, and all five baselines exist and are non-empty.
- Pruned the DROP-classified imperatives (process scaffolding, step-ordering reminders, redundant plan-mode rationales) from all five files while leaving every safety, scope, and irreversibility guard intact.
- Bumped `plan-agent` to 7.2.0, `git-agent` to 4.9.0, and `skill-reviewer` to 2.4.0 (version targets in the plan were stale; see Completion Report in the plan file).
- Wired `test-imperative-pruning.sh` into `.github/workflows/check-plugin-versions.yml`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `tests/fixtures/imperative-baselines/keep-phrases.txt` | Test data — KEEP classification, one phrase per skill path | Created |
| `tests/fixtures/imperative-baselines/scenarios/` | Test data — fixed inputs per skill for headless runs | Created |
| `tests/fixtures/imperative-baselines/*.expected` | Test data — recorded structural manifests (5 files) | Created |
| `tests/plugins/test-skill-behavior-baselines.sh` | Local behavioral harness | Created |
| `tests/plugins/test-imperative-pruning.sh` | Objective CI test | Created |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill — DROP-classified imperatives removed | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill — DROP-classified imperatives removed | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Skill — DROP-classified imperatives removed | Modified |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Skill — DROP-classified imperatives removed | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Skill — DROP-classified imperatives removed | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — version bumps | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — 7.2.0 entry | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Plugin changelog — 4.9.0 entry | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Plugin changelog — 2.4.0 entry | Modified |

## How it works

The key insight is that imperatives fall into two categories: safety guards (violating them fails silently and expensively) and process scaffolding (step-ordering reminders, plan-mode rationales, redundant restatements). The plan kept all safety guards — things like "Never merge on anything but green", `branch-agent`'s stash guards, and `implementation-plan`'s `## Scope Constraint — Plans Only` block — and dropped scaffolding text the model already infers from surrounding steps.

Baselines were established *before* any edit. The harness runs each skill headless against a fixed scenario and records structural facts only (not prose), making the baseline trustworthy even months later. The commit landing baselines (`ed6b854`) touches no plugin file — it is the green reference point every later step is compared against.

By the time this plan ran, three of the five target files had already shrunk ~80% from an earlier PR (#487/#489), so the actual DROP set was five items across five files (7 insertions, 14 deletions), far smaller than the 118-imperative premise.

The harness itself required two defect fixes: a stdin inheritance issue that caused headless runs to wedge, and a watchdog subshell that kept a pipe open and pinned every run to the full 900-second timeout. Both are corrected in the shipped version.

## How to use it

```bash
# Run the objective test (CI gate)
bash tests/plugins/test-imperative-pruning.sh

# Run the behavioral harness locally (requires claude CLI)
bash tests/plugins/test-skill-behavior-baselines.sh

# Run it without the claude CLI to prove it cannot silently skip
PATH=/usr/bin:/bin bash tests/plugins/test-skill-behavior-baselines.sh
# → exits 1 with "claude CLI not found"
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
