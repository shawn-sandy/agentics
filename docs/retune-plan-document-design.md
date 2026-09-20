# Retune the plan document design

> The plan page had six competing hues and three typefaces. Collapse it to one accent plus two states, demote mono to code only, and re-render every committed...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [retune-plan-document-design.md](plans/retune-plan-document-design.md)
**Type:** refactor

## What shipped

- Fix the palette values against the contrast gate *before* editing any CSS, by scripting the same WCAG maths `test-plan-redesign.mjs` uses over the proposed light and dark token sets.
- Retune the three token blocks in `scripts/lib/plan-shell.mjs` — the light `:root`, the `[data-theme="dark"]` block, and the `prefers-color-scheme` block — keeping the two dark blocks in sync.
- Demote `--mono` to code and data: sans for the title and the section headings, `--prose` redefined to `var(--ui)`, and `code.md` reduced to a tint with no border.
- Retune the components the palette change exposes — the objective slab to a lead statement, the Implement row off moss and onto a neutral surface, header state before controls via CSS `order`, step actions to emphasised body weight.
- Fix the three defects the screenshots surfaced: `word-break: break-all` splitting words mid-token in four prompt rows, nested file-tree entries inheriting `font-weight: 600` from their directory row, and six hardcoded copies of the mono stack that could resolve to a different face than `var(--mono)`.
- Re-copy the edited shell to `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs`.
- Apply the same token values to `kit/plugins/plan-agent/templates/plans-gallery.html` and `prototypes-gallery.html`, and correct the stale contrast comment on the current-tab chip.
- Re-render every committed plan with `scripts/rerender-plans.mjs` and rebuild the gallery index.
- Bump plan-agent to 9.1.0 in `.claude-plugin/marketplace.json` and write the CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | palette, type roles, component tuning | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | re-copied from the repo-root source | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | same palette, so the gallery does not clash with the plans behind it | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | same palette | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 9.1.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | the 9.1.0 entry | Modified |
| `docs/plans/index.html` | rebuilt gallery index | Modified |

## How it works

Reduce the plan document's presentation to one coherent system — a single accent plus two semantic states, cool neutrals that match that accent, and two type roles instead of three — without changing a single byte of what `extractSections()` reads out of a rendered plan.

The 7.5.0 redesign fixed what it set out to fix: it measured contrast, added a dark palette, surfaced the Verify line, and built the step rail. What it left behind was a page that reads as loud rather than considered. Six hues compete for the same eye — a violet accent, moss, a burnt-orange signal, red, and two purples — over a warm cream `#fcfcfa` ground that belongs

The implementation proceeded through the following steps: Fix the palette values against the contrast gate *before* editing any; Retune the three token blocks in `scripts/lib/plan-shell.mjs` — the; Demote `--mono` to code and data: sans for the title and the section; Retune the components the palette change exposes — the objective slab to; Fix the three defects the screenshots surfaced: `word-break: break-all`; Re-copy the edited shell to.

- 12 plans left on the old shell — `rerender-plans.mjs` reports them as unreadable because they are review documents that do not satisfy the plan DOM contract; they already predated the 7.5.0 shell and are unchanged by this work - Two sibling galleries still render cream — `docs/artifacts/index.html` and

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [retune-plan-document-design.md](plans/retune-plan-document-design.md)
