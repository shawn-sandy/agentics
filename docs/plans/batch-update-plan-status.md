---
status: in-progress
created: 2026-03-30
---

# Plan: Batch Update Plan Status (84 files)

## Context

The `docs/plans/` directory has 84 plan files accumulated over time. Most lack
YAML frontmatter with lifecycle metadata (`status`, `created`, `modified`,
`type`). This makes it hard to distinguish active work from completed or
abandoned plans.

The `/plan-interview:update-plan-status` command will analyze all 84 files,
score each against codebase evidence, and add/update YAML frontmatter in bulk.

## Execution Steps

1. **Create progress todos** for each step (Steps 1-7)

2. **Discover files** — Glob `docs/plans/*.md` (already confirmed: 84 files)

3. **Triage into groups:**
   - Group A (no frontmatter): ~81 files — analyze + add frontmatter
   - Group B (frontmatter, no status): ~0 files
   - Group C (status: todo/in-progress): ~1 file — skip unless `--force`
   - Group D (status: completed): ~2 files — skip unless `--force`
   - Group E (status: artifact): ~0 files
   - Present triage summary, ask user to confirm

4. **Batch git dates** — single shell loop to get created/modified dates for
   all ~81 files in the processing set

5. **Analyze codebase evidence (batch)** — for each file:
   - Read content, extract backtick tokens (skip fenced code blocks)
   - Apply strict token filter (file paths, PascalCase/camelCase identifiers)
   - Glob/Grep each qualifying token
   - Score: 0% = todo, 1-79% = in-progress, 80%+ = completed
   - Flag zero-signal files as `no signals` (default to `todo`)

6. **Type classification** — for files scoring `completed`:
   - >= 30 days since last modification -> `type: artifact`
   - Otherwise -> `type: standard`

7. **Present results table** — show all files with status, type, token counts,
   evidence %, dates, and flags. Show aggregated stats.

8. **Get user approval** — options: Write all / Override some / Export only /
   Cancel

9. **Write frontmatter** — hybrid strategy:
   - Files without frontmatter: Bash `insert_frontmatter` loop
   - Files with existing frontmatter: Edit tool to update fields
   - Progress message every 10 files

## Key Files

- `docs/plans/*.md` — 84 plan files to process
- `.claude/settings.json` — confirms `plansDirectory: "docs/plans"`

## Known Considerations

- 4 files have randomly-generated names (nested-jumping-ritchie, etc.) —
  these will still get frontmatter but should be renamed separately via
  `/plan-interview:plan-hygiene`
- Documentation-focused plans may score inaccurately — flagged as `docs plan`
  for manual review
- No `--force` flag provided, so 3 files with existing status will be skipped

## Verification

- After writing, spot-check 5-10 files to confirm frontmatter was applied
  correctly
- Run `grep -l '^status:' docs/plans/*.md | wc -l` to confirm count matches
- Verify no duplicate `---` delimiters in files that already had frontmatter

## Next Steps

- Run `/plan-interview:plan-hygiene` to rename the 4 randomly-named files
- Consider periodic re-runs with `--force` as plans progress
