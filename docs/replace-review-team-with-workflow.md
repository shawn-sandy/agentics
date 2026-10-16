# Replace review team with workflow

> Replaces the experimental Agent Teams dispatch in review-plan with a standard Workflow script, removes the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` gate, and adds a verify pass for high/critical findings.

<!-- generated:start -->

**Status:** Shipped 2026-09-01 **Plan:** [replace-review-team-with-workflow.md](plans/replace-review-team-with-workflow.md)
**Type:** refactor

## What shipped

- Replaced Agent Teams dispatch with `review-workflow.mjs`: a Workflow script that runs each review lens as a parallel agent.
- Removed the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` feature flag gate.
- Added a verify pass: findings rated high or critical get a second agent to confirm they're real before surfacing.
- Deleted `role-prompts.md` (only used by the Agent Teams flow).
- Created `tests/review-plan-workflow.test.mjs`.
- Bumped plan-agent to 9.12.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs` | Workflow script | Created |
| `kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md` | Role prompts | Deleted |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Skill core | Modified |
| `tests/review-plan-workflow.test.mjs` | Workflow tests | Created |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

The Agent Teams experimental feature required setting `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` before each session. This gate prevented `review-plan` from working for most users and would break when the experimental flag was removed. The Workflow script is GA and requires no flag.

`review-workflow.mjs` runs each review lens (product, security, frontend, technical feasibility) as parallel `agent()` calls in a Workflow. Parallel execution means all four lenses run simultaneously instead of sequentially, halving wall-clock time for a typical four-lens review.

The verify pass spawns a second agent for each finding rated high or critical: the verifier re-reads the relevant plan section with fresh context and either confirms the finding or dismisses it with a reason. This eliminates false-positive high/critical findings that would otherwise derail plan acceptance.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [replace-review-team-with-workflow.md](plans/replace-review-team-with-workflow.md)
