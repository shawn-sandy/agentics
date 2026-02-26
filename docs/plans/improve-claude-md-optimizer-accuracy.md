# Plan: Improve claude-md-optimizer SKILL.md Against Official Memory Docs

## Context

The `claude-md-optimizer` skill audits CLAUDE.md files. The official Claude Code memory
documentation at `https://code.claude.com/docs/en/memory` reveals several gaps and one
factual error in the current skill. This plan makes targeted, surgical edits — the existing
6-step structure and scoring rubric are solid and stay unchanged.

A secondary fix is needed in the repo itself: a local override file was created with the
wrong name (`.claude.md.local` instead of the official `CLAUDE.local.md`). Both the file
and its `.gitignore` entry will be corrected in the same commit.

## Files to Modify

| File | Action |
|------|--------|
| `plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md` | Edit — 6 targeted changes |
| `plugins/claude-md-optimizer/.claude-plugin/plugin.json` | Minor version bump (1.0.0 → 1.1.0) |
| `plugins/claude-md-optimizer/README.md` | Edit — update step count / description to match new metric |
| `.claude-plugin/marketplace.json` | Sync version to 1.1.0 |
| `plugins/claude-md-optimizer/CHANGELOG.md` | Create — document minor changes |
| `.claude.md.local` | Rename to `CLAUDE.local.md` |
| `.gitignore` | Edit — fix entry from `.claude.md.local` to `CLAUDE.local.md` |

## Changes (in priority order)

### 1. Fix `CLAUDE.md.local` filename — CRITICAL (factual error, 2 occurrences in SKILL.md)

The official local override file is `CLAUDE.local.md`, not `CLAUDE.md.local`.

- **Dimension 6, Structure criterion:** `CLAUDE.md.local` → `CLAUDE.local.md` (auto-added to `.gitignore` by Claude Code)
- **Tips section:** same fix + note that Claude Code auto-adds it to `.gitignore`

### 2. Rename real local file and fix .gitignore

- Rename `.claude.md.local` → `CLAUDE.local.md` in the repo root
- Update `.gitignore`: replace `.claude.md.local` entry with `CLAUDE.local.md`
- Must land in a single commit to avoid a window where the file is unignored

### 3. Step 1 — Add `.claude/CLAUDE.md` as alternate project location — HIGH

Current priority list has 3 entries. Update to 4:

1. Explicit path in `$ARGUMENTS`
2. `$PWD/CLAUDE.md` (primary project location)
3. `$PWD/.claude/CLAUDE.md` (alternate project location, checked if primary absent)
4. `~/.claude/CLAUDE.md` (global user-level)

Update the "stop and ask" condition to match new numbering.

### 4. Step 2 — Add `@import` detection as 5th metric — HIGH

After the existing 4 metrics, add:

> **Import scan** — detect any `@path/to/file` references in the file. List each one found.
> Note that imported content counts toward effective instruction load but is not visible in the raw line count.

Flag existence only — do not read or count imported file contents.

### 5. Dimension 4 — Expand Progressive Disclosure to include `.claude/rules/` — HIGH

Replace the single-sentence description with two named delegation targets:

- **`.claude/rules/*.md`** — loaded automatically by Claude Code; can be path-scoped with `paths:` frontmatter
- **External docs** (e.g., `docs/architecture.md`, `CONTRIBUTING.md`) — referenced via `@import` or plain link

Scoring rubric (2/1/0) is unchanged — goal is delegation, not which mechanism is used.

### 6. Tips — Add full memory hierarchy bullet — MEDIUM

Add one bullet showing the load order:
> project rules → project memory → user memory → project local (`CLAUDE.local.md`). Combined instruction count across all loaded files is what matters.

### 7. Tips — Add 3 new educational bullets — MEDIUM

- `/init` command to bootstrap a starter CLAUDE.md from codebase context
- `@path/to/file` import syntax for keeping CLAUDE.md short while retaining references
- `.claude/rules/*.md` for modular rules, with `paths:` frontmatter for path-scoping

## Version Bump

New audit criteria (import scan, `.claude/rules/` in Dimension 4) = MINOR (1.0.0 → 1.1.0).
Both `plugin.json` and `marketplace.json` must match exactly.

## Commit Strategy

Two commits:

1. `fix(repo): rename .claude.md.local → CLAUDE.local.md and fix .gitignore`
2. `feat(plugins/claude-md-optimizer): improve skill against official memory docs, bump to 1.1.0`

## Verification

```bash
# Confirm version sync
grep -r '"version"' plugins/claude-md-optimizer/.claude-plugin/ .claude-plugin/marketplace.json

# Confirm old filename is gone (should return 0 matches in SKILL.md)
grep -n "CLAUDE.md.local" plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md

# Confirm new alternate location added to Step 1
grep -n ".claude/CLAUDE.md" plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md

# Confirm local file rename
ls -la CLAUDE.local.md && git check-ignore -v CLAUDE.local.md
```

## Interview Summary

### Key Decisions Confirmed
- Fix all 3 artifacts (rename real file, fix `.gitignore`, fix SKILL.md) — full consistency
- Import scan: flag existence only — no reading or counting of imported files
- MINOR version bump (1.1.0) — new audit criteria = new capability
- Dimension 4 rubric unchanged — delegation goal, not mechanism

### Open Risks & Concerns
- Rename and `.gitignore` fix must land in same commit (atomicity)
- README needs minor update to reflect new Step 2 metric

### Recommended Next Steps
Implement changes in order: file rename first, then SKILL.md edits, then version bumps.
