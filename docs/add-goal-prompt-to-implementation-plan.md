# Add outcome-driven goal prompt to implementation plans

> Add an always-present goal prompt to every generated HTML plan, wired through the same surfaces (meta tag, rendered row, Step 2 computation) as the implement...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Add the goal prompt to `reference/SKELETON.html`. — Insert `<meta name="plan-goal" content="{goal-prompt}">` in `<head>`, a collapsible `.plan-goal` `<details>` block (purple `--purple*` tokens) between the implement row and the workflow block, and a `copyGoal()` clipboard helper mirroring `copyWorkflow()`. -
- Update the `implementation-plan` SKILL.md contract. — Step 2 computes `{goal-prompt}` (always — no flag, no heuristic); Step 3 always emits the `plan-goal` meta tag; HTML Output Requirements list `plan-goal` among the always-present meta tags and document the `.plan-goal` element; re-anchor the workflow bullet below it. -
- Document and version the change. — Add a "Goal prompt" bullet to the plugin README, bump `plan-agent` `2.5.1 → 2.6.0` in `marketplace.json` with a description mention, and add a `2.6.0` CHANGELOG entry. -

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `reference/SKELETON.html` | Source file | Modified |
| `marketplace.json` | Marketplace entry | Modified |

## How it works

Add an always-present goal prompt to every generated HTML plan, wired through the same surfaces (meta tag, rendered row, Step 2 computation) as the implement and workflow prompts, and pin the contract with a smoke test.

The `plan-agent:implementation-plan` skill renders two copy-paste prompts on every generated HTML plan: the always-present **implement prompt** (strict, in-session, step-by-step execution) and a conditional **workflow prompt** (parallel subagent orchestration via `/workflows`). Both are wired through three coordinated surfaces — a `<meta>` tag, a visible/collapsible row in the body, and a Step 2 placeholder computed from the objective + plan path + the canonical digest-extraction one-liner. A third execution framing was missing: pursue the plan's *outcome* rather than mechanically follow its steps. This plan adds an **outcome-driven goal prompt** as a first-class sibling — "Achieve this goal: … use the plan as reference, but optimize for the outcome" — giving the implementer latitude to deviate when a better path to the same result exists.

The implementation proceeded through the following steps: Add the goal prompt to `reference/SKELETON.html`.: Insert `<meta name="plan-goal" content="{goal-prompt}">` in `<head>`, a collapsible `; Update the `implementation-plan` SKILL.md contract.: Step 2 computes `{goal-prompt}` (always — no flag, no heuristic); Step 3 always emits the `plan-goal` meta tag; HTML Output Requirements list `plan-goal` among the always-present meta tags and document the `; Document and version the change.: Add a "Goal prompt" bullet to the plugin README, bump `plan-agent` `2.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
