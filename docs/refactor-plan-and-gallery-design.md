# Rebuild the plan document and gallery design

> Generated plan pages were hard to scan — two stacked summaries, every section in an identical bordered box, the Verify line hidden behind a disclosure, three competing progress devices, no dark mode, and a tertiary text colour failing WCAG at 2.5:1. This rebuilds the presentation shell around a monochrome-plus-serif-prose type system, a step rail, and a gallery that leads with in-flight work.

<!-- generated:start -->

**Status:** Shipped 2026-07-31 **Plan:** [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
**Type:** refactor

## What shipped

- Replaced the `:root` token block in `plan-shell.mjs` with the prototype's palette (`--paper`, `--ink`, `--ink-2`, `--ink-3`, `--rule`, `--accent`, `--moss`, `--signal`, `--mono`, `--ui`, `--prose`); added dark palette under `:root[data-theme="dark"]` and `@media (prefers-color-scheme: dark)`; retired `--subtle: #9ca3af` (the WCAG 2.5:1 failure).
- Added theme toggle: inline `<head>` script reads stored preference before first paint; labelled button with `aria-pressed` in the header; handler in `SCRIPT` block.
- Merged glance block inside the objective card; removed `<details>` wrapper from `Verify:` text — it is now a plain labelled block with `class="verify-body"` intact.
- Added step rail to sidebar: each `.step-card` gets `id="step-N"`; `nav()` now emits a `<ul class="rail-steps">` of `<a class="rail-step">` links with visually-hidden state spans; `progressBlock` and `NAV_ENTRIES` left untouched.
- Fixed scroll-spy to clear active link when no section intersects.
- Deleted superseded rules (`.steps-list::before`, `.step-verify-toggle`, `.plan-glance` sibling margin).
- Narrowed the back-compat guard in `test-build-plan-html.mjs` from a whole-document byte-diff to `extractSections` deep-equality.
- Added gallery controls to `plans-gallery.html`: search field, status segmented control with per-status counts, type and effort `<details>` disclosures; client-side "In flight" and month separators (never baked into markup, so the merge driver is unaffected).
- Emitted `data-month` on each card and sorted in-progress plans first in all three byte-identical build scripts.
- Synced bundled copies under `kit/plugins/plan-agent/scripts/`.
- Added `tests/plugins/test-plan-redesign.mjs`.
- Bumped plan-agent to 7.5.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | Full design token and markup rewrite | Modified |
| `scripts/build-plan-html.mjs` | Glance nesting, step list pass | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Gallery controls + client-side grouping | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | data-month + in-progress-first sort | Modified |
| `scripts/build-plans-index.sh` | Byte-identical | Modified |
| `docs/plans/build-index.sh` | Byte-identical | Modified |
| `docs/plans/index.html` | Regenerated | Modified |
| `docs/artifacts/index.html` | Regenerated | Modified |
| `docs/prototypes/index.html` | Regenerated | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Narrowed back-compat guard | Modified |
| `tests/plugins/test-plan-redesign.mjs` | Objective-verification smoke test | Created |
| `.claude-plugin/marketplace.json` | plan-agent → 7.5.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.5.0 entry | Modified |

## How it works

**Token system**: Every colour is a CSS custom property with a dark-mode override. The pre-paint theme script reads `localStorage['plan-theme']` before first paint so there is no flash-of-wrong-theme on `file://` pages. `--subtle` is gone; selectors that used it now use `--ink-3`, which measures ≥4.5:1 in both themes.

**Merged objective**: The glance renders inside `id="objective"`, not as a sibling. `extractSections` strips nested `.plan-glance` already, so the round-trip is lossless.

**Step rail**: Steps are reachable by anchor (`#step-N`) and listed in the sidebar. The nav id list is unchanged so existing tests keep passing.

**Gallery separators**: "In flight" and month group headings are inserted by `applyFilters()` on every filter change. They are never baked into the generated markup, so the merge driver's `CARD_RE` never sees them and `test-merge-gallery-index.sh` needed no changes.

## How to use it

The changes are automatic — plan pages regenerated from this version forward use the new design. The theme toggle appears in every rendered plan header.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-07-31 | refactor(plan-agent): rebuild plan document and gallery design — tokens, dark mode, step rail, merged goal panel, gallery controls (7.5.0) (#500) |

<!-- generated:end -->

## References

- Plan: [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
