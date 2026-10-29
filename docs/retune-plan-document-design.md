# Retune the Plan Document Design

> The plan page had six competing hues and three typefaces. Collapse it to one accent plus two states, demote mono to code only, and re-render every committed plan through the result.

<!-- generated:start -->

**Status:** Shipped 2026-08-08  **Plan:** [retune-plan-document-design.md](plans/retune-plan-document-design.md)
**Type:** refactor

## What shipped

- Replaced six competing hues (violet accent, moss, burnt-orange, red, two purples) over a warm cream ground with a single accent family plus two semantic states, resolving the cool-violet-on-warm-cream mismatch.
- Demoted `--mono` from four roles (2.2rem headline, section headings, structural labels, code) to code and data labels only; all headings and titles now use the sans system stack; `--prose` was redefined to `var(--ui)` rather than removed, preserving all rules that reference it.
- Reduced inline code spans from a fill-plus-border barcode pattern to a tint with no border.
- Fixed the objective slab to read as a lead statement, moved the Implement row off moss onto a neutral surface, ordered header state before controls via CSS `order` (without moving DOM nodes, preserving extractor/gallery compatibility), and set step actions to emphasised body weight.
- Fixed three defects exposed by screenshots: `word-break: break-all` splitting words mid-token in prompt rows (replaced with path-boundary break), nested file-tree entries inheriting `font-weight: 600` from directory rows, and six hardcoded mono stack copies that could resolve to a different face than `var(--mono)`.
- Verified all 26 WCAG contrast pairs at ≥4.5:1 in both light and dark palettes before any CSS was edited; kept the two dark-theme selector blocks in sync.
- Re-copied `scripts/lib/plan-shell.mjs` to `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` byte-for-byte, passing the parity assertion.
- Applied the same token values to `plans-gallery.html` and `prototypes-gallery.html` so the gallery index and plan pages share one visual system.
- Re-rendered all 87 re-renderable committed plans; confirmed `extractSections()` over each re-rendered file matches its committed predecessor byte-for-byte.
- Bumped `plan-agent` to 9.1.0 and added a CHANGELOG entry.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `scripts/lib/plan-shell.mjs` | Canonical renderer shell — palette, type roles, component tuning | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy — byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Gallery template — palette synced to plan pages | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Prototypes gallery — palette synced to plan pages | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — plan-agent 9.1.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — 9.1.0 entry | Modified |
| `docs/plans/index.html` | Gallery index — rebuilt after palette change | Modified |

## How it works

The 7.5.0 redesign had delivered correct contrast, a dark palette, the Verify line, and the step rail. What it left behind was a page with competing visual signals: six distinct hues fighting for the same eye over a warm cream `#fcfcfa` background that matched none of them. Warm cream under a cool violet accent is a specific colour-temperature mismatch, and cream-plus-terracotta reads as machine-generated rather than designed.

The palette retune started from the test, not from CSS. `test-plan-redesign.mjs` already measured 26 WCAG contrast pairs across both palettes. A standalone script ran the same maths over the proposed token set before any source file was edited. All pairs cleared 4.5:1 in both palettes, establishing the green reference point. Token *names* were left exactly as they were — they are referenced by 2,269 lines of rules and by the test itself, and renaming them would have bought nothing. `--purple` and `--wish-*` were resolved to the accent family rather than deleted, removing two hues from the rendered page without touching any rule that uses them.

The typography change had more visible impact than the palette shift. `--mono` at 2.2rem on the page title made every plan page read as a terminal dump. Georgia prose against monospaced section headings produced a serif/mono collision on nearly every reading line, compounded by the 3,000+ inline code spans in the plan corpus. The fix is straightforward: `--mono` now appears only on code and data labels; the title and all section headings use the sans system stack; `--prose` is redefined to `var(--ui)` so every rule that names it keeps working without a search-and-replace. Inline `code.md` was reduced to a background tint with no border, eliminating the barcode effect in code-dense paragraphs.

Three defects surfaced during screenshot review that were wrong regardless of palette choice. `word-break: break-all` was splitting long tokens mid-character in prompt rows rather than at path boundaries. Nested file-tree entries were inheriting `font-weight: 600` from their parent directory row. Six hardcoded mono font-stack strings in the CSS would resolve to a different face than `var(--mono)` if the token value ever changed. All three were corrected in the same pass. Header state ordering was fixed with CSS `order` rather than by reordering DOM nodes; the extractor and gallery both walk that markup, and moving nodes would have changed their output.

The two dark-theme blocks (the `[data-theme="dark"]` attribute selector and the `prefers-color-scheme: dark` media query) must stay in sync; the test asserts they define identical token names and values. Both were updated together. The gallery templates `plans-gallery.html` and `prototypes-gallery.html` carry their own copies of the palette, so they were updated to match — without this step the index page would have remained warm cream while every plan behind it was indigo. Twelve plans remained on the old shell because they are review documents that do not satisfy the plan DOM contract and were already outside the 7.5.0 redesign scope.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [retune-plan-document-design.md](plans/retune-plan-document-design.md)
