# Give the galleries the row layout and shell the prototype specified

> Replaces the plans gallery card grid with a row list and step-progress bar, adds a sticky topbar across all four galleries, and brings prototypes and social galleries onto the shared design token set.

<!-- generated:start -->

**Status:** Shipped 2026-08-01  **Plan:** [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
**Type:** refactor

## What shipped

- Updated `kit/plugins/plan-agent/templates/plans-gallery.html` — replaced the `.gallery-grid` card rules with the prototype's dense row grid, added in-flight band styling (`border-left`, step bar, `N / M steps` text), deleted the view toggle, added the sticky topbar with five tabs and per-collection counts.
- Updated `kit/plugins/plan-agent/templates/prototypes-gallery.html` — replaced the pre-503 token block (including the WCAG-failing `--subtle: #9ca3af`) with the shared palette, dark rules, and pre-paint theme script; added the topbar.
- Updated `kit/plugins/social-media-tools/templates/gallery.html` — replaced the hardcoded dark-only palette with the shared token set; added the theme toggle and topbar with Social marked active; gallery retains its image-card layout.
- Updated `docs/plans/build-index.sh`, `scripts/build-plans-index.sh`, and `kit/plugins/plan-agent/hooks/build-index.sh` (kept byte-identical) — row card markup with `aria-hidden` glyph + `sr-only` status text, `data-steps-done`/`data-steps-total` from plan HTML `step-card` counts, `N / M steps` span for in-progress plans only, cross-gallery topbar counts.
- Updated `kit/plugins/plan-agent/hooks/build-artifacts-index.sh` and `build-prototypes-index.sh` — row card markup and topbar variables.
- Updated `kit/plugins/plan-agent/skills/plans-library/SKILL.md` and `kit/plugins/social-media-tools/skills/media-library/SKILL.md` — kept card heredocs in step with the build scripts.
- Added `tests/plugins/test-gallery-row-layout.mjs` — asserts splice-unit constraints, step-count derivation, no view-toggle, five-tab topbar, and visually-hidden status text.
- Added `tests/plugins/test-build-index-parity.mjs` — checksum guard for the three byte-identical build-script copies.
- Regenerated `docs/plans/index.html`, `docs/artifacts/index.html`, `docs/prototypes/index.html`, `docs/media/social/index.html`.
- Bumped plan-agent to `7.7.0` and social-media-tools to `2.21.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Gallery template | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Prototypes template | Modified |
| `kit/plugins/social-media-tools/templates/gallery.html` | Social media template | Modified |
| `docs/plans/build-index.sh` | Index generator | Modified |
| `scripts/build-plans-index.sh` | Index generator (copy) | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Index generator (copy) | Modified |
| `kit/plugins/plan-agent/hooks/build-artifacts-index.sh` | Artifacts index generator | Modified |
| `kit/plugins/plan-agent/hooks/build-prototypes-index.sh` | Prototypes index generator | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Skill instructions | Modified |
| `tests/plugins/test-gallery-row-layout.mjs` | Row layout test | Created |
| `tests/plugins/test-build-index-parity.mjs` | Script parity test | Created |
| `docs/plans/index.html` | Generated gallery | Modified |
| `docs/artifacts/index.html` | Generated gallery | Modified |
| `docs/prototypes/index.html` | Generated gallery | Modified |
| `docs/media/social/index.html` | Generated gallery | Modified |
| `.claude-plugin/marketplace.json` | Marketplace versions | Modified |

## How it works

PR #503 adopted the prototype's design tokens in `plans-gallery.html` but kept the card grid layout. This plan closes the remaining gap by replacing the grid with the prototype's single-column row list.

Each card is a bare `<a class="gallery-card">` with no nested `<a>` and no `<li>` wrapper, preserving the `CARD_RE` pattern that `scripts/merge-plans-index.mjs` uses to splice concurrent gallery updates. The in-flight band is styled in-place on `[data-status="in-progress"]` rows rather than moved into a container, because the merge driver would destroy any content between cards on the next concurrent merge.

Step counts (`data-steps-done`, `data-steps-total`) are derived from `class="step-card"` and `class="step-card completed"` in each plan's rendered HTML — data the build script already reads for meta tags. The `N / M steps` text is server-rendered so it survives with JavaScript off; the segmented bar is drawn client-side from the two attributes.

The topbar tab counts are derived from `*.html` files (minus `index.html`) in each collection directory at generation time, so counts are always current regardless of generator order.

The prototypes template's `--subtle: #9ca3af` was a live WCAG AA failure (2.5:1 contrast). Bringing it onto the shared token set removes the failure and aligns all four galleries visually.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
