# Refactor gallery to row layout with sticky topbar

> Replaces the card grid with a row-per-plan layout, adds a sticky 5-tab topbar with counts, and adds an in-flight step-progress bar — landed as plan-agent 7.7.0 after resolving a PR conflict mid-development.

<!-- generated:start -->

**Status:** Shipped 2026-08-01 **Plan:** [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
**Type:** refactor

## What shipped

- Replaced the card grid layout in the plans gallery with a row-per-plan layout for denser information display.
- Added a sticky 5-tab topbar (All / In-flight / Todo / Done / Archived) with live counts.
- Added an in-flight step progress bar derived from `data-steps-done` / `data-steps-total` attributes.
- The plans-index merge driver constraint was preserved: `CARD_RE` still matches, no nested anchor, no `<li>`.
- Bumped plan-agent to 7.7.0 (not 7.6.0 — a PR conflict during development consumed that version).
- Updated both `social-media-tools` to 2.21.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Gallery renderer | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Build script | Modified |
| `kit/plugins/plan-agent/scripts/` (bundled copies) | Bundled copies | Modified |
| `kit/plugins/social-media-tools/skills/` | Social media skills | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |

## How it works

The card grid used variable heights and 3-column wrapping that made scanning for a specific plan slow. Rows give each plan a fixed-height entry with the title, status chip, and progress inline — scanning becomes a linear list read.

The sticky topbar uses client-side JavaScript to count plans by status and update tab labels live. Clicking a tab filters the list client-side; no server round-trip. The "In-flight" tab is the default view.

The step progress bar reads `data-steps-done` and `data-steps-total` HTML attributes that the renderer emits on each plan card, then renders a narrow filled bar. This gives at-a-glance completion without opening the plan.

The plans-index merge driver constraint required care: the driver uses `CARD_RE` to identify plan entries in `index.html` and union them on merge. The row format was designed to keep each plan's card as one `<article>` element with no nested anchors or list items, so `CARD_RE` continues to match reliably.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
