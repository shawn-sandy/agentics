# Add outcome-driven goal prompt to implementation plans

> Adds an always-present goal prompt to every generated HTML plan — "Achieve this goal: …" — wired through the same meta tag, rendered row, and clipboard button as the implement and workflow prompts.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Added `<meta name="plan-goal" content="{goal-prompt}">` to `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` (now `SKELETON.md`) in `<head>`.
- Added a collapsible `.plan-goal` `<details>` block with purple `--purple*` CSS tokens between the implement row and the workflow block, with a `copyGoal()` clipboard helper mirroring `copyWorkflow()`.
- Updated `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md`: Step 2 now always computes `{goal-prompt}` (no flag, no complexity heuristic), Step 3 always emits the `plan-goal` meta tag, and the HTML Output Requirements list `plan-goal` among the always-present meta tags.
- Bumped `plan-agent` to `2.6.0` in `.claude-plugin/marketplace.json` with a README note and `2.6.0` CHANGELOG entry.
- Added `tests/plugins/test-goal-prompt.sh` with 6 assertions covering the meta tag, `.plan-goal` markup, `copyGoal` wiring, DOM order, and CSS.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | HTML skeleton template — plan-goal meta and markup | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions — goal-prompt computation and emission | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — 6 assertions | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry — plan-agent 2.6.0 | Modified |

## How it works

Every generated HTML plan previously offered two execution framings: the implement prompt (strict step-by-step) and the workflow prompt (parallel subagent orchestration, gated on file/directory count). The goal prompt adds a third: "Achieve this goal: `{title}`. Use the plan as reference, but optimize for the outcome." This framing explicitly gives the implementer latitude to deviate when a better path to the same result exists.

The three prompts are wired through parallel surfaces: a `<meta>` tag in `<head>` for programmatic consumption, a visible collapsible row in the plan body for the human reader, and a clipboard copy button for one-click use. The goal prompt row uses purple CSS tokens (`--purple*`) to distinguish it visually from the green implement row and blue workflow row.

The `SKELETON.html`/`SKELETON.md` is the single source every plan is generated from, so adding the markup there guarantees the prompt appears in all future plans. The SKILL.md contract change ensures the model computes and fills `{goal-prompt}` during generation — the skeleton change alone would produce an unfilled placeholder.

The DOM order constraint (`implement → goal → workflow`) is asserted by the smoke test, which also checks that `.plan-goal` is hidden in print media and when the plan has `status: completed`, so it does not appear in printed plan documents.

## How to use it

The goal prompt is always present on every generated plan — there is no flag to enable it. When viewing a plan HTML artifact, a purple "Pursue as goal" disclosure row appears between the green "Implement now" row and the blue "Run as workflow" row. Clicking "Copy goal prompt" places the outcome-driven prompt on the clipboard for use as a Claude session starter.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
