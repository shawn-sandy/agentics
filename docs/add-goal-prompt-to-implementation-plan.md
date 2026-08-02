# Add outcome-driven goal prompt to implementation plans

> Adds an always-present "Pursue as goal" copy-paste prompt to every generated HTML plan, giving implementers latitude to optimize for the outcome rather than mechanically follow the steps.

<!-- generated:start -->

**Status:** Shipped 2026-06-18 **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Added a `<meta name="plan-goal" content="{goal-prompt}">` tag to the `SKELETON.html` `<head>`, an always-present `plan-goal` meta among the plan's machine-readable tags (Why: the skeleton is the single source every plan is filled from, so the prompt must live there to appear in all future plans).
- Added a collapsible `.plan-goal` `<details>` block rendered in purple (`--purple*` design tokens) immediately below the implement row and above the workflow block, with a `copyGoal()` clipboard helper mirroring the existing `copyWorkflow()`.
- Hidden the `.plan-goal` block when `data-status="completed"` and suppressed in `@media print`, exactly like the implement and workflow rows.
- Updated `implementation-plan` SKILL.md so Step 2 always computes `{goal-prompt}` (no flag, no complexity heuristic), Step 3 always emits the `plan-goal` meta tag, and HTML Output Requirements list `plan-goal` among the always-present meta tags.
- Framed the goal prompt as "Achieve this goal: `<objective>` — use the plan as reference, but optimize for the outcome" so the implementing agent has explicit latitude to deviate when a better path exists.
- Added `tests/plugins/test-goal-prompt.sh` pinning the goal prompt to the skeleton (meta tag, markup, `copyGoal()` wiring, CSS hidden-when-completed and print rules) and the SKILL.md contract.
- Bumped `plan-agent` from `2.5.1` to `2.6.0` in `.claude-plugin/marketplace.json` (new always-present feature = minor) with a matching CHANGELOG entry.

> See [CHANGELOG v2.6.0](../kit/plugins/plan-agent/CHANGELOG.md#260--outcome-driven-goal-prompt-on-every-html-plan-2026-06-18) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | HTML skeleton — adds `.plan-goal` markup, CSS, `copyGoal()`, and `<meta name="plan-goal">` | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions — Step 2 computation, Step 3 meta emission, HTML Output Requirements | Modified |
| `tests/plugins/test-goal-prompt.sh` | Objective smoke test — pins goal prompt to skeleton and SKILL.md contract | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry — `plan-agent` version bumped to `2.6.0` | Modified |

## How it works

Every generated plan now renders three copy-paste execution framings — **implement**, **goal**, and **workflow** — in that DOM order. The goal prompt is the middle sibling.

**SKELETON.html — markup.** `<meta name="plan-goal" content="{goal-prompt}">` appears in `<head>` alongside the existing `plan-implement` and `plan-workflow` meta tags. In the body, a `.plan-goal` `<details>` block sits between the green implement row and the blue workflow block. Its interior holds the goal-prompt text with an `id="goal-cmd"` element and an `onclick="copyGoal(this)"` button — structurally identical to the implement and workflow rows, differentiated only by the purple accent (`--purple*` tokens). The block carries `data-status`-aware CSS: `[data-status="completed"] .plan-goal { display: none; }` hides it once a plan is marked done, and `@media print { .plan-goal { display: none !important; } }` suppresses it in print, matching the other two rows' rules.

**SKILL.md contract.** Step 2 computes `{goal-prompt}` on every plan generation — always, unconditionally. The formula is: `Achieve this goal: <condensed-objective> — use the plan as reference, but optimize for the outcome. <digest-extraction-clause>`. The digest-extraction clause is the same one-liner that appears in the implement and workflow prompts, so the pursuing agent reads the spec digest rather than the full styled HTML. Step 3 always fills `<meta name="plan-goal" content="{goal-prompt}">` in the skeleton head, and the HTML Output Requirements section lists `plan-goal` as a required always-present meta.

**Test coverage.** `tests/plugins/test-goal-prompt.sh` runs 6 assertions: (1) the `plan-goal` meta tag is present in `SKELETON.html`; (2) `.plan-goal` markup with `id="goal-cmd"` and `onclick="copyGoal(this)"` is present; (3) the `.plan-goal` CSS block exists; (4) `[data-status="completed"] .plan-goal` and `@media print { .plan-goal` rules exist; (5) DOM order is `implement → goal → workflow`; (6) SKILL.md references `{goal-prompt}`, `plan-goal`, and `copyGoal(this)`.

**Fan-out note (added in v7.0.0).** A later update (CHANGELOG v7.0.0, 2026-07-29) extended the goal prompt text to license parallel subagents on plans with a workflow row: `Fan out across parallel subagents where the plan's workflow prompt supports it`. This is appended by the skill only when both the workflow row is present and the goal prompt is filled — the base `Achieve this goal:` prefix is unchanged.

## How to use it

The goal prompt appears automatically in every plan generated by `/plan-agent:implementation-plan`. No flags or options are required — it is always present.

When viewing a plan, the purple "Pursue as goal" collapsible row renders between the green implement row and the blue workflow row. Click **Copy** to place the goal prompt on the clipboard, then paste it into a new session. The implementing agent receives:

> Achieve this goal: `<your plan's objective>` — use the plan as reference, but optimize for the outcome. Read the spec digest in `<meta name="plan-goal">` …

This framing lets the agent deviate from the plan's specific steps when a better route to the same outcome exists, unlike the implement prompt which instructs step-by-step execution.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `ce69bc8` | 2026-07-29 | feat(plan-agent)!: validate frontmatter enums, trim the verify gate, license fan-out in goal prompts (#488) |
| `d07c389` | 2026-07-21 | feat(git-agent): add lint gate before commit (#448) |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
- Changelog: [plan-agent v2.6.0](../kit/plugins/plan-agent/CHANGELOG.md#260--outcome-driven-goal-prompt-on-every-html-plan-2026-06-18)
