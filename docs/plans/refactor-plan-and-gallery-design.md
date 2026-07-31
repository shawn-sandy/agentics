---
status: todo
type: refactor
created: 2026-07-31
issue: https://github.com/shawn-sandy/agentics/issues/500
effort: high
workflow: never
glance: Generated plan pages are hard to scan — two stacked summaries, every section in an identical bordered box, the Verify line hidden behind a disclosure, three competing progress devices, no dark mode, and a tertiary text colour that fails WCAG at 2.5:1. This rebuilds the presentation shell around a mono-chrome-plus-serif-prose type system, a single step rail that replaces the progress bar and the table of contents, and a gallery that leads with the plans actually in flight. Done when a rendered plan passes contrast in both themes, the extractor round-trips every committed plan unchanged, and the three gallery indexes regenerate with in-flight cards first.
---

# Plan: Rebuild the plan document and gallery design

## Objective

Rebuild the presentation layer of generated plan pages and the gallery index — design tokens with a persisted dark theme, a mono-and-serif type system, one merged goal panel, an always-visible Verify line, a sidebar step rail that absorbs the progress bar, and gallery controls that surface in-flight work first — without changing the DOM contract that `extractSections` and the gallery generator read.

## Context

Every generated plan is styled by one 1930-line module, `scripts/lib/plan-shell.mjs`, whose `CSS` export has drifted into a generic default: `system-ui` at 15px, `#2563eb` blue, `4px` radius, and a `1px solid #e5e7eb` border on every container. A visual audit of a rendered plan, the 88-card gallery at `docs/plans/index.html`, and the hub at `docs/index.html` found six concrete failures, and two prototypes at `docs/prototypes/plan-document-redesign.html` and `docs/prototypes/plans-site-redesign.html` were built and verified against them.

The failures are structural, not cosmetic. `objectiveCard` and `glanceBlock` render as siblings, so a reader hits two abstracts before any content and cannot tell which is authoritative — `plan-shell.mjs` line 376 even carries a `margin: -1.5rem 0 1.5rem` hack to pull the second up against the first. `stepCard` buries the `Verify:` text in a `<details class="step-verify-toggle">`, which is the one line a reader needs while executing. Three separate devices report progress — the shimmer bar at `progressBlock`, the icon nav from `nav()`, and the `.steps-list::before` timeline — and none of them says which step you are on, because `NAV_ENTRIES` has a single `steps` entry rather than one per step. `--subtle: #9ca3af` on `#ffffff` measures 2.5:1 and is used for nav icons and step chips, so the page fails WCAG AA today. There is no dark mode at all.

Three test gates constrain how this can be done, and they shaped the step order.

The first is the nav regex at `tests/plugins/test-build-plan-html.mjs:635`: `[...html.matchAll(/<a href="#([a-z-]+)">/g)]` requires each section anchor's `href` to be its only attribute. Step links are therefore emitted with a leading `class` attribute and ids containing digits (`#step-1`), both of which that regex skips — the section-link `deepEqual` keeps passing without being loosened.

The second is the back-compat guard at `tests/plugins/test-build-plan-html.mjs:928`. It renders the sample spec through the renderer at `origin/main` and through the working copy, blanks the three prompt payloads and the `<style>` block, and asserts the two documents are byte-identical. Its stated purpose in the comment above it is narrower than what it does: presentation is expected to evolve, and what the guard protects is "the DOM contract the extractor and the gallery read". As written it fails on *any* intentional markup change, and the inline `<script>` is not blanked either, so it also fails on the theme-toggle and scroll-spy edits. It is narrowed in step 2, before the first markup change lands, rather than left red across the whole PR.

The third is the byte-identical mirror at `tests/plugins/test-build-plan-html.mjs:951`, which asserts the three files under `kit/plugins/plan-agent/scripts/` match their repo-root counterparts under `scripts/`. `lib/plan-spec.mjs` is not edited by this plan, so only two files are re-copied.

