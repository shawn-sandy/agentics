# Add outcome-driven goal prompt to implementation plans

> Every generated HTML plan now renders a third execution prompt — "Achieve this goal" — wired through the same meta tag, visible row, and Step 2 computation as the implement and workflow prompts.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [add-goal-prompt-to-implementation-plan](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- `<meta name="plan-goal" content="{goal-prompt}">` added to every generated HTML plan's `<head>`
- A collapsible `.plan-goal` `<details>` block rendered between the implement row and the workflow block, styled in purple (`--purple*` tokens)
- `copyGoal()` clipboard helper mirroring the existing `copyWorkflow()` function
- `implementation-plan` SKILL.md updated: Step 2 always computes `{goal-prompt}`, Step 3 always emits the `plan-goal` meta tag, HTML Output Requirements list `plan-goal` among always-present tags
- `plan-agent` bumped `2.5.1 → 2.6.0` with CHANGELOG entry and README update
- Smoke test `tests/plugins/test-goal-prompt.sh` added (6 assertions)

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | HTML skeleton — `plan-goal` meta tag, `.plan-goal` details block, `copyGoal()` helper, CSS tokens | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill contract — `{goal-prompt}` computation in Step 2, `plan-goal` meta in Step 3, HTML Output Requirements updated | Modified |
| `.claude-plugin/marketplace.json` | `plan-agent` 2.5.1 → 2.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | `[2.6.0]` entry | Modified |
| `kit/plugins/plan-agent/README.md` | "Goal prompt" bullet added | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — 6 assertions covering meta tag, markup, CSS, DOM order, SKILL.md contract | Created |

## How it works

`implementation-plan` builds every HTML plan by filling a skeleton template (`SKELETON.html`). Previously the skeleton carried two execution prompts: a green implement row and a conditionally shown blue workflow row. The goal prompt is added as a third, always-present row between them, so every generated plan offers all three framings.

Step 2 of the SKILL.md contract now always computes `{goal-prompt}` from the plan's objective and path, following the same canonical digest-extraction one-liner used by the other two prompts. There is no flag or complexity heuristic — the goal prompt is unconditional.

The skeleton inserts `<meta name="plan-goal" content="{goal-prompt}">` in `<head>` alongside the existing `plan-implement` and `plan-workflow` tags. In the body, a `<details class="plan-goal">` element renders the collapsible row. The row carries `id="goal-cmd"` and `onclick="copyGoal(this)"` so the clipboard helper follows the same wiring as `copyWorkflow`.

The `copyGoal()` JavaScript function mirrors `copyWorkflow()` — it reads the `plan-goal` meta tag's content attribute and writes it to the clipboard, giving users a one-click path to the outcome-framed prompt.

Styling uses purple `--purple*` CSS tokens to visually distinguish the goal row from the green implement row and the blue workflow row. The `.plan-goal` block is hidden in print and when the plan status is `completed`, matching the suppression rules for the other two rows.

The smoke test at `tests/plugins/test-goal-prompt.sh` asserts 6 checks: the meta tag exists in `SKELETON.html`, the `.plan-goal` markup with the correct `id` and `onclick` is present, the `copyGoal` function is defined, the `.plan-goal` CSS block is present, the DOM order is implement → goal → workflow, and `SKILL.md` documents `{goal-prompt}` and `plan-goal`.

## How to use it

After running `/plan-agent:implementation-plan`, every generated HTML plan now includes a purple "Pursue as goal" disclosure row. Click it to expand the outcome-driven prompt, then click the copy button to copy it to the clipboard.

The goal prompt instructs the implementer to achieve the plan's stated outcome and use the plan steps as reference — deviating when a better path to the same result exists. This contrasts with the implement prompt (strict step-by-step execution) and the workflow prompt (parallel subagent orchestration).

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `df49b6d` | 2026-08-12 | feat(settings-sync): restore onto a new machine via clone URL (1.1.0) (#548) |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan](plans/add-goal-prompt-to-implementation-plan.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — `[2.6.0]`
