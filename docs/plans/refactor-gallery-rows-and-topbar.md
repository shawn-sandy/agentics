---
status: completed
type: refactor
created: 2026-08-01
modified: 2026-08-01
effort: high
workflow: never
glance: PR #503 gave the plans gallery the prototype's colours but left its card grid in place, so the shipped page still does not look like the design that was signed off. This swaps the 2-up cards for the prototype's dense row list, gives in-flight plans a real step-progress bar derived from the plan HTML, and puts one sticky topbar across all four galleries — which also means dragging the prototypes and social galleries onto the shared token set, since they are still on the pre-503 palette and one of them fails WCAG today. Done when every gallery renders rows under the same shell in both themes, the merge driver and its two tests pass unedited, and no gallery stylesheet contains a retired token.
---

# Plan: Give the galleries the row layout and shell the prototype specified

## Objective

Replace the plans gallery's card grid with the row list, in-flight band, and sticky topbar specified by `docs/prototypes/plans-site-redesign.html`, and bring the artifacts, prototypes, and social galleries onto the same shell — without changing the `<a class="gallery-card">` splice unit that `scripts/merge-plans-index.mjs` depends on.

## Context

Commit `dd5c425` (PR #503) rebuilt the plan-document shell and adopted the prototype's design tokens in `kit/plugins/plan-agent/templates/plans-gallery.html`, but kept the gallery's layout. Its plan, `docs/plans/refactor-plan-and-gallery-design.md`, scoped step 8 to "Rebuild the **controls**" and listed only "search plus status segmented control, type and effort disclosure, client-side In-flight and month grouping" against that template. The layout was never attempted, so the shipped `docs/plans/index.html` is a 2-up card grid wearing the prototype's palette while the prototype specifies a single-column row list. This plan closes that gap.

Two objections recorded in the previous plan turn out not to hold, and the steps below depend on both being wrong.

The first is the missing data source for the in-flight band's step bar. `build-index.sh` already reads each plan's full rendered HTML to pull its meta tags, and since PR #503 every plan carries one `class="step-card"` per step and `class="step-card completed"` on each done step. Counting both gives `done / total` with no new spec field and no new parser — `docs/plans/refactor-plan-and-gallery-design.html` measures 11 of 11, `docs/plans/add-plan-phase-checkpoints.html` measures 0 of 12. The prototype's *phase* line ("Phase 2 of 3 — Renderer") stays out: phases genuinely do not exist yet, and `docs/plans/add-plan-phase-checkpoints.md` is the plan that adds them.

The second is the merge driver. `scripts/merge-plans-index.mjs:35` is `const CARD_RE = /<a class="gallery-card"[\s\S]*?<\/a>/g` — non-greedy, terminating at the first `</a>`. A row anchor is still one `<a class="gallery-card">…</a>` with no nested anchor, so the driver keeps matching without an edit. What the driver does constrain is sharper than "do not touch the cards": `<a class="gallery-card"` must stay the leading attribute pair, no card may contain a nested `<a>`, and the counts the driver rewrites must keep their shape. That last one is looser than it looks — `COUNT_RE` at `merge-plans-index.mjs:104` is `/(<p>|<span>|&middot;\s*)(\d+)(\s*(?:plans|items|artifacts)\b)/g`, so what matters is a `<p>` or `<span>` opening immediately followed by digits and then the word `items`, `plans`, or `artifacts`. The header's `<p>98 items &mdash; click any card to open it</p>` matches on its prefix and the trailing prose is free text; the footer's `<span>98 items</span>` matches whole. Rewording the header for rows is safe, moving the number away from the opening tag is not. The driver also splices over *everything between the first and last card*, which rules out the prototype's `<ul class="rows"><li>` wrapper: `<li>` tags between cards would be destroyed by the first concurrent merge and stay destroyed until the next regeneration. Rows are therefore bare anchors laid out as grid items directly inside `#galleryGrid`, and the in-flight band is a style applied to `[data-status="in-progress"]` rows in place rather than a separate container the cards are moved into.

Card markup is emitted from six places that are kept in step by convention alone. `docs/plans/build-index.sh`, `scripts/build-plans-index.sh`, and `kit/plugins/plan-agent/hooks/build-index.sh` are byte-identical copies (`204708e3e621b1e0a83f8d2254f95f8f` today) with no test guarding the identity. `kit/plugins/plan-agent/hooks/build-artifacts-index.sh` renders through the *same* `plans-gallery.html` template, so the row layout lands on the artifacts gallery whether or not that was asked for; its cards carry `data-status=""` and no effort, so the glyph column has to degrade rather than render an empty cell. `kit/plugins/plan-agent/hooks/build-prototypes-index.sh` renders through its own template. And `kit/plugins/plan-agent/skills/plans-library/SKILL.md` carries a sixth copy of the card heredoc, which `tests/plugins/test-index-card-count.mjs` extracts and executes — so a change made in the build scripts but not in the skill drifts silently past the test suite.

Scope grew once the topbar was confirmed. `prototypes-gallery.html` and `kit/plugins/social-media-tools/templates/gallery.html` never received the PR #503 refresh: the first still declares `--subtle: #9ca3af`, the retired token that measures 2.5:1 on white and was the WCAG failure #503 removed from the plan shell, and the second is a hardcoded dark-only GitHub palette with no light mode and no theme toggle. A nav bar whose tabs lead to two pages that look like a different site is not shippable, so both templates move onto the shared token set in the same change. That is also why `social-media-tools` gets a version bump alongside `plan-agent`.

The docs hub at `docs/index.html` stays out. It is already a recorded follow-up on the previous plan, it is hand-maintained with no generator, and it needs a design (the prototype's collections list) rather than a port.

`workflow: never` is set deliberately. Three byte-identical shell scripts, one template shared by two galleries, and a sixth card copy inside a SKILL.md are exactly the shape subagents corrupt: the renderer's file-count heuristic would otherwise license fan-out this plan cannot use.

## Files

- kit/plugins/plan-agent/templates/plans-gallery.html (modified) — row layout, in-flight band, topbar; the view toggle deleted
- kit/plugins/plan-agent/templates/prototypes-gallery.html (modified) — shared token set, theme toggle, row layout, topbar
- kit/plugins/social-media-tools/templates/gallery.html (modified) — shared token set, theme toggle, topbar
- docs/plans/build-index.sh (modified) — row card markup, step counts, cross-gallery counts
- scripts/build-plans-index.sh (modified) — same edit, kept byte-identical
- kit/plugins/plan-agent/hooks/build-index.sh (modified) — same edit, kept byte-identical
- kit/plugins/plan-agent/hooks/build-artifacts-index.sh (modified) — row card markup without a status glyph, cross-gallery counts
- kit/plugins/plan-agent/hooks/build-prototypes-index.sh (modified) — row card markup, cross-gallery counts
- kit/plugins/plan-agent/skills/plans-library/SKILL.md (modified) — card heredoc kept in step with the build scripts
- kit/plugins/social-media-tools/skills/media-library/SKILL.md (modified) — topbar variables in its gallery generator
- docs/plans/index.html (generated) — regenerated
- docs/artifacts/index.html (generated) — regenerated
- docs/prototypes/index.html (generated) — regenerated
- docs/media/social/index.html (generated) — regenerated
- tests/plugins/test-gallery-row-layout.mjs (new) — objective-verification test
- tests/plugins/test-build-index-parity.mjs (new) — checksum guard for the three build-script copies
- .claude-plugin/marketplace.json (modified) — plan-agent 7.5.0 to 7.6.0, social-media-tools 2.20.1 to 2.21.0
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 7.6.0 entry
- kit/plugins/social-media-tools/CHANGELOG.md (modified) — 2.21.0 entry

## Steps

1. [x] Add `tests/plugins/test-build-index-parity.mjs` asserting the three build-script copies (`docs/plans/build-index.sh`, `scripts/build-plans-index.sh`, `kit/plugins/plan-agent/hooks/build-index.sh`) hash identically, and confirm it passes against the tree as it stands. Why: those three files are kept in sync by convention with nothing enforcing it, and steps 4 and 7 edit all three — landing the guard first means a missed copy fails a test instead of shipping a stale generator, and writing it before the edits proves the guard is green for the right reason rather than because it was tuned to a diff. Verify: `node tests/plugins/test-build-index-parity.mjs` exits 0 now, and exits 1 with the offending path named after appending a comment line to one copy in a scratch checkout.
2. [x] Rebuild the layout in `plans-gallery.html` — replace the `.gallery-grid` card rules with the prototype's row grid applied to `.gallery-card` itself (`grid-template-columns: 1.25rem minmax(0,1fr) 9rem 3.5rem`, `align-items: baseline`, `border-bottom: 1px solid var(--rule-soft)`), add `.glyph`, `.r-title`, `.r-meta`, `.r-date` and the `.s-completed` / `.s-in-progress` / `.s-todo` colour rules from the prototype, add an `.sr-only` clip utility for the status text step 4 emits, add the serif `--prose` subtitle under the `h1`, collapse to the prototype's 700px breakpoint, and delete `.view-toggle`, `.view-btn`, both toggle buttons, and the view-switching JavaScript outright. Why: this is the actual mismatch the plan exists to fix, and the toggle predates the redesign, appears in neither the prototype nor the previous plan's file list, and is a second layout to style and keep accessible for a preference nobody asked for. Verify: the stylesheet contains no `view-btn` or `list-view` selector and no `repeat(auto-fill` declaration, the regenerated page renders one row per plan, and grepping the template for `--subtle`, `--grey-bg`, and `--border-mid` returns nothing.
3. [x] Give in-flight plans their band in the same template — style `.gallery-card[data-status="in-progress"]` with the prototype's `border-left: 2px solid var(--signal)`, a bold title, and a `.bar` of `<i>` segments the inline script draws from `data-steps-done` and `data-steps-total`, leaving the `N / M steps` text server-rendered so it survives with JavaScript off. Why: the in-flight run is the one thing a reader opens this page to find, and the previous plan left it as a text separator over identical cards because it believed no step data existed; drawing the bar client-side keeps the generated markup to two attributes and one span instead of a dozen `<i>` tags per card, while server-rendering the count keeps the information present when the script does not run. Why the bar is styled in place rather than moved into a `.flight-list` container: the merge driver splices over everything between the first and last card, so a second container would be destroyed by the first concurrent merge. Verify: an in-progress card renders a segmented bar whose lit count equals its `data-steps-done`, the same card still matches `/<a class="gallery-card"[\s\S]*?<\/a>/`, and disabling JavaScript leaves the `N / M steps` text visible.
4. [x] Change the card emitter in all three byte-identical build scripts to the row shape — `<span class="glyph" aria-hidden="true">` carrying `✓` for completed, `○` otherwise, immediately followed by `<span class="sr-only">completed</span>` (or `in progress` / `todo`), then `.r-title`, `.r-meta` (`type · effort`), and `.r-date` — and add `data-steps-done` / `data-steps-total` counted from the plan HTML the script already reads (`class="step-card` followed by a quote or a space for the total — matching on `class="step-card"` alone would exclude every completed step, since the renderer emits those as `class="step-card completed"` — and `class="step-card completed"` for done) plus the `N / M steps` span on in-progress plans only. Keep `<a class="gallery-card"` as the leading attribute pair, emit no nested `<a>` and no `<li>`, and keep both counts matching `COUNT_RE` — the number stays immediately after the `<p>` or `<span>` opening and immediately before the word `items`, though the header's trailing "click any card to open it" is free text and should be reworded for rows. Why: the template from step 2 styles markup the generator does not emit yet, and the three splice constraints listed are exactly what `scripts/merge-plans-index.mjs` and its two tests depend on. The glyph is `aria-hidden` with a visually-hidden text sibling rather than labelled directly, because the card layout it replaces carried a readable status pill and dropping to a glyph alone would lose that information for anyone not looking at the page — an `aria-label` on the anchor was rejected for the same reason it usually is, that it overrides the row's own text and makes the announced content diverge from the visible content. Verify: `node tests/plugins/test-build-index-parity.mjs` exits 0, the regenerated index has one `data-steps-total` per plan card, an accessibility-tree dump of three rows announces their status followed by the title, the counted values match `grep -c` on two spot-checked plan files, and `bash tests/plugins/test-merge-gallery-index.sh` passes unedited.
5. [x] Mirror the new card heredoc into `kit/plugins/plan-agent/skills/plans-library/SKILL.md`. Why: `tests/plugins/test-index-card-count.mjs` extracts the `gallery-card` heredoc from that file and executes it, so the skill carries a sixth copy of the card markup that drifts silently from the build scripts if it is not updated in the same step — and the skill is what runs when a user invokes `/plan-agent:plans-library` rather than the hook. Verify: `node tests/plugins/test-index-card-count.mjs` exits 0 unedited, and a diff of the skill's heredoc against the build script's `cards.append` block shows the same attributes and child spans in the same order.
6. [x] Bring the artifacts and prototypes galleries onto the row layout — update `build-artifacts-index.sh` to emit the row shape with no status glyph (its cards carry `data-status=""`, and an empty first column is worse than a collapsed one) and `build-prototypes-index.sh` likewise, then replace the token block in `prototypes-gallery.html` with the shared palette, dark rules, and pre-paint theme script from `plans-gallery.html` and give it the same row CSS. Why: `build-artifacts-index.sh` renders through `plans-gallery.html`, so the artifacts gallery inherits step 2's layout whether or not its generator is updated — leaving it emitting card markup produces broken rows; and `prototypes-gallery.html` is still on the pre-503 palette including `--subtle: #9ca3af`, which measures 2.5:1 and is a live WCAG AA failure, not a cosmetic gap. Verify: both regenerated galleries render rows, the artifacts gallery still hides the status segmented control (no card carries a status), the prototypes stylesheet contains no retired token name, and computed `color` on `.r-meta` clears 4.5:1 against `--paper` in both themes on both pages.
7. [x] Add the sticky topbar to `plans-gallery.html` and `prototypes-gallery.html` — the prototype's `.topbar` / `.topbar-in` / `.mark` / `.tabs` with the opaque `background: var(--paper)` declared before the `color-mix` line, tabs for Home, Plans, Prototypes, Artifacts, and Social each carrying a `<span class="n">` count, and `aria-current="page"` on the tab matching the page being generated. Feed the counts and the tab hrefs from template variables the generators substitute: counts from `*.html` minus `index.html` on disk in each collection directory, hrefs from `os.path.relpath` between each target index and the page being generated. Read the plans collection from the resolved `plansDirectory` rather than a fixed `docs/plans`, since a project that moves it would otherwise get a wrong Plans count and tab links that resolve from the wrong depth. Why: counts have to come from the filesystem rather than from parsing sibling `index.html` files, because the four generators run in arbitrary order and a parse would read whichever indexes happened to be stale; the opaque background is declared first because a browser without `color-mix` drops that declaration and a transparent sticky bar over scrolled text is unreadable. Verify: every tab count matches `ls` on its directory, the active tab is the only element with `aria-current="page"`, the bar stays legible over scrolled content with `color-mix` forced off in DevTools, and tabbing reaches every tab with a visible focus ring.
8. [x] Give the media library the same shell — replace the hardcoded dark palette in `kit/plugins/social-media-tools/templates/gallery.html` with the shared token set, dark rules, and pre-paint theme script, add the theme toggle and the same topbar with `aria-current="page"` on Social, and update `kit/plugins/social-media-tools/skills/media-library/SKILL.md` to substitute the count variables. Why: the Social tab is one of the five the topbar offers, and a nav bar that vanishes into a differently-styled dark-only page when you click one of its own tabs is a defect rather than a deferral; the media gallery keeps its image-card layout, which suits thumbnails in a way rows do not — only the shell changes. Verify: the regenerated media gallery carries the topbar with Social marked current, honours a stored `plan-theme` preference set on the plans gallery, and renders legibly in the light theme it has never had.
9. [x] Add `tests/plugins/test-gallery-row-layout.mjs` asserting the objective end to end, then regenerate all four indexes. Why: every other check here is a prose assertion, and the specific things this plan changes — the splice-unit constraints, the step-count derivation, the absence of the view toggle — are invisible to the existing suite and would regress the next time a generator is touched; regenerating afterwards means the committed indexes are produced by tested code. Verify: `node tests/plugins/test-gallery-row-layout.mjs` exits 0, and the four regenerated indexes each contain the topbar, no `view-btn`, and one row per item.
10. [x] Bump `plan-agent` from 7.5.0 to 7.6.0 and `social-media-tools` from 2.20.1 to 2.21.0 in `.claude-plugin/marketplace.json`, and add the matching CHANGELOG entries covering the row layout, the in-flight step bar, the topbar, and the token adoption in the two stale templates. Why: repo convention requires any edit under `kit/plugins/<name>/` to ship a version exceeding main's, both plugins are touched here, and a new user-facing shell across four galleries is a minor bump rather than a patch. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with both new versions reported.

## Tests

Tier 1 — This plan changes application code
- Objective: the generated galleries render the prototype's rows under one shell without breaking the merge-driver splice unit. File: tests/plugins/test-gallery-row-layout.mjs; Type: smoke; Asserts: running `build-index.sh` over a fixture plans directory produces an index where every card matches `CARD_RE` extracted from the source of `scripts/merge-plans-index.mjs` (the driver runs its CLI on import and exports nothing, so the test reads the literals out of the file rather than importing them — which also keeps the driver unedited, as required) and the match count equals the fixture plan count, no card contains a nested `<a>` or any `<li>`, `<a class="gallery-card"` is the leading attribute pair on every card, `COUNT_RE` extracted the same way matches exactly twice with both numbers equal to the card count, each in-progress card carries `data-steps-done`/`data-steps-total` matching the fixture's `step-card` counts, every plan card carries a visually-hidden status text sibling to its `aria-hidden` glyph, the stylesheet contains no `view-btn` selector and no retired token name, and the topbar renders five tabs with exactly one `aria-current="page"`; Run: node tests/plugins/test-gallery-row-layout.mjs
- Unit: build-script copy parity. File: tests/plugins/test-build-index-parity.mjs; Targets: docs/plans/build-index.sh, scripts/build-plans-index.sh, kit/plugins/plan-agent/hooks/build-index.sh; Key cases: all three hash identically, a one-byte divergence fails with the offending path named
- Unit: step-count derivation. File: tests/plugins/test-gallery-row-layout.mjs; Targets: the `step-card` counting block in build-index.sh; Key cases: a plan with no steps, a plan with zero completed, a plan fully completed, a plan whose HTML contains `step-card-header` (must not be counted as a step)
- Integration: existing gallery gates pass unedited. File: tests/plugins/test-merge-gallery-index.sh, tests/plugins/test-index-card-count.mjs; Targets: merge-plans-index.mjs, the plans-library and media-library card heredocs; Key cases: a two-sided merge unions the row cards, the card-count assertion still detects truncated output

## Acceptance Criteria

- [x] `docs/plans/index.html` renders one row per plan, not a card grid, and contains no `repeat(auto-fill` declaration
- [x] `view-btn`, `list-view`, and the view-switching JavaScript are absent from every gallery template
- [x] Every gallery card is a bare `<a class="gallery-card">` with `class` as its first attribute, no nested `<a>`, and no `<li>` wrapper
- [x] `CARD_RE` from `scripts/merge-plans-index.mjs` matches every card in all four regenerated indexes, and the driver source is unedited
- [x] `COUNT_RE` from `scripts/merge-plans-index.mjs` matches exactly twice in every regenerated index, and both captured numbers equal the card count
- [x] Each in-progress plan card carries `data-steps-done` and `data-steps-total` matching its plan HTML's `step-card` counts, and renders a bar whose lit segments equal `data-steps-done`
- [x] The `N / M steps` text is present with JavaScript disabled
- [x] Every plan row announces its status as text to an accessibility-tree dump, and the glyph itself is `aria-hidden`
- [x] No phase label is rendered anywhere — phases do not exist yet
- [x] All four galleries render the sticky topbar with five tabs, each count matching its directory's file count, and exactly one `aria-current="page"`
- [x] The topbar declares an opaque `background` before its `color-mix` value and stays legible with `color-mix` unsupported
- [x] `--subtle`, `--grey-bg`, and `--border-mid` appear in no gallery template
- [x] Every text token in all four gallery stylesheets measures at least 4.5:1 against its background in both light and dark palettes
- [x] The media gallery renders in the light theme and honours a `plan-theme` preference stored by the plans gallery
- [x] The artifacts gallery hides the status segmented control and renders no empty glyph column
- [x] At 375px wide every gallery collapses to the prototype's stacked layout with no horizontal scroll
- [x] The three `build-index.sh` copies have identical checksums, enforced by a test
- [x] The `plans-library` SKILL.md card heredoc emits the same attributes and child spans as the build scripts
- [x] `node tests/plugins/test-gallery-row-layout.mjs` and `node tests/plugins/test-build-index-parity.mjs` exit 0
- [x] `node tests/plugins/test-index-card-count.mjs`, `bash tests/plugins/test-merge-gallery-index.sh`, `node tests/plugins/test-plan-redesign.mjs`, `node tests/plugins/test-build-plan-html.mjs`, and `node tests/plugins/test-extract-plan-spec.mjs` all exit 0 unedited
- [x] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with plan-agent at 7.6.0 and social-media-tools at 2.21.0

## Completion Report

- Status is selected off `[data-status]`, not the prototype's `.s-completed` / `.s-in-progress` / `.s-todo` classes — `CARD_RE` matches the class attribute with its closing quote, so a second class in there makes every card invisible to the merge driver. The attribute selectors are equivalent in effect. The same trap caught a template comment mid-implementation: a literal opening card tag written into the head comment became the "first card" for the splice, which would have eaten the whole page chrome on the first concurrent merge. The comment was reworded and the template now warns against ever spelling that tag out in the chrome.
- The queued glyph drops the prototype's `opacity: .5` — it puts `--ink-3` near 2.5:1 against the page, failing this plan's own contrast criterion. The glyph reads at full `--ink-3` instead: 5.06:1 light, 5.42:1 dark.
- The current tab's count takes the accent colour — `--ink-3` on `--accent-soft` measured 4.46:1, under AA by a hair. Every other text token cleared 4.5:1 unchanged.
- The status segmented control wraps below 700px — out of scope, but at 375px `.seg` clipped its fourth button ("Shipped") rather than scrolling, and the 375px criterion could not honestly be ticked with a control cut off. One `flex-wrap: wrap` in the existing media query.
- The media gallery lost its colour transitions — Chrome keeps painting a transitioned colour's pre-change value when only the custom property underneath it changed, so a theme toggle left the filter chips and the "View image" links in the light palette at 3.6:1 and 2.5:1. Measured after removal: 5.42:1 and 7.40:1.
- The media gallery's eight per-type badge hues became one neutral badge — they were fixed to a dark background and half fell under 4.5:1 the moment the page gained a light theme. Type is still filterable in the toolbar above.
- The media gallery was regenerated by hand from its skill's documented steps — `media-library` is model-driven, not a script. Its index was also stale, 27 cards for 36 files on disk, so the rebuild picked up nine cards that had never been published.
- The topbar reads the resolved `plansDirectory`, not a fixed `docs/plans` — raised in review of the plan. The first implementation counted and linked `docs/plans` directly, so a project that configures `plansDirectory` elsewhere would have seen a wrong Plans count and tab links resolving from the wrong depth. Every tab href is now `os.path.relpath(target, output_dir)`, and the plans tab reports what the page actually rendered. The objective test's fixture now sets `plansDirectory: docs/notes/plans` so the default layout is never the only one exercised.
- Landed as plan-agent 7.7.0, not 7.6.0 — PR #505 took 7.6.0 on main while this branch was open.
- Two verification steps were done by proxy — `color-mix` could not be disabled in the browser, so the fallback was proven by deleting the `color-mix` declaration at runtime and reading the computed background back as opaque `--paper`; and the preview pane serves static snapshots that will not re-navigate, so the media gallery's pre-paint theme script was verified by re-executing the page's own script against the stored `plan-theme` key rather than by reloading. It applied `dark` as written.

## Verification

Regenerate everything and compare against the design it is supposed to match. Run `bash docs/plans/build-index.sh`, then the artifacts, prototypes, and media generators, and open `docs/plans/index.html` beside `docs/prototypes/plans-site-redesign.html`. The shipped page should now carry the same four things the prototype does: a sticky topbar with per-collection counts, an in-flight band whose rows show a step bar and `N / M steps`, a dense row list with a status glyph rather than a badge pill, and month separators with a rule. The phase line is the one prototype element deliberately absent.

Measure rather than eyeball — screenshots have come back blank in this repo. In each of the four galleries, in both themes, read the computed `color` and `background-color` of `.r-title`, `.r-meta`, `.r-date`, `.glyph` on all three status classes, and the topbar tab text, and confirm every pair clears 4.5:1. The glyph colours are the new risk: `--moss` and `--signal` were verified against `--paper` for chips with a tinted background, and a bare glyph sits on the page background instead. Then narrow to 375px and confirm each gallery collapses without horizontal scroll, and tab through the topbar confirming every tab takes a visible focus ring. Dump the accessibility tree for three plan rows — one per status — and confirm each announces its status as text before its title, since the glyph carrying that status visually is `aria-hidden` and the row would otherwise be silent about it.

The steps stay in order and ship together. The topbar spans four galleries, so any split leaves a nav bar pointing at pages that do not have it yet, and the two stale templates carry a live WCAG failure that should not outlive the PR that touches them.

Prove the merge contract survived. Run `bash tests/plugins/test-merge-gallery-index.sh` and `node tests/plugins/test-index-card-count.mjs` with `scripts/merge-plans-index.mjs` unedited, then simulate the real hazard: take the regenerated `docs/plans/index.html`, hand-build a second copy with one extra row card, and run the driver over both — the union must contain both card sets with no stray separators, `<li>` fragments, or duplicated topbars. Confirm `COUNT_RE` still matches exactly twice in the merged output and that both numbers were rewritten to the union's card count.

Spot-check the derived step counts against their sources. Pick two in-progress plans and compare each card's `data-steps-done` / `data-steps-total` with `grep -c 'class="step-card completed"'` and `grep -c 'class="step-card"'` on the plan's own HTML, and confirm `step-card-header` is not being counted as a step.

Finally run the full gate: `node tests/plugins/test-gallery-row-layout.mjs`, `node tests/plugins/test-build-index-parity.mjs`, `node tests/plugins/test-index-card-count.mjs`, `bash tests/plugins/test-merge-gallery-index.sh`, `node tests/plugins/test-plan-redesign.mjs`, `node tests/plugins/test-build-plan-html.mjs`, `node tests/plugins/test-extract-plan-spec.mjs`, and `BASE_REF=main node scripts/check-plugin-versions.mjs`.

## Next Steps

- Give the docs hub the same shell and an activity band
  Carried forward unchanged from docs/plans/refactor-plan-and-gallery-design.md — the hub is the last page still on the old design once this plan lands, and the topbar's Home tab points at it.
  ```text
  In the agentics repo, redesign docs/index.html to match the shell in
  docs/prototypes/plans-site-redesign.html: the same sticky topbar with per-collection
  counts, an "In flight" band listing in-progress plans with their step progress, and a
  collections list showing each gallery's count and three most recent items. The hub is
  hand-maintained today — add a generator under scripts/ that reads the four gallery
  indexes and writes docs/index.html, and wire it into kit/plugins/plan-agent/hooks/dispatch.py
  beside the existing index builders. Reuse the topbar markup and the count-from-disk helper
  the galleries already use rather than writing a second copy. Bump the plan-agent minor
  version in .claude-plugin/marketplace.json and add a CHANGELOG entry. Verify by running the
  generator and confirming docs/index.html shows counts matching the four index.html files
  and that every text token clears 4.5:1 in both themes.
  ```

- Add the phase line to the in-flight band once phases land
  Depends on docs/plans/add-plan-phase-checkpoints.md, which adds the phase concept to the parser, digest, renderer, and extractor. The prototype specifies this line; it was omitted here because the data does not exist.
  ```text
  In the agentics repo, once ### Phase: headings are parsed into sections.phases and rendered
  into plan HTML, add the prototype's phase line to the in-flight band in
  kit/plugins/plan-agent/templates/plans-gallery.html: a .flight-phase element reading
  "Phase N of M — <name>" under the row title. Derive N and M in the three byte-identical
  build-index.sh copies from the phase markers in each plan's rendered HTML, alongside the
  existing step counts, and emit them as data attributes. Fall back to omitting the line when
  a plan declares no phases. Keep the plans-library SKILL.md card heredoc in step, and keep
  <a class="gallery-card" as the leading attribute pair with no nested anchor. Bump the
  plan-agent minor version in .claude-plugin/marketplace.json and add a CHANGELOG entry.
  Verify with node tests/plugins/test-build-index-parity.mjs, node
  tests/plugins/test-gallery-row-layout.mjs, and bash tests/plugins/test-merge-gallery-index.sh.
  ```

- Extract the shared gallery shell into one template partial
  After this plan there are four templates carrying the same token block, theme script, and topbar by copy-paste — the same drift risk the six card copies already have.
  ```text
  In the agentics repo, the token block, pre-paint theme script, theme toggle, and topbar are
  duplicated across kit/plugins/plan-agent/templates/plans-gallery.html,
  kit/plugins/plan-agent/templates/prototypes-gallery.html, and
  kit/plugins/social-media-tools/templates/gallery.html. Investigate extracting them into a
  single shared partial the generators splice in, and report whether that is worth doing given
  the generators are python heredocs inside shell scripts across two plugins — or whether a
  test asserting the three blocks are byte-identical is the cheaper guard. Recommend one option
  with its cost. Do not implement.
  ```

## Resources

- docs/prototypes/plans-site-redesign.html — the design this plan implements; the row grid, in-flight band, and topbar are specified there
- docs/plans/refactor-plan-and-gallery-design.md — the previous plan, which scoped the gallery to controls only and recorded the two objections this plan overturns
- scripts/merge-plans-index.mjs — CARD_RE at line 35 and the splice region that forbids `<li>` wrappers between cards
- tests/plugins/test-index-card-count.mjs — extracts and executes the card heredoc out of the plans-library and media-library SKILL.md files
- kit/plugins/plan-agent/templates/plans-gallery.html — the template PR #503 half-updated; tokens current, layout not
