---
status: in-progress
created: 2026-03-26
---

# Make Deep Grill Step Optional in Plan Interview Skill

## Context

The deep grill step in `plan-interview` currently runs automatically after all structured interview rounds. It can be time-consuming and may not always be needed. Making it opt-in gives users control and keeps shorter interviews snappy.

## Changes

**File:** `plugins/plan-interview/skills/plan-interview/SKILL.md`

### 1. Step 0 — Update todo label (line 30)

Change:
```
- Step 4: Deep grill session
```
To:
```
- Step 4: Deep grill session (optional — ask user)
```

### 2. Step 4 — Add AskUserQuestion gate (lines 305-319)

Replace the opening line of Step 4 with an opt-in prompt before any deep-grill work begins:

```markdown
### Step 4 — Deep grill (optional)

Use `AskUserQuestion` to ask the user whether to run the deep grill:

- **Question:** "The structured interview is complete. Would you like to run a deep grill session? This walks each design-tree branch in depth and may take additional time."
- **Options:** "Yes, run deep grill" / "No, skip to summary"

If the user declines, mark Step 4 completed and proceed directly to Step 5.

If the user confirms, conduct the deep-grill session:

- Walk each branch of the design tree in the plan, one at a time.
- For each decision node, ask a focused question and provide your recommended
  answer before waiting for the user's response.
- If the question can be answered by exploring the codebase, use `Glob`, `Grep`,
  or `Read` first, then present your finding as the recommended answer.
- After each response, check whether sub-questions exist for that branch. If so,
  resolve them before moving to the next branch.
- Continue until every decision branch is fully resolved or the user signals
  they are done.
- Collect all decisions and insights; include them in the Step 6 summary under a
  new **Deep Grill Findings** section.
```

## Steps

1. Edit `SKILL.md` line 30: update the Step 4 todo label to include `(optional — ask user)`
2. Edit `SKILL.md` lines 305-319: replace the Step 4 body with the opt-in version above
3. Bump `plan-interview` version in `.claude-plugin/marketplace.json` (patch bump — behavior change behind opt-in)
4. Add a CHANGELOG entry in `plugins/plan-interview/CHANGELOG.md`

## Verification

- Load the plugin locally and run `/plan-interview:plan-interview` on any plan file
- After structured rounds complete, confirm AskUserQuestion appears with Yes/No options
- Confirm selecting "No" skips to Step 5 and marks Step 4 completed
- Confirm selecting "Yes" runs the full deep grill as before

## Next Steps (out of scope)

- Add a similar opt-in gate for the "Surface out-of-scope concerns" step (Step 5)
- Allow users to configure default behavior via plugin settings
