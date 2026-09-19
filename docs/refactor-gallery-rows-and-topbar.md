# Give the galleries the row layout and shell the prototype specified

> Replaces the plans gallery's card grid with the row list, in-flight step-progress bar, and sticky topbar from the prototype design, and unifies all four galleries onto the same shared shell and token set.

<!-- generated:start -->

**Status:** Shipped 2026-08-01 **Plan:** [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
**Type:** refactor

## What shipped

- Added `tests/plugins/test-build-index-parity.mjs` asserting the three byte-identical build-script copies hash identically, before making any edits (landing the guard first proves it is green for the right reason).
- Rebuilt the layout in `plans-gallery.html`: replaced `.gallery-grid` card rules with the prototype's single-column row grid on `.gallery-card` itself (`grid-template-columns: 1.25rem minmax(0,1fr) 9rem 3.5rem`), added `.glyph`, `.r-title`, `.r-meta`, `.r-date` plus status colour rules, deleted the view-toggle and its JavaScript, and collapsed to the prototype's 700px breakpoint (status selected off `[data-status]` attribute rather than CSS classes, because `CARD_RE` matches the class attribute with its closing quote and a second class makes every card invisible to the merge driver).
- Added the in-flight band in the same template: `[data-status="in-progress"]` cards get a `border-left: 2px solid var(--signal)`, a bold title, and a client-side `.bar` of `<i>` segments drawn from `data-steps-done` / `data-steps-total`; the `N / M steps` count is server-rendered so it survives without JavaScript.
- Updated all three byte-identical build scripts to the row card shape: `aria-hidden` status glyph with a visually-hidden text sibling, `.r-title`, `.r-meta`, `.r-date`, and `data-steps-done`/`data-steps-total` counted from the plan HTML (`class="step-card` for total, `class="step-card completed"` for done — matching on `class="step-card"` alone would exclude completed steps); `<a class="gallery-card"` remains the leading attribute pair with no nested `<a>` and no `<li>`.
- Mirrored the new card heredoc into `kit/plugins/plan-agent/skills/plans-library/SKILL.md` (the sixth copy, executed by `test-index-card-count.mjs`).
- Brought the artifacts and prototypes galleries onto the row layout (`build-artifacts-index.sh` with no status glyph; `build-prototypes-index.sh` with rows; `prototypes-gallery.html` updated from pre-503 palette — `--subtle: #9ca3af` measured 2.5:1 against white, a live WCAG AA failure).
- Added the sticky topbar to `plans-gallery.html` and `prototypes-gallery.html`: five tabs (Home, Plans, Prototypes, Artifacts, Social), counts from the filesystem rather than sibling index files (generators run in arbitrary order), `aria-current="page"` on the matching tab, opaque background declared before `color-mix` for browsers without it.
- Updated the media library (`social-media-tools/templates/gallery.html`) from a hardcoded dark-only GitHub palette to the shared token set with theme toggle and topbar; updated `media-library/SKILL.md` to substitute count variables.
- Added `tests/plugins/test-gallery-row-layout.mjs` and regenerated all four indexes.
- Bumped plan-agent from 7.5.0 to 7.7.0 (7.6.0 was taken by PR #505 on main during the branch) and social-media-tools from 2.20.1 to 2.21.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Row layout, in-flight band, topbar; view toggle deleted | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Shared token set, theme toggle, row layout, topbar | Modified |
| `kit/plugins/social-media-tools/templates/gallery.html` | Shared token set, theme toggle, topbar | Modified |
| `docs/plans/build-index.sh` | Row card markup, step counts, cross-gallery counts | Modified |
| `scripts/build-plans-index.sh` | Same edit, kept byte-identical | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Same edit, kept byte-identical | Modified |
| `kit/plugins/plan-agent/hooks/build-artifacts-index.sh` | Row card markup without status glyph; cross-gallery counts | Modified |
| `kit/plugins/plan-agent/hooks/build-prototypes-index.sh` | Row card markup; cross-gallery counts | Modified |
| `kit/plugins/plan-agent/skills/plans-library/SKILL.md` | Card heredoc kept in step with build scripts | Modified |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | Topbar variables in gallery generator | Modified |
| `docs/plans/index.html` | Regenerated | Modified |
| `docs/artifacts/index.html` | Regenerated | Modified |
| `docs/prototypes/index.html` | Regenerated | Modified |
| `docs/media/social/index.html` | Regenerated | Modified |
| `tests/plugins/test-gallery-row-layout.mjs` | Objective-verification test | Created |
| `tests/plugins/test-build-index-parity.mjs` | Checksum guard for three build-script copies | Created |
| `.claude-plugin/marketplace.json` | plan-agent → 7.7.0; social-media-tools → 2.21.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.7.0 entry | Modified |
| `kit/plugins/social-media-tools/CHANGELOG.md` | 2.21.0 entry | Modified |

## How it works

Commit `dd5c425` (PR #503) had rebuilt the plan-document shell and adopted the prototype's design tokens in `plans-gallery.html`, but kept the 2-up card grid. Two objections from that earlier plan turned out not to hold.

The first was the missing data source for the in-flight band's step bar. `build-index.sh` already reads each plan's full rendered HTML for meta tags, and since PR #503 every plan carries one `class="step-card"` element per step and `class="step-card completed"` on each done step. Counting both gives `done / total` with no new spec field and no new parser. The `step-card-header` element must not be counted — the total pattern matches `class="step-card` followed by a quote or space, not a bare `class="step-card"` which excludes completed steps.

The second was the merge driver constraint. `scripts/merge-plans-index.mjs:35` defines `CARD_RE` as `/<a class="gallery-card"[\s\S]*?<\/a>/g` — non-greedy, terminating at the first `</a>`. A row anchor is still one `<a class="gallery-card">…</a>` with no nested anchor, so the driver keeps matching without an edit. What it does constrain: `<a class="gallery-card"` must lead, no card may contain a nested `<a>`, and counts matching `COUNT_RE` (`/<p>|<span>|&middot;`) must keep their shape. The prototype's `<ul><li>` wrapper cannot be used — `<li>` tags between cards would be destroyed by the first concurrent merge. Rows are therefore bare anchors laid out as grid items directly inside `#galleryGrid`.

The glyph's `aria-hidden` attribute with a visually-hidden text sibling (`<span class="sr-only">completed</span>`) preserves accessibility for sighted and screen-reader users alike. An `aria-label` on the anchor was rejected because it overrides the row's own text, making the announced content diverge from what is visible.

The topbar counts come from `os.path.relpath` between each target index and the page being generated, and from the resolved `plansDirectory` rather than a hardcoded `docs/plans`. An implementation using fixed paths would give wrong Plans counts and broken tab links for any project that configures `plansDirectory` elsewhere.

The status colour rule uses attribute selectors (`[data-status="in-progress"]`) rather than CSS classes. The merge driver's `CARD_RE` matches with the class attribute's closing quote, so any second class in the `class` attribute makes the card invisible to the splice and silently drops it on the next concurrent merge.

A completion-report deviation: the status segmented control needed `flex-wrap: wrap` at 375px — it clipped the "Shipped" button otherwise, and that criterion could not honestly be marked. The media gallery dropped per-type badge hues (fixed to a dark background, half failed 4.5:1 in light mode) and colour transitions (Chrome paints the pre-change value when only the custom property underneath changes, leaving filter chips at 3.6:1 after a theme toggle).

## How to use it

`/plan-agent:plans-library` — regenerates `docs/plans/index.html` with the row layout, step-progress bars for in-flight plans, and the sticky five-tab topbar. No invocation change; the skill delegates to the gallery generator.

The topbar links to Home, Plans, Prototypes, Artifacts, and Social galleries; counts reflect the filesystem at generation time.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3a62fa1` | 2026-08-01 | feat(galleries): row layout, in-flight step progress, and one shared topbar (#507) |
| `dd5c425` | 2026-07-31 | refactor: rebuild plan document and gallery design with 7.5.0 shell bump (#503) |
| `8641b56` | 2026-08-04 | fix(plan-agent): plans-library delegates to the gallery generator (8.5.1) (#525) |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |

<!-- generated:end -->

## References

- Plan: [refactor-gallery-rows-and-topbar.md](plans/refactor-gallery-rows-and-topbar.md)
