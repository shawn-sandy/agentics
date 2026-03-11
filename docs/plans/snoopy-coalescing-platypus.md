# Plan: Update plan-interview Step 6 to apply findings inline

## Context

The plan-interview plugin currently appends an `## Interview Summary` section to the end of the plan file after the interview. The user wants the interview findings to be **applied directly into the plan's content** — updating existing sections, adding missing ones, removing over-engineered elements — rather than tacking on a summary. Changes should only be applied after user approval.

## Changes

### 1. Replace Step 6 in both files

**Files:**
- `plugins/plan-interview/commands/plan-interview.md` (lines 258–269)
- `plugins/plan-interview/skills/plan-interview/SKILL.md` (lines 311–322)

**New Step 6 — "Apply interview findings to the plan":**

- Derive a numbered list of specific edits from the Step 5 summary. Each edit is one of: **update** an existing section, **add** missing content, **remove/simplify** over-engineered elements, or **resolve** open questions answered during the interview.
- Present the numbered edits to the user with a concrete description of what changes and where (referencing section headings).
- Ask the user to approve via `AskUserQuestion`: approve **all**, list specific numbers (e.g., "1, 3, 4"), or **none**.
- Apply only approved edits inline using the `Edit` tool — modify the plan's existing structure in place. Do **not** append a summary section.
- Confirm: *"Applied [N] edits to `[plan-file-path]`."*

### 2. Update Step 0 todo label in both files

Change `Step 6: Save findings to the plan file` → `Step 6: Apply approved changes to the plan`

- `commands/plan-interview.md` line 34
- `skills/plan-interview/SKILL.md` line 26 (same text)

### 3. Update CHANGELOG.md

- `plugins/plan-interview/CHANGELOG.md` — update the 1.5.0 entry to reflect the new behavior (apply inline edits with approval, not auto-append summary)

### 4. No version bump needed

The previous commit already bumped to 1.5.0. The changelog entry just needs to accurately describe the final behavior.

## Verification

- Read both modified files and confirm Step 6 instructions describe the inline-edit-with-approval flow
- Confirm Step 0 todo labels match in both files
- Confirm CHANGELOG 1.5.0 entry describes the correct behavior