Two hazards were designed around rather than accepted. `scripts/merge-plans-index.mjs` is the git merge driver for the generated gallery indexes; it splices the union of `<a class="gallery-card">` blocks over the region between the first and last card, so anything sitting *between* cards — a static month heading, for instance — is destroyed by a merge and stays destroyed until the next regeneration. Month grouping is therefore rendered client-side from a `data-month` attribute on each card rather than baked into the generated markup: the driver never sees a group header, `CARD_RE` is untouched, `tests/plugins/test-merge-gallery-index.sh` is untouched, and a filtered view re-groups correctly instead of leaving empty headings behind. The same technique carries the In-flight band, which is a client-side separator over cards the generator sorts first.

The second hazard is the theme toggle. `plan-shell.mjs` already selects on `[data-status="…"]` set on `<html>`, so the theme attribute is a second attribute on the same element (`data-theme`) rather than a class, and the two compose without either winning. The stored preference is read by a small inline script in `<head>` before first paint, because a plan opened from `file://` has no server to set a class for it and a flash of the wrong theme on every page load is worse than no dark mode.

One redundancy is knowingly left in place. The prototype folds the progress bar into the sidebar rail so the page carries a single progress device; this plan does not, because relocating `progressBlock` would drop `progress` from `NAV_ENTRIES` and invalidate both nav `deepEqual` arrays for a purely cosmetic gain. The bar keeps its position and its ids, loses its shimmer animation in step 1, and the rail is a step index rather than a second progress readout. Merging the two is a follow-up, not a prerequisite.

Phases are deliberately not in scope. The step rail groups nothing today because `parseSpecMarkdown` returns steps as a flat `{ action, why, verify }` list with no phase concept anywhere in the parser, the digest, the renderer, or the extractor — see `docs/plans/add-plan-phase-checkpoints.md`, which adds all four. That plan already edits `nav()`'s neighbours, so phase grouping is added there once the rail exists, rather than building a grouping hook here for data that does not exist yet.

`workflow: never` is set deliberately. Steps 1 through 6 are ordered edits to the same two files, `scripts/lib/plan-shell.mjs` and `scripts/build-plan-html.mjs`, so subagents fanning out would conflict on them. The renderer's own heuristic counts files and top-level directories and would otherwise license fan-out this plan cannot use.

## Files

- scripts/lib/plan-shell.mjs (modified) — tokens, dark palette, type roles, theme toggle, objective and step markup, step rail, scroll-spy fix
- scripts/build-plan-html.mjs (modified) — nest the glance in the objective card and pass the step list to `nav()`; the `progressBlock` call and the `NAV_ENTRIES` id list are left as they are
- kit/plugins/plan-agent/scripts/lib/plan-shell.mjs (generated) — re-copied from the repo-root source
- kit/plugins/plan-agent/scripts/build-plan-html.mjs (generated) — re-copied from the repo-root source
- kit/plugins/plan-agent/templates/plans-gallery.html (modified) — search plus status segmented control, type and effort disclosure, client-side In-flight and month grouping
- kit/plugins/plan-agent/hooks/build-index.sh (modified) — `data-month` attribute and in-progress-first sort
- scripts/build-plans-index.sh (modified) — same edit, kept byte-identical
- docs/plans/build-index.sh (modified) — same edit, kept byte-identical
- docs/plans/index.html (generated) — regenerated by the build script
- docs/artifacts/index.html (generated) — regenerated by the build script
- docs/prototypes/index.html (generated) — regenerated by the build script
- tests/plugins/test-build-plan-html.mjs (modified) — narrow the back-compat guard; the two nav id arrays stay as they are
- tests/plugins/test-plan-redesign.mjs (new) — objective-verification smoke test
- .claude-plugin/marketplace.json (modified) — plan-agent 7.4.4 to 7.5.0
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 7.5.0 entry

## Steps

