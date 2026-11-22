# Add outcome-driven goal prompt to implementation plans

> Every generated HTML plan now renders a "Pursue as goal" prompt alongside the implement and workflow prompts, letting implementers optimize for the outcome rather than mechanically follow steps.

<!-- generated:start -->

**Status:** Shipped 2026-08-27 **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Added `<meta name="plan-goal" content="{goal-prompt}">` to `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html`.
- Rendered a collapsible `.plan-goal` `<details>` block (purple `--purple*` tokens) between the implement and workflow rows.
- Added a `copyGoal()` clipboard helper mirroring `copyWorkflow()`.
- Updated `implementation-plan/SKILL.md` to always compute `{goal-prompt}` in Step 2 and emit the meta tag in Step 3.
- Added a "Goal prompt" bullet to the plugin README, bumped `plan-agent` to `2.6.0`, and added a CHANGELOG entry.
- Added `tests/plugins/test-goal-prompt.sh` asserting the full contract (meta tag, markup, CSS, `copyGoal`, DOM order).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | HTML plan skeleton | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test | Created |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |

## How it works

The goal prompt is always present — no flag or complexity heuristic gates it. `implementation-plan` Step 2 computes `{goal-prompt}` from the plan's objective and path, and Step 3 always emits the `plan-goal` meta tag in the generated HTML.

The `.plan-goal` `<details>` block renders between the green implement row and the blue workflow block, using the existing `--purple*` CSS tokens for a visually distinct third framing. The `copyGoal()` function copies the prompt text to the clipboard, following the same pattern as `copyWorkflow()`.

The DOM order `implement → goal → workflow` is pinned by `test-goal-prompt.sh` check 5, ensuring a consistent reading flow in every generated plan. The CSS hides the goal row when the plan is `completed` or in print mode, matching the existing rules for the other rows.

## How to use it

The goal prompt appears automatically on every newly generated HTML plan. Click "Pursue as goal" to copy the prompt, then paste it into a new session to implement the plan outcome-first without being bound to the step order.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `87285986` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
