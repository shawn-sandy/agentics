# Give the galleries the row layout and shell the prototype specified

> Replaces the plans gallery's 2-up card grid with a dense row list, in-flight step-progress bar, and sticky topbar from the signed-off prototype, and brings the artifacts, prototypes, and social galleries onto the same shared token shell — shipped as plan-agent 7.7.0 and social-media-tools 2.21.0.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
**Type:** refactor

## What shipped

- Replaced the `.gallery-grid` card rules in `plans-gallery.html` with the prototype's single-column row grid; deleted the view-toggle, both toggle buttons, and all view-switching JavaScript
- Added `.glyph`, `.r-title`, `.r-meta`, `.r-date`, status-colour rules, `.sr-only`, and the in-flight bar script to the template
- Styled in-progress cards with a segmented `<i>` bar driven by `data-steps-done` / `data-steps-total` attributes, with server-rendered `N / M steps` text that survives without JavaScript
- Updated all three byte-identical build scripts (`docs/plans/build-index.sh`, `scripts/build-plans-index.sh`, `kit/plugins/plan-agent/hooks/build-index.sh`) to emit the row card shape with status glyphs, `sr-only` text siblings, and step-count attributes
- Mirrored the card heredoc into `kit/plugins/plan-agent/skills/plans-library/SKILL.md`
- Updated `build-artifacts-index.sh` and `build-prototypes-index.sh` to emit row markup; updated `prototypes-gallery.html` to the shared token set
- Replaced the hardcoded dark palette in `social-media-tools/templates/gallery.html` with the shared token set, dark rules, pre-paint theme script, and theme toggle; updated `media-library/SKILL.md` with count variables
- Added a sticky topbar with five tabs (Home, Plans, Prototypes, Artifacts, Social) with per-directory counts and `aria-current="page"` to `plans-gallery.html` and `prototypes-gallery.html`
- Added `tests/plugins/test-gallery-row-layout.mjs` (objective verification) and `tests/plugins/test-build-index-parity.mjs` (checksum guard for the three build-script copies)
- Regenerated all four gallery indexes
- Bumped plan-agent from 7.5.0 to 7.7.0 (7.6.0 was taken by PR #505 on main) and social-media-tools from 2.20.1 to 2.21.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Row layout, in-flight band, topbar; view toggle deleted | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Shared token set, theme toggle, row layout, topbar | Modified |
| `kit/plugins/social-media-tools/templates/gallery.html` | Shared token set, theme toggle, topbar | Modified |
| `docs/plans/build-index.sh` | Row card markup, step counts, cross-gallery counts | Modified |
| `scripts/build-plans-index.sh` | Same edit, kept byte-identical | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Same edit, kept byte-identical | Modified |
| `kit/plugins/plan-agent/hooks/build-artifacts-index.sh` | Row card markup without status glyph | Modified |
| `kit/plugins/plan-agent/hooks/build-prototypes-index.sh` | Row card markup, cross-gallery counts | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Card heredoc kept in step with the build scripts | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Topbar count variables in gallery generator | Modified |
| `docs/plans/index.html` | Regenerated | Modified |
| `docs/artifacts/index.html` | Regenerated | Modified |
| `docs/prototypes/index.html` | Regenerated | Modified |
| `docs/media/social/index.html` | Regenerated | Modified |
| `tests/plugins/test-gallery-row-layout.mjs` | Objective-verification test | Created |
| `tests/plugins/test-build-index-parity.mjs` | Checksum guard for three build-script copies | Created |
| `.claude-plugin/marketplace.json` | plan-agent 7.5.0 → 7.7.0, social-media-tools 2.20.1 → 2.21.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.6.0/7.7.0 entries | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | 2.21.0 entry | Modified |

## How it works

PR #503 gave the plans gallery the prototype's design tokens but kept its 2-up card grid. This plan closes the layout gap: the gallery now renders the single-column row list, in-flight step bar, and sticky topbar that the prototype specifies.

The row grid is applied directly to `.gallery-card` elements (`grid-template-columns: 1.25rem minmax(0,1fr) 9rem 3.5rem`) rather than a `<ul><li>` wrapper. This is a hard constraint: `scripts/merge-plans-index.mjs` splices over everything between the first and last card in the index, so any `<li>` element between cards would be destroyed by the first concurrent merge. The merge-driver regex (`CARD_RE`) matches `<a class="gallery-card">…</a>` without a nested anchor — the row shape preserves both invariants.

The in-flight band is a style applied in-place to `[data-status="in-progress"]` rows rather than a separate container, for the same reason. `build-index.sh` already reads each plan's rendered HTML for meta tags; it now counts `class="step-card"` occurrences for the total (matching the quote or a trailing space to include both plain and `completed` variants) and `class="step-card completed"` for done, emitting them as `data-steps-done` / `data-steps-total`. The inline JavaScript draws `<i>` bar segments client-side; the `N / M steps` span is server-rendered so the count is present with JavaScript disabled.

The three byte-identical build scripts were a co-ordination hazard — convention alone kept them in sync. `test-build-index-parity.mjs` now asserts their checksums are identical, and exits with the offending path named on the first divergence. A status glyph (`✓` / `○`) carries `aria-hidden="true"` with a visually-hidden text sibling (`<span class="sr-only">completed</span>`) so screen readers announce the status before the title without overriding the row's own text.

`prototypes-gallery.html` still carried `--subtle: #9ca3af`, the retired token that measures 2.5:1 on white — a live WCAG AA failure. It was replaced with the shared token set in the same change. `social-media-tools/templates/gallery.html` was dark-only with no light mode; it received the shared palette, pre-paint theme script, and theme toggle. Both templates now honour a `plan-theme` preference set on any other gallery.

Two Completion Report deviations are worth noting. Status is selected via `[data-status]` attribute selectors rather than the prototype's `.s-completed` etc. class names, because `CARD_RE` matches the `class` attribute with its closing quote, making a second class invisible to the driver. The queued glyph drops the prototype's `opacity: .5` because `--ink-3` at 50% opacity falls under 4.5:1 against the page background; it reads at full `--ink-3` (5.06:1 light, 5.42:1 dark). The topbar tab count text uses the accent colour; the current-tab pairing (`--ink-3` on `--accent-soft`) measured 4.46:1, under AA by a hair, so a token adjustment was applied. The media gallery's per-type badge hues were neutralised since half fell under 4.5:1 on the new light background.

The final version shipped as 7.7.0 rather than the planned 7.6.0 because PR #505 claimed 7.6.0 on main while this branch was open.

## How to use it

Open any of the four gallery indexes in a browser. The plans gallery at `docs/plans/index.html` renders one row per plan with a status glyph, type, effort, and date. In-progress plans show a segmented step-progress bar and a `N / M steps` label. A sticky topbar at the top of every gallery links to all four collections with live counts.

The theme toggle persists a `plan-theme` key in `localStorage`; switching themes on any gallery is honoured by all others on the same origin.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
- Prototype: [docs/prototypes/plans-site-redesign.html](prototypes/plans-site-redesign.html)
- Previous plan: [docs/plans/refactor-plan-and-gallery-design.md](plans/refactor-plan-and-gallery-design.md)
