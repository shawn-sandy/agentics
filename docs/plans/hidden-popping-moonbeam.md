# Plan: Add Plan Name Validation to plan-interview Plugin

## Context

Plan files in `docs/plans/` and `~/.claude/plans/` historically used random generated names (e.g., `fuzzy-swimming-pearl.md`) that obscured their purpose. A prior effort renamed 24 plan files to descriptive names. However, the plan-interview plugin does not currently validate whether a plan's name reflects its content. Adding this check ensures non-descriptive names are caught during review, keeping the plans directory scannable and self-documenting.

## Approach

Add a **plan name validation** sub-step inside the existing **Step 2 (Read and analyze the plan)**. This is the natural location because:
- Step 1 only resolves the file path (no content available yet)
- Step 2 is where the file is first read and its purpose extracted
- Adding it as a sub-step avoids renumbering existing steps

The validation checks both the **filename** and the **H1 heading**, flags issues immediately, and includes findings in the Step 5 summary.

## Files to Modify

| File | Change |
|------|--------|
| `plugins/plan-interview/skills/plan-interview/SKILL.md` | Add name validation block to Step 2, update Step 0 todo, update Step 5 summary template |
| `plugins/plan-interview/commands/plan-interview.md` | Mirror identical changes |
| `plugins/plan-interview/.claude-plugin/plugin.json` | Bump version `1.1.0` → `1.2.0` |
| `.claude-plugin/marketplace.json` | Bump plan-interview version `1.1.0` → `1.2.0` |
| `plugins/plan-interview/CHANGELOG.md` | Add `[1.2.0]` entry |
| `plugins/plan-interview/README.md` | Mention name validation in "After the interview" section |

## Steps

### 1. Update Step 0 todo list (both files)

In both `SKILL.md` (line 19) and `commands/plan-interview.md` (line 27), change:

```
- Step 2: Read and analyze the plan
```

to:

```
- Step 2: Read, validate plan name, and analyze the plan
```

### 2. Insert name validation block into Step 2 (both files)

In both files, insert the following after `Read the resolved plan file.` and before `Extract the following to guide question generation:`:

```markdown
**Plan name validation**: Before extracting plan details, check whether the
plan's filename and H1 heading accurately describe the plan's content.

1. **Extract identifiers**: Get the filename (without path or `.md` extension)
   and the H1 heading (first line matching `# ...`).

2. **Determine the plan's purpose**: Read enough of the plan to form a
   one-sentence summary of what it intends to accomplish.

3. **Evaluate the filename** against these criteria:
   - **Descriptive**: Contains words that relate to the plan's goal or content.
     Good: `create-skill-reviewer-plugin`, `fix-marketplace-json-location`.
     Bad: `fuzzy-swimming-pearl`, `hidden-popping-moonbeam`.
   - **Not random**: Does not follow a random adjective-noun or
     adjective-verb-noun pattern with no connection to the plan's subject matter.
     Note: `add-dark-mode-toggle` is descriptive even though it contains
     adjectives — the key test is whether the words relate to the plan content.
   - **Not too generic**: Not a placeholder like `plan.md`, `untitled.md`,
     `draft.md`, `temp.md`, or `new-plan.md`.

4. **Evaluate the H1 heading**:
   - Does an H1 heading exist?
   - Does it describe the plan's purpose? (Good: `# Plan: Create
     'skill-reviewer' Plugin`. Bad: `# Plan` alone, or missing entirely.)
   - Does it align with the filename? Both should refer to the same intent.

5. **Record the result** as one of:
   - **Pass**: Both filename and heading are descriptive and aligned — proceed
     silently.
   - **Needs attention**: One or both are non-descriptive, generic, or
     misaligned. Record:
     - Which element(s) failed (filename, heading, or both)
     - Why (random pattern, too generic, misaligned, or missing)
     - A **suggested filename** in kebab-case derived from the plan's goal
     - A **suggested H1 heading** in `# Plan: [Description]` format

If the name needs attention, present the finding immediately before continuing:

```​markdown
### Plan Name Review

| Element | Current | Issue | Suggested |
|---------|---------|-------|-----------|
| Filename | `fuzzy-swimming-pearl.md` | Random — unrelated to content | `create-skill-reviewer-plugin.md` |
| H1 Heading | _(missing)_ | No H1 heading found | `# Plan: Create 'skill-reviewer' Plugin` |
```​

If the name passes, skip this section silently and continue with the rest of
Step 2.
```

### 3. Update Step 5 summary template (both files)

Insert a `### Plan Naming` section between `### Key Decisions Confirmed` and `### Open Risks & Concerns`:

