# Refactor plan and gallery design system

> Rebuilds the plan presentation shell with a new token system, dark mode, merged objective+glance, visible Verify line, sidebar step rail, and client-side gallery grouping — while preserving backward compatibility through `extractSections()`.

<!-- generated:start -->

**Status:** Shipped 2026-07-31 **Plan:** [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
**Type:** refactor

## What shipped

- Rebuilt `plan-shell.mjs` (the HTML presentation shell) with a new CSS token system and dark mode support.
- Merged the `## Objective` and `## Glance` sections into a unified header.
- Made the Verify line visible in step cards (previously hidden behind a disclosure).
- Added a sidebar step rail for quick navigation on long plans.
- Added client-side gallery grouping: In-flight plans get a distinct band with progress indicators.
- Narrowed the back-compat guard to `extractSections()` comparison only.
- Bumped plan-agent to 7.5.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | HTML renderer | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Spec parser | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Build script | Modified |
| `kit/plugins/plan-agent/scripts/` (bundled copies) | Bundled copies | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |

## How it works

The CSS token system defines color, spacing, and typography as `:root` variables (`--clr-accent`, `--spacing-step`, etc.) and redefines them under `@media (prefers-color-scheme: dark)`. This makes theme changes a one-variable edit rather than a search-and-replace through dozens of hardcoded values.

Merging Objective and Glance removes the two-block redundancy that existed because Glance was a later addition to the schema — it answered the same question as Objective but in a shorter format. The merged header shows the Glance text (one line) with the full Objective available on expansion.

The step rail on the left sidebar gives a spatial overview of a plan: steps marked `[x]` appear as filled dots, in-progress as half-filled, todo as empty. This makes the plan's overall completion state visible without scrolling.

The gallery's In-flight band uses client-side JavaScript to group plans with `status: in-progress` at the top, with a progress bar derived from `data-steps-done` and `data-steps-total` attributes the renderer emits. The gallery cards themselves are unchanged, so the merge driver's `CARD_RE` regex still matches.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
