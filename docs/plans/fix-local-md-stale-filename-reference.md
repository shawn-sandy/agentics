# Fix: Stale `.claude.md.local` Reference in CLAUDE.md

## Context

Audit of `CLAUDE.md` (11/12, Optimized). Single deduction in Structure dimension: line 43 references `.claude.md.local` — the old filename before the project renamed it to `CLAUDE.local.md` (commits `c5ad022`, `fb4240b`). All other dimensions scored 2/2.

## Change

**File:** `CLAUDE.md` — line 43

```diff
- > Machine-specific paths (e.g. absolute local paths) belong in `.claude.md.local`, not here.
+ > Machine-specific paths (e.g. absolute local paths) belong in `CLAUDE.local.md`, not here.
```

## Verification

```bash
grep -n 'claude.md.local\|CLAUDE.local' CLAUDE.md
# Expected: only CLAUDE.local.md on line 43
```

## Commit

```
fix(claude-md): update stale .claude.md.local reference to CLAUDE.local.md
```
