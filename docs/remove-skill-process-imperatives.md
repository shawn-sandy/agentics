# Earn Every NEVER — Baseline First, Then Prune

> Five skills carry 118 hard imperatives across 13,758 words, and most of them restate process the model already infers. We will know this worked when the pruned skills reproduce their recorded structural manifests exactly on the same fixed inputs, and every safety guard we classified as load-bearing is still literally present in its file.

<!-- generated:start -->

**Status:** Shipped 2026-07-30  **Plan:** [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
**Type:** refactor

## What shipped

- Classified all 118 imperatives across five target SKILL.md files as KEEP or DROP using the discriminator "violating it silently fails expensively," and wrote the KEEP set to `tests/fixtures/imperative-baselines/keep-phrases.txt` as machine-checkable `<skill path>\t<literal phrase>` lines.
- Built a behavioral baseline harness (`tests/plugins/test-skill-behavior-baselines.sh`) with fixed-input scenarios per skill, recording structural manifests (files written, gates fired, refusals emitted) rather than prose output, for use as a pre-prune green reference point.
- Made the harness exit 1 with an explicit error when the `claude` CLI is absent, preventing silent skips that turn a red gate green.
- Wrote the objective test `tests/plugins/test-imperative-pruning.sh` asserting four things: every KEEP phrase is present, each `description:` line is byte-identical to the golden file, all five `.expected` manifests exist, and the behavioral harness passes when the CLI is available. Wired it into `.github/workflows/check-plugin-versions.yml`.
- Committed the classification, scenarios, manifests, harness, and tests as a single pre-prune commit touching no plugin files — establishing the green reference before any imperative was removed.
- Pruned DROP-classified imperatives from all five SKILL.md files: removed plan-mode rationale sentences, per-step re-render reminders, ordering restatements, and duplicate stopping rules — while leaving every KEEP guard (merge-on-green, stash guards, scope constraint, disable-model-invocation prohibition) literally intact.
- Bumped `plan-agent` to 7.2.0, `git-agent` to 4.9.0, and `skill-reviewer` to 2.4.0 (targets were superseded by concurrent PRs; the shipped versions are higher than those specified in the plan).

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `tests/fixtures/imperative-baselines/keep-phrases.txt` | Classification contract — KEEP phrases per skill path | Created |
| `tests/fixtures/imperative-baselines/` | Scenario inputs and structural manifests per skill | Created |
| `tests/plugins/test-skill-behavior-baselines.sh` | Behavioral harness — runs skills headless against fixed scenarios | Created |
| `tests/plugins/test-imperative-pruning.sh` | Objective test — checks KEEP phrases, description stability, manifests, harness | Created |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill — process reminders pruned, gate guards retained | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill — process reminders pruned, Scope Constraint intact | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Skill — ordering prose pruned, merge and branch-deletion guards retained | Modified |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Skill — duplicate ordering text pruned, stash and no-force guards retained | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | Skill — process reminders pruned, disable-model-invocation prohibition retained | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — three plugin version bumps | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — version entry with prune summary | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Plugin changelog — version entry with prune summary | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Plugin changelog — version entry with prune summary | Modified |
| `.github/workflows/check-plugin-versions.yml` | CI workflow — new step running `test-imperative-pruning.sh` | Modified |

## How it works

Anthropic's context-engineering guidance makes judgment over rules the primary principle for Claude 5 generation models: they removed 80%+ of Claude Code's own system prompt with no measurable loss. The catch is that they had behavioral evals. This plan applies the same discipline: classify before cutting, record baselines before editing, and treat a failed baseline as a reason to restore an imperative rather than debug further.

The classification step produced `tests/fixtures/imperative-baselines/keep-phrases.txt`, where each line is a tab-separated `<skill-path>\t<literal phrase>`. Only guards where violation fails silently and expensively made the KEEP list — the merge-on-green guard, the `--delete-branch` guard (which wraps across a line so only the greppable fragment was recorded), the review-dismissal guard, both stash guards, the `## Scope Constraint — Plans Only` block (forbidding an implementation-plan skill from writing source files), the never-hand-edit-the-HTML rule, and the `disable-model-invocation: false` prohibition. Everything else was classified DROP: step-ordering reminders, plan-mode rationale sentences, per-step re-render callouts, and duplicate stopping clauses.

Baselines were recorded with `tests/plugins/test-skill-behavior-baselines.sh --record` against the unmodified skills, committed as a standalone commit (`ed6b854`) that touched no plugin file, and then independently reproduced 5/5. Each scenario runs the skill headless via `claude -p` against a fixed input — a known `todo` plan spec for `build`, a known objective for `implementation-plan`, a throwaway `git init` sandbox for the git-agent skills, a fixture SKILL.md for `optimizing-skill-frontmatter` — and records only structural facts: files written and their paths, gates that fired, refusals emitted. Prose is excluded because it is nondeterministic; structural outcomes are not.

The pruning itself was seven insertions and fourteen deletions across five files. Several named DROP targets had already been removed in prior PRs (#487, #489) that split these skills into cores and references — at implementation time, three of the five targets had shrunk ~80% from the word counts the plan measured. The real DROP set was five items, not the originally counted remainder of 118. The plan's own "honest accounting" section had predicted the smallest token return of the set; the true figure was smaller still.

The objective test `tests/plugins/test-imperative-pruning.sh` is wired into CI and serves as the permanent gate: it checks every KEEP phrase via `grep -F`, compares each `description:` line against `tests/fixtures/imperative-baselines/descriptions.expected` (not `origin/main`, to allow deliberate future changes without breaking CI), asserts all five manifests exist and are non-empty, and invokes the behavioral harness when the `claude` CLI is present. A falsifiability check confirmed the test exits 1 when the merge-on-green guard is deleted and exits 1 when a `description:` line is modified by one character.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
