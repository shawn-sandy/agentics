# Add outcome-driven goal prompt to implementation plans

> Adds an always-present goal prompt to every generated HTML plan, wired through the same meta tag, rendered row, and Step 2 computation surfaces as the implement and workflow prompts.

<!-- generated:start -->

**Status:** Shipped 2026-06-18  **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Added a `<meta name="plan-goal" content="{goal-prompt}">` tag to `reference/SKELETON.html` in `<head>`.
- Added a collapsible `.plan-goal` `<details>` block (purple `--purple*` color tokens) between the implement row and the workflow block in the skeleton.
- Added a `copyGoal()` clipboard helper mirroring `copyWorkflow()` in the skeleton's JavaScript.
- Updated `implementation-plan` SKILL.md to compute `{goal-prompt}` in Step 2 (always, no flag or heuristic), always emit the `plan-goal` meta tag in Step 3, and list `plan-goal` among always-present meta tags in HTML Output Requirements.
- Documented the change in the plugin README, bumped `plan-agent` from `2.5.1` to `2.6.0` in `marketplace.json`, and added a `2.6.0` CHANGELOG entry.
- Added `tests/plugins/test-goal-prompt.sh` with 6 assertions covering the meta tag, `.plan-goal` markup with `copyGoal()` wiring, CSS hidden states, DOM order, and SKILL.md contract.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | Plan HTML skeleton | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin README | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test | Created |

## How it works

Before this change, `implementation-plan` produced two execution framings on every generated plan: the **implement prompt** (strict, in-session, step-by-step execution) and a conditional **workflow prompt** (parallel subagent orchestration). Both are copy-paste prompts that appear as collapsible rows in the plan HTML.

The goal prompt adds a third framing: "Achieve this goal: … use the plan as reference, but optimize for the outcome." This gives an implementer latitude to deviate from the plan's specific steps when a better path to the same result exists — a meaningful distinction from the implement prompt, which expects strict step-by-step adherence.

The implementation follows the same three-surface wiring pattern as the existing prompts. In `SKELETON.html`, the `<meta name="plan-goal">` tag in `<head>` stores the computed prompt for programmatic access, the `.plan-goal` `<details>` block renders it as a collapsible purple row in the plan body, and `copyGoal()` gives it the same one-click copy affordance as its siblings. In `SKILL.md`, Step 2 always computes `{goal-prompt}` from the objective and plan path, and Step 3 always emits the meta tag — no flag or complexity heuristic gates it.

The DOM order `implement → goal → workflow` was verified in a browser: the purple "Pursue as goal" disclosure renders between the green implement row and the blue workflow row. The `.plan-goal` CSS block hides the row when the plan is marked completed and in print output, matching the behavior of its siblings.

The test in `tests/plugins/test-goal-prompt.sh` runs 6 assertions and was also run against the three sibling skeleton tests (`test-plan-digest.sh`, `test-save-pdf.sh`, `test-responsive-retrofit.sh`) to confirm no regression.

## How to use it

The goal prompt appears automatically on every newly generated HTML plan. Open any plan file, locate the purple "Pursue as goal" disclosure row, and click the copy button to copy the outcome-oriented prompt to the clipboard.

Invoke `implementation-plan` as usual:

```text
/plan-agent:implementation-plan
```

The generated plan will include all three prompt rows: implement (green), goal (purple), and workflow (blue, conditional on plan complexity).

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
