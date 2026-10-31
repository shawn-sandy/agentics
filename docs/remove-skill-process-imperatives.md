# Remove process-reminder imperatives from skills

> Prunes "always do X" and "never do Y" process-reminder language from five skills whose behavioral tests showed the imperatives were over-constraining without improving outcomes.

<!-- generated:start -->

**Status:** Shipped 2026-07-30 **Plan:** [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
**Type:** refactor

## What shipped

- Removed process-reminder imperatives from 5 skills across plan-agent, git-agent, and skill-reviewer.
- Added behavioral baseline tests with recorded manifests to verify no behavioral regression.
- Bumped plan-agent to 7.2.0, git-agent to 4.9.0, skill-reviewer to 2.4.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/` (multiple) | Skill instructions | Modified |
| `kit/plugins/git-agent/skills/` (multiple) | Skill instructions | Modified |
| `kit/plugins/skill-reviewer/skills/` (multiple) | Skill instructions | Modified |
| `tests/plugins/test-skill-behavior-baselines.sh` | Behavioral test | Created |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

Process-reminder imperatives — phrases like "Always commit in small increments", "Never modify files outside your scope", "Remember to check X before Y" — were added to skills over time to correct observed bad behaviors. Over-accumulated, they become noise: the model reads them but they contribute more words than guidance.

The behavioral baseline approach: before removing any imperative, a test records the manifest of what the skill actually does in representative scenarios (its "behavioral baseline"). Removal is safe when the baseline stays the same — the imperative was redundant with the model's natural behavior. If the baseline changes, the imperative was load-bearing and stays.

The actual DROP set was 5 items, not the 118 implied by an earlier scan — previous skill splits had already reduced the raw count considerably. The real question for each imperative was: does removing it change what the skill does? For these 5, it did not.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [remove-skill-process-imperatives.md](plans/remove-skill-process-imperatives.md)
