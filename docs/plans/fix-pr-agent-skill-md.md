# Plan: Fix pr-agent SKILL.md

## Context

Skill review identified 1 major and 3 minor issues in `plugins/git-agent/skills/pr-agent/SKILL.md`. User approved applying all fixes.

## File to Modify

`plugins/git-agent/skills/pr-agent/SKILL.md`

## Changes

1. **Frontmatter description** — Remove `"Does not enter plan mode."` (implementation note, not a trigger phrase). Keep commit-agent cross-reference.

2. **Opening line** — Add out-of-scope note after the summary sentence:
   > `"This skill does not commit changes or run tests."`

3. **Step 2 heading** — Rename from `"Detect Base Branch"` to `"Detect Base Branch and Gather PR Content"`.

4. **Step 4** — Replace fragile `git status` upstream check with:
   ```bash
   git rev-parse --abbrev-ref --symbolic-full-name @{u}
   ```
   Non-zero exit = no upstream (push with `-u`). Zero exit = upstream exists (push normally if ahead).

## Verification

- Read updated file and confirm all 4 changes are applied correctly.
- No version bump needed (patch-level clarification, not behavioral change).