1. Replace the `:root` token block in `plan-shell.mjs`'s `CSS` export with the prototype's palette and font stacks — `--paper`, `--panel`, `--sunk`, `--ink`, `--ink-2`, `--ink-3`, `--rule`, `--rule-soft`, `--accent`, `--accent-soft`, `--accent-line`, `--moss`, `--signal`, plus `--mono`, `--ui`, `--prose` — keeping every existing token name as an alias pointing at its replacement so no downstream selector breaks, then add the dark palette under both `:root[data-theme="dark"]` and `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) }`, and retarget the existing chrome selectors (`.plan-title`, `.plan-doc-type`, `.nav-heading`, `.plan-meta`, `.section-card h2`, `.step-number`, `.step-chip`) to `--mono`, `.section-card p` to `--prose`, and `.progress-bar-fill` to a flat accent with the `shimmer` animation dropped. Why: this is the whole visual refresh with zero DOM risk, because the back-compat guard blanks the `<style>` block, and it retires `--subtle: #9ca3af`, which measures 2.5:1 on white and is the page's current WCAG failure; aliasing rather than repointing keeps steps 1 through 5 safe against the old names, and step 6 removes both in one sweep. Verify: render a committed plan and confirm `git diff` touches no markup, that computed `color` on `.plan-nav li a` and `.step-chip` clears 4.5:1 against the page background in both themes, and that the literal string `html { scroll-behavior: auto; }` still appears verbatim.
2. Narrow the back-compat guard at `tests/plugins/test-build-plan-html.mjs:883` from a whole-document `assert.equal(stripVolatile(after), stripVolatile(before))` to `assert.deepEqual(extractSections(after), extractSections(before))` plus explicit assertions that the no-prototype render carries no `plan-prototype` meta tag and no prototype header link. Why: the guard's own comment says it protects "the DOM contract the extractor and the gallery read" while presentation evolves, but the byte-diff also fails on every intentional markup and inline-script change, so leaving it would make steps 3 through 6 indistinguishable from an accidental regression. Verify: the narrowed assertion passes against the unchanged renderer, and re-running it after deliberately renaming `class="verify-body"` in a scratch copy fails with the extractor contract named.
3. Add the theme toggle — a `data-theme`-reading inline script at the top of `<head>` in `page()`, a labelled toggle button in `header()` beside the Save-as-PDF button with `aria-pressed` and a 44×44px hit area, and a handler in the `SCRIPT` block that flips `documentElement.dataset.theme` and writes the choice to `localStorage`. Why: the palette from step 1 is inert without a way to reach it on a machine whose OS is set the other way, and the read has to happen in `<head>` before first paint because a plan opened from `file://` has no server to stamp the attribute and a wrong-theme flash on every load is worse than no toggle. Verify: toggling flips both the rendered colours and `aria-pressed`, the choice survives a reload, a first visit with no stored value follows `prefers-color-scheme`, and the button is absent from the print stylesheet output.
4. Nest the At-a-glance block inside the objective card — change `objectiveCard(objective)` to `objectiveCard(objective, glanceHtml = '')` emitting the existing `<section class="plan-glance">` inside the `<div id="objective">`, drop the separate `main.push(shell.glanceBlock(…))` at `build-plan-html.mjs:338`, and replace `stepCard`'s `<details class="step-verify-toggle"><summary>` wrapper with a plain labelled block that keeps `<div class="verify-body">` intact. Why: two sibling abstracts leave the reader unable to tell which is authoritative, and `Verify:` is the line someone needs while executing a step rather than one they should have to open; both are safe because `extractSections` at `plan-spec.mjs:219` already strips a nested `.plan-glance` and reads the verify text from `class="verify-body"` regardless of its wrapper. Verify: `extractSections` on the re-rendered sample returns an objective with no glance text in it, the glance still renders once, and the `.plan-glance` negative-margin rule is gone from the stylesheet.
5. Add the step rail to the sidebar — give each `.step-card` an `id="step-N"` while keeping `class="step-card completed"` as a literal substring, and change `nav(ids)` to `nav(ids, steps)` so it emits the existing section links unchanged (`<a href="#step-id">`, no other attributes) plus a `<ul class="rail-steps">` of `<a class="rail-step" href="#step-N">` links, each carrying the step's action text and a visually-hidden state span reading `step N of M, done` or `step N of M`. Below 900px the rail's step list moves inside a closed `<details>` rather than being hidden, so a mobile reader keeps the jump targets. The `progressBlock` output and the `NAV_ENTRIES` id list are left exactly where they are. Why: the plan's steps are its actual structure and the sidebar currently collapses all of them into one `steps` entry, so a reader can neither see how far along the work is nor jump to a step; leaving the progress block and the nav id list untouched keeps the progress JavaScript at `plan-shell.mjs:1438-1456`, its two assertions, and both nav `deepEqual` arrays green, so this step adds markup without invalidating any existing test. Verify: the section-link `deepEqual` at test line 635 returns the unchanged id list, every `#step-N` anchor resolves to a card, each rail link exposes its state to an accessibility-tree dump, and at 375px wide the step list is reachable through the disclosure.
6. Fix the scroll-spy so it clears the active link when nothing intersects — the observer at `plan-shell.mjs:1534-1545` only reacts to `isIntersecting` entries, so the last matched link stays highlighted forever — then delete the rules the redesign supersedes (`.steps-list::before`, `.step-verify-toggle`, and the `.plan-glance` sibling margin), remove the step 1 token aliases, and repoint every selector still naming an old token. Why: with one nav entry the stale highlight was invisible, but with a link per step a wrong "you are here" marker is worse than none; and carrying two names for every colour past the point where all callers have moved is how the stylesheet became generic in the first place. Verify: scrolling past the last section clears every `.active` class, scrolling back restores exactly one, grepping the stylesheet for the three deleted selectors and for each retired token name returns nothing, and the rendered page is visually unchanged from the end of step 5.
7. Re-copy `scripts/build-plan-html.mjs` and `scripts/lib/plan-shell.mjs` over their counterparts under `kit/plugins/plan-agent/scripts/`, after steps 1 through 6 and before any test run. Why: `tests/plugins/test-build-plan-html.mjs:951` asserts the bundled copies are byte-identical to the repo-root sources, so editing only one side both fails an existing test and ships the old design to anyone who installs the plugin. Verify: `diff scripts/build-plan-html.mjs kit/plugins/plan-agent/scripts/build-plan-html.mjs` and the same for `lib/plan-shell.mjs` each report no differences.
8. Rebuild the controls in `kit/plugins/plan-agent/templates/plans-gallery.html` — replace the three filter-chip rows with a search field, a status segmented control carrying per-status counts, and a `<details>` holding the type and effort chips, then extend the existing inline `applyFilters()` to insert an "In flight" separator before the in-progress run and a month separator between `data-month` values, rebuilding those separators on every filter change. Why: 88 uniform cards behind twenty filter targets buries the four plans actually in flight, and generating the separators client-side keeps them out of the markup `scripts/merge-plans-index.mjs` splices, so neither the merge driver nor `tests/plugins/test-merge-gallery-index.sh` has to learn about non-card content. Verify: load the regenerated index and confirm the counts match the cards, filtering to one status leaves no empty separators, the search still matches `data-title`, and the status control hides itself on the artifacts gallery, whose cards carry no status.
9. Emit `data-month` on each card and sort in-progress plans ahead of the date order in all three byte-identical copies of the build script — `kit/plugins/plan-agent/hooks/build-index.sh`, `scripts/build-plans-index.sh`, and `docs/plans/build-index.sh` — then regenerate `docs/plans/index.html`, `docs/artifacts/index.html`, and `docs/prototypes/index.html`. Why: the client-side grouping from step 8 has nothing to group without the attribute, the three copies are kept identical only by convention with no test guarding them, and the committed indexes are what the GitHub Pages site actually serves. Verify: `md5sum` of the three scripts match, every `<a class="gallery-card"` in the regenerated plans index carries a `data-month`, in-progress cards appear first, and the `<p>N items</p>` and `<span>N items</span>` strings the merge driver patches are unchanged.
10. Add `tests/plugins/test-plan-redesign.mjs` asserting the objective end to end. Why: every other check in this plan is a prose assertion, and without a runnable test the contrast fix, the merged goal panel, and the extractor round trip all regress silently the next time the stylesheet is touched. Verify: `node tests/plugins/test-plan-redesign.mjs` exits 0, and `node tests/plugins/test-build-plan-html.mjs` and `node tests/plugins/test-extract-plan-spec.mjs` both exit 0 with their nav id arrays unedited.
11. Bump plan-agent from 7.4.4 to 7.5.0 in `.claude-plugin/marketplace.json` and add the matching `kit/plugins/plan-agent/CHANGELOG.md` entry covering the token set, the theme toggle, the merged goal panel, the step rail, and the gallery controls. Why: repo convention requires any change under `kit/plugins/` to ship a version exceeding the value on main, and a reworked presentation shell with a new user-facing control is a minor bump rather than a patch. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.

