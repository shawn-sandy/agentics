# Add outcome-driven goal prompt to implementation plans

> Adds an always-present goal prompt to every generated HTML plan — a third copy-paste framing alongside the implement and workflow prompts — that lets the implementer pursue the outcome rather than execute steps mechanically.

<!-- generated:start -->

**Status:** Shipped 2026-06-18 **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Added `<meta name="plan-goal" content="{goal-prompt}">` in `reference/SKELETON.html`'s `<head>` — always emitted, no flag or heuristic gates it.
- Added a collapsible `.plan-goal` `<details>` block (purple `--purple*` accent tokens) between the implement row and the workflow block in the skeleton body, with a `copyGoal()` clipboard helper mirroring the existing `copyWorkflow()` pattern.
- Updated `implementation-plan` SKILL.md to compute `{goal-prompt}` in Step 2 (always, from the condensed objective + plan path + digest-extraction one-liner) and emit the `plan-goal` meta tag in Step 3.
- Goal prompt text: "Achieve this goal: `<condensed-objective>` — use the plan at `<plan-path>` as reference, but optimize for the outcome." The implementer is explicitly invited to deviate when a better path to the same result exists.
- Documented the goal prompt in the plugin README and added a `2.6.0` CHANGELOG entry; version bumped `plan-agent` from `2.5.1` to `2.6.0` in `marketplace.json`.
- Added `tests/plugins/test-goal-prompt.sh` — 6 assertions covering the meta tag, `.plan-goal` markup + `copyGoal()` wiring, CSS hidden-when-completed/print rules, DOM order `implement → goal → workflow`, and the SKILL.md contract.

> See [CHANGELOG v2.6.0](../kit/plugins/plan-agent/CHANGELOG.md#260--outcome-driven-goal-prompt-on-every-html-plan-2026-06-18) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | HTML plan skeleton — `plan-goal` meta tag, `.plan-goal` details block, `copyGoal()` helper, purple CSS tokens | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill contract — Step 2 computes `{goal-prompt}`, Step 3 emits `plan-goal` meta, HTML Output Requirements updated | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — "Goal prompt" bullet in feature table | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — 2.6.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — `plan-agent` version to 2.6.0 | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — 6 assertions on goal prompt presence and wiring | Created |

## How it works

Every HTML plan is generated from `reference/SKELETON.html`. Adding the goal prompt there means all future plans automatically inherit it — no per-plan decision is needed.

The skeleton change adds three things: a `<meta name="plan-goal">` tag in `<head>` (machine-readable, same pattern as `plan-implement` and `plan-workflow`), a `.plan-goal` `<details>` element in the body rendered in purple accent colors to visually distinguish it from the green implement block and blue workflow block, and a `copyGoal(this)` JavaScript helper that copies the prompt text to the clipboard.

The SKILL.md update wires the template slot: Step 2 now always computes `{goal-prompt}` as "Achieve this goal: `<condensed-objective>` — use the plan at `<plan-path>` as reference, but optimize for the outcome." The condensed objective is derived the same way as the implement prompt — from the plan's Objective section, trimmed for token efficiency. The digest-extraction clause is appended so the implementer's agent reads the spec digest from the HTML rather than the full ~21k styled document.

Step 3 emits the `plan-goal` meta tag unconditionally. The HTML Output Requirements section of SKILL.md lists `plan-goal` among always-present meta tags and documents the `.plan-goal` element's expected structure, keeping the contract auditable.

The DOM order `implement → goal → workflow` is enforced by position in the skeleton and validated by `test-goal-prompt.sh`. CSS hides `.plan-goal` when `[data-status="completed"]` is set on `<html>` and in `@media print`, matching the existing behavior of the implement and workflow rows.

## How to use it

The goal prompt appears automatically in every plan generated after 2026-06-18 — no invocation change is needed. When you open a plan HTML file, the purple "Pursue as goal" disclosure is collapsed by default; click to expand and copy the prompt with the clipboard button.

The prompt is designed to be pasted at the start of a new session: it tells Claude to treat the plan's objective as the success condition, use the plan as reference material, but not feel bound to execute steps in order if a better route to the same outcome exists.

```
# Example goal prompt text (auto-computed per plan)
Achieve this goal: <condensed objective> — use the plan at docs/plans/<slug>.html
as reference, but optimize for the outcome. Extract the spec digest with:
python3 -c "import re,sys; c=open(sys.argv[1]).read(); ..."
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `950b214` | 2026-06-18 | feat(plan-agent): add outcome-driven goal prompt to HTML plans (2.6.0) (#332) |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
- Changelog: [kit/plugins/plan-agent/CHANGELOG.md](../kit/plugins/plan-agent/CHANGELOG.md)
