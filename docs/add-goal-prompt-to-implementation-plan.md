# Add outcome-driven goal prompt to implementation plans

> Adds an always-present goal prompt to every generated HTML plan, wired through the same meta tag, rendered row, and Step 2 computation surfaces as the implement and workflow prompts.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-goal-prompt-to-implementation-plan](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Added `<meta name="plan-goal" content="{goal-prompt}">` to the HTML plan skeleton
- Added a collapsible `.plan-goal` `<details>` block in purple (`--purple*` tokens) between the implement row and the workflow block
- Added `copyGoal()` clipboard helper mirroring `copyWorkflow()`
- Updated `implementation-plan/SKILL.md`: Step 2 always computes `{goal-prompt}`; Step 3 always emits the `plan-goal` meta tag
- Added `tests/plugins/test-goal-prompt.sh` with 6 assertions covering meta tag, markup, CSS, DOM order, and SKILL.md contract
- Bumped `plan-agent` to `2.6.0` with CHANGELOG entry and marketplace description update

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | HTML skeleton — goal prompt row, meta tag, CSS | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill contract — goal-prompt computation and emission | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — 6 assertions | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent 2.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — 2.6.0 entry | Modified |

## How it works

The goal prompt is a third execution framing alongside the implement prompt (strict step-by-step) and the workflow prompt (parallel subagent orchestration). Where the implement prompt says "follow these steps exactly", the goal prompt says "achieve this outcome — use the plan as reference but optimize for the outcome". This gives the implementer latitude to deviate from a step when a better path to the same result exists.

The `{goal-prompt}` placeholder is computed in `implementation-plan/SKILL.md` Step 2 using the plan's objective, plan path, and the canonical digest-extraction one-liner — the same inputs as the implement prompt. Computation is unconditional: no flag or complexity heuristic gates it, so every plan gets all three execution framings.

In the rendered HTML, the `.plan-goal` row sits between the green implement row and the blue workflow block, styled in purple to visually distinguish the three framings. The row collapses by default and exposes the goal text plus a `copyGoal(this)` button that copies to clipboard.

The `test-goal-prompt.sh` smoke test asserts the meta tag, `.plan-goal` markup with `id="goal-cmd"` and `onclick="copyGoal(this)"`, the CSS block, and the DOM order `implement → goal → workflow`.

## How to use it

The goal prompt appears automatically in every newly generated HTML plan. Click the purple "Pursue as goal" disclosure to copy it to the clipboard, then paste it as a fresh session prompt.

```
/plan-agent:implementation-plan <topic>   # generated plan includes goal prompt automatically
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan](plans/add-goal-prompt-to-implementation-plan.md)
