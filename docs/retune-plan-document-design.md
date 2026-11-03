# Retune the plan document design

> Collapses six competing hues to one accent plus two semantic states, demotes monospace to code only, and fixes three defects — word-break, nested font-weight, and hardcoded mono stacks — without changing any byte that `extractSections()` reads.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [retune-plan-document-design](plans/retune-plan-document-design.md)
**Type:** refactor

## What shipped

- Fixed palette token values against the WCAG contrast gate (all 26 measured pairs at or above 4.5:1 in both palettes) before touching any CSS
- Retuned the three token blocks in `scripts/lib/plan-shell.mjs` — light `:root`, `[data-theme="dark"]`, and `prefers-color-scheme` — replacing warm cream (`#fcfcfa`) with cool neutrals that match the indigo accent
- Resolved `--purple` and `--wish-*` to the accent family (removed two hues without touching rules that use them), and redefined `--prose` to `var(--ui)` so existing rules keep working
- Demoted `--mono` to code and data: the 2.2rem title and section headings now use sans; `code.md` reduced to a tint with no border
- Retuned the objective slab to a lead statement, moved the Implement row off moss to a neutral surface, fixed header state ordering via CSS `order`, and changed step actions to emphasised body weight
- Fixed three defects: `word-break: break-all` splitting words mid-token in prompt rows; nested file-tree entries inheriting `font-weight: 600` from their directory row; six hardcoded mono stacks replaced with `var(--mono)`
- Re-copied the edited shell to `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs`
- Applied the same token values to `plans-gallery.html` and `prototypes-gallery.html`
- Re-rendered 87 committed plans via `scripts/rerender-plans.mjs` and rebuilt the gallery index (12 legacy review documents that predate the 7.5.0 DOM contract were left on the old shell)
- Bumped plan-agent to 9.1.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | Script — palette, type roles, component tuning | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled copy — byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | Template — new palette | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | Template — new palette | Modified |
| `docs/plans/index.html` | Generated gallery index — rebuilt | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent 9.1.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — 9.1.0 entry | Modified |

## How it works

The 7.5.0 redesign fixed structural problems (contrast, dark mode, step rail). What it left was a page that reads as loud rather than considered: six hues competing for the same eye — violet accent, moss, burnt-orange signal, red, and two purples — over a warm cream ground (`#fcfcfa`) that belongs to none of them. Warm cream under cool violet is the specific mismatch; cream-plus-terracotta is also one of the stock looks that reads as machine-generated.

The token names were kept exactly as they are (they appear in 2,269 lines of rules and in `test-plan-redesign.mjs`), so the fix was purely in values. The cool neutral ground (`--paper`, `--panel`, `--sunk`) was moved to the indigo family, `--purple` and `--wish-*` were aliased to the accent family (removing two hues without any rule changes), and `--moss` was replaced by a neutral surface for the Implement row.

The typography problem: `--mono` was doing four jobs — the 2.2rem headline, every section heading, every structural label, and code. A monospaced headline reads as a terminal dump. Meanwhile the plan corpus carries 3,000+ inline code spans, making nearly every line of reading text a serif/mono collision, and `code.md` had a fill *and* a border that turned a paragraph with six code spans into a barcode. The fix: sans-serif for title and headings, `--prose` redefined to `var(--ui)`, `code.md` reduced to a background tint only.

Three latent defects were fixed during the screenshot review pass: `word-break: break-all` was splitting path tokens mid-character inside prompt rows (changed to `overflow-wrap: anywhere`); file-tree entries under a subdirectory were inheriting `font-weight: 600` from their parent directory row (specificity fix); and six places used a hardcoded monospace stack instead of `var(--mono)`.

The two dark token blocks (`[data-theme="dark"]` and the `prefers-color-scheme` block) must define identical names and values — an assertion in `test-plan-redesign.mjs`. Both blocks were edited together to maintain that invariant.

`extractSections()` parity: `rerender-plans.mjs` re-rendered 87 plans and confirmed that `extractSections()` over each re-rendered file deep-equals the same call on its committed predecessor. Twelve plans were left on the old shell because they are review documents that predate the 7.5.0 DOM contract and were not produced by the current renderer. Two sibling galleries (`docs/artifacts/index.html`, `docs/media/social/index.html`) are out of scope — they belong to `artifact-tools` and `social-media-tools`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [retune-plan-document-design](plans/retune-plan-document-design.md)
