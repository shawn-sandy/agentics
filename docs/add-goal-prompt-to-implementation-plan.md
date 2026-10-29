# Add outcome-driven goal prompt to implementation plans

> Adds an always-present goal prompt to every generated HTML plan — a third copy-paste framing alongside the implement and workflow prompts — that lets the implementer pursue the outcome rather than execute steps mechanically.

<!-- generated:start -->

**Status:** Shipped 2026-06-18 **Plan:** [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
**Type:** feature

## What shipped

- Added `<meta name="plan-goal" content="{goal-prompt}">` in `reference/SKELETON.html`'s `<head>` — always emitted, no flag or heuristic gates it.
- Added an always-present `.plan-goal` row inside the flat `.plan-more-ways` drawer in the skeleton body (purple accent colours), with a `copyGoal()` clipboard helper. The drawer is a single flat `<details>` that must not contain nested `<details>` elements — the `.plan-goal` row is a plain `<div>`, not a disclosure.
- Updated `implementation-plan` SKILL.md to compute `{goal-prompt}` in Step 2 (always) and emit the `plan-goal` meta tag in Step 3.
- Goal prompt text: "Achieve this goal: `<condensed-objective>`. The plan at `<plan-path>` describes one approach — use it as reference, but optimize for the outcome." The implementer is explicitly invited to deviate when a better path to the same result exists.
- Documented the goal prompt in the plugin README and added a `2.6.0` CHANGELOG entry; version bumped `plan-agent` from `2.5.1` to `2.6.0` in `marketplace.json`.
- Added `tests/plugins/test-goal-prompt.sh` — 6 assertions covering the meta tag, `.plan-goal` markup + `copyGoal()` wiring, CSS hidden-when-completed/print rules, DOM order `implement → goal → workflow`, and the SKILL.md contract.

> See [CHANGELOG v2.6.0](../kit/plugins/plan-agent/CHANGELOG.md#260--outcome-driven-goal-prompt-on-every-html-plan-2026-06-18) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` | HTML plan skeleton — `plan-goal` meta tag, `.plan-goal` row in `.plan-more-ways` drawer, `copyGoal()` helper, purple CSS tokens | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill contract — Step 2 computes `{goal-prompt}`, Step 3 emits `plan-goal` meta, HTML Output Requirements updated | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — "Goal prompt" bullet in feature table | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — 2.6.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — `plan-agent` version to 2.6.0 | Modified |
| `tests/plugins/test-goal-prompt.sh` | Smoke test — 6 assertions on goal prompt presence and wiring | Created |

## How it works

Every HTML plan is generated from `reference/SKELETON.html`. Adding the goal prompt there means all future plans automatically inherit it — no per-plan decision is needed.

The skeleton change adds three things: a `<meta name="plan-goal">` tag in `<head>` (machine-readable, same pattern as `plan-implement` and `plan-workflow`), a `.plan-goal` plain `<div>` row inside the flat `.plan-more-ways` drawer rendered in purple accent colours, and a `copyGoal(this)` JavaScript helper that copies the prompt text to the clipboard. The drawer is a single `<details class="plan-more-ways">` — it contains no nested `<details>` elements. The goal row sits first inside the drawer body, before the optional workflow row and the plan-source rows.

The SKILL.md update wires the template slot: Step 2 now always computes `{goal-prompt}` as "Achieve this goal: `<condensed-objective>`. The plan at `<plan-path>` describes one approach — use it as reference, but optimize for the outcome." The condensed objective and relative plan path are the same values used in the implement prompt.

Step 3 emits the `plan-goal` meta tag unconditionally. The HTML Output Requirements section of SKILL.md lists `plan-goal` among always-present meta tags and documents the `.plan-goal` element as a plain row inside the drawer, keeping the contract auditable.

CSS hides `.plan-goal` when `[data-status="completed"]` is set on `<html>` and in `@media print`. The entire `.plan-more-ways` drawer is also suppressed in print, making the print rule on `.plan-goal` redundant — but it is retained verbatim because `test-goal-prompt.sh` pins it byte-for-byte.

## How to use it

The goal prompt appears automatically in every plan generated after 2026-06-18 — no invocation change is needed. Open a plan HTML file and expand the "More ways to run this plan" drawer; the purple "Pursue as goal" row is always present. Click Copy to copy the prompt to the clipboard.

The prompt is designed to be pasted at the start of a new session: it frames the work as an outcome to achieve rather than steps to execute, giving the implementer latitude to deviate from the plan when a better path to the same result exists.

```
# Example goal prompt text (auto-computed per plan)
Achieve this goal: Ship a dark-mode toggle that persists across all three themes.
The plan at docs/plans/add-dark-mode-toggle.html describes one approach — use it
as reference, but optimize for the outcome.
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `950b214` | 2026-06-18 | feat(plan-agent): add outcome-driven goal prompt to HTML plans (2.6.0) (#332) |

<!-- generated:end -->

## References

- Plan: [add-goal-prompt-to-implementation-plan.md](plans/add-goal-prompt-to-implementation-plan.md)
- Changelog: [kit/plugins/plan-agent/CHANGELOG.md](../kit/plugins/plan-agent/CHANGELOG.md)
