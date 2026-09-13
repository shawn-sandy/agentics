# Add outcome-driven goal prompt to implementation plans

> Adds an always-present `.plan-goal` row to every generated HTML plan, giving implementers an outcome framing alongside the strict implement and workflow prompts.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Added `<meta name="plan-goal" content="{goal-prompt}">` to `SKELETON.html` `<head>` — always emitted, no flag
- Added collapsible `.plan-goal` `<details>` block with purple `--purple*` CSS tokens, positioned between the implement row and the workflow block
- Added `copyGoal()` clipboard helper function mirroring the existing `copyWorkflow()` pattern
- Updated `implementation-plan` SKILL.md to always compute `{goal-prompt}` in Step 2 and always emit it in Step 3
- Documented `.plan-goal` in the HTML Output Requirements section of SKILL.md alongside always-present meta tags
- Bumped `plan-agent` to `2.6.0` in `marketplace.json` with a CHANGELOG entry
- Added `tests/plugins/test-goal-prompt.sh` with 6 assertions covering the skeleton and SKILL.md contract

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | Plan HTML template — meta tag, `.plan-goal` block, `copyGoal()` function | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill contract — `{goal-prompt}` computation in Step 2, `plan-goal` meta in Step 3 | Modified |
| `.claude-plugin/marketplace.json` | Plugin version registry — bumped to `2.6.0` | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — 6 assertions for goal prompt end-to-end contract | Created |

## How it works

Every generated plan already rendered two execution framings: an **implement prompt** (strict step-by-step execution) in green and a conditional **workflow prompt** (parallel subagent orchestration) in blue. Both are wired through three coordinated surfaces: a `<meta>` tag for machine consumption, a visible/collapsible row in the plan body, and a Step 2 placeholder computation in the SKILL.md contract.

The goal prompt adds a third framing — "Achieve this goal: … use the plan as reference, but optimize for the outcome" — as a first-class sibling using the same three-surface pattern. The key design choice is that the goal prompt is unconditional: unlike the workflow prompt (which is conditional), the goal prompt is always computed and always emitted regardless of plan complexity.

In `SKELETON.html`, the change adds three things. The `<meta name="plan-goal" content="{goal-prompt}">` tag appears in `<head>` alongside the existing implement and workflow meta tags. The `.plan-goal` `<details>` block appears in the plan body between the implement row (`.plan-implement`) and the workflow block (`.plan-workflow`), using CSS variables from the `--purple*` token family to distinguish it visually from green (implement) and blue (workflow). The `copyGoal(this)` clipboard helper function mirrors `copyWorkflow()` exactly, writing the goal text to the clipboard when the user clicks the copy button.

In SKILL.md, two steps were updated. Step 2 was extended to always compute `{goal-prompt}` — the outcome framing of the plan objective, worded as an instruction to pursue the result rather than follow the steps. Step 3 was extended to always emit the `plan-goal` meta tag. The HTML Output Requirements section documents `.plan-goal` as a required always-present element alongside `plan-implement`.

The DOM order `implement → goal → workflow` is preserved by the `<details>` block placement in the skeleton. The `test-goal-prompt.sh` smoke test asserts all six contract points: the meta tag in the skeleton, the `.plan-goal` markup with `id="goal-cmd"` and `onclick="copyGoal(this)"`, the CSS block, the `copyGoal` function, the DOM order, and the SKILL.md documentation of the derived prompt format.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
- Related docs: `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html`, `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md`
