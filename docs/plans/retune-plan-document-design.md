---
status: completed
type: refactor
created: 2026-08-08
effort: medium
glance: The plan page had six competing hues and three typefaces. Collapse it to one accent plus two states, demote mono to code only, and re-render every committed plan through the result.
---

# Plan: Retune the plan document design

## Objective

Reduce the plan document's presentation to one coherent system — a single
accent plus two semantic states, cool neutrals that match that accent, and two
type roles instead of three — without changing a single byte of what
`extractSections()` reads out of a rendered plan.

## Context

The 7.5.0 redesign fixed what it set out to fix: it measured contrast, added a
dark palette, surfaced the Verify line, and built the step rail. What it left
behind was a page that reads as loud rather than considered.

Six hues compete for the same eye — a violet accent, moss, a burnt-orange
signal, red, and two purples — over a warm cream `#fcfcfa` ground that belongs
to none of them. Warm cream under a cool violet is the specific mismatch, and
cream-plus-terracotta is also one of the stock looks that reads as
machine-generated rather than designed.

`--mono` carries four jobs at once: the 2.2rem headline, every section
heading, every structural label, and code. A monospaced headline makes the
page read as a terminal dump. Meanwhile prose was Georgia, and the plan corpus
carries 3,000+ inline code spans, so nearly every line of reading text was a
serif/mono collision. `code.md` had a fill *and* a border, which turned a
paragraph with six code spans into a barcode.

The renderer also has two homes: `scripts/lib/plan-shell.mjs` and its
byte-identical copy under `kit/plugins/plan-agent/scripts/lib/`. A test asserts
they match, so both move together or neither does.

## Decisions

- Token *names* stay exactly as they are; only values move. The names are
  referenced by `tests/plugins/test-plan-redesign.mjs` and by 2,269 lines of
  rules, and renaming them buys nothing the retune needs.
- `--purple` and `--wish-*` resolve to the accent family rather than being
  deleted, which removes two hues from the page without touching any rule that
  uses them.
- No webfont. The CSP blocks font CDNs, and inlining a face as a data URI would
  add six figures of bytes to each of ~100 committed plan files. Character
  comes from scale, weight, and tracking on the system stack instead.
- `--prose` is redefined to `var(--ui)` rather than removed, so every rule that
  names it keeps working.
- Header order is fixed with CSS `order`, not by moving nodes — the extractor
  and the gallery both walk that markup.
- `SKELETON.html` is deliberately left alone. `kit/plugins/plan-agent/README.md`
  labels it legacy and no rendered plan passes through it.

## Files

- scripts/lib/plan-shell.mjs (modified) — palette, type roles, component tuning
- kit/plugins/plan-agent/scripts/lib/plan-shell.mjs (generated) — re-copied from the repo-root source
- kit/plugins/plan-agent/templates/plans-gallery.html (modified) — same palette, so the gallery does not clash with the plans behind it
- kit/plugins/plan-agent/templates/prototypes-gallery.html (modified) — same palette
- .claude-plugin/marketplace.json (modified) — plan-agent 9.1.0
- kit/plugins/plan-agent/CHANGELOG.md (modified) — the 9.1.0 entry
- docs/plans/index.html (generated) — rebuilt gallery index

## Steps

1. [x] Fix the palette values against the contrast gate *before* editing any
   CSS, by scripting the same WCAG maths `test-plan-redesign.mjs` uses over the
   proposed light and dark token sets. Why: the shell ships 26 measured colour
   pairs, and discovering a failure after the edits means unpicking which of
   several changes caused it. Verify: the standalone script reports all pairs
   at or above 4.5:1 in both palettes.

2. [x] Retune the three token blocks in `scripts/lib/plan-shell.mjs` — the
   light `:root`, the `[data-theme="dark"]` block, and the
   `prefers-color-scheme` block — keeping the two dark blocks in sync. Why: the
   test asserts the two dark selectors define identical token names and values,
   so an edit to one alone fails. Verify: `node tests/plugins/test-plan-redesign.mjs`
   passes its contrast and token-parity checks.

3. [x] Demote `--mono` to code and data: sans for the title and the section
   headings, `--prose` redefined to `var(--ui)`, and `code.md` reduced to a
   tint with no border. Why: mono doing four jobs at 2.2rem is the single
   loudest thing on the page, and the serif/mono collision is the second.
   Verify: render a code-dense plan and confirm the title, headings, and body
   are one family and the code spans read as quiet inline objects.

