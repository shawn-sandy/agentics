---
status: completed
created: 2026-05-01
type: artifact
---

# Refactor ExitPlanMode: Conditional Detection + Silent Exit

## Context

Several plugins call `ExitPlanMode` unconditionally or ask the user to exit plan mode manually. The user wants:
1. Skills that use ExitPlanMode should detect whether plan mode is active first (skip if not)
2. Skills should never ask the user whether to exit plan mode — just exit silently

## Objective

Standardize all ExitPlanMode usage across plugins to a "detect-then-exit-silently" pattern. No behavioral regressions (ExitPlanMode is already a no-op outside plan mode), but instructions become explicit about conditional detection.

## Scope

| Plugin | File | Current Pattern | Change |
|--------|------|-----------------|--------|
| git-agent | `skills/branch-agent/SKILL.md` | Unconditional exit | Add detection check |
| git-agent | `skills/commit-agent/SKILL.md` | Unconditional exit | Add detection check |
| git-agent | `skills/pr-agent/SKILL.md` | Unconditional exit | Add detection check |
| git-agent | `skills/ship/SKILL.md` | Unconditional exit | Add detection check |
| agentic-plugin-dev | `skills/plugin-creator/SKILL.md` | Blocks + tells user to exit | Self-exit silently |
| code-simplifier | `skills/code-simplifier/SKILL.md` | N/A | No change needed |
| plan-interview | `hooks.json` | Post-exit suggestion | No change needed |

## Steps

### 1. Replace Step 0 in all four git-agent skills

Replace the current "Always call ExitPlanMode" wording with conditional detection in:
- `kit/plugins/git-agent/skills/branch-agent/SKILL.md`
- `kit/plugins/git-agent/skills/commit-agent/SKILL.md`
- `kit/plugins/git-agent/skills/pr-agent/SKILL.md`
- `kit/plugins/git-agent/skills/ship/SKILL.md`

New Step 0 template (adapting the final rationale sentence per skill):

```markdown
## Step 0: Exit Plan Mode (if active)

If plan mode is active (a system reminder indicates "Plan mode is active"),
call `ExitPlanMode` silently before any other action. If plan mode is not
active, skip directly to Step 1. Do not prompt the user — exit silently.
[Rationale sentence about why mutations need plan mode off.]
```

### 2. Refactor plugin-creator to self-exit plan mode

File: `kit/plugins/agentic-plugin-dev/skills/plugin-creator/SKILL.md`

- **Add `ExitPlanMode` to `allowed-tools`** (alphabetical):
  `allowed-tools: AskUserQuestion, ExitPlanMode, Glob, Read, Write`
- **Replace the "Plan Mode Guard" section** (lines 7-13) with:
  ```markdown
  ## Step 0: Exit Plan Mode (if active)

  If plan mode is active (a system reminder indicates "Plan mode is active"),
  call `ExitPlanMode` silently before proceeding. If plan mode is not active,
  skip directly to Step 1. Do not prompt the user — exit silently. Plugin
  scaffolding writes files and directories, which requires exiting plan mode.
  ```
- **Renumber steps**: Current Step 0 (Disambiguation) becomes Step 1, current Step 1-5 become Step 2-6
- **Update the Table of Contents** to reflect new numbering and add Step 0

### 3. Update git-agent CHANGELOG

Prepend to `kit/plugins/git-agent/CHANGELOG.md`:

```markdown
## v3.6.1

- All four git-mutating skills (`branch-agent`, `commit-agent`, `pr-agent`,
  `ship`) now detect whether plan mode is active before calling
  `ExitPlanMode`, skipping the call when not in plan mode
- No behavioral change (ExitPlanMode was already a no-op outside plan mode)
  but instructions now explicitly model conditional detection and silent exit
```

### 4. Update agentic-plugin-dev CHANGELOG

Prepend to `kit/plugins/agentic-plugin-dev/CHANGELOG.md`:

```markdown
## [1.2.0] - 2026-05-01

### Changed

- `plugin-creator` now self-exits plan mode instead of blocking execution
  and telling the user to exit manually
- Added `ExitPlanMode` to `plugin-creator` allowed-tools
- Replaced "Plan Mode Guard" with "Step 0: Exit Plan Mode (if active)"
- Renumbered subsequent steps (Disambiguation is now Step 1, etc.)
```

### 5. Bump versions in marketplace.json

File: `.claude-plugin/marketplace.json`

- `git-agent`: `3.6.0` -> `3.6.1` (PATCH — no behavioral change)
- `agentic-plugin-dev`: `1.1.0` -> `1.2.0` (MINOR — new capability)

### 6. Update memory file

Update `feedback_skill_plan_mode.md` to reflect the new conditional pattern.

## No Changes Needed

- **code-simplifier** — Its Step 5 asks about applying changes, not about exiting plan mode. The skill owns its own plan mode lifecycle (enters in Step 1, exits in Step 6). Acceptable as-is.
- **plan-interview hooks.json** — Fires a suggestion AFTER ExitPlanMode has already been called. Not asking whether to exit. Actually improves with conditional exit (no longer fires on no-op calls).

## Verification

1. `grep -r "Always call.*ExitPlanMode" kit/plugins/` — should return 0 results
2. `grep -r "Please exit plan mode" kit/plugins/` — should return 0 results
3. `grep -r "ExitPlanMode" kit/plugins/` — should only appear in `allowed-tools` lines and the conditional Step 0 sections (plus code-simplifier Step 6)
4. Load `git-agent` and `agentic-plugin-dev` with `--plugin-dir` and invoke each skill to confirm they work correctly both in and out of plan mode
