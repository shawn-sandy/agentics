# Rebuild the plan document and gallery design

> The plan document presentation was rebuilt with design tokens, dark mode, a merged goal panel, always-visible Verify lines, a sidebar step rail, and gallery controls that surface in-flight work first; shipped as plan-agent 7.5.0.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
**Type:** refactor

## What shipped

- Replaced the `:root` token block in `plan-shell.mjs` with the prototype's palette (`--paper`, `--panel`, `--ink`, `--ink-2`, `--ink-3`, `--rule`, `--accent`, `--moss`, `--signal`, `--mono`, `--ui`, `--prose`), added dark palette under `[data-theme="dark"]` and `@media (prefers-color-scheme: dark)`, and retired `--subtle: #9ca3af` (which measured 2.5:1 and was a live WCAG AA failure).
- Narrowed the back-compat test guard from a whole-document byte-diff to `extractSections` deep-equal plus explicit no-prototype assertions.
- Added a theme toggle with a `data-theme`-reading inline head script, a labelled button with `aria-pressed`, and a `localStorage` persistence handler.
- Nested the At-a-glance block inside the objective card; replaced the `<details class="step-verify-toggle">` wrapper with a plain labelled block keeping `<div class="verify-body">` intact (Verify text now always visible).
- Added a sidebar step rail: each step card gets `id="step-N"`, `nav()` extended to emit `<ul class="rail-steps">` with per-step `<a class="rail-step">` links carrying visually-hidden state spans; below 900px the list moves inside a `<details>`.
- Fixed the scroll-spy so it clears the active link when nothing intersects; deleted `.steps-list::before`, `.step-verify-toggle`, and the `.plan-glance` sibling margin.
- Re-copied both renderer files into `kit/plugins/plan-agent/scripts/`.
- Rebuilt the plans-gallery controls: replaced three filter-chip rows with a search field, a status segmented control with per-status counts, and a `<details>` for type/effort chips; client-side `applyFilters()` inserts "In flight" and month separators (never in static markup, to preserve the merge driver).
- Emitted `data-month` on each card and sorted in-progress plans ahead of the date order in all three byte-identical build-script copies; regenerated all three gallery indexes.
- Added `tests/plugins/test-plan-redesign.mjs`; bumped plan-agent to 7.5.0 with CHANGELOG.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | Presentation shell — tokens, dark palette, type roles, theme toggle, step rail, scroll-spy | Modified |
| `scripts/build-plan-html.mjs` | Build script — glance nesting, step list to nav() | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy (byte-identical) | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Gallery controls: search, status segmented control, type/effort disclosure | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | `data-month` attribute and in-progress-first sort | Modified |
| `scripts/build-plans-index.sh` | Same edit, byte-identical | Modified |
| `docs/plans/build-index.sh` | Same edit, byte-identical | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Back-compat guard narrowed to extractSections | Modified |
| `tests/plugins/test-plan-redesign.mjs` | Objective-verification smoke test | Created |
| `.claude-plugin/marketplace.json` | plan-agent 7.4.4 → 7.5.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.5.0 entry | Modified |

## How it works

Six concrete failures were found in a visual audit: two sibling abstracts (objective card and glance block) with no clear hierarchy, Verify text buried behind a `<details>` toggle, three competing progress devices with no "you are here" marker, `--subtle` failing WCAG AA at 2.5:1 on white, and no dark mode.

The token replacement in `plan-shell.mjs` Step 1 was safe to land first because the back-compat test blanks the `<style>` block — no markup risk. Existing token names were kept as aliases pointing at their replacements so no downstream selector broke during the refactor; Step 6 then removed the aliases and repointed every remaining selector.

The back-compat guard at `test-build-plan-html.mjs:883` was narrowed before the first markup change. Its comment said it protected "the DOM contract the extractor and the gallery read", but the byte-diff also failed on every intentional markup and script change, making it indistinguishable from a regression guard. The new assertion deep-equals `extractSections` output rather than document bytes, plus explicit checks that prototype-only elements are absent from non-prototype renders.

The theme toggle reads `localStorage.getItem('plan-theme')` in an inline `<head>` script before first paint — necessary because plans are served from `file://` where no server can stamp a class. The toggle button flips `documentElement.dataset.theme` and writes back to storage; a `prefers-color-scheme` media query handles the first-visit case.

The At-a-glance block was nested inside the objective card (via `objectiveCard(objective, glanceHtml)`) rather than being a sibling, and the `<details class="step-verify-toggle">` was replaced with a plain block — `extractSections` already strips nested `.plan-glance` and reads `verify-body` regardless of wrapper, so both changes were safe.

The step rail extends `nav()` to emit a `<ul class="rail-steps">` of per-step `<a class="rail-step">` links alongside the unchanged section links. Each link carries a visually-hidden state span (`step N of M, done` / `step N of M`). The `progressBlock` and `NAV_ENTRIES` id list were deliberately left untouched to keep the progress JavaScript and its two `deepEqual` arrays green.

Month separators and the In-flight band are generated client-side by `applyFilters()` from `data-month` attributes on cards. This keeps separators out of the static markup the merge driver splices, so `tests/plugins/test-merge-gallery-index.sh` and `scripts/merge-plans-index.mjs` required no edits.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `c16fe83f` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `b8cfa1fd` | 2026-09-04 | fix(plan-agent): style header links as chips and refocus a leading select after submit (9.13.1) (#623) |
| `d2e9f101` | 2026-09-02 | feat: polish the plan-document HTML output (#617) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/500
- Prototype: `docs/prototypes/plan-document-redesign.html`
- Gallery prototype: `docs/prototypes/plans-site-redesign.html`
