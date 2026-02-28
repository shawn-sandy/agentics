# Plan: Audit claude-md-optimizer SKILL.md

## Context

The user has requested an audit of
`plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md`
using the `reviewing-skills` skill from the `skill-reviewer` plugin. The
SKILL.md has already been read (295 lines, fully inline). The goal is to
score it against the 5-dimension rubric defined in
`plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md`
and surface actionable improvements.

---

## Critical Files

| File | Role |
|------|------|
| `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md` | Target file to audit (295 lines) |
| `plugins/skill-reviewer/skills/reviewing-skills/SKILL.md` | Audit workflow definition |
| `plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md` | Scoring rubric (Steps 3–6) |
| `plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` | Anthropic best practices reference |

---

## Step 2 — Measurements

| Metric | Value |
|--------|-------|
| Total lines | 295 |
| Body lines | ~290 (frontmatter is 4 lines) |
| Word count (est.) | ~2,000 |
| Frontmatter fields | `name`, `description` |
| Reference files | None |
| Folder structure | No `references/`, `scripts/`, or `assets/` subdirs |
| Design pattern | Sequential / Pipeline (6-step ordered workflow) |

---

## Step 3 — Preliminary Scores (to be confirmed during execution)

| Dimension | Expected Score | Rationale |
|-----------|---------------|-----------|
| 1. Frontmatter Validity | 1 | Name and trigger phrase valid; description lacks explicit scope boundary (no "not for SKILL.md" exclusion) |
| 2. Body Quality | 2 | Within 500-line / 5K-word limits; imperative voice; concrete example output present |
| 3. Structure & Progressive Disclosure | 1 | TOC present and headings clear, but entire 295-line body is inline — no `references/` delegation despite depth of content |
| 4. Anti-pattern Detection | 2 | No Windows paths, no `$ARGUMENTS`, no reserved words, no hardcoded paths, no time-sensitive content |
| 5. Discoverability | 2 | "Use when…" trigger with 5 scenarios; 4+ searchable keywords; CLAUDE.md scope clearly stated |
| **Total** | **8 / 10** | **Functional** |

---

## Top Issues to Address

1. **Progressive Disclosure (Dimension 3 — score 1):** All 295 lines are embedded inline. The example audit output (~45 lines) and the Notes section should be extracted into a `references/` folder. Compare: `reviewing-skills` itself delegates all step detail to `references/audit-steps.md`.

2. **Frontmatter Description (Dimension 1 — score 1):** The description doesn't state what the skill does NOT cover (e.g., SKILL.md files, commands, markdown files other than CLAUDE.md). Adding a scope boundary reduces false activations.

3. **Missing freedom level:** The body never states whether Claude must follow the six steps exactly or may adapt. Adding a one-line freedom statement improves predictability.

---

## Execution Plan

1. Run the full `reviewing-skills` audit workflow (Steps 3–6) against the target file.
2. Produce the scored report in Step 4 format.
3. Ask the user if they want an optimized version generated (Step 5).
4. Offer to extract the example output and notes into a new `references/` folder.
5. Ask for explicit confirmation before writing any file to disk (Step 6).

---

## Verification

- Confirm the score table totals match per-dimension reasoning.
- Confirm all Quick Reference Checklist items are addressed in the report.
- Do not write to disk without explicit user confirmation.
