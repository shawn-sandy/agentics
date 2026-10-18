# Retune the plan document design

> Collapses the plan page from six competing hues and three typefaces to one accent plus two semantic states, demotes monospace to code only, and re-renders all committed plans through the result.

<!-- generated:start -->

**Status:** Shipped 2026-08-08  **Plan:** [retune-plan-document-design.md](plans/retune-plan-document-design.md)
**Type:** refactor

## What shipped

- Retuned the three token blocks in `scripts/lib/plan-shell.mjs` — light `:root`, `[data-theme="dark"]`, and `prefers-color-scheme` — replacing warm cream with a cool-neutral ground that matches the violet accent, collapsing `--purple` and `--wish-*` to the accent family, and retiring the burnt-orange `--signal` hue.
- Demoted `--mono` from headlines and section headings to code and data only; redefined `--prose` to `var(--ui)` so existing rules stay valid; removed the border from `code.md` (tint only, no barcode effect).
- Retuned structural components: the objective slab to a lead statement, the Implement row off moss and onto a neutral surface, header state before controls via CSS `order` (without moving DOM nodes), step actions to emphasised body weight.
- Fixed three layout defects: `word-break: break-all` replaced with path-boundary breaking, nested file-tree entries no longer inherit `font-weight: 600`, and six hardcoded mono stacks replaced with `var(--mono)`.
- Re-copied the edited shell byte-for-byte to `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs`.
- Applied the same token values to `plans-gallery.html` and `prototypes-gallery.html` so the gallery and its plans read as one system.
- Re-rendered all 87 committed plans with `scripts/rerender-plans.mjs` and rebuilt the gallery index; confirmed `extractSections()` output is byte-identical to each plan's committed predecessor.
- Bumped plan-agent to `9.1.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `scripts/lib/plan-shell.mjs` | Renderer shell | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled renderer shell | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Gallery template | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Prototypes template | Modified |
| `docs/plans/index.html` | Generated gallery | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |

## How it works

The 7.5.0 redesign fixed the structural problems — contrast, dark mode, visible Verify line, step rail. What it left was a page that read loud rather than designed: six competing hues (violet, moss, burnt-orange, red, two purples) over a warm cream `#fcfcfa` ground that belongs to none of them, and `--mono` doing four jobs simultaneously (2.2rem headline, every section heading, every label, and code).

The retune resolves two specific mismatches. Warm cream under a cool violet creates a palette war; replacing the ground with a cool neutral ends it. Monospace at 2.2rem makes the page read as a terminal dump; demoting it to code and labels only means the title and headings share one sans family with the body.

`--purple` and `--wish-*` were aliases pointing nowhere useful; repointing them to the accent family removes two hues from the rendered page without deleting any CSS rule that references them. `--prose` is redefined to `var(--ui)` rather than deleted for the same reason — every rule using it keeps working.

The three layout defects (word breaking, weight inheritance, mono stack duplication) were fixed because they were visible as broken regardless of the palette, not because they required a design change.

Re-rendering all 87 committed plans was required because those files are committed HTML output — a shell change only reaches new plans otherwise. `extractSections()` parity on all re-rendered files confirms no data was silently changed by the CSS edit.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [retune-plan-document-design.md](plans/retune-plan-document-design.md)
