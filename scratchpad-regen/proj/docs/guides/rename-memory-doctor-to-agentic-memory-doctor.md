# Rename `memory-doctor` to `agentic-memory-doctor`

> MAJOR version bump renaming the `memory-doctor` skill in the `memory-tools` plugin to `agentic-memory-doctor`, updating all references across the repo with no functional logic changes.

<!-- generated:start -->

**Status:** Shipped 2026-05-10  **Plan:** [rename-memory-doctor-to-agentic-memory-doctor.md](plans/rename-memory-doctor-to-agentic-memory-doctor.md)
**Type:** artifact

## What shipped

- Renamed skill directory `kit/plugins/memory-tools/skills/memory-doctor/` → `kit/plugins/memory-tools/skills/agentic-memory-doctor/` (MAJOR bump: renaming a skill changes its activation name and breaks existing `@import` references).
- Updated SKILL.md frontmatter: `name: memory-doctor` → `name: agentic-memory-doctor`. New invocation: `memory-tools:agentic-memory-doctor`.
- Updated cross-reference in sibling skill `path-rules-advisor/SKILL.md`: "use memory-doctor for that" → "use agentic-memory-doctor for that".
- Updated skill table row in `kit/plugins/memory-tools/README.md`.
- Updated skill listing row in root `README.md`.
- Updated skill listing line in `kit/plugins/README.md`.
- Updated reference path in `kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md`.
- Added `## [3.0.0] — 2026-05-10` entry to `kit/plugins/memory-tools/CHANGELOG.md` with BREAKING CHANGE notice and `@import` path migration instructions.
- Bumped `memory-tools` version from `2.0.1` → `3.0.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md` | Sibling skill cross-reference | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin documentation | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` | Best-practices reference | Modified |
| `kit/plugins/README.md` | Plugin listing | Modified |
| `README.md` | Root documentation | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |

## How it works

This plan follows the same rename mechanics as the prior v2.0.0 release (`md-optimizer` → `memory-doctor`). The skill directory rename was performed with `git mv` to preserve history as a tracked rename rather than a delete-and-add. The SKILL.md `name:` field was updated to match the new directory — Claude Code resolves skills by matching the plugin folder name against the `name:` frontmatter, so both must change together.

The scope was intentionally minimal: skill folder, frontmatter, and every downstream reference that names the skill by its old identity. No functional logic in the SKILL.md body was altered. The seven touched files outside the renamed directory are all surface-level references — README tables, a sibling skill's cross-reference description, and the `best-practices.md` reference in `skill-reviewer`.

The CHANGELOG `## [3.0.0]` entry includes an `@import` migration note because any user who added `@<plugin-dir>/skills/memory-doctor/SKILL.md` to their CLAUDE.md will get a silent 404 after the directory rename. Historical CHANGELOG entries (pre-3.0.0) were left unchanged — they correctly record what was true at the time they were written.

The version jump from `2.0.1` to `3.0.0` reflects the project's MAJOR bump rule for skill renames: renaming a skill is always MAJOR because it changes the activation name and breaks `@import` references in users' CLAUDE.md files.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `260cf32` | 2026-05-10 | fix(docs/plans): narrow verification grep to exclude CHANGELOG historical entries |
| `029ed9e` | 2026-05-10 | fix(docs/plans): rename plan file to descriptive name and add frontmatter |
| `9bac78a` | 2026-05-10 | feat(kit/plugins/memory-tools)!: rename memory-doctor skill to agentic-memory-doctor |

<!-- generated:end -->

## References

- Plan: [rename-memory-doctor-to-agentic-memory-doctor.md](plans/rename-memory-doctor-to-agentic-memory-doctor.md)