## Tests

Tier 1 — This plan changes application code
- Objective: a rendered plan carries the new design in both themes without breaking the extractor contract. File: tests/plugins/test-plan-redesign.mjs; Type: smoke; Asserts: the rendered sample contains a `[data-theme]` dark rule and a theme-toggle button, every text token in the stylesheet clears 4.5:1 against its background in both palettes, the glance renders inside `id="objective"` while `extractSections` returns an objective free of glance text, `verify-body` appears outside any `<details>`, one `id="step-N"` anchor exists per step with a matching `a.rail-step` link, and `extractSections(renderPlanHtml(spec))` deep-equals the parsed spec sections; Run: node tests/plugins/test-plan-redesign.mjs
- Unit: nav emission with and without step links. File: tests/plugins/test-build-plan-html.mjs; Targets: shell.nav, NAV_ENTRIES; Key cases: section anchors keep a bare `href` attribute, the id list is unchanged from before this plan, a spec with one step, a spec with twelve steps, step link ids matching the card ids, the visually-hidden state span present on every rail link
- Unit: objective and step markup. File: tests/plugins/test-build-plan-html.mjs; Targets: objectiveCard, stepCard; Key cases: glance present, glance absent, completed step keeps `class="step-card completed"` as a literal substring, verify text preserved through the round trip
- Integration: gallery generation and grouping. File: tests/plugins/test-build-plan-html.mjs; Targets: build-index.sh, applyFilters; Key cases: every card carries `data-month`, in-progress cards sort first, the count strings the merge driver patches are unchanged, a gallery whose cards carry no status hides the status control

