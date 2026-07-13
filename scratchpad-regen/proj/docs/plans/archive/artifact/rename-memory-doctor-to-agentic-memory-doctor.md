---
status: completed
created: 2026-05-10
type: artifact
---

# Plan: Rename `memory-doctor` to `agentic-memory-doctor`

## Context

The `memory-doctor` skill in `kit/plugins/memory-tools` needs to be renamed to `agentic-memory-doctor`. This follows the same pattern as the prior v2.0.0 rename (`md-optimizer` → `memory-doctor`). Per project versioning conventions, renaming a skill is a **MAJOR** version bump because it changes the skill's activation name and breaks any `@import` references.

Current version: `2.0.1` → New version: `3.0.0`

---

## Objective

Rename the skill `memory-doctor` to `agentic-memory-doctor` across all files in the repo — skill directory, frontmatter, README tables, cross-plugin references, changelog, and marketplace version entry.

---

## Steps

### 1. Rename the skill directory

```text
kit/plugins/memory-tools/skills/memory-doctor/
  → kit/plugins/memory-tools/skills/agentic-memory-doctor/
```

**Why:** The directory name must match the skill `name` field — Claude Code resolves skills by directory path.

### 2. Update `SKILL.md` frontmatter

File: `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md`

Change `name: memory-doctor` → `name: agentic-memory-doctor`

**Why:** This is the canonical identifier used for activation and `@import` paths.

### 3. Update cross-reference in sibling skill

File: `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` (line 3)

Change `use memory-doctor for that` → `use agentic-memory-doctor for that`

**Why:** This description references the old skill name; users see it in skill activation messages.

### 4. Update memory-tools README skill table

File: `kit/plugins/memory-tools/README.md`

Change `` `memory-doctor` `` → `` `agentic-memory-doctor` `` in the skills table row.

### 5. Update root repo README skill table

File: `README.md`

Change `| memory-doctor | Optimize, audit...` → `| agentic-memory-doctor | Optimize, audit...`

### 6. Update kit/plugins README

File: `kit/plugins/README.md`

Change `memory-doctor` → `agentic-memory-doctor` in the listing line.

### 7. Update skill-reviewer best-practices reference

File: `kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md`

Change `memory-doctor/` → `agentic-memory-doctor/` in the reference line.

### 8. Add changelog entry to memory-tools CHANGELOG

File: `kit/plugins/memory-tools/CHANGELOG.md`

Add a new `## [3.0.0] — 2026-05-10` section:
```markdown
### BREAKING CHANGE
- Skill renamed from `memory-doctor` to `agentic-memory-doctor`
- Update any `@import` paths from `memory-doctor/SKILL.md` to `agentic-memory-doctor/SKILL.md`
```

### 9. Bump version in marketplace.json

File: `.claude-plugin/marketplace.json`

Change `"version": "2.0.1"` → `"version": "3.0.0"` for the `memory-tools` entry.

---

## Critical Files

| File | Change |
|------|--------|
| `kit/plugins/memory-tools/skills/memory-doctor/` | Rename directory |
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | `name` frontmatter field |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Cross-reference text |
| `kit/plugins/memory-tools/README.md` | Skill table row |
| `README.md` | Skill listing row |
| `kit/plugins/README.md` | Skill listing line |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` | Reference path |
| `kit/plugins/memory-tools/CHANGELOG.md` | New v3.0.0 entry |
| `.claude-plugin/marketplace.json` | Version bump 2.0.1 → 3.0.0 |

---

## Verification

1. `grep -r "memory-doctor" kit/plugins/ README.md .claude-plugin/ --exclude="CHANGELOG.md"` returns no matches (CHANGELOG.md intentionally retains historical references)
2. `grep -r "agentic-memory-doctor" kit/plugins/memory-tools/` returns hits in `SKILL.md`, `README.md`, `CHANGELOG.md`, and the sibling skill
3. `cat .claude-plugin/marketplace.json | grep -A2 '"memory-tools"'` shows version `3.0.0`
4. Directory `kit/plugins/memory-tools/skills/agentic-memory-doctor/` exists; `memory-doctor/` does not

---

## Next Steps

- None required; this is a complete rename with no functional logic changes.