4. [x] Retune the components the palette change exposes — the objective slab to
   a lead statement, the Implement row off moss and onto a neutral surface,
   header state before controls via CSS `order`, step actions to emphasised
   body weight. Why: recolouring alone leaves the same two saturated fills
   stacked above the fold and the same twelve-headline step list. Verify:
   screenshot the rendered plan in both themes and confirm no fill dominates
   the opening screen.

5. [x] Fix the three defects the screenshots surfaced: `word-break: break-all`
   splitting words mid-token in four prompt rows, nested file-tree entries
   inheriting `font-weight: 600` from their directory row, and six hardcoded
   copies of the mono stack that could resolve to a different face than
   `var(--mono)`. Why: these are wrong regardless of palette, and they are what
   made the page look broken rather than merely loud. Verify: a rendered plan
   breaks long paths at path boundaries, files under a subdirectory render at
   normal weight, and no hardcoded mono stack remains.

6. [x] Re-copy the edited shell to
   `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs`. Why: a test asserts the
   bundled copy is byte-identical to the repo-root source, so editing one side
   both fails CI and ships a stale renderer to anyone who installs the plugin.
   Verify: `diff` between the two paths reports no differences.

7. [x] Apply the same token values to
   `kit/plugins/plan-agent/templates/plans-gallery.html` and
   `prototypes-gallery.html`, and correct the stale contrast comment on the
   current-tab chip. Why: the galleries carry their own copy of the palette, so
   without this the index a reader lands on stays cream while every plan behind
   it is indigo. Verify: the regenerated `docs/plans/index.html` carries the new
   `--paper` values and the tab-chip note states the measured ratio.

8. [x] Re-render every committed plan with `scripts/rerender-plans.mjs` and
   rebuild the gallery index. Why: the ~100 plans under `docs/plans/` are
   committed output, so a shell change reaches them only when someone next
   writes that plan's spec. Verify: the script reports 87 re-rendered, and
   `extractSections()` over each re-rendered file matches its committed
   predecessor exactly.

9. [x] Bump plan-agent to 9.1.0 in `.claude-plugin/marketplace.json` and write
   the CHANGELOG entry. Why: the CI guard fails any PR whose changed plugin
   does not exceed the base branch. Verify:
   `BASE_REF=main node scripts/check-plugin-versions.mjs` reports OK.

## Tests

- **Objective test** — `node tests/plugins/test-plan-redesign.mjs` passes all 12
  checks, including the 26 contrast pairs in both palettes and the token-parity
  assertion across the two dark blocks.
- **Regression** — every test in `.github/workflows/check-plugin-versions.yml`
  that runs today still runs, with `test-imperative-pruning.sh` failing exactly
  as it does on a clean checkout of `main`.
- **Presentation-only** — `extractSections()` over each re-rendered plan
  deep-equals the same call on its committed predecessor, for all 86 files with
  a diff.

## Acceptance Criteria

- [x] Every token pair the redesign test measures clears 4.5:1 in both palettes
- [x] The two dark token blocks define identical names and values
- [x] `--mono` appears on no heading, title, or prose rule — only code and labels
- [x] The two `plan-shell.mjs` copies are byte-identical
- [x] No re-rendered plan changes its extracted content
- [x] The gallery index and the plan pages resolve the same `--paper` value
- [x] plan-agent is 9.1.0 and the version guard passes

## Verification

Render a code-dense plan through `scripts/build-plan-html.mjs`, screenshot it in
both themes at 1280px, and confirm: the title is sans, no fill dominates the
opening screen, code spans read as quiet inline objects rather than a barcode,
long paths break at path boundaries, and files under a subdirectory render at
normal weight. Then open `docs/plans/index.html` and confirm the gallery and the
plan pages read as one system.

## Completion Report

- 12 plans left on the old shell — `rerender-plans.mjs` reports them as
  unreadable because they are review documents that do not satisfy the plan DOM
  contract; they already predated the 7.5.0 shell and are unchanged by this work
- Two sibling galleries still render cream — `docs/artifacts/index.html` and
  `docs/media/social/index.html` carry their own copies of the old palette and
  belong to `artifact-tools` and `social-media-tools`, so they are out of scope
- The galleries keep their monospaced heading — on an index page mono reads as a
  directory listing rather than a terminal dump, so changing it is a separate
  call from the palette sync this plan needed
