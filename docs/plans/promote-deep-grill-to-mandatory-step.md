# Plan: Promote Deep Grill to Mandatory Step

## Context

Step 4.5 "Deep Grill" in `plan-interview` is a self-contained workflow that
relentlessly interviews developers about every decision branch in a plan,
providing recommended answers and exploring the codebase for evidence. The user
wants it extracted into a standalone skill named `developer-interview` within
the same plugin, with a paired command for explicit invocation.

## Changes

### 1. Create `plugins/plan-interview/skills/developer-interview/SKILL.md`

New standalone skill with the full deep grill logic. Frontmatter:

```yaml
---
name: developer-interview
description: >
  Use when the user wants to deeply interview or grill a developer about every
  decision branch in a plan, or run a deep-grill session on a plan.
allowed-tools: Read, Glob, Grep, AskUserQuestion, TodoWrite
---
```

Skill body — steps:

1. **Resolve the plan file** — same priority order as `plan-interview` (user
   message → IDE file → project config → global config → default plans dir)
2. **Read and map decision branches** — walk the plan and enumerate every
   decision node in a todo list
3. **For each decision node**:
   - Ask a focused question
   - Provide a recommended answer (explore codebase with `Glob`/`Grep`/`Read`
     first if the question can be answered from code)
   - Wait for the user's response
   - Resolve sub-questions for that branch before moving on
4. **Continue** until every branch is resolved or the user signals they are done
5. **Output a Deep Grill Findings summary** listing all decisions and insights

### 2. Create `plugins/plan-interview/commands/developer-interview.md`

Paired command for explicit invocation via
`/plan-interview:developer-interview [plan-path]`.

```yaml
---
description: >
  Deeply interview a developer about every decision branch in a plan,
  providing recommended answers at each step
allowed-tools: Read, Glob, Grep, AskUserQuestion, TodoWrite
argument-hint: "[path/to/plan.md]"
---
```

Body: reference the `developer-interview` skill instructions.

### 3. Update `plugins/plan-interview/skills/plan-interview/SKILL.md`

Replace the full Step 4.5 body with a compact delegate reference:

```markdown
### Step 4.5 — Deep grill (optional)

After surfacing out-of-scope concerns, ask the user:

> "Would you like a deep-grill session? I'll interview you relentlessly about
> every decision branch until we reach a shared understanding."

If the user **declines**, mark this todo complete and proceed to Step 5.

If the user **confirms**, follow the `developer-interview` skill instructions
for this plan. Collect all decisions and insights; include them in the Step 5
summary under a new **Deep Grill Findings** section.
```

### 4. Bump version in `.claude-plugin/marketplace.json`

`plan-interview`: `1.8.0` → `1.9.0` (new skill + command = minor bump)

### 5. Update `plugins/plan-interview/CHANGELOG.md`

Add a `v1.9.0` entry documenting the new `developer-interview` skill and
command.

### 6. Update `plugins/plan-interview/README.md`

Add `developer-interview` to the Features section (skill + command docs).

## Critical Files

| File | Action |
|------|--------|
| `plugins/plan-interview/skills/developer-interview/SKILL.md` | Create |
| `plugins/plan-interview/commands/developer-interview.md` | Create |
| `plugins/plan-interview/skills/plan-interview/SKILL.md` | Edit (Step 4.5 only) |
| `.claude-plugin/marketplace.json` | Edit (version bump) |
| `plugins/plan-interview/CHANGELOG.md` | Edit (add v1.9.0 entry) |
| `plugins/plan-interview/README.md` | Edit (add new skill/command docs) |

## Verification

1. Confirm `skills/developer-interview/SKILL.md` exists and follows skill conventions
2. Confirm `commands/developer-interview.md` exists with correct frontmatter
3. Confirm Step 4.5 in `plan-interview` SKILL.md is slimmed down and references `developer-interview`
4. Confirm `marketplace.json` shows `version: "1.9.0"` for `plan-interview`
5. Confirm `plugin.json` does **not** contain a `version` field (relative-path plugin convention)

## Next Steps

- Consider extracting the plan-file resolution logic into a shared reference
  document to avoid duplication across skills
- The deep grill session could eventually support a `--aggressive` mode that
  forces resolution of every branch with no user skip
