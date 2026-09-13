# Give the galleries the row layout and shell the prototype specified

> Replace the plans gallery's card grid with the row list, in-flight step-progress band, and sticky topbar from the plans-site-redesign prototype, and bring all four galleries — plans, artifacts, prototypes, and social — onto a shared token set and shell.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
**Type:** refactor

## What shipped

- Replaced the `.gallery-grid` card rules in `plans-gallery.html` with the prototype's single-column row grid on `.gallery-card` itself (`grid-template-columns: 1.25rem minmax(0,1fr) 9rem 3.5rem`), with `.glyph`, `.r-title`, `.r-meta`, `.r-date` columns and status-specific colour rules from the prototype.
- Added the in-flight band: `[data-status="in-progress"]` rows get `border-left: 2px solid var(--signal)` and a segmented `.bar` drawn client-side from `data-steps-done` / `data-steps-total`, with a server-rendered `N / M steps` fallback that stays visible with JavaScript off.
- Added the sticky topbar (`.topbar` / `.topbar-in`) with five tabs (Home, Plans, Prototypes, Artifacts, Social) each carrying a `<span class="n">` count derived at generation time from the filesystem rather than from parsing sibling `index.html` files.
- Deleted the view toggle (`view-btn`, `list-view`, view-switching JavaScript) from `plans-gallery.html`.
- Updated all three byte-identical build-script copies (`docs/plans/build-index.sh`, `scripts/build-plans-index.sh`, `kit/plugins/plan-agent/hooks/build-index.sh`) to emit the row shape with `data-steps-done`, `data-steps-total`, and an `aria-hidden` status glyph with visually-hidden `sr-only` text.
- Brought `prototypes-gallery.html` and `kit/plugins/social-media-tools/templates/gallery.html` onto the shared token set, adding the theme toggle and topbar; retired `--subtle: #9ca3af` (the pre-503 WCAG failure) from those templates.
- Mirrored the new card heredoc into `kit/plugins/plan-agent/skills/plans-library/SKILL.md`.
- Added `tests/plugins/test-gallery-row-layout.mjs` (end-to-end objective test) and `tests/plugins/test-build-index-parity.mjs` (checksum guard for the three build-script copies).
- Bumped plan-agent to 7.7.0 (not 7.6.0 — PR #505 took that version on main while the branch was open) and social-media-tools to 2.21.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Row layout, in-flight band, topbar; view toggle removed | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Shared token set, theme toggle, row layout, topbar | Modified |
| `kit/plugins/social-media-tools/templates/gallery.html` | Shared token set, theme toggle, topbar | Modified |
| `docs/plans/build-index.sh` | Row card markup, step counts, cross-gallery counts | Modified |
| `scripts/build-plans-index.sh` | Byte-identical copy | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Byte-identical copy | Modified |
| `kit/plugins/plan-agent/hooks/build-artifacts-index.sh` | Row card markup without status glyph | Modified |
| `kit/plugins/plan-agent/hooks/build-prototypes-index.sh` | Row card markup, cross-gallery counts | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Card heredoc kept in step with build scripts | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Topbar variables in gallery generator | Modified |
| `tests/plugins/test-gallery-row-layout.mjs` | End-to-end objective verification | Created |
| `tests/plugins/test-build-index-parity.mjs` | Checksum guard for three build-script copies | Created |
| `.claude-plugin/marketplace.json` | plan-agent 7.5.0 → 7.7.0; social-media-tools 2.20.1 → 2.21.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.7.0 entry | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | 2.21.0 entry | Modified |

## How it works

PR #503 had adopted the prototype's design tokens in `plans-gallery.html` but kept the card grid layout. This plan closed the remaining gap by replacing that grid with the prototype's dense row list.

The merge-driver constraint shaped the row structure. `scripts/merge-plans-index.mjs` splices the union of `<a class="gallery-card">` blocks over the region between the first and last card — anything between cards (a `<ul>` wrapper, `<li>` elements, month headings) is destroyed by a merge. Rows are therefore bare anchors laid out directly inside `#galleryGrid` using a CSS grid on `.gallery-card` itself. The in-flight band is a style applied to `[data-status="in-progress"]` rows in place rather than a separate container.

Each card's step progress comes from the build script counting `class="step-card"` (total) and `class="step-card completed"` (done) in the plan's rendered HTML — data that existed since PR #503 with no new spec field needed. The counts are emitted as `data-steps-done` and `data-steps-total` attributes; a short inline script draws the segmented `.bar`; the `N / M steps` span is server-rendered as a fallback.

The status glyph (✓ / ○) is `aria-hidden` with a visually-hidden `<span class="sr-only">` sibling carrying the status text, so screen readers announce the status without the card's `aria-label` overriding the row's visible content.

Scope grew once the topbar was confirmed: `prototypes-gallery.html` still declared `--subtle: #9ca3af` (the retired 2.5:1 WCAG failure from before PR #503), and `social-media-tools/templates/gallery.html` was a hardcoded dark-only palette with no light mode. Both were moved onto the shared token set in the same change, because a topbar pointing at two pages that look like a different site is not shippable.

Two deviations from plan: status is selected via `[data-status]` attribute selectors rather than the prototype's `.s-completed` / `.s-in-progress` / `.s-todo` classes (a second class would have broken `CARD_RE`); and the media gallery's nine per-type badge hues became one neutral badge because the fixed dark colours fell under 4.5:1 once the page gained a light theme.

## How to use it

This is an internal infrastructure change. The four gallery indexes (`docs/plans/index.html`, `docs/artifacts/index.html`, `docs/prototypes/index.html`, `docs/media/social/index.html`) are regenerated by their respective build scripts and reflect the new layout automatically.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
