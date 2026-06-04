---
status: todo
created: 2026-03-31
---

# Update plan-status Skill Description for Broader Activation

## Context

The `plan-status` skill currently only triggers when the user explicitly asks to
"check, update, or determine the status of a plan file." This misses common
scenarios where plan status tracking would be useful — entering plan mode,
creating new plans, or updating existing plans. Broadening the description will
make the skill auto-activate in these contexts.

## Change

**File:** `plugins/plan-interview/skills/plan-status/SKILL.md` (line 3)

**Current description:**
```
description: Use when the user asks to check, update, or determine the status of a plan file — not for stress-testing, validating, or critiquing plan content.
```

**New description:**
```
description: Use when the user asks to check, update, or determine the status of a plan file, when entering or exiting plan mode, when creating or updating plans, or when working with plan files in any capacity — not for stress-testing, validating, or critiquing plan content.
```

### Why this wording

1. **"entering or exiting plan mode"** — catches the plan mode lifecycle
2. **"creating or updating plans"** — catches active plan authoring workflows
3. **"working with plan files in any capacity"** — catch-all for edge cases
4. Preserves the existing exclusion clause to avoid overlap with `plan-interview` and `deep-grill` skills

## Verification

1. Confirm the frontmatter YAML is still valid after the edit
2. Confirm the exclusion clause still differentiates from sibling skills (`plan-interview`, `deep-grill`)

## Next Steps

- Consider whether `deep-grill` and `plan-interview` descriptions need similar broadening (out of scope for this task)
