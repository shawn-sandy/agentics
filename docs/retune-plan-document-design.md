# Retune the plan document design

> Reduce the plan document's visual design to a single accent, two semantic states, cool neutrals, and two type roles — eliminating six competing hues and monospace overuse without changing a byte of extracted content.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [retune-plan-document-design.md](plans/retune-plan-document-design.md)
**Type:** refactor

## What shipped

- Retuned the three token blocks in `scripts/lib/plan-shell.mjs` (light `:root`, `[data-theme="dark"]`, and `prefers-color-scheme`) to a single accent family with cool neutrals
- Resolved `--purple` and `--wish-*` tokens into the accent family rather than deleting them, removing two hues without breaking any referencing rule
- Demoted `--mono` to code and data only; title and section headings now use the sans stack; `--prose` redefined to `var(--ui)`
- Reduced `code.md` to a tint with no border, eliminating the barcode effect in code-dense prose
- Fixed `word-break: break-all` splitting tokens mid-word in prompt rows, nested file-tree entries inheriting bold weight from their directory row, and six hardcoded mono stacks
- Re-copied the edited shell to `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` for byte-identical parity
- Applied the same palette tokens to `plans-gallery.html` and `prototypes-gallery.html` so gallery and plan pages form a coherent system
- Re-rendered all ~87 committed plans under `docs/plans/` with `scripts/rerender-plans.mjs`; no `extractSections()` output changed
- Bumped plan-agent to 9.1.0 and added a CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | Canonical renderer shell — palette and type tuning | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy — re-copied from root | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Gallery template — palette synced | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Prototypes gallery — palette synced | Modified |
| `.claude-plugin/marketplace.json` | plan-agent bumped to 9.1.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.1.0 entry | Modified |
| `docs/plans/index.html` | Regenerated gallery index | Modified |

## How it works

The 7.5.0 redesign introduced measurable contrast and a dark palette but left behind a visually loud result. Six hues competed on the same page — violet, moss, burnt-orange, red, and two purples — over a warm cream `#fcfcfa` ground that clashed with all of them. Warm cream under a cool violet accent is a specific mismatch; cream-plus-terracotta reads as machine-generated. Meanwhile `--mono` was doing four jobs at once: the 2.2rem page headline, every section heading, structural labels, and inline code. A monospaced headline made the page read like a terminal dump, and nearly every prose line was a serif/mono collision because the plan corpus carries 3,000+ inline code spans.

The retune is a values-only change: token *names* stay exactly as they were. `--purple` and `--wish-*` resolve to the accent family rather than disappearing, so rules that use them keep working without touching 2,269 lines of existing rules. `--prose` is redefined to `var(--ui)` rather than removed for the same reason. This meant no cascade audit was needed, only value substitution.

The palette work started before any CSS was edited: the same WCAG contrast maths that `test-plan-redesign.mjs` uses were scripted against the proposed light and dark token sets, verifying all 26 measured color pairs clear 4.5:1 before the first edit. The test also asserts the two dark token blocks (`[data-theme="dark"]` and `prefers-color-scheme: dark`) define identical names and values, which the renderer requires for predictable behavior across explicit and media-query activation.

Type demotions resolve the two loudest problems with single-rule changes: `--mono` is removed from the title and heading rules (replaced with the system sans stack), and `code.md` loses its border (keeping only a background tint). The objective slab was restated as a lead statement, the Implement row moved off moss and onto a neutral surface, and step actions were set to emphasized body weight rather than a distinct family. Header state is ordered before controls via CSS `order` property rather than by moving DOM nodes, preserving the extractor's walk order.

Three defects surfaced during screenshot review and were fixed in the same pass: `word-break: break-all` was splitting long tokens (like file paths) mid-character rather than at path separators; nested file-tree entries were inheriting `font-weight: 600` from their parent directory row; and six hardcoded mono stack strings outside `var(--mono)` would resolve inconsistently if the token ever changed.

The renderer lives in two places — `scripts/lib/plan-shell.mjs` (canonical) and the byte-identical copy in `kit/plugins/plan-agent/scripts/lib/`. A test asserts parity, so both had to move together. The gallery templates (`plans-gallery.html`, `prototypes-gallery.html`) carry their own copy of the palette and were updated so the index a reader lands on resolves the same `--paper` value as the plan pages behind it.

Finally, the ~87 committed plan HTML files under `docs/plans/` were re-rendered with `scripts/rerender-plans.mjs`. A presentation-only change is only correct if `extractSections()` over each re-rendered file deep-equals the same call on its predecessor — confirmed for all files with a diff.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `d2e9f10` | 2026-09-02 | feat: polish the plan-document HTML output (#617) |
| `94c0569` | 2026-08-23 | feat(plan-agent): add design phase — canvas link, gallery, and drift check (#596) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [retune-plan-document-design.md](plans/retune-plan-document-design.md)
