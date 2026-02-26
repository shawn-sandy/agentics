# Plan: Fix Plans Directory Resolution in review-rename-plans Command

## Context

The `review-rename-plans` command (v1.3.0) currently resolves the plans directory with hardcoded paths (`docs/plans/`, `.claude/plans/`) checked **before** the project's `.claude/settings.json` configuration. This is backwards — if a project has configured a `plansDirectory` in settings, that should be the primary source of truth. The SKILL.md in the same plugin already does this correctly (settings first, then fallback), but the command file doesn't match.

The user wants the command to:
1. Read the repo's configured `plansDirectory` from settings **first**
2. Fall back to global settings or ask the user if not found
3. Check default locations as a last resort
4. Ask the user interactively if nothing works

## Change

**Single file to edit:** `plugins/plan-interview/commands/review-rename-plans.md`

Replace Step 1's resolution priority order (lines 34–40) from:

```
1. Explicit $ARGUMENTS
2. Project docs/plans/
3. Project .claude/plans/
4. Project settings .claude/settings.json → plansDirectory
5. Global default ~/.claude/plans/
```

To this new order (matching the SKILL.md pattern, plus an interactive fallback):

```
1. Explicit $ARGUMENTS — user-provided path
2. Project settings — read .claude/settings.json in $PWD, use "plansDirectory" if present
3. Global settings — read ~/.claude/settings.json, use "plansDirectory" if present
4. Default locations — check docs/plans/, .claude/plans/, ~/.claude/plans/ (first that exists)
5. Ask the user — if none of the above resolve, use AskUserQuestion to prompt for the path
```

Also update the "stop" behavior: instead of silently stopping when no directory is found, the command now asks the user before giving up.

## Files to modify

- `plugins/plan-interview/commands/review-rename-plans.md` — Step 1 rewrite (lines 32–46)

## Verification

- Read the updated command and confirm the resolution order matches the SKILL.md pattern (settings → global settings → defaults → ask user)
- Confirm version files are unchanged (this is a PATCH-level docs fix within the same release, no bump needed since 1.3.0 hasn't been published yet)
