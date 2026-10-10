# Rebuild the plan document and gallery design

> Rebuild the presentation layer of generated plan pages with design tokens, a persisted dark theme, one merged goal panel, always-visible Verify lines, a sidebar step rail, and gallery controls — without changing the DOM contract the extractor and gallery generator depend on.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
**Type:** refactor

## What shipped

- Replaced the `:root` token block in `plan-shell.mjs` with the prototype's palette (`--paper`, `--panel`, `--sunk`, `--ink`, `--ink-2`, `--ink-3`, `--rule`, `--rule-soft`, `--accent`, `--accent-soft`, `--accent-line`, `--moss`, `--signal`, `--mono`, `--ui`, `--prose`) including a complete dark palette under both `[data-theme="dark"]` and `prefers-color-scheme: dark`; retired `--subtle: #9ca3af` (which measured 2.5:1 on white).
- Added a theme toggle button in the plan header with `aria-pressed`, a 44×44px hit area, and a `<head>` inline script that reads `localStorage` before first paint to avoid a wrong-theme flash on `file://` opens.
- Nested the At-a-glance block inside `objectiveCard()` so readers see one goal panel instead of two stacked summaries; promoted `Verify:` text out of `<details>` into a plain labelled block.
- Added a sidebar step rail: each step card gets `id="step-N"`; `nav()` emits a `<ul class="rail-steps">` of `<a class="rail-step" href="#step-N">` links each carrying the step's action text and a visually-hidden state span; below 900px the step list moves inside a `<details>` so mobile readers keep the jump targets.
- Fixed the scroll-spy observer to clear `.active` when nothing intersects.
- Deleted superseded rules (`.steps-list::before`, `.step-verify-toggle`, `.plan-glance` negative-margin), removed step 1 token aliases, and repointed selectors naming retired token names.
- Re-copied `scripts/lib/plan-shell.mjs` and `scripts/build-plan-html.mjs` into `kit/plugins/plan-agent/scripts/`.
- Rebuilt the gallery controls in `plans-gallery.html`: search field, status segmented control with per-status counts, `<details>` holding type and effort chips; `applyFilters()` inserts In-flight and month separators client-side so the merge driver never sees non-card content.
- Emitted `data-month` on each card and sorted in-progress plans first in all three byte-identical build-script copies; regenerated `docs/plans/index.html`, `docs/artifacts/index.html`, and `docs/prototypes/index.html`.
- Added `tests/plugins/test-plan-redesign.mjs`; narrowed the back-compat guard to `extractSections` deep-equality rather than a whole-document byte diff.
- Bumped plan-agent from 7.4.4 to 7.5.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | Design tokens, dark palette, theme toggle, step rail, markup | Modified |
| `scripts/build-plan-html.mjs` | Nests glance in objective card; passes steps to nav() | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy (re-copied) | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy (re-copied) | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Search, status segmented control, type/effort disclosure, client-side grouping | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | `data-month` attribute, in-progress-first sort | Modified |
| `scripts/build-plans-index.sh` | Byte-identical copy | Modified |
| `docs/plans/build-index.sh` | Byte-identical copy | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Back-compat guard narrowed to extractSections | Modified |
| `tests/plugins/test-plan-redesign.mjs` | Objective-verification smoke test | Created |
| `.claude-plugin/marketplace.json` | plan-agent 7.4.4 → 7.5.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.5.0 entry | Modified |

## How it works

Before this plan, `scripts/lib/plan-shell.mjs` was a 1930-line module that had drifted to a generic default: `system-ui` at 15px, `#2563eb` blue, 4px radius borders, and a `1px solid #e5e7eb` wrapper on every container. Six concrete failures were identified: two sibling goal panels, `Verify:` hidden in a `<details>`, three competing progress devices, `--subtle: #9ca3af` failing WCAG AA at 2.5:1, and no dark mode.

The token replacement in step 1 carried old token names as aliases so that downstream selectors remained valid across the subsequent steps. Only step 6 removed the aliases, after every selector had been repointed — this kept the back-compat test green on each intermediate commit.

Nesting the glance inside `objectiveCard()` was safe because `extractSections` in `plan-spec.mjs` already strips a nested `.plan-glance` and reads verify text from `class="verify-body"` regardless of its wrapper. The back-compat guard was narrowed from a whole-document byte diff to an `extractSections` deep-equality before any markup change landed — so the change could proceed without every intentional redesign appearing as a regression.

The step rail was added as a separate `<ul class="rail-steps">` emitted by `nav()` alongside the existing section links, preserving the existing `<a href="#([a-z-]+)">` section-link regex and the two nav id `deepEqual` arrays in the tests. The `progressBlock` and `NAV_ENTRIES` were left exactly in place to avoid invalidating those tests for a cosmetic gain.

Client-side month and In-flight separators in the gallery were a direct consequence of the merge-driver constraint: `scripts/merge-plans-index.mjs` splices over everything between the first and last `<a class="gallery-card">` card, so any static separator baked into generated HTML would be destroyed by the first concurrent merge and stay missing until the next regeneration. Rendering separators in `applyFilters()` sidesteps this entirely.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
