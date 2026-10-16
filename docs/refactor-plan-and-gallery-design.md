# Rebuild the plan document and gallery design

> Generated plan pages are hard to scan — two stacked summaries, every section in an identical bordered box, the Verify line hidden behind a disclosure, three competing progress devices, no dark mode, and a tertiary text colour that fails WCAG at 2.5:1.

<!-- generated:start -->

**Status:** Shipped 2026-07-31  **Plan:** [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
**Type:** refactor

## What shipped

- Replaced the `:root` token block in `plan-shell.mjs` with a mono-chrome-plus-serif type system: new tokens (`--paper`, `--panel`, `--ink`, `--ink-2`, `--ink-3`, `--rule`, `--accent`, `--moss`, `--signal`, `--mono`, `--ui`, `--prose`) with dark palette under `[data-theme="dark"]` and `@media (prefers-color-scheme: dark)`. Retired `--subtle: #9ca3af` (2.5:1 WCAG failure) — replaced with `--ink-3` which clears 4.5:1.
- Added a theme toggle: a `data-theme`-reading inline script in `<head>` (reads before first paint), a labelled toggle button in the header with `aria-pressed` and a 44×44 px hit area, and a `localStorage`-backed handler.
- Narrowed the back-compat test guard from a whole-document byte diff to `assert.deepEqual(extractSections(after), extractSections(before))` plus explicit markup assertions — protecting the DOM contract the extractor and gallery read without blocking every intentional presentation change.
- Nested the At-a-glance block inside the objective card (one goal panel instead of two stacked summaries), and replaced the `<details class="step-verify-toggle">` Verify wrapper with a plain labelled block so the Verify line is always visible.
- Added a step rail to the sidebar: each `.step-card` gets `id="step-N"`, and `nav()` emits a `<ul class="rail-steps">` of `<a class="rail-step">` links carrying each step's action text and a visually-hidden state span (`step N of M, done` or `step N of M`). The existing progress block, `NAV_ENTRIES` id list, and progress JavaScript are left untouched.
- Fixed the scroll-spy to clear the active link when no section is intersecting, then deleted superseded rules (`.steps-list::before`, `.step-verify-toggle`, `.plan-glance` sibling margin) and removed token aliases.
- Re-copied both `scripts/build-plan-html.mjs` and `scripts/lib/plan-shell.mjs` into `kit/plugins/plan-agent/scripts/` byte-identically.
- Rebuilt the gallery controls in `plans-gallery.html`: search field, status segmented control with per-status counts, `<details>` holding type and effort chips; client-side In-flight separator and month separators derived from `data-month` on each card.
- Emitted `data-month` on each card and sorted in-progress plans first in all three byte-identical build scripts; regenerated the plans, artifacts, and prototypes indexes.
- Added `tests/plugins/test-plan-redesign.mjs` as the objective test; bumped plan-agent to 7.5.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `scripts/lib/plan-shell.mjs` | Renderer — tokens, dark palette, type roles, theme toggle, step rail, scroll-spy | Modified |
| `scripts/build-plan-html.mjs` | Build script — glance nested in objective, step list passed to nav() | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy — byte-identical to repo-root | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy — byte-identical to repo-root | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Gallery template — search, status control, type/effort chips, client-side grouping | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Hook build script — data-month, in-progress-first sort | Modified |
| `scripts/build-plans-index.sh` | Repo build script — byte-identical to above | Modified |
| `docs/plans/build-index.sh` | Docs build script — byte-identical to above | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Test suite — back-compat guard narrowed to extractSections | Modified |
| `tests/plugins/test-plan-redesign.mjs` | Objective test — tokens, theme toggle, goal panel, step rail | Created |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent 7.4.4 → 7.5.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 7.5.0 entry | Modified |

## How it works

The presentation shell lived entirely in the 1930-line `CSS` export of `scripts/lib/plan-shell.mjs`. A visual audit identified six concrete failures, all structural: two stacked abstracts (the `objectiveCard` and `glanceBlock` rendered as siblings with a hack margin), the Verify text hidden inside a `<details>` disclosure, three redundant progress devices (the shimmer bar, the icon nav, and the `.steps-list::before` timeline) none of which named the current step, `--subtle: #9ca3af` failing WCAG AA at 2.5:1, and no dark mode.

The token replacement uses aliases for the initial steps: each new token maps to a new variable, and the old names (`--subtle`, `--grey-bg`, `--border-mid`) are kept as aliases through the refactor and removed in Step 6 after all selectors have been repointed. This keeps the back-compat guard green for Steps 1–5 and makes Step 6 the single "retire old names" commit.

The theme toggle architecture matters because plans are often opened from `file://` rather than a server. A CSS `prefers-color-scheme` media query would work, but a toggle that persists across reloads requires reading `localStorage` before first paint. The inline `<head>` script sets `document.documentElement.dataset.theme` before any rendering occurs, eliminating the flash-of-wrong-theme that would otherwise appear on every page load.

Nesting the glance inside the objective card required a two-part change: `objectiveCard(objective, glanceHtml)` in `plan-shell.mjs` and dropping the separate `main.push(shell.glanceBlock(…))` in `build-plan-html.mjs`. `extractSections` in `plan-spec.mjs` was not changed — it already strips nested `.plan-glance` and reads verify text from `class="verify-body"` regardless of wrapper.

The step rail is additive to the existing nav structure. The section-link `deepEqual` at `test-build-plan-html.mjs:635` requires section anchor `href`s to have no other attributes — the rail links use `id="step-N"` (containing a digit), which the nav regex `/<a href="#([a-z-]+)">/g` skips, so the two nav id arrays and the progress JavaScript are entirely unaffected.

The gallery client-side grouping was forced by the merge driver. `scripts/merge-plans-index.mjs` splices the union of `<a class="gallery-card">` blocks over the region between the first and last card — any static separator between cards would be destroyed on the first concurrent merge. Month separators and the In-flight band are therefore injected by `applyFilters()` in JavaScript on every filter change, reading `data-month` and `data-status` attributes. The driver never sees them.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
