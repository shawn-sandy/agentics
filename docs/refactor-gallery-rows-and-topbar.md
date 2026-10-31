# Give the galleries the row layout and shell the prototype specified

> Replaces the plans gallery's 2-up card grid with the prototype's dense row list, in-flight step-progress band, and sticky cross-gallery topbar — and brings the artifacts, prototypes, and social galleries onto the same shell.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [refactor-gallery-rows-and-topbar](plans/refactor-gallery-rows-and-topbar.md)
**Type:** refactor

## What shipped

- Replaced the `.gallery-grid` card rules in `plans-gallery.html` with single-column row layout (`grid-template-columns: 1.25rem minmax(0,1fr) 9rem 3.5rem`)
- Added in-flight step bars: `data-steps-done`/`data-steps-total` attributes derived from step-card counts in plan HTML; a JavaScript bar draws lit segments from those attributes; `N / M steps` text is server-rendered for no-JS fallback
- Added a sticky five-tab topbar (Home, Plans, Prototypes, Artifacts, Social) with per-collection counts from the filesystem and `aria-current="page"` on the active tab
- Deleted the view toggle and all view-switching JavaScript
- Brought `prototypes-gallery.html` and the social media `gallery.html` onto the shared token set and theme toggle (both were still on the pre-503 palette, including `--subtle: #9ca3af` at 2.5:1 contrast — a live WCAG AA failure)
- Updated all five build scripts with row card markup; kept the three byte-identical `build-index.sh` copies in sync (enforced by a new parity test)
- Mirrored the card heredoc into `plans-library/SKILL.md` and `media-library/SKILL.md`
- Regenerated all four gallery indexes
- Created `tests/plugins/test-gallery-row-layout.mjs` and `tests/plugins/test-build-index-parity.mjs`
- Bumped plan-agent to 7.7.0 (7.6.0 was taken by a concurrent PR) and social-media-tools to 2.21.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Template — row layout, step bars, topbar | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Template — shared token set, topbar | Modified |
| `kit/plugins/social-media-tools/templates/gallery.html` | Template — shared token set, topbar | Modified |
| `docs/plans/build-index.sh` | Generator — row card markup, step counts | Modified |
| `scripts/build-plans-index.sh` | Generator — kept byte-identical | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Generator — kept byte-identical | Modified |
| `kit/plugins/plan-agent/hooks/build-artifacts-index.sh` | Generator — row cards, no status glyph | Modified |
| `kit/plugins/plan-agent/hooks/build-prototypes-index.sh` | Generator — row cards | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Skill — card heredoc synced | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Skill — topbar variables | Modified |
| `tests/plugins/test-gallery-row-layout.mjs` | Smoke test — splice-unit constraints, step counts, topbar | Created |
| `tests/plugins/test-build-index-parity.mjs` | Smoke test — three build-script checksums | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — version bumps | Modified |

## How it works

Commit `dd5c425` (PR #503) adopted the prototype's design tokens but kept the card grid. This plan closes the layout gap.

The merge driver in `scripts/merge-plans-index.mjs` constrains what the cards can look like: `CARD_RE` is `/<a class="gallery-card"[\s\S]*?<\/a>/g`, so `<a class="gallery-card"` must remain the leading attribute pair, no card may contain a nested `<a>`, and the two count strings matched by `COUNT_RE` must keep their `<p>` or `<span>` opener immediately before the digits. Rows are bare anchors laid out as grid items directly inside `#galleryGrid` — no `<ul>/<li>` wrapper — so the driver keeps matching and the merge gate tests pass unedited.

In-flight step bars are generated client-side from `data-steps-done`/`data-steps-total` counted from each plan's rendered HTML (total = all `class="step-card"` matches; done = `class="step-card completed"` matches). The server renders `N / M steps` text for no-JS fallback. The in-flight band is a style on `[data-status="in-progress"]` rows in place rather than a separate container, so the merge driver never sees it.

The topbar counts come from the filesystem at generation time (`*.html` minus `index.html` in each collection directory) rather than from parsing sibling indexes, so arbitrary generator ordering cannot produce stale counts. The plans count reads from the resolved `plansDirectory` rather than a fixed `docs/plans`.

`prototypes-gallery.html` and the social `gallery.html` still carried `--subtle: #9ca3af` from the pre-PR-503 palette — a value that measures 2.5:1 on white, failing WCAG AA. Both templates were moved to the shared token set in this change because the new topbar links to them and a nav bar pointing to differently-styled pages is not shippable.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [refactor-gallery-rows-and-topbar](plans/refactor-gallery-rows-and-topbar.md)
