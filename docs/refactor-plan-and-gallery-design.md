# Rebuild the plan document and gallery design

> Rebuilds the presentation layer of generated plan pages and the plans gallery — design tokens, persisted dark theme, merged goal panel, visible Verify line, sidebar step rail, and gallery controls that surface in-flight plans first.

<!-- generated:start -->

**Status:** Shipped 2026-07-31  **Plan:** [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
**Type:** refactor

## What shipped

- Replaced the `:root` token block in `scripts/lib/plan-shell.mjs` with the prototype's palette (`--paper`, `--ink`, `--accent`, `--moss`, `--signal`, etc.) plus `--mono`, `--ui`, `--prose` font stacks; added full dark palette; retired `--subtle: #9ca3af` (was 2.5:1 contrast, WCAG AA failure).
- Added theme toggle — inline pre-paint script in `<head>`, labelled button with `aria-pressed`, handler writing to `localStorage`.
- Nested the At-a-glance block inside the objective card; replaced `<details class="step-verify-toggle">` with a plain visible `<div class="verify-body">` so the Verify line is always visible.
- Added sidebar step rail — `<ul class="rail-steps">` with one `<a class="rail-step">` per step carrying a visually-hidden state span; step cards emit `id="step-N"`; below 900px the list moves into a `<details>` disclosure.
- Fixed scroll-spy so it clears the active link when nothing intersects.
- Removed retired rules (`.steps-list::before`, `.step-verify-toggle`, `.plan-glance` negative-margin).
- Re-copied `scripts/build-plan-html.mjs` and `scripts/lib/plan-shell.mjs` to their byte-identical `kit/plugins/plan-agent/scripts/` counterparts.
- Rebuilt gallery controls in `plans-gallery.html` — search field, status segmented control with per-status counts, type/effort disclosure; client-side In-flight separator and month groupings; gallery hides status control when no cards carry a status.
- Added `data-month` attribute to gallery cards; sorted in-progress plans first in all three byte-identical build-script copies; regenerated `docs/plans/index.html`, `docs/artifacts/index.html`, `docs/prototypes/index.html`.
- Narrowed the back-compat guard in `tests/plugins/test-build-plan-html.mjs` from whole-document byte-diff to `extractSections` deep-equality.
- Added `tests/plugins/test-plan-redesign.mjs`.
- Bumped plan-agent to `7.5.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `scripts/lib/plan-shell.mjs` | Renderer shell | Modified |
| `scripts/build-plan-html.mjs` | HTML renderer | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled renderer shell | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled renderer | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Gallery template | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Index generator | Modified |
| `scripts/build-plans-index.sh` | Index generator (copy) | Modified |
| `docs/plans/build-index.sh` | Index generator (copy) | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Renderer test | Modified |
| `tests/plugins/test-plan-redesign.mjs` | Design smoke test | Created |
| `docs/plans/index.html` | Generated gallery | Modified |
| `docs/artifacts/index.html` | Generated gallery | Modified |
| `docs/prototypes/index.html` | Generated gallery | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |

## How it works

The previous presentation shell used generic defaults — `system-ui` at 15px, blue links, `1px solid #e5e7eb` on every container — and had six structural failures identified by a visual audit against two prototypes: two stacked goal panels, a hidden Verify line, three competing progress devices, no dark mode, and a WCAG AA failure on tertiary text.

The redesign replaces the CSS token block with a semantic palette (paper/ink/accent/signal/moss), adds a dark palette activated by a pre-paint inline script (so `file://` served plans don't flash the wrong theme), and merges the At-a-glance block into the objective card so a reader hits one goal statement rather than two.

The step rail adds one navigation link per step in the sidebar, exposing the plan's full structure rather than a single collapsed "steps" entry. Each link carries a visually-hidden state span so screen readers can announce done/not-done without relying on the tick glyph.

The gallery controls replace 20 flat filter chips with a search + status segmented control + type/effort disclosure, and the In-flight separator surfaces the currently active plans above the month-grouped historical list. The separator is client-side so the merge driver never sees it between card nodes.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
