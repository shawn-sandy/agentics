# Fix: Stale `.claude.md.local` Reference in CLAUDE.md

> One-line fix in `CLAUDE.md` correcting a stale filename reference from `.claude.md.local` to `CLAUDE.local.md` following the project's rename of the machine-specific override file.

<!-- generated:start -->

**Status:** Shipped 2026-02-24   **Plan:** [fix-claude-md-stale-local-filename.md](plans/fix-claude-md-stale-local-filename.md)   **Type:** artifact

## What shipped

- `CLAUDE.md` line 43 updated: `.claude.md.local` → `CLAUDE.local.md` in the inline note about machine-specific paths.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `CLAUDE.md` | Project instructions | Modified (line 43) |

## How it works

The project renamed its machine-specific override file from `.claude.md.local` to `CLAUDE.local.md` in commits `c5ad022` and `fb4240b`. A single inline note on line 43 of `CLAUDE.md` was missed in that rename and continued to reference the old filename. This plan corrected that one line, bringing the documentation back in sync with the actual file structure.

The `CLAUDE.md` audit that identified this scored 11/12 (Optimized) with a single deduction in the Structure dimension for this stale reference.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |

<!-- generated:end -->

## References

- Plan: [fix-claude-md-stale-local-filename.md](plans/fix-claude-md-stale-local-filename.md)
