# Rebuild the plan document and gallery design

> Rebuild the presentation layer of generated plan pages and the gallery index with design tokens, persisted dark theme, a merged goal panel, an always-visible Verify line, a sidebar step rail, and gallery controls that surface in-flight work first.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
**Type:** refactor

## What shipped

- Replaced the `:root` token block in `scripts/lib/plan-shell.mjs` with a new palette (`--paper`, `--ink`, `--accent`, `--moss`, `--signal`, etc.) plus dark-mode rules under both `[data-theme="dark"]` and `prefers-color-scheme: dark`; retired `--subtle: #9ca3af` (2.5:1 contrast, WCAG failure).
- Added theme toggle: inline `<head>` script reads stored preference before first paint; labelled button with `aria-pressed` in the header; click handler writes to `localStorage`.
- Merged the At-a-glance block inside the objective card; removed the negative-margin hack.
- Replaced `stepCard`'s `<details>` wrapper for Verify text with a plain labelled block, keeping `<div class="verify-body">` intact.
- Added a step rail to the sidebar: each `.step-card` gets `id="step-N"`; `nav()` now emits a `<ul class="rail-steps">` with one `<a class="rail-step">` per step carrying visually-hidden state text; rail collapses to a `<details>` below 900px.
- Fixed the scroll-spy observer to clear the active link when nothing intersects.
- Deleted `.steps-list::before`, `.step-verify-toggle`, and the `.plan-glance` sibling margin; removed all step 1 token aliases.
- Re-copied `scripts/build-plan-html.mjs` and `scripts/lib/plan-shell.mjs` to byte-identical `kit/plugins/plan-agent/scripts/` counterparts.
- Rebuilt gallery controls in `plans-gallery.html`: search field, status segmented control with per-status counts, type/effort `<details>`; added "In flight" and month separators rendered client-side from `data-month`.
- Emitted `data-month` on each card and sorted in-progress plans first in all three byte-identical build scripts; regenerated all three gallery indexes.
- Shipped `tests/plugins/test-plan-redesign.mjs`; bumped plan-agent to `7.5.0`.

> See [CHANGELOG v7.5.0](../kit/plugins/plan-agent/CHANGELOG.md) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | Tokens, dark palette, type roles, theme toggle, objective/step markup, step rail, scroll-spy fix | Modified |
| `scripts/build-plan-html.mjs` | Nest glance in objective card; pass step list to `nav()` | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Search, status segmented control, type/effort disclosure, client-side grouping | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | `data-month` attribute, in-progress-first sort | Modified |
| `scripts/build-plans-index.sh` | Same edit, kept byte-identical | Modified |
| `docs/plans/build-index.sh` | Same edit, kept byte-identical | Modified |
| `tests/plugins/test-plan-redesign.mjs` | Objective-verification smoke test | Created |
| `tests/plugins/test-build-plan-html.mjs` | Back-compat guard narrowed from byte-diff to `extractSections` diff | Modified |

## How it works

The 1930-line `plan-shell.mjs` CSS export had drifted into generic defaults: `system-ui` at 15px, `#2563eb` blue, `4px` radius, `1px solid #e5e7eb` on every container. A visual audit found six failures: two sibling abstracts at the top, `Verify:` hidden behind a disclosure, three competing progress devices, `--subtle` failing WCAG at 2.5:1, and no dark mode.

The token replacement was done first because it carries zero DOM risk — the back-compat guard blanks the `<style>` block during comparison. Every retired token name was kept as an alias pointing at its replacement through step 5, then all aliases were removed in step 6 once every caller had moved.

The back-compat guard at `tests/plugins/test-build-plan-html.mjs:883` was narrowed before any markup changes: from a whole-document byte-diff to `assert.deepEqual(extractSections(after), extractSections(before))` plus explicit assertions about the prototype meta tag. This made the guard protect the DOM contract the extractor reads rather than failing on every intentional markup change.

The theme toggle reads `localStorage` in an inline `<head>` script before first paint so a plan opened from `file://` doesn't flash the wrong theme on load. The button uses `aria-pressed` and a 44×44px hit area; it is hidden in the print stylesheet.

Nesting the glance inside the objective card removed the need for the negative-margin hack (`margin: -1.5rem 0 1.5rem`) that pulled the second abstract up against the first. `extractSections` already strips a nested `.plan-glance` and was unchanged.

The step rail emits one `<a class="rail-step" href="#step-N">` per step with the step's action text and a visually-hidden state span ("step N of M, done" or "step N of M"). The existing `progressBlock` and `NAV_ENTRIES` id list were left untouched to keep the progress JavaScript and both nav `deepEqual` arrays passing.

Client-side month separators and the In-flight band are injected by `applyFilters()` from `data-month` attributes on the cards rather than baked into the generated markup. This keeps separators out of the region `scripts/merge-plans-index.mjs` splices, so the merge driver and `tests/plugins/test-merge-gallery-index.sh` needed no changes.

## How to use it

The changes are automatic — any plan rendered via `node scripts/build-plan-html.mjs` or by the plugin's hooks receives the new shell.

The theme toggle button appears in the plan page header. The preference is stored under `plan-theme` in `localStorage` and honoured by all gallery pages.

Gallery controls: use the search field to filter by title, the status segmented control to filter by completion state, or the type/effort disclosure chips for further narrowing. The In-flight band always appears at the top when any in-progress plans exist.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |
| `22e2280` | 2026-08-30 | fix(plan-agent): unbreak the build completion gate for artifact-only plans (9.10.1) (#610) |
| `d2e9f10` | 2026-09-02 | feat: polish the plan-document HTML output (#617) |
| `b8cfa1f` | 2026-09-04 | fix(plan-agent): style header links as chips and refocus a leading select after submit (9.13.1) (#623) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `1c31569` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |

<!-- generated:end -->

## References

- Plan: [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
- Prototypes: docs/prototypes/plan-document-redesign.html, docs/prototypes/plans-site-redesign.html
