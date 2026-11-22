# Refactor gallery rows and topbar

> PR #503 gave the plans gallery the prototype's colours but left its card grid in place, so the shipped page still did not look like the signed-off design. This swaps the 2-up cards for the prototype's dense row list, adds an in-flight step progress bar, and puts one sticky topbar across all four galleries.

<!-- generated:start -->

**Status:** Shipped 2026-08-01 **Plan:** [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
**Type:** refactor

## What shipped

- Replaced the plans gallery's `.gallery-grid` card rules with the prototype's row grid in `plans-gallery.html`; deleted the view toggle, `.view-btn`, and view-switching JavaScript.
- Added in-flight band: `.gallery-card[data-status="in-progress"]` styled with a left-border stripe; `data-steps-done`/`data-steps-total` derived from `step-card completed` counts in each plan's HTML; a segmented bar drawn client-side; `N / M steps` text server-rendered for no-JS.
- Added sticky topbar with five tabs (Home, Plans, Prototypes, Artifacts, Social) in `plans-gallery.html` and `prototypes-gallery.html`; counts derived from filesystem at generation time; `aria-current="page"` on the active tab.
- Brought `prototypes-gallery.html` and `social-media-tools/templates/gallery.html` onto the shared token set, theme toggle, and pre-paint theme script from `plans-gallery.html`; the WCAG-failing `--subtle: #9ca3af` token removed from both.
- Updated the three byte-identical build scripts (`docs/plans/build-index.sh`, `scripts/build-plans-index.sh`, `kit/plugins/plan-agent/hooks/build-index.sh`) to emit the row card shape; `build-artifacts-index.sh` and `build-prototypes-index.sh` likewise.
- Kept `plans-library/SKILL.md` and `media-library/SKILL.md` card heredocs in sync with the build scripts.
- Added `tests/plugins/test-gallery-row-layout.mjs`: splice-unit constraints, step-count derivation, topbar, no view toggle, no retired tokens.
- Added `tests/plugins/test-build-index-parity.mjs`: checksum guard for the three byte-identical build-script copies.
- Regenerated all four indexes.
- Landed as plan-agent 7.7.0 (7.6.0 was taken by PR #505 while this branch was open); social-media-tools 2.21.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Row layout, in-flight band, topbar | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Shared token set + topbar | Modified |
| `kit/plugins/social-media-tools/templates/gallery.html` | Shared token set + topbar | Modified |
| `docs/plans/build-index.sh` | Row card emitter + step counts | Modified |
| `scripts/build-plans-index.sh` | Byte-identical | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Byte-identical | Modified |
| `kit/plugins/plan-agent/hooks/build-artifacts-index.sh` | Row cards, no status glyph | Modified |
| `kit/plugins/plan-agent/hooks/build-prototypes-index.sh` | Row cards + cross-gallery counts | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Card heredoc in sync | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Topbar count variables | Modified |
| `tests/plugins/test-gallery-row-layout.mjs` | Objective-verification test | Created |
| `tests/plugins/test-build-index-parity.mjs` | Build-script checksum guard | Created |
| `docs/plans/index.html` | Regenerated | Modified |
| `docs/artifacts/index.html` | Regenerated | Modified |
| `docs/prototypes/index.html` | Regenerated | Modified |
| `docs/media/social/index.html` | Regenerated | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 7.7.0, social-media-tools 2.21.0 | Modified |

## How it works

**Row layout**: Each `<a class="gallery-card">` is a CSS grid row (`grid-template-columns: 1.25rem minmax(0,1fr) 9rem 3.5rem`) rather than a card tile. `<a class="gallery-card"` remains the leading attribute pair so the merge driver's `CARD_RE` and `COUNT_RE` match without change — the driver source was not edited.

**Step bar**: The build scripts count `class="step-card"` (all steps, including completed) and `class="step-card completed"` from each plan's existing HTML. These go into `data-steps-done` and `data-steps-total`; an inline script draws `<i>` segments client-side; the `N / M steps` text is server-rendered for no-JS.

**In-flight band**: Rows with `data-status="in-progress"` are styled in place with a left border stripe. No separate container is used — the merge driver splices over everything between the first and last card, so a container there would be destroyed on the first concurrent merge.

**Topbar**: Each gallery reads its collection count from the filesystem at generation time (not from sibling `index.html` files, which could be stale). Tab hrefs are computed with `os.path.relpath` between each target index and the page being generated. The Plans tab reads `plansDirectory` from project config rather than a fixed `docs/plans`.

## How to use it

The changes are automatic — regenerating any gallery index from its build script produces the new layout. No invocation change needed.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-08-01 | refactor(plan-agent): row layout, in-flight step bar, sticky topbar, shared shell across four galleries (7.7.0) |

<!-- generated:end -->

## References

- Plan: [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