## Acceptance Criteria

- [ ] Every text token in the stylesheet measures at least 4.5:1 against its background in both the light and dark palettes
- [ ] `--subtle: #9ca3af` no longer appears in `scripts/lib/plan-shell.mjs`
- [ ] The literal string `html { scroll-behavior: auto; }` still appears in the rendered stylesheet
- [ ] The rendered stylesheet contains no literal `{lowercase-word}` sequence that the unfilled-token check at test line 630 would flag
- [ ] A first visit with no stored preference follows `prefers-color-scheme`, and a toggled choice survives a reload
- [ ] The theme toggle button is hidden by the print stylesheet
- [ ] The At-a-glance block renders inside `<div id="objective">` and `extractSections` returns an objective containing none of its text
- [ ] Step `Verify:` text renders visible, outside any `<details>`, and still inside `<div class="verify-body">`
- [ ] Each step card carries `id="step-N"` and keeps `class="step-card completed"` as a literal substring when done
- [ ] Every `a.rail-step` href resolves to a step card in the same document, and each carries a visually-hidden state span
- [ ] At 375px wide the step list is reachable through a disclosure rather than removed from the page
- [ ] Section anchors in the sidebar still match `/<a href="#([a-z-]+)">/` with no other attribute
- [ ] The two nav id arrays at `tests/plugins/test-build-plan-html.mjs:636` and `:639` pass unedited, and `id="progress-bar"` and `id="progress-label"` still exist exactly once each
- [ ] Scrolling past the last section leaves no `.active` class set
- [ ] `.steps-list::before`, `.step-verify-toggle`, and the `.plan-glance` negative-margin rule are absent from the stylesheet
- [ ] No retired token name — including `--subtle`, `--grey-bg`, and `--border-mid` — remains in the stylesheet after step 6, and no selector references one
- [ ] `diff` reports no differences between `scripts/build-plan-html.mjs` and `kit/plugins/plan-agent/scripts/build-plan-html.mjs`, and the same for `lib/plan-shell.mjs`
- [ ] The three `build-index.sh` copies have identical checksums
- [ ] Every `<a class="gallery-card"` in the regenerated plans index carries `data-month`, and in-progress cards precede the rest
- [ ] `<a class="gallery-card"` remains the leading attribute pair on every card, and the `<p>N items</p>` and `<span>N items</span>` strings are unchanged
- [ ] Filtering the gallery to a single status leaves no separator with zero cards under it
- [ ] `node tests/plugins/test-plan-redesign.mjs` exits 0
- [ ] `node tests/plugins/test-build-plan-html.mjs`, `node tests/plugins/test-extract-plan-spec.mjs`, `node tests/plugins/test-index-card-count.mjs`, and `bash tests/plugins/test-merge-gallery-index.sh` all exit 0
- [ ] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with plan-agent at 7.5.0

