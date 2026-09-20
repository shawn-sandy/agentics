# Add outcome-driven goal prompt to implementation plans

> Add an always-present goal prompt to every generated HTML plan, wired through the same surfaces (meta tag, rendered row, Step 2 computation) as the implement...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Add the goal prompt to `reference/SKELETON.html`. — Insert `<meta name="plan-goal" content="{goal-prompt}">` in `<hea...
- Update the `implementation-plan` SKILL.md contract. — Step 2 computes `{goal-prompt}` (always — no flag, no heuristic...
- Document and version the change. — Add a "Goal prompt" bullet to the plugin README, bump `plan-agent` `2

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `(see plan)` | — | — |

## How it works

Add an always-present goal prompt to every generated HTML plan, wired through the same surfaces (meta tag, rendered row, Step 2 computation) as the implement and workflow prompts, and pin the contract with a smoke test.

The `plan-agent:implementation-plan` skill renders two copy-paste prompts on every generated HTML plan: the always-present **implement prompt** (strict, in-session, step-by-step execution) and a conditional **workflow prompt** (parallel subagent orchestration via `/workflows`). Both are wired through three coordinated surfaces — a `<meta>` tag, a visible/collapsible row in the body, and a Step 2 placeholder computed from the objective + plan path + the canonical digest-extraction one-liner. A th...

The implementation proceeded through these steps: Add the goal prompt to `reference/SKELETON.html`.: Insert `<meta name="plan-goal" content="{goal-prompt}">` in `<head...; Update the `implementation-plan` SKILL.md contract.: Step 2 computes `{goal-prompt}` (always — no flag, no heuristic)...; Document and version the change.: Add a "Goal prompt" bullet to the plugin README, bump `plan-agent` `2.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
