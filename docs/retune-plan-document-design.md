# Retune the plan document design

> The plan page had six competing hues and three typefaces. The 7.5.0 redesign fixed contrast and dark mode; this collapses to one accent plus two semantic states, demotes monospace to code only, and re-renders every committed plan through the result.

<!-- generated:start -->

**Status:** Shipped 2026-08-08 **Plan:** [retune-plan-document-design.md](plans/retune-plan-document-design.md)
**Type:** refactor

## What shipped

- Retuned the three token blocks in `scripts/lib/plan-shell.mjs` — light `:root`, `[data-theme="dark"]`, and `prefers-color-scheme: dark` — keeping every token name identical and moving only values. `--subtle: #9ca3af` (the WCAG 2.5:1 failure) replaced by `--ink-3`; `--purple` and `--wish-*` resolve to the accent family, removing two hues without touching any rule that uses them.
- Demoted `--mono` to code and data: title and section headings moved to sans (`var(--ui)`); `--prose` redefined to `var(--ui)`; `code.md` reduced to a tint with no border.
- Retuned components: objective slab to a lead statement, Implement row off moss and onto a neutral surface, header state before controls via CSS `order` (no DOM changes — the extractor and gallery both walk that markup), step actions to emphasised body weight.
- Fixed three defects the screenshots surfaced: `word-break: break-all` splitting words mid-token in prompt rows; nested file-tree entries inheriting `font-weight: 600` from their directory row; six hardcoded mono stacks replaced with `var(--mono)`.
- Re-copied the edited shell to `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` (byte-identical).
- Applied the same token values to `plans-gallery.html` and `prototypes-gallery.html`.
- Re-rendered 87 committed plans with `scripts/rerender-plans.mjs`; `extractSections()` over each re-rendered file deep-equals its committed predecessor. 12 plans left on the old shell (review documents predating the 7.5.0 contract).
- Bumped plan-agent to 9.1.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | Palette, type roles, component tuning | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Token values synced | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Token values synced | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.1.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent → 9.1.0 | Modified |
| `docs/plans/index.html` | Regenerated | Modified |

## How it works

**Single-accent palette**: Warm cream `#fcfcfa` was the specific mismatch with the violet accent. The new `--paper` is neutral-cool. `--moss` and `--signal` (burnt-orange) resolve to the accent family, leaving one hue across the page instead of six.

**Type system**: `--mono` doing four jobs at 2.2rem was the loudest element. The title and all headings are now `var(--ui)` (system sans), code uses `var(--mono)`, and prose uses `var(--ui)` via the redefined `--prose`. Georgia and the 3,000+ inline code spans no longer collide on every reading line.

**Token names unchanged**: Names are referenced by `tests/plugins/test-plan-redesign.mjs` and 2,269 lines of rules; renaming them bought nothing the retune needed. Only values moved.

**Presentation-only**: `extractSections()` over each re-rendered plan deep-equals the same call on its committed predecessor — zero content changes across 87 files.

## How to use it

The changes are automatic — plans rendered from this version forward use the new palette and type system. The theme toggle remains in every rendered plan header.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-08-08 | refactor(plan-agent): retune palette to single accent, demote mono to code, fix three layout defects, re-render 87 plans (9.1.0) |

<!-- generated:end -->

## References

- Plan: [retune-plan-document-design.md](plans/retune-plan-document-design.md)
