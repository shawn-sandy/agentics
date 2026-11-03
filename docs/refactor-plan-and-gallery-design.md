# Rebuild the plan document and gallery design

> Rebuilt the presentation layer of generated plan HTML pages and the gallery index — dark-mode palette, merged goal panel, always-visible Verify lines, a sidebar step rail, and gallery controls that sort in-flight work first — without breaking the DOM contract the extractor and merge driver read.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
**Type:** refactor

## What shipped

- Replaced the entire `:root` token block in `scripts/lib/plan-shell.mjs` with a new mono-and-serif palette (`--paper`, `--ink`, `--accent`, `--mono`, `--prose`, etc.), dark palette under both `prefers-color-scheme` and `[data-theme="dark"]`, and aliased old names to prevent downstream breakage.
- Added a dark theme toggle button in the plan page header with `aria-pressed`, a 44×44 px hit area, localStorage persistence, and a head-inline script that reads the stored preference before first paint.
- Nested the At-a-glance block inside the objective card so readers see one goal panel instead of two stacked summaries, and exposed the step `Verify:` text outside `<details>` so it is visible without expanding.
- Added a sidebar step rail — one `<a class="rail-step">` per step with a visually-hidden state span — that replaces the collapsed `steps` nav entry, with a `<details>` fallback at narrow viewports.
- Fixed the scroll-spy observer to clear `.active` when no section intersects, deleted the superseded `.steps-list::before`, `.step-verify-toggle`, and negative-margin `.plan-glance` rules, and removed all retired token names.
- Re-copied `scripts/build-plan-html.mjs` and `scripts/lib/plan-shell.mjs` into `kit/plugins/plan-agent/scripts/` to satisfy the byte-identity test.
- Rebuilt the gallery controls in `plans-gallery.html`: search field, status segmented control with per-status counts, type/effort disclosure, and client-side In-flight and month separators that regenerate on every filter change.
- Added `data-month` attribute to each card and in-progress-first sort in all three byte-identical `build-index.sh` copies; regenerated `docs/plans/index.html`, `docs/artifacts/index.html`, and `docs/prototypes/index.html`.
- Added `tests/plugins/test-plan-redesign.mjs` asserting the objective end-to-end: contrast, merged goal panel, step rail, and extractor round-trip.
- Narrowed the back-compat guard in `test-build-plan-html.mjs` from a whole-document byte-diff to an `extractSections` deep-equal, so intentional markup changes are distinguishable from accidental regressions.
- Bumped plan-agent 7.4.4 → 7.5.0 with a CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | Presentation shell: tokens, dark palette, theme toggle, step rail, scroll-spy | Modified |
| `scripts/build-plan-html.mjs` | Renderer: glance nested in objective, step list passed to nav() | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Gallery controls: search, status segmented control, client-side grouping | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | data-month attribute, in-progress-first sort | Modified |
| `tests/plugins/test-plan-redesign.mjs` | Objective smoke test | Created |
| `tests/plugins/test-build-plan-html.mjs` | Narrowed back-compat guard | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 7.4.4 → 7.5.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.5.0 entry | Modified |

## How it works

**The visual refresh is a token swap.** `scripts/lib/plan-shell.mjs` carries a `CSS` export that is a single template literal. The plan replaced its `:root` block with a new palette of semantic tokens — `--paper` (page background), `--ink` (body text), `--accent` (interactive), `--mono` and `--prose` (type roles) — while aliasing every old name to its replacement so no downstream selector broke. Chrome selectors were retargeted to the new semantic tokens, and the progress bar's shimmer animation was dropped in favour of a flat fill.

**Dark mode is a read-before-first-paint pattern.** A small inline script at the top of `<head>` reads `localStorage.getItem('plan-theme')` and sets `document.documentElement.dataset.theme` before the browser renders anything. This means a plan opened from `file://` — with no server to stamp a class — never flashes the wrong theme. The toggle button in the header flips `dataset.theme` and writes the choice back to localStorage; the OS preference is honoured on first visit.

**The merged goal panel removes the two-abstract problem.** Previously `objectiveCard` and `glanceBlock` rendered as siblings, leaving the reader to determine which was authoritative. `objectiveCard` now accepts an optional `glanceHtml` argument and wraps the At-a-glance block inside `<div id="objective">`. The separate `shell.glanceBlock()` call in `build-plan-html.mjs` was dropped. `extractSections` already stripped `.plan-glance` and read verify text from `class="verify-body"` regardless of wrapper, so the DOM contract was unchanged.

**The step rail gives the sidebar real structure.** Previously the sidebar nav collapsed all steps into a single `steps` entry. Now `nav(ids, steps)` emits both the existing section links (unchanged, matching `/<a href="#([a-z-]+)">/`) and a `<ul class="rail-steps">` of per-step anchors with `id="step-N"` targets. Each rail link carries a visually-hidden state span that announces the step number and done/pending state. Below 900px the step list moves inside a `<details>` so jump targets remain reachable on mobile without taking over the sidebar.

**Client-side gallery grouping keeps the merge driver intact.** `scripts/merge-plans-index.mjs` splices the union of `<a class="gallery-card">` blocks between the first and last card; any static heading between cards is destroyed by a merge and stays destroyed. Month grouping and the In-flight separator are therefore generated by `applyFilters()` in JavaScript from the `data-month` attribute on each card, so the merge driver never sees a group header. The `build-index.sh` scripts were updated to emit `data-month` and sort in-progress cards first, and the gallery template was rebuilt with a search field, a status segmented control, and a type/effort disclosure that hide themselves when cards carry no matching attribute.

**The back-compat guard was narrowed, not removed.** The original guard at `test-build-plan-html.mjs:883` byte-diffed the full rendered document, causing it to fail on every intentional markup change. The narrowed version calls `assert.deepEqual(extractSections(after), extractSections(before))` and adds explicit assertions that the no-prototype render carries no prototype meta tag. This preserves the actual contract — the extractor and gallery generator can still read every rendered plan — while allowing the presentation layer to evolve.

## How to use it

Render any committed plan to see the new design:

```bash
node scripts/build-plan-html.mjs docs/plans/<plan-name>.md -o /tmp/check.html
```

Open the HTML file in a browser. The theme toggle in the top-right corner persists across reloads. Narrow the viewport to 375px to exercise the mobile step-rail disclosure. Run the full test gate:

```bash
node tests/plugins/test-plan-redesign.mjs
node tests/plugins/test-build-plan-html.mjs
bash docs/plans/build-index.sh
bash tests/plugins/test-merge-gallery-index.sh
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
