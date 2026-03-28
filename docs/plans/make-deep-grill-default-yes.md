# Plan: Make Deep Grill Default Yes in Plan Interview Skill

## Context

Step 4 (Deep grill) in the plan-interview skill currently presents a neutral
opt-in prompt with no preferred default. The user wants the deep grill to run
by default — keeping the `AskUserQuestion` so users can still skip it, but
making "Yes" the first/default option.

## Changes

### File: [plugins/plan-interview/skills/plan-interview/SKILL.md](../../plugins/plan-interview/skills/plan-interview/SKILL.md)

1. **Step 0 todo label** (line 32): No change needed — label already accurate.

2. **Step 4 — Deep grill** (lines 334–343): Reorder the `AskUserQuestion`
   options so "Yes" comes first. Update framing to signal it as the recommended
   path.

   **Before:**
   ```
   - **Options:** "Yes, run deep grill (you can stop at any time)" / "No, skip to summary"
   ```

   **After:**
   ```
   - **Options (first = recommended):** "Yes, run deep grill (you can stop at any time)" / "No, skip to summary"
   ```

   Also update the question text to reflect the default:

   **Before:**
   > "The structured interview is complete. Would you like to run a deep grill
   > session? This walks each design-tree branch in depth and may take
   > additional time."

   **After:**
   > "The structured interview is complete. Run a deep grill session next? This
   > walks each design-tree branch in depth — recommended for most plans. (You
   > can stop at any time.)"

## Verification

1. Run `/plan-interview` on any plan file.
2. After Step 3 completes, confirm the deep grill prompt appears with "Yes" as
   the first option.
3. Select "Yes" — confirm deep grill runs.
4. Select "No" — confirm it skips to Step 5.

## Next Steps

- Consider making deep grill fully mandatory (no prompt) for complex/multi-area
  plans while keeping the opt-out for short plans.