```markdown
### Plan Naming

[Include only if name validation found issues in Step 2. Reproduce the table
showing current name(s), the issue, and suggested replacement(s). Omit this
section entirely if the name passed validation.]
```

### 4. Bump version to 1.2.0

- `plugins/plan-interview/.claude-plugin/plugin.json`: `"version": "1.1.0"` → `"1.2.0"`
- `.claude-plugin/marketplace.json`: plan-interview entry `"version": "1.1.0"` → `"1.2.0"`

### 5. Update CHANGELOG.md

Add entry at the top (after `# Changelog`):

```markdown
## [1.2.0] - 2026-02-26

### Added

- Plan name validation in Step 2 — checks whether the filename and H1 heading are descriptive and aligned with the plan's content, suggests better names when they are random or generic
```

### 6. Update README.md

Update the "After the interview" section to mention name validation:

```markdown
### After the interview

The skill compiles a **Plan Interview Summary** with:
- Plan naming issues (if the filename or heading is non-descriptive)
- Key decisions confirmed
- Open risks and concerns
- Recommended next steps
- Simplification opportunities (if any)
```

## Validation Criteria Summary

| Check | Pass | Fail |
|-------|------|------|
| Filename descriptiveness | Words relate to the plan's goal | Random words unrelated to content |
| Filename specificity | Names a concrete action/subject | Generic placeholder (`plan.md`, `untitled.md`) |
| H1 heading existence | `# ...` line exists | No H1 heading found |
| H1 heading descriptiveness | Describes the plan's purpose | Generic (`# Plan`) or empty |
| Filename-heading alignment | Both refer to the same intent | Filename and heading describe different things |

## Behavior

- **Pass**: Validation runs silently. No output shown, no section in summary.
- **Needs attention**: Table shown immediately in Step 2. Same table reproduced in Step 5 summary under `### Plan Naming`. The suggestion is informational only — the plugin does not rename files or edit headings automatically.

## Verification

1. Load the plugin locally: `claude --plugin-dir ./plugins/plan-interview`
2. Run `/plan-interview:plan-interview` against a plan with a random name (e.g., this plan file itself: `hidden-popping-moonbeam.md`) — confirm the name validation flags the random filename and suggests a descriptive one
3. Run against a plan with a good name (e.g., `docs/plans/create-skill-reviewer-plugin.md`) — confirm name validation passes silently
4. Verify version sync: `grep -r '"version"' plugins/plan-interview/.claude-plugin/ .claude-plugin/marketplace.json`
5. Confirm both SKILL.md and command file have identical changes

## Interview Summary

### Plan Naming

| Element | Current | Issue | Suggested |
|---------|---------|-------|-----------|
| Filename | `hidden-popping-moonbeam.md` | Random adjective-verb-noun pattern — unrelated to content | `add-plan-name-validation-to-interview.md` |
| H1 Heading | `# Plan: Add Plan Name Validation to plan-interview Plugin` | No issue — descriptive and clear | No change needed |

### Key Decisions Confirmed

- **Heuristic-based validation** — Claude judges descriptiveness from context and examples rather than enforcing a rigid verb-prefix rule
- **Topic-only alignment check** — filename-heading misalignment is only flagged when they refer to entirely different topics, not when scope or action verb differs
- **Offer to rename** — after presenting the Plan Name Review table, the plugin should ask the user whether they want the file renamed (not just report and move on)
- **Duplicate content is acceptable** — both `SKILL.md` and `commands/plan-interview.md` will contain identical validation text; no need for shared partials

### Open Risks & Concerns

- **Plan text contradicts the rename decision**: The plan currently says findings are "informational only" and "the plugin does not rename files." This needs to be updated to include the rename offer via `AskUserQuestion` after the Plan Name Review table.
- **Heading update scope unclear**: If the user accepts a rename and the H1 heading was also flagged, should the heading be corrected too? The plan should specify whether the rename offer covers both elements.
- **File path propagation after rename**: If the file is renamed mid-interview (during Step 2), the resolved path used in Steps 4–6 must be updated. The plan should note this explicitly to prevent writing the summary to the old (now nonexistent) path.
- **Alignment criterion wording is ambiguous**: The current text ("Both should refer to the same intent") could be interpreted as flagging scope mismatches. It should explicitly say: flag only when filename and heading refer to different topics entirely.

### Recommended Next Steps

1. **Update the plan** to replace the "informational only" language with a rename offer using `AskUserQuestion` (e.g., *"Would you like me to rename this file to `[suggested-name].md`?"*)
2. **Clarify** whether the rename offer also updates the H1 heading when it was flagged
3. **Add a note** that the resolved file path must be refreshed after a rename so Step 6's save operation targets the correct file
4. **Tighten the alignment criterion** wording to explicitly scope it to topic-level mismatches only