## Verification

Render a committed plan end to end: `node scripts/build-plan-html.mjs docs/plans/add-plan-phase-checkpoints.md -o /tmp/check.html` and confirm exit 0. Open it and check the four things this plan is for — one goal panel rather than two stacked summaries, a visible Verify line under every step, a sidebar listing all twelve steps as jump targets, and a theme toggle that flips the page and survives a reload. Narrow the window to 375px and confirm the step list is still reachable through its disclosure, then dump the accessibility tree for the rail and confirm each link announces its step number and done state rather than relying on the tick glyph. Then measure rather than eyeball: read the computed `color` and `background-color` of `.plan-nav li a`, `.step-chip`, `.plan-meta`, and `.section-card p` in both themes and confirm each pair clears 4.5:1, since the current `--subtle` fails at 2.5:1 and a screenshot cannot show that.

Prove the DOM contract survived. Run `node scripts/extract-plan-spec.mjs /tmp/check.html` — the extractor ships only at the repo root, not in the plugin bundle — and confirm the printed spec matches `docs/plans/add-plan-phase-checkpoints.md` section for section, with the glance absent from the objective. Re-render that extracted spec and diff the two HTML files to confirm the cycle is stable. The real-corpus round trip inside `tests/plugins/test-build-plan-html.mjs` re-renders at least ten committed plans and is the broader version of this check.

Exercise the gallery. Run `bash docs/plans/build-index.sh` and open `docs/plans/index.html`: confirm the four in-flight plans appear above the month-grouped remainder, that the header and footer counts agree with the number of cards, that filtering to `completed` leaves no empty separator, and that search still matches on title. Open `docs/artifacts/index.html` and confirm the status control is hidden there, since those cards carry no status. Then confirm the merge driver is unaffected by running `bash tests/plugins/test-merge-gallery-index.sh` and `node tests/plugins/test-index-card-count.mjs`.

Finally run the full gate: `node tests/plugins/test-plan-redesign.mjs`, `node tests/plugins/test-build-plan-html.mjs`, `node tests/plugins/test-extract-plan-spec.mjs`, `node tests/plugins/test-backfill-digest.mjs`, and `BASE_REF=main node scripts/check-plugin-versions.mjs`.

