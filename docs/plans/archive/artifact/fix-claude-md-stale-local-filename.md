---
status: completed
type: artifact
created: 2026-02-24
---

# Fix: Stale `.claude.md.local` Reference in CLAUDE.md

## Context

The project recently renamed its machine-specific override file from `.claude.md.local` to `CLAUDE.local.md` (commits `c5ad022`, `fb4240b`). The inline note on line 43 of `CLAUDE.md` was not updated and still references the old name. This creates a misleading instruction that contradicts actual project structure.

Audit score: **11/12 (Optimized)** — single deduction in Structure dimension.

## Changes

### 1. Fix stale filename reference

**File:** `CLAUDE.md` line 43

```diff
- > Machine-specific paths (e.g. absolute local paths) belong in `.claude.md.local`, not here.
+ > Machine-specific paths (e.g. absolute local paths) belong in `CLAUDE.local.md`, not here.
```

### 2. Optional improvements (lower priority)

- Consider adding a `## Development Workflow` stub with validation commands
- Consider whether to upgrade the `.claude/rules/` mentions to `@import` syntax

## Verification

1. Confirm change: `grep -n 'claude.md.local\|CLAUDE.local' CLAUDE.md`
2. Expected result: only `CLAUDE.local.md` appears (no `.claude.md.local`)
3. Confirm `CLAUDE.local.md` exists: `ls -la CLAUDE.local.md`

## Commit

```
fix(claude-md): update stale .claude.md.local reference to CLAUDE.local.md
```
