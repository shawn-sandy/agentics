# Retune the plan document design

> The plan page had six competing hues and three typefaces. Collapse it to one accent plus two states, demote mono to code only, and re-render every committed...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [retune-plan-document-design.md](plans/retune-plan-document-design.md)
**Type:** refactor

## What shipped

- Fix the palette values against the contrast gate *before* editing any
- Retune the three token blocks in `scripts/lib/plan-shell.mjs` — the
- Demote `--mono` to code and data: sans for the title and the section
- Retune the components the palette change exposes — the objective slab to
- Fix the three defects the screenshots surfaced: `word-break: break-all`
- Re-copy the edited shell to
- Apply the same token values to
- Re-render every committed plan with `scripts/rerender-plans.mjs` and
- Bump plan-agent to 9.1.0 in `.claude-plugin/marketplace.json` and write

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-shell.mjs` | palette, type roles, component tuning | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | re-copied from the repo-root source | Modified |
| `kit/plugins/plan-agent/templates/plans-gallery.html` | same palette, so the gallery does not clash with the plan... | Modified |
| `kit/plugins/plan-agent/templates/prototypes-gallery.html` | same palette | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 9.1.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | the 9.1.0 entry | Modified |
| `docs/plans/index.html` | rebuilt gallery index | Modified |

## How it works

Reduce the plan document's presentation to one coherent system — a single accent plus two semantic states, cool neutrals that match that accent, and two type roles instead of three — without changing a single byte of what `extractSections()` reads out of a rendered plan.

The 7.5.0 redesign fixed what it set out to fix: it measured contrast, added a dark palette, surfaced the Verify line, and built the step rail. What it left behind was a page that reads as loud rather than considered. Six hues compete for the same eye — a violet accent, moss, a burnt-orange

The implementation proceeded through these steps: Fix the palette values against the contrast gate *before* editing any; Retune the three token blocks in `scripts/lib/plan-shell.mjs` — the; Demote `--mono` to code and data: sans for the title and the section; Retune the components the palette change exposes — the objective slab to; Fix the three defects the screenshots surfaced: `word-break: break-all`.

- 12 plans left on the old shell — `rerender-plans.mjs` reports them as unreadable because they are review documents that do not satisfy the plan DOM contract; they already predated the 7.5.0 shell and are unchanged by this work

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [retune-plan-document-design.md](plans/retune-plan-document-design.md)
