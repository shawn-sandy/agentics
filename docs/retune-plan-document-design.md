# Retune the plan document design

> Reduced the plan document's palette from six competing hues to one accent plus two semantic states, and demoted monospace from structural headings to code-only, without touching any data extractSections() reads.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [retune-plan-document-design.md](plans/retune-plan-document-design.md)
**Type:** refactor

## What shipped

- Retuned the light and dark token blocks in `scripts/lib/plan-shell.mjs` — replaced six competing hues (violet, moss, burnt-orange, red, two purples over warm cream) with a single cool-neutral accent family, keeping token names identical.
- Redefined `--purple` and `--wish-*` to resolve to the accent family rather than being deleted, removing hues without touching any rule that references them.
- Demoted `--mono` to code and data only: sans-serif for title and section headings, `--prose` redefined to `var(--ui)`, `code.md` reduced to a tint with no border.
- Retuned components exposed by the palette change: objective slab to a lead statement, Implement row off moss, header state before controls via CSS `order`, step actions to emphasised body weight.
- Fixed three rendering defects: `word-break: break-all` splitting tokens mid-word, nested file-tree entries inheriting `font-weight: 600`, and six hardcoded mono-stack copies.
- Re-copied the edited shell to `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` (held byte-identical by an existing parity assertion).
- Applied the same token values to `plans-gallery.html` and `prototypes-gallery.html`.
- Re-rendered all ~87 committed plans via `scripts/rerender-plans.mjs`; verified `extractSections()` deep-equals its committed predecessor on every file.
- Bumped plan-agent to 9.1.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | Canonical renderer — palette, type, component retune | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Plugin renderer — byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Gallery template — palette synced | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Gallery template — palette synced | Modified |
| `docs/plans/index.html` | Gallery index — rebuilt | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — plan-agent 9.1.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — 9.1.0 entry | Modified |

## How it works

The 7.5.0 redesign had introduced functional improvements (contrast measurement, dark palette, step rail) but left a visually loud page: six hues competing on a warm cream ground that matched none of them, monospace at 2.2rem making the title read as a terminal dump, and `code.md` with both a fill and a border that turned dense paragraphs into a barcode.

The retune fixed the ground first by switching to a cool neutral (`--paper`). The accent family then resolved consistently across all hues. `--purple` and `--wish-*` were aliases rather than deletions — this removes the hues from the rendered output without requiring changes to 2,269 lines of rules.

Demoting `--mono` required redefining `--prose` to `var(--ui)` rather than leaving it as Georgia — every rule that names `--prose` got sans-serif automatically without a grep-and-replace pass.

The renderer lives in two places: `scripts/lib/plan-shell.mjs` (canonical, imported by tests) and a byte-identical bundle copy under `kit/plugins/plan-agent/scripts/lib/`. An existing parity assertion fails if the two diverge. This plan edits the canonical copy, then re-copies.

All ~100 committed plan files are generated output from `scripts/lib/plan-shell.mjs`. Changing the renderer only reaches them when someone next writes that plan's spec, so `scripts/rerender-plans.mjs` ran a batch re-render. Twelve plans were left on the old shell (review documents that predate the plan DOM contract); these are unchanged.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `c16fe83f` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract (9.14.0–9.17.0) (#628) |
| `b8cfa1fd` | 2026-09-04 | fix(plan-agent): style header links as chips and refocus a leading select after submit (9.13.1) (#623) |
| `d2e9f101` | 2026-09-02 | feat: polish the plan-document HTML output (#617) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [retune-plan-document-design.md](plans/retune-plan-document-design.md)
