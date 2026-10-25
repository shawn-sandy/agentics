# Rebuild the plan document and gallery design

> Rebuilds the presentation layer of generated plan pages and gallery index: design tokens with a persisted dark theme, a mono-and-serif type system, one merged goal panel, an always-visible Verify line, a sidebar step rail, and gallery controls that surface in-flight work first.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [refactor-plan-and-gallery-design](plans/refactor-plan-and-gallery-design.md)
**Type:** refactor

## What shipped

- Replaced the `:root` token block in `plan-shell.mjs` with a new palette (`--paper`, `--panel`, `--sunk`, `--ink`, `--ink-2`, `--ink-3`, `--rule`, `--accent`, `--accent-soft`, `--moss`, `--signal`, plus `--mono`, `--ui`, `--prose` font stacks) including a dark palette under `:root[data-theme="dark"]` and the `prefers-color-scheme` media query
- Added a theme toggle button and a pre-paint inline script in `<head>` that reads `localStorage` before first paint
- Merged the At-a-glance block inside the objective card; removed the two-abstract layout
- Made the Verify line always visible (removed the `<details>` wrapper from `step-verify-toggle`)
- Added the sidebar step rail: `id="step-N"` on each step card, a `<ul class="rail-steps">` of `<a class="rail-step">` links with visually-hidden state spans, collapsing to a `<details>` at 900px
- Fixed the scroll-spy to clear the active link when nothing intersects
- Deleted `.steps-list::before`, `.step-verify-toggle`, and the `.plan-glance` negative-margin rule
- Rebuilt the gallery controls: a search field, a status segmented control with per-status counts, and a `<details>` holding type and effort chips; client-side In-flight separator and month separators
- Emitted `data-month` on each card; sorted in-progress plans first in all three byte-identical `build-index.sh` copies
- Re-copied `plan-shell.mjs` and `build-plan-html.mjs` to `kit/plugins/plan-agent/scripts/`
- Created `tests/plugins/test-plan-redesign.mjs`
- Bumped plan-agent to 7.5.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | Script — tokens, dark palette, type roles, theme toggle, step rail, scroll-spy | Modified |
| `scripts/build-plan-html.mjs` | Script — glance nesting, step list to nav() | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Template — gallery controls, client-side grouping | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Generator — data-month, in-progress-first sort | Modified |
| `scripts/build-plans-index.sh` | Generator — byte-identical | Modified |
| `docs/plans/build-index.sh` | Generator — byte-identical | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Smoke test — back-compat guard narrowed | Modified |
| `tests/plugins/test-plan-redesign.mjs` | Smoke test — new objective test | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent 7.5.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history | Modified |

## How it works

The existing `plan-shell.mjs` had drifted into a generic default: `system-ui` at 15px, `#2563eb` blue, and a 1px border on every container. Six structural failures were found in a visual audit: two stacked abstracts (objective card + glance block as siblings), a `Verify:` line hidden in a `<details>`, three separate progress devices with none showing which step you are on, `--subtle: #9ca3af` failing WCAG AA at 2.5:1, no dark mode, and a three-device progress readout (shimmer bar, icon nav, steps-list timeline).

Two prototypes at `docs/prototypes/plan-document-redesign.html` and `docs/prototypes/plans-site-redesign.html` were built and verified against them. This plan implements the design.

The back-compat guard in `test-build-plan-html.mjs` was narrowed from a byte-diff of the whole document to `extractSections` parity — protecting the DOM contract the extractor and gallery read while allowing intentional markup changes.

The scroll-spy fix: the IntersectionObserver at line 1534 only reacted to `isIntersecting` entries. With one nav entry the stale highlight was invisible; with a link per step a wrong active marker is worse than none.

Month grouping and the in-flight band are generated client-side from `data-month` attributes on each card. The merge driver (`scripts/merge-plans-index.mjs`) splices over everything between the first and last card, so baked-in month headings between cards would be destroyed on every concurrent merge. Client-side grouping keeps them out of the markup the driver sees.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [refactor-plan-and-gallery-design](plans/refactor-plan-and-gallery-design.md)
