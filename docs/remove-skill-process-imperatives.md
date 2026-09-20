# Earn every NEVER — baseline first, then prune

> Five skills carry 118 hard imperatives across 13,758 words, and most of them restate process the model already infers. We will know this worked when the prun...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
**Type:** refactor

## What shipped

- Classify every one of the 118 imperatives in the five target SKILL.md files as KEEP or DROP using the discriminator "...
- Build `tests/plugins/test-skill-behavior-baselines.sh` plus `tests/fixtures/imperative-baselines/scenarios/`, giving...
- Make the harness exit 1 with `claude CLI not found — behavioral baselines cannot be skipped` when the CLI is absent,...
- Write the objective test `tests/plugins/test-imperative-pruning.sh` asserting four things — every `keep-phrases.txt`...
- Commit the classification, scenarios, recorded manifests, harness, objective test, and workflow wiring as one commit...
- Prune the DROP-classified imperatives from `kit/plugins/plan-agent/skills/build/SKILL.md` and `kit/plugins/plan-agent...
- Prune the DROP-classified imperatives from `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` and `kit/plugins/g...
- Prune the DROP-classified imperatives from `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md`...
- Bump `plan-agent` to 5.1.0, `git-agent` to 4.8.0, and `skill-reviewer` to 2.3.0 in `.claude-plugin/marketplace.json`,...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `docs/plans/remove-skill-process-imperatives.md` | this spec | Created |
| `tests/fixtures/imperative-baselines/keep-phrases.txt` | the committed KEEP classification: one literal guard phra... | Created |
| `tests/fixtures/imperative-baselines/*.expected` | recorded structural manifests, one per target skill | Created |
| `tests/plugins/test-skill-behavior-baselines.sh` | local-only behavioral harness; runs each skill headless a... | Created |
| `tests/plugins/test-imperative-pruning.sh` | objective test; CI-wired structural gate | Created |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | prune process reminders, keep gate guards | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | prune process reminders, keep `## Scope Constraint — Plan... | Modified |
| `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | prune process reminders, keep merge and branch-deletion g... | Modified |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | prune duplicate ordering text, keep stash and no-force gu... | Modified |
| `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` | prune process reminders, keep the `disable-model-invocati... | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 5.0.0 → 5.1.0, git-agent 4.7.0 → 4.8.0, skill-... | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 5.1.0 entry | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.8.0 entry | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | 2.3.0 entry | Modified |
| `.github/workflows/check-plugin-versions.yml` | add a step running `bash tests/plugins/test-imperative-pr... | Modified |

## How it works

Remove process-reminder imperatives from the five most over-constrained SKILL.md files in `plan-agent`, `git-agent`, and `skill-reviewer`, but only after each skill's behavior is captured as a committed, passing baseline test that proves the pruning changed nothing that matters.

Anthropic's "The new rules of context engineering for Claude 5 generation models" makes Rule 1 — judgment over rules — the headline: they removed 80%+ of Claude Code's system prompt with no measurable loss. The catch is the part that does not travel: they had evals. Removing constraints with "it still looks fine" as the verification is precisely how a silent regression ships, and the regressions in this repo are not cosmetic. `git-agent:ship-autonomous` ends in an irreversible squash merge. `pla...

The implementation proceeded through these steps: Classify every one of the 118 imperatives in the five target SKILL.md files as KEEP or DROP using the discriminator "...; Build `tests/plugins/test-skill-behavior-baselines.sh` plus `tests/fixtures/imperative-baselines/scenarios/`, giving ...; Make the harness exit 1 with `claude CLI not found — behavioral baselines cannot be skipped` when the CLI is absent, ...; Write the objective test `tests/plugins/test-imperative-pruning.sh` asserting four things — every `keep-phrases.txt` ...; Commit the classification, scenarios, recorded manifests, harness, objective test, and workflow wiring as one commit ....

All nine steps ran and all ten acceptance criteria hold. The entries below record what diverged from the spec, rather than absorbing it silently. - Premise stale, contract intact — this spec was written before PRs #487/#489 split these skills into cores plus references. Re-measured at implementation

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
