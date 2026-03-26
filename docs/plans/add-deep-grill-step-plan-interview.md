# Plan: Add Optional Deep Grill Step to Plan Interview Skill

## Context

The plan-interview skill conducts structured multi-round interviews before implementation.
Users want an optional "deep grill" mode that goes beyond the structured rounds — relentlessly
walking every decision branch in the plan, resolving dependencies one-by-one, and providing
recommended answers (or exploring the codebase when the answer lives there). This step sits
before the final summary so its findings feed into it.

## Changes

### 1. `plugins/plan-interview/skills/plan-interview/SKILL.md`

Two edits:

**a) Step 0 — Add optional todo**

Add to the `TodoWrite` list:

```
- Step 4.5: Deep grill session (optional)
```

**b) Insert Step 4.5 between Step 4 and Step 5**

```markdown
### Step 4.5 — Deep grill (optional)

After surfacing out-of-scope concerns, ask the user:

> "Would you like a deep-grill session? I'll interview you relentlessly about
> every decision branch until we reach a shared understanding — providing my
> recommended answer for each question. Where answers can be found in the
> codebase, I'll explore it instead of guessing."

If the user **declines**, mark this todo complete and proceed to Step 5.

If the user **confirms**:

- Walk each branch of the design tree in the plan, one at a time.
- For each decision node, ask a focused question and provide your recommended
  answer before waiting for the user's response.
- If the question can be answered by exploring the codebase, use `Glob`,
  `Grep`, or `Read` first, then present your finding as the recommended answer.
- After each response, check whether sub-questions exist for that branch. If
  so, resolve them before moving to the next branch.
- Continue until every decision branch is fully resolved or the user signals
  they are done.
- Collect all decisions and insights; include them in the Step 5 summary under
  a new **Deep Grill Findings** section.
```

### 2. `plugins/plan-interview/CHANGELOG.md`

Add entry:

```markdown
## v1.6.0 — 2026-03-26

### Added

- Optional deep grill step (Step 4.5) in the plan-interview skill: relentlessly
  walks every decision branch, provides recommended answers, and explores the
  codebase when answers can be found there. Findings feed into the Step 5 summary.
```

### 3. `.claude-plugin/marketplace.json`

Bump `plan-interview` version from current to `1.6.0`.

## Files to Modify

| File | Change |
|------|--------|
| `plugins/plan-interview/skills/plan-interview/SKILL.md` | Add Step 4.5 + Step 0 todo |
| `plugins/plan-interview/CHANGELOG.md` | Add v1.6.0 entry |
| `.claude-plugin/marketplace.json` | Bump plan-interview to v1.6.0 |

## Verification

1. Load the plugin locally:
   ```bash
   claude --plugin-dir ~/devbox/agentics/plugins/plan-interview
   ```
2. Open a plan file in the IDE and trigger the skill (e.g., "stress-test this plan").
3. Proceed through Steps 0–4. After Step 4, confirm you are prompted with the deep-grill offer.
4. Accept the offer. Verify Claude walks branches, provides recommendations, and explores the codebase for answerable questions.
5. Decline the offer on a second run. Verify the skill proceeds directly to Step 5 without interruption.
6. Confirm Step 5 summary includes a **Deep Grill Findings** section when the session was conducted.

## Next Steps

- Apply the same Step 4.5 to `commands/plan-interview.md` (currently out of scope)
- Consider a `--deep-grill` flag on the command to skip the opt-in prompt
