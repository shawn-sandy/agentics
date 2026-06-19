---
status: completed
type: feature
created: 2026-06-18
modified: 2026-06-18
repo-name: agentics
---

# Plan: Add outcome-driven goal prompt to implementation plans

## Context

The `plan-agent:implementation-plan` skill renders two copy-paste prompts on every generated HTML plan: the always-present **implement prompt** (strict, in-session, step-by-step execution) and a conditional **workflow prompt** (parallel subagent orchestration via `/workflows`). Both are wired through three coordinated surfaces — a `<meta>` tag, a visible/collapsible row in the body, and a Step 2 placeholder computed from the objective + plan path + the canonical digest-extraction one-liner.

A third execution framing was missing: pursue the plan's *outcome* rather than mechanically follow its steps. This plan adds an **outcome-driven goal prompt** as a first-class sibling — "Achieve this goal: … use the plan as reference, but optimize for the outcome" — giving the implementer latitude to deviate when a better path to the same result exists.

## Objective

Add an always-present goal prompt to every generated HTML plan, wired through the same surfaces (meta tag, rendered row, Step 2 computation) as the implement and workflow prompts, and pin the contract with a smoke test.

## Steps

1. **Add the goal prompt to `reference/SKELETON.html`.** Insert `<meta name="plan-goal" content="{goal-prompt}">` in `<head>`, a collapsible `.plan-goal` `<details>` block (purple `--purple*` tokens) between the implement row and the workflow block, and a `copyGoal()` clipboard helper mirroring `copyWorkflow()`.
   - *Why:* The skeleton is the single source every plan is filled from; the prompt must live there to appear in all future plans.
   - *Verify:* `grep` confirms the meta tag, `.plan-goal` markup with `id="goal-cmd"` + `onclick="copyGoal(this)"`, the `.plan-goal` CSS block, and the `copyGoal` function are present.

2. **Update the `implementation-plan` SKILL.md contract.** Step 2 computes `{goal-prompt}` (always — no flag, no heuristic); Step 3 always emits the `plan-goal` meta tag; HTML Output Requirements list `plan-goal` among the always-present meta tags and document the `.plan-goal` element; re-anchor the workflow bullet below it.
   - *Why:* The skill body is what Claude follows when generating a plan; the skeleton change is inert unless the contract tells the model to compute and fill `{goal-prompt}`.
   - *Verify:* `grep` confirms `{goal-prompt}`, `plan-goal`, and `copyGoal(this)` appear in SKILL.md.

3. **Document and version the change.** Add a "Goal prompt" bullet to the plugin README, bump `plan-agent` `2.5.1 → 2.6.0` in `marketplace.json` with a description mention, and add a `2.6.0` CHANGELOG entry.
   - *Why:* Project convention requires a version bump + changelog + README update for every plugin change.
   - *Verify:* `marketplace.json` is valid JSON and reports `2.6.0`; README and CHANGELOG mention the goal prompt.

## Tests

> Tier: 1 (code-touching — modifies `SKELETON.html` and `SKILL.md`)

### Objective-Verification Test

- **File:** `tests/plugins/test-goal-prompt.sh`
- **Type:** smoke test
- **Asserts:** the goal prompt exists end-to-end — `plan-goal` meta tag, `.plan-goal` markup + `copyGoal()` wiring, `.plan-goal` CSS hidden when completed and in print, DOM order `implement → goal → workflow`, and the SKILL.md contract documenting it.
- **Run:** `bash tests/plugins/test-goal-prompt.sh`

Unit / integration / E2E sub-sections are omitted: the change is to a static HTML skeleton and a skill spec (no runtime functions, API surface, or user flow beyond the static render), so the shell smoke test fully covers the objective.

## Acceptance Criteria

- [x] Every newly generated HTML plan renders a `.plan-goal` row with the outcome-driven prompt.
- [x] The goal prompt is always present — no flag or complexity heuristic gates it.
- [x] `<meta name="plan-goal">` is always emitted.
- [x] `plan-agent` version is `2.6.0` in `marketplace.json` (higher than `main`'s `2.5.1`).
- [x] `test-goal-prompt.sh` passes (6/6) and the three sibling skeleton tests still pass.

## Verification

- Ran `bash tests/plugins/test-goal-prompt.sh` → 6/6 assertions pass; `test-plan-digest.sh`, `test-save-pdf.sh`, and `test-responsive-retrofit.sh` still pass (no regression).
- Rendered a filled sample in a browser: the purple "Pursue as goal" disclosure renders between the implement (green) and workflow (blue) rows; goal text correct; `copyGoal` wired; DOM order `implement → goal → workflow`; `plan-goal` meta present.

## Next Steps *(optional)*

- Surface the goal prompt as a Step 8 menu action:
  ```text
  In kit/plugins/plan-agent/skills/implementation-plan/SKILL.md, evaluate adding a "Pursue as goal" option to the Step 8 exit menu alongside "Implement now" / "Run as workflow". AskUserQuestion caps at 4 options and the menu already adaptive-swaps to stay under that cap, so propose how to fit a fourth action (e.g. fold it into the workflow slot, or gate it). Recommend one approach with reasoning before editing.
  ```
