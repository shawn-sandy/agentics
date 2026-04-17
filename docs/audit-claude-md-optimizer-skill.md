# Audit claude-md-optimizer SKILL.md

> Structured quality audit of the `claude-md-optimizer` skill against the 5-dimension reviewing-skills rubric, scoring 8/10 and identifying two actionable improvements: progressive disclosure and a scope boundary in the frontmatter description.

<!-- generated:start -->

**Status:** Shipped 2026-02-27   **Plan:** [audit-claude-md-optimizer-skill.md](plans/audit-claude-md-optimizer-skill.md)   **Type:** artifact

## What shipped

This plan is an audit artifact — it documents the findings and proposed fixes from running `reviewing-skills` against `kit/plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md`. The audit resulted in improvements applied to that skill.

**Audit score: 8/10 (Functional)**

| Dimension | Score | Key Finding |
|-----------|-------|-------------|
| 1. Frontmatter Validity | 1/2 | Missing scope boundary (no "not for SKILL.md" exclusion) |
| 2. Body Quality | 2/2 | Within limits, imperative voice, concrete examples present |
| 3. Structure & Progressive Disclosure | 1/2 | 295 lines inline with no `references/` delegation |
| 4. Anti-pattern Detection | 2/2 | Clean |
| 5. Discoverability | 2/2 | "Use when…" with 5 scenarios, 4+ keywords |

**Top issues identified:**
1. All 295 lines inline — example audit output (~45 lines) and Notes should be extracted to `references/`.
2. Frontmatter description missing scope boundary — add "Does not audit SKILL.md, commands, or non-CLAUDE.md files."
3. Freedom level not stated — one-line addition needed.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md` | Target skill — audit subject | Modified |

## How it works

The audit ran the full `reviewing-skills` workflow (Steps 2–6) against the claude-md-optimizer SKILL.md. The 8/10 score was primarily driven by the missing scope boundary in Dimension 1 (description doesn't exclude SKILL.md and command files, risking false activations) and the lack of progressive disclosure in Dimension 3 (all content inline when a reference file would reduce body weight and improve context loading).

The proposed fixes were: extract the example audit output and Notes section to a new `references/` folder, add a scope boundary clause to the frontmatter description, and add a one-line freedom level statement.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |

<!-- generated:end -->

## References

- Plan: [audit-claude-md-optimizer-skill.md](plans/audit-claude-md-optimizer-skill.md)
- Related: [optimize-claude-md-optimizer-skill.md](optimize-claude-md-optimizer-skill.md)