## Next Steps

- Fold the progress bar into the step rail
  Left out deliberately: relocating it costs an edit to both nav id arrays for a cosmetic gain, so it is worth doing on its own.
  ```text
  In the agentics repo, move the progressBlock output from the main column into the sidebar
  rail in scripts/lib/plan-shell.mjs, directly above the rail-steps list, keeping
  id="progress-bar" and id="progress-label" so the progress JavaScript and its assertions
  still resolve. Drop 'progress' from NAV_ENTRIES and update the two nav id arrays at
  tests/plugins/test-build-plan-html.mjs:636 and :639 to match. Re-copy the edited sources
  into kit/plugins/plan-agent/scripts/. Bump the plan-agent minor version in
  .claude-plugin/marketplace.json and add a CHANGELOG entry. Verify by rendering a committed
  plan and confirming the page shows one progress device, the label still reads "N / M done"
  after ticking a criterion, and node tests/plugins/test-build-plan-html.mjs exits 0.
  ```

- Give the docs hub the same shell and an activity band
  The hub at docs/index.html is still four static cards with no data; the prototype replaces it with an In-flight band plus per-collection counts and recent items.
  ```text
  In the agentics repo, redesign docs/index.html to match the shell in
  docs/prototypes/plans-site-redesign.html: the same sticky top bar with per-collection
  counts, an "In flight" band listing in-progress plans with their step progress, and a
  collections list showing each gallery's count and three most recent items. The hub is
  hand-maintained today — add a generator under scripts/ that reads the four gallery
  indexes and writes docs/index.html, and wire it into kit/plugins/plan-agent/hooks/dispatch.py
  beside the existing index builders. Bump the plan-agent minor version in
  .claude-plugin/marketplace.json and add a CHANGELOG entry. Verify by running the
  generator and confirming docs/index.html shows counts matching the four index.html files.
  ```

- Group the step rail by phase once phases land
  Depends on docs/plans/add-plan-phase-checkpoints.md, which adds the phase concept to the parser, digest, renderer, and extractor.
  ```text
  In the agentics repo, once ### Phase: headings are parsed into sections.phases by
  scripts/lib/plan-spec.mjs, group the sidebar step rail in scripts/lib/plan-shell.mjs by
  phase: emit a phase header above each phase's run of a.rail-step links, mark the current
  phase, and fall back to the existing flat list when a spec declares no phases. Re-copy the
  edited sources into kit/plugins/plan-agent/scripts/. Bump the plan-agent minor version in
  .claude-plugin/marketplace.json and add a CHANGELOG entry. Verify by rendering a phased
  fixture and an unphased one, confirming the phased rail shows headers in document order and
  the unphased rail is byte-identical to its output before the change.
  ```

- Wish list: a per-plan reading-time and step-cost estimate in the rail
  Blue sky — no data source exists for it yet.
  ```text
  In the agentics repo, explore whether the step rail in scripts/lib/plan-shell.mjs can show
  an estimated effort per step rather than only done/not-done. Investigate what signal is
  available from the spec today — step count, file count, the effort: frontmatter key — and
  report whether a per-step estimate is derivable without new authoring burden, or whether it
  would require a new spec field. Recommend one option with its cost. Do not implement.
  ```

## Resources

- docs/prototypes/plan-document-redesign.html — the verified plan-document prototype this plan implements
- docs/prototypes/plans-site-redesign.html — the verified gallery and hub prototype
- scripts/lib/plan-shell.mjs — the presentation shell; CSS export at line 30, SCRIPT at 1315, template functions from 1583
- tests/plugins/test-build-plan-html.mjs — the three gates: nav regex at 635, back-compat guard at 883, mirror at 948
- scripts/merge-plans-index.mjs — the gallery merge driver whose card-splice behaviour forced client-side grouping
