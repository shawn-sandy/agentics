# Add outcome-driven goal prompt to implementation plans

> Adds an always-present goal prompt to every generated HTML plan, wired through the same meta tag, rendered row, and Step 2 computation surfaces as the implement and workflow prompts.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Added `<meta name="plan-goal" content="{goal-prompt}">` to `reference/SKELETON.html` so every generated plan carries the goal prompt in a machine-readable tag.
- Added a collapsible `.plan-goal` `<details>` block in purple (`--purple*` tokens) between the implement row and the workflow block, including a `copyGoal()` clipboard helper.
- Updated `implementation-plan` SKILL.md: Step 2 now always computes `{goal-prompt}` (no flag, no complexity heuristic); Step 3 always emits the `plan-goal` meta tag; HTML Output Requirements list `plan-goal` among always-present meta tags.
- Added `tests/plugins/test-goal-prompt.sh` with six assertions covering the meta tag, `.plan-goal` markup, `copyGoal()` wiring, CSS visibility rules, DOM order (`implement → goal → workflow`), and the SKILL.md contract.
- Bumped `plan-agent` from `2.5.1` to `2.6.0` in `marketplace.json` with a CHANGELOG entry and README mention.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | HTML skeleton — goal meta tag, `.plan-goal` block, `copyGoal()` | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill contract — goal-prompt computation and emission | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version bump to 2.6.0 | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — six-assertion contract pin | Created |

## How it works

**Three-surface wiring.** The goal prompt follows the same pattern as the implement and workflow prompts: it lives in three coordinated places — a `<meta>` tag in `<head>` for machine consumption, a visible/collapsible row in the body for human use, and a Step 2 placeholder computed from the plan's objective and path. Any change to one surface should be reflected in the others, and the smoke test enforces this by checking all three.

**SKELETON.html changes.** `reference/SKELETON.html` received a `<meta name="plan-goal" content="{goal-prompt}">` tag in `<head>`, a `.plan-goal` `<details>` element styled with purple tokens (distinguishing it from the green implement row and blue workflow block), and a `copyGoal()` JavaScript function that mirrors `copyWorkflow()`. The DOM order places the goal row between implement and workflow.

**SKILL.md contract.** Step 2 of the SKILL.md now computes `{goal-prompt}` unconditionally on every plan run — no flag, no heuristic based on plan complexity. Step 3 always emits the `plan-goal` meta tag. The HTML Output Requirements section lists `plan-goal` among the meta tags that must always be present. The workflow block anchor was updated to sit below the goal row in the generated DOM.

**Goal prompt framing.** The outcome-driven prompt is framed as "Achieve this goal: … use the plan as reference, but optimize for the outcome" — giving an implementer latitude to deviate from the plan steps when a better path to the same result exists. This is distinct from the implement prompt (strict step-by-step execution) and the workflow prompt (parallel subagent orchestration).

**Test coverage.** `tests/plugins/test-goal-prompt.sh` runs six assertions: the `plan-goal` meta tag exists in SKELETON.html, the `.plan-goal` markup with `id="goal-cmd"` and `onclick="copyGoal(this)"` is present, the `.plan-goal` CSS block exists with hidden-when-completed and print rules, the DOM order is `implement → goal → workflow`, and `{goal-prompt}` and `copyGoal` appear in SKILL.md. The three sibling skeleton tests (`test-plan-digest.sh`, `test-save-pdf.sh`, `test-responsive-retrofit.sh`) continue to pass with no regression.

## How to use it

The goal prompt is generated automatically by `/plan-agent:implementation-plan` — no flag or option is needed. Every new HTML plan renders a purple "Pursue as goal" disclosure row between the green implement row and the blue workflow row.

Clicking the disclosure copies a prompt of the form:

```
Achieve this goal: <objective>. Use the plan at <path> as reference, but optimize for the outcome.
```

Paste this prompt to start an implementation session that is outcome-driven rather than step-constrained.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43a7fd9` | 2026-09-01 | feat(plan-agent): take review-plan off the experimental Agent Teams flag (#614) |
| `4147530` | 2026-08-26 | fix(plan-agent): stop artifact-mode renders leaking local paths (9.7.1) (#602) |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |
| `daa72b9` | 2026-08-23 | build-feature: add product content, stories, metrics, rollout, and publishing (#593) |
| `94c0569` | 2026-08-23 | feat(plan-agent): add design phase — canvas link, gallery, and drift check (#596) |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
