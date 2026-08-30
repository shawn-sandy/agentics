# Rebuild the plan document and gallery design

> Rebuilt the presentation layer of generated plan pages and the gallery index — design tokens with a persisted dark theme, a mono-and-serif type system, one merged goal panel, an always-visible Verify line, a sidebar step rail, and gallery controls that surface in-flight work first.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [refactor-plan-and-gallery-design](plans/refactor-plan-and-gallery-design.md)
**Type:** refactor

## What shipped

- Replaced the `:root` token block in `plan-shell.mjs` with a new palette and font-stack system including full dark-mode support under both `[data-theme="dark"]` and `prefers-color-scheme`.
- Added a theme-toggle button to the plan page header with `localStorage` persistence, hidden from print stylesheets.
- Merged the At-a-glance block inside the objective card and made the Verify line always visible (removed the `<details>` disclosure wrapper).
- Added a sidebar step rail with per-step anchors, visually-hidden state spans, and a `<details>` disclosure on narrow viewports.
- Fixed the scroll-spy observer to clear the active link when nothing intersects.
- Rebuilt the gallery controls in `plans-gallery.html` with a search field, a status segmented control, and client-side In-flight and month separators.
- Emitted `data-month` on each gallery card and sorted in-progress plans first in all three build-script copies.
- Added `tests/plugins/test-plan-redesign.mjs` and narrowed the back-compat guard from a byte-diff to an `extractSections` deepEqual.
- Bumped `plan-agent` from 7.4.4 to 7.5.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `scripts/lib/plan-shell.mjs` | Presentation shell — tokens, markup, scripts | Modified |
| `scripts/build-plan-html.mjs` | Build entry point | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Gallery template | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Index build hook | Modified |
| `scripts/build-plans-index.sh` | Root build script | Modified |
| `docs/plans/build-index.sh` | Docs build script | Modified |
| `docs/plans/index.html` | Plans gallery | Modified (regenerated) |
| `tests/plugins/test-build-plan-html.mjs` | Test suite | Modified |
| `tests/plugins/test-plan-redesign.mjs` | New objective test | Created |
| `.claude-plugin/marketplace.json` | Version manifest | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog | Modified |

## How it works

**Token system and dark mode (Step 1).** The `:root` CSS block in `plan-shell.mjs` was replaced with a named token palette (`--paper`, `--panel`, `--ink`, `--ink-2`, `--ink-3`, `--rule`, `--accent`, `--mono`, `--ui`, `--prose`, and others). The retired `--subtle: #9ca3af` token, which measured 2.5:1 against white and was the page's WCAG AA failure, was removed. The dark palette is defined twice: under `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) }` for the system default and under `:root[data-theme="dark"]` for the explicit toggle, so the two do not fight. Existing token names were aliased to their replacements during the transition and removed in Step 6 once all callers were repointed.

**Back-compat guard narrowed (Step 2).** The guard at `tests/plugins/test-build-plan-html.mjs:883` previously byte-diffed the entire rendered output against `origin/main`, which would fail on any intentional markup or script change. It was narrowed to `assert.deepEqual(extractSections(after), extractSections(before))` — asserting only the DOM contract the extractor and gallery generator read — with two additional assertions that the no-prototype render carries no prototype meta tag or header link.

**Theme toggle (Step 3).** A labelled toggle button with a 44×44 px hit area and `aria-pressed` was added to the plan page header. A small inline script in `<head>` reads the stored `localStorage` preference before first paint, preventing a wrong-theme flash on `file://` opens. The handler flips `documentElement.dataset.theme` and writes the choice back. The button is hidden by the print stylesheet.

**Merged goal panel (Step 4).** `objectiveCard` was extended to accept the glance HTML as a second argument and nest it inside `<div id="objective">`, and the separate `glanceBlock` push in `build-plan-html.mjs` was removed. `stepCard`'s `<details class="step-verify-toggle">` wrapper around the Verify text was replaced with a plain labelled block, keeping `<div class="verify-body">` intact. Both changes are safe because `extractSections` already strips nested `.plan-glance` content and reads verify text from `class="verify-body"` regardless of wrapper.

**Sidebar step rail (Step 5).** Each `.step-card` received an `id="step-N"` attribute while keeping `class="step-card completed"` as a literal substring for existing test compatibility. `nav()` was extended to accept the step list and emit a `<ul class="rail-steps">` of `<a class="rail-step" href="#step-N">` links, each carrying the step's action text and a visually-hidden state span. Section anchors in the sidebar kept their bare `href`-only attribute, so the nav regex at test line 635 was unaffected. On viewports narrower than 900px the rail's step list moves inside a closed `<details>` rather than being hidden, keeping jump targets reachable on mobile.

**Scroll-spy fix and cleanup (Step 6).** The IntersectionObserver handler only reacted to `isIntersecting` entries, leaving the last matched link highlighted permanently after scrolling past the final section. A clearing branch was added so every `.active` class is removed when nothing intersects. The redesign-superseded rules (`.steps-list::before`, `.step-verify-toggle`, and the `.plan-glance` negative-margin hack) were deleted, Step 1's token aliases were removed, and all selectors were repointed to the new token names.

**Bundled copies re-synced (Step 7).** `scripts/build-plan-html.mjs` and `scripts/lib/plan-shell.mjs` were re-copied to their counterparts under `kit/plugins/plan-agent/scripts/`. The byte-identity assertion in `tests/plugins/test-build-plan-html.mjs:951` pins both.

**Gallery controls (Step 8).** `plans-gallery.html`'s three filter-chip rows were replaced with a search field, a status segmented control with per-status card counts, and a `<details>` holding type and effort chips. The inline `applyFilters()` function was extended to insert an "In flight" separator before the in-progress run and month separators between `data-month` values, rebuilding those separators on every filter change. Separators are generated client-side from `data-month` attributes to keep them out of the markup that `scripts/merge-plans-index.mjs` splices — the driver never sees a group header, and `test-merge-gallery-index.sh` is unaffected. The status control hides itself on the artifacts gallery, whose cards carry no `status` attribute.

**Build scripts and regenerated indexes (Step 9).** All three copies of the build script (`kit/plugins/plan-agent/hooks/build-index.sh`, `scripts/build-plans-index.sh`, and `docs/plans/build-index.sh`) were updated to emit `data-month` on each card and to sort in-progress plans ahead of the date order. The three files are kept byte-identical by convention. `docs/plans/index.html`, `docs/artifacts/index.html`, and `docs/prototypes/index.html` were regenerated.

**Objective test (Step 10).** `tests/plugins/test-plan-redesign.mjs` asserts end to end: a `[data-theme]` dark rule and a theme-toggle button are present in the rendered output; every text token in the stylesheet clears 4.5:1 against its background in both palettes; the glance renders inside `id="objective"` while `extractSections` returns an objective free of glance text; `verify-body` appears outside any `<details>`; one `id="step-N"` anchor exists per step with a matching `a.rail-step` link; and the extract-render cycle is stable.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `df49b6d` | 2026-08-12 | feat(settings-sync): restore onto a new machine via clone URL (1.1.0) (#548) |

<!-- generated:end -->

## References

- Plan: [refactor-plan-and-gallery-design](plans/refactor-plan-and-gallery-design.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — 7.5.0 entry
- Prototypes: `docs/prototypes/plan-document-redesign.html`, `docs/prototypes/plans-site-redesign.html`
