# Retune plan document design tokens

> Reduces the plan design system to 1 accent color and 2 semantic states, demotes `--mono` to code-only, retunes token values without renaming them, and re-renders all committed plans to the new tokens.

<!-- generated:start -->

**Status:** Shipped 2026-08-08 **Plan:** [retune-plan-document-design.md](plans/retune-plan-document-design.md)
**Type:** refactor

## What shipped

- Reduced to 1 accent color (`--clr-accent`) and 2 semantic state colors (`--clr-ok`, `--clr-warn`).
- Demoted `--mono` font to code-only usage (removed from UI chrome, headings).
- Retuned token values (colors, spacing) without renaming tokens, preserving consumer code.
- Re-rendered all committed plans from `docs/plans/` to the new token values.
- Kept both dark-mode CSS blocks (`@media` and `[data-theme="dark"]`) in sync.
- Bumped plan-agent to 9.1.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Design tokens | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Dark mode sync | Modified |
| `kit/plugins/plan-agent/scripts/` (bundled copies) | Bundled copies | Modified |
| `docs/plans/*.html` | Re-rendered plans | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |

## How it works

The previous token system had accumulated accent colors through incremental additions: `--clr-accent`, `--clr-accent-alt`, `--clr-accent-muted`, plus separate status colors for each plan state. The retune consolidated these into the minimum set that carries meaning: one accent for interactive elements and highlights, two semantic states for pass/fail conditions.

Token values were changed but token names were preserved. This means consumer code (`class="text-accent"`, CSS rules referencing `var(--clr-accent)`) continues to work without edits — only the rendered color changes. This is the right trade-off: a token rename would require finding all uses, while a value retune is a one-file change.

The `--mono` demotion removes monospace font from non-code UI elements (step numbers, status chips, metadata). This was cosmetic but meaningful: monospace in non-code contexts reads as "terminal output" rather than "structured document," which conflicted with the plan's role as a formal specification.

Both dark-mode CSS blocks must stay in sync because some environments use the media-query form and others use the `data-theme` attribute form. The re-render of all committed plans updates the HTML artifacts to match the new tokens.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [retune-plan-document-design.md](plans/retune-plan-document-design.md)
