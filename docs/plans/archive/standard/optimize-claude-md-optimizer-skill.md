---
status: in-progress
created: 2026-02-24
---

# Plan: Optimize claude-md-optimizer SKILL.md

## Context

The `claude-md-optimizer` skill's `SKILL.md` has three compliance violations against skill best practices (as defined in `superpowers:writing-skills`):
1. Forbidden `version` field in frontmatter
2. Description doesn't start with "Use when..." and mixes workflow explanation with trigger conditions
3. Minor structural gaps (no overview section, verbose Tips/Scope section)

The goal is to bring the skill into conformance without changing any of the 6-step audit logic.

**Target file:** `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md`

---

## Implementation Steps

### 1. Fix YAML frontmatter

Remove the `version: 1.0.0` line (only `name` and `description` are allowed):

```yaml
---
name: claude-md-optimizer
description: Use when the user asks to audit, optimize, review, clean up, or improve a CLAUDE.md file, or reports Claude ignoring instructions, behaving inconsistently, or experiencing context overflow.
---
```

- Description starts with "Use when..."
- Lists only trigger conditions (actions + symptoms)
- No workflow summary
- 190 characters (well under 500)

### 2. Add a brief Overview section

Insert 3-line intro immediately after the frontmatter title, before Step 1:

```markdown
Audits a CLAUDE.md against six quality dimensions and scores it out of 12. Optionally generates an optimized version. Follow all six steps in order — do not skip or combine them.
```

### 3. Consolidate Tips + Scope Boundaries

Merge the existing `## Tips` (9 lines) and `## Scope boundaries` (7 lines) sections into a single `## Notes` section (4–5 lines), eliminating off-topic content (e.g., `/init` bootstrap tip unrelated to the audit workflow).

---

## Files to Modify

- `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md` — all changes above

---

## Verification

1. Confirm frontmatter has exactly `name` and `description` — no other keys
2. Confirm description starts with "Use when..." and contains no workflow summary
3. Confirm description is under 500 characters
4. Confirm the 6-step audit logic is unchanged
5. Load the plugin locally and verify skill still activates as expected:
   ```bash
   claude --plugin-dir ~/devbox/agentics/plugins/claude-md-optimizer
   ```

---

## Unresolved Questions

None.
