# Give the galleries the row layout and shell the prototype specified

> The plans gallery's card grid was replaced with the prototype's row list and in-flight step bar; all four galleries now share a sticky topbar; plan-agent shipped as 7.7.0 (landed as 7.7.0, not 7.6.0 as planned).

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
**Type:** refactor

## What shipped

- Added `tests/plugins/test-build-index-parity.mjs` first, asserting the three byte-identical `build-index.sh` copies hash identically before any edits landed.
- Replaced the `.gallery-grid` card rules in `plans-gallery.html` with the prototype's single-column row grid applied directly to `.gallery-card`, deleted `.view-toggle`, `.view-btn`, both toggle buttons, and the view-switching JavaScript.
- Added in-flight band styling for `[data-status="in-progress"]` rows with a client-side step progress bar (segments drawn from `data-steps-done`/`data-steps-total`) and server-rendered `N / M steps` text.
- Updated the card emitter in all three byte-identical build scripts to the row shape with a status glyph (`✓` / `○`), `aria-hidden` glyph with a visually-hidden text sibling, `.r-title`, `.r-meta`, `.r-date`, and `data-steps-done`/`data-steps-total` on in-progress cards.
- Mirrored the new card heredoc into `kit/plugins/plan-agent/skills/plans-library/SKILL.md`.
- Brought artifacts, prototypes, and social galleries onto the row layout (no status glyph for artifacts; prototypes adopted the shared token set and theme toggle, fixing a live WCAG AA failure from `--subtle: #9ca3af`).
- Added the sticky topbar to all galleries with five tabs (Home, Plans, Prototypes, Artifacts, Social), per-directory counts from the filesystem, and `aria-current="page"` on the active tab.
- Updated `kit/plugins/social-media-tools/templates/gallery.html` from hardcoded dark-only to the shared token set with a light theme and theme toggle.
- Added `tests/plugins/test-gallery-row-layout.mjs` and regenerated all four gallery indexes.
- Bumped plan-agent to 7.7.0 and social-media-tools to 2.21.0 (plan-agent 7.6.0 was taken by a concurrent PR on main).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Row layout, in-flight band, topbar; view toggle deleted | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Shared token set, theme toggle, row layout, topbar | Modified |
| `kit/plugins/social-media-tools/templates/gallery.html` | Shared token set, light/dark theme, topbar | Modified |
| `docs/plans/build-index.sh` | Row card markup, step counts, cross-gallery counts | Modified |
| `scripts/build-plans-index.sh` | Same edit, byte-identical | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Same edit, byte-identical | Modified |
| `kit/plugins/plan-agent/hooks/build-artifacts-index.sh` | Row card markup without status glyph | Modified |
| `kit/plugins/plan-agent/hooks/build-prototypes-index.sh` | Row card markup, cross-gallery counts | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Card heredoc kept in sync with build scripts | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Topbar count variables | Modified |
| `tests/plugins/test-gallery-row-layout.mjs` | Objective-verification test | Created |
| `tests/plugins/test-build-index-parity.mjs` | Checksum guard for three build-script copies | Created |
| `.claude-plugin/marketplace.json` | plan-agent → 7.7.0, social-media-tools → 2.21.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.7.0 entry | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | 2.21.0 entry | Modified |

## How it works

PR #503 had adopted the prototype's design tokens but kept the card grid layout, leaving `docs/plans/index.html` as a 2-up card grid wearing the right palette while the prototype specified a single-column row list. This plan closed that gap.

The row layout replaces the grid with `grid-template-columns: 1.25rem minmax(0,1fr) 9rem 3.5rem` applied directly to `.gallery-card` — keeping `<a class="gallery-card">` as the leading attribute pair with no nested anchors and no `<li>` wrappers. This preserves the `CARD_RE` regex in `scripts/merge-plans-index.mjs` exactly, so the merge driver continues to function unedited.

The in-flight step bar was possible because `build-index.sh` already reads each plan's rendered HTML for meta tags, and since PR #503 every plan carries one `class="step-card"` per step and `class="step-card completed"` per done step. The scripts count both patterns to derive `data-steps-done` / `data-steps-total`; the bar is drawn client-side from those attributes while the `N / M steps` text is server-rendered so it remains visible with JavaScript off.

The topbar tab counts come from the filesystem at generation time (`*.html` minus `index.html` in each collection directory) rather than from parsing sibling `index.html` files — since the four generators run in arbitrary order, parsing would read stale indexes. The topbar reads the resolved `plansDirectory` rather than a fixed `docs/plans`, so a project with a custom plans location gets correct counts and tab hrefs.

The completion notes record that the topbar background is declared with an opaque `--paper` value before the `color-mix` value, ensuring the bar stays legible when `color-mix` is unsupported. They also record that the current tab's count uses `--accent-soft` which measured slightly under 4.5:1 at first, requiring a colour adjustment; the glyph colour dropped the prototype's `opacity: 0.5` for the same reason.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
- Prototype: `docs/prototypes/plans-site-redesign.html`
- Previous plan: [refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
