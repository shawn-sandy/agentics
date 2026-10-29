# Add outcome-driven goal prompt to implementation plans

> Adds an always-present goal prompt to every generated HTML plan, giving implementers latitude to pursue the plan's outcome rather than follow its steps mechanically.

<!-- generated:start -->

**Status:** Shipped 2026-06-18 **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Added an `<meta name="plan-goal">` tag and a `.plan-goal` `<details>` block (purple theme) to every generated HTML plan between the implement row and the workflow block.
- Authored a `copyGoal()` clipboard helper mirroring `copyWorkflow()`, so the goal prompt is one-click copyable.
- Updated `implementation-plan` SKILL.md to always compute `{goal-prompt}` (no flag or heuristic gates it) and emit the `plan-goal` meta tag.
- Bumped `plan-agent` to `2.6.0` in `marketplace.json` with a matching CHANGELOG entry.
- Added `tests/plugins/test-goal-prompt.sh` pinning the skeleton contract (6/6 assertions).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | HTML plan skeleton | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test | Created |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

The plan skeleton (`SKELETON.html`) was the single source every HTML plan is filled from, so the goal prompt meta tag and collapsible block had to land there. A `<meta name="plan-goal" content="{goal-prompt}">` tag was inserted in `<head>`, and a `.plan-goal` `<details>` block using the `--purple*` color tokens was inserted between the implement row and the workflow block.

The SKILL.md contract tells the model to compute `{goal-prompt}` unconditionally in Step 2, always emit the `plan-goal` meta tag in Step 3, and list `plan-goal` among the always-present meta tags in the HTML Output Requirements. This makes the goal prompt a first-class sibling of the implement and workflow prompts.

The smoke test (`test-goal-prompt.sh`) asserts the meta tag, `.plan-goal` markup with `id="goal-cmd"` and `onclick="copyGoal(this)"`, the `.plan-goal` CSS block, and the `copyGoal` function are all present in SKELETON.html — catching any future skeleton edit that drops them.

## How to use it

Invoke `/plan-agent:implementation-plan` as usual. Every generated HTML plan now renders a purple "Pursue as goal" disclosure row between the green implement row and the blue workflow row. Clicking the copy button delivers the goal prompt — "Achieve this goal: … use the plan as reference, but optimize for the outcome."

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
- Changelog: [plan-agent CHANGELOG v2.6.0](../kit/plugins/plan-agent/CHANGELOG.md)
