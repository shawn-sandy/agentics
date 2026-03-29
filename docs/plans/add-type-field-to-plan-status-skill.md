---
status: completed
created: 2026-03-29
---

# Plan: Add `type` frontmatter field to plan-status skill

## Context

The plan-status skill manages plan lifecycle via YAML frontmatter (`status`, `created`, `modified`). Currently "artifact" is a terminal status value promoted from `completed` after 30 days. The user wants a separate `type` field set when a plan is completed, classifying it as `standard` (default) or `artifact` (important project documentation). This cleanly separates lifecycle position (status) from documentation classification (type).

## Changes

### 1. Remove `artifact` as a status value

Statuses become three: `todo`, `in-progress`, `completed`. Artifact exists only as `type: artifact`.

**Files:** SKILL.md (line 116), command (line 102)

- Remove `artifact` from the manual status options list
- Change: `todo`, `in-progress`, `completed`, `artifact` -> `todo`, `in-progress`, `completed`

### 2. Add legacy `artifact` status migration to Step 3

When existing frontmatter has `status: artifact`, normalize it to `status: completed` + `type: artifact` and inform the user.

**Files:** SKILL.md (after line 94), command (after line 80)

- Add bullet: "If existing status is `artifact` (legacy), inform user it will be normalized to `status: completed` with `type: artifact`. Treat as completed for the rest of the flow."

### 3. Rewrite Step 5 to set `type` instead of changing status

Currently Step 5 changes status to `artifact`. Now it sets the `type` field.

**Files:** SKILL.md (lines 131-144), command (lines 117-130)

- Step runs whenever status resolves to `completed` (automatic or manual)
- If plan already has `type: artifact`, inform user and skip
- Always ask via `AskUserQuestion`: "Classify this completed plan as `standard` or `artifact` (valuable project documentation)?" Default: `standard`
- If >= 30 days since modified, add context to the prompt: "This plan was completed 30+ days ago" (nudge toward artifact)
- Outcome is always a `type` value, never a status change

### 4. Add `Type` row to Step 6 summary table

Show the type field in the findings table when status is `completed`.

**Files:** SKILL.md (lines 146-158), command (lines 132-153)

- Add conditional `Type` row after `Status` row (only for completed plans)
- Update confirmation prompt: "Should I update with status `completed` and type `standard`?"

### 5. Update Step 7 to write `type` field

Add `type` to the set of managed frontmatter fields for completed plans.

**Files:** SKILL.md (lines 169-191), command (lines 154-178)

- Add completed example with `type: standard`
- Change field list: "update or add `status`, `type` (when completed), `created`, and `modified`"
- Add rule: "Include `type` only when status is `completed`. Valid values: `standard` (default), `artifact`. Omit for `todo` and `in-progress`."

### 6. Update README status table and frontmatter example

**File:** [README.md](plugins/plan-interview/README.md) (lines 63-84)

- Remove `artifact` row from status table
- Add new "Type values" table: `standard` and `artifact`
- Update frontmatter example to include `type: standard`

### 7. Add CHANGELOG entry

**File:** [CHANGELOG.md](plugins/plan-interview/CHANGELOG.md) (top)

- Version: `1.11.0`
- Added: `type` frontmatter field for completed plans
- Changed: `artifact` removed as status, now a type classification; statuses simplified to three

## Files to modify

| File                                                   | Changes                      |
| ------------------------------------------------------ | ---------------------------- |
| `plugins/plan-interview/skills/plan-status/SKILL.md`   | Steps 3-7 updates            |
| `plugins/plan-interview/commands/plan-status.md`        | Mirror all SKILL.md changes  |
| `plugins/plan-interview/README.md`                      | Status table, type table, example |
| `plugins/plan-interview/CHANGELOG.md`                   | v1.11.0 entry                |

## Verification

1. Load plugin: `claude --plugin-dir ~/devbox/agentics/plugins/plan-interview`
2. Run on a completed plan: `/plan-interview:plan-status docs/plans/plan-status-skill-audit-fixes.md`
   - Should detect legacy `status: completed`, offer re-analysis or keep
   - If kept, should set `type: standard` (completed < 30 days ago)
3. Run on an old plan (if any exist with 30+ day gap): should prompt for artifact classification
4. Verify frontmatter output includes `type` field for completed plans
5. Verify `todo` and `in-progress` plans do NOT get a `type` field

## Next Steps

- Batch-update existing plan files that have `status: artifact` to the new schema
- Consider adding a `/plan-interview:plan-search` command that filters by type
- Consider adding `type` to the plan-hygiene pre-commit checks
