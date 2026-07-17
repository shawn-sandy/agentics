---
name: deep-grill
description: "Stress-tests plan decisions node-by-node with focused questions. Walks each decision point surfacing assumptions and weak spots. Use when the user asks to deep grill or stress-test a plan."
allowed-tools: Read, Glob, Grep, AskUserQuestion, TodoWrite
disable-model-invocation: true
---

# Deep Grill

Walk each branch of a plan's design tree, asking focused questions at every
decision node and exploring the codebase to resolve them.

## Table of Contents

- [Step 0 — Create progress todos](#step-0--create-progress-todos)
- [Step 1 — Resolve the plan file](#step-1--resolve-the-plan-file)
- [Step 2 — Read and build design tree](#step-2--read-and-build-design-tree)
- [Step 3 — Walk design-tree branches](#step-3--walk-design-tree-branches)
- [Step 4 — Present deep grill summary](#step-4--present-deep-grill-summary)

## Instructions

### Step 0 — Create progress todos

Before doing any other work, use `TodoWrite` to create todos for each step of
this session. This gives the user visibility into progress and ensures no step is
skipped.

Create the following todos (all starting with `status: "pending"`):

- Step 1: Resolve plan file
- Step 2: Read and build design tree
- Step 3: Walk design-tree branches (deep grill session)
- Step 4: Present deep grill summary

Mark each todo `status: "completed"` as you finish that step.

### Step 1 — Resolve the plan file

Use the first match from this priority order:

1. **Argument**: If a file path appears in `$ARGUMENTS` or the user's message,
   treat it as the plan file path and read it directly.
2. **Currently open file**: If no path was given, check whether a `.md` file is
   currently open or selected in the IDE (provided via context). If it exists
   and its content looks like a plan (contains headings like
   `## Implementation`, `## Plan`, `## Steps`, `## Context`, or `## Summary`),
   use it.
3. **Settings `plansDirectory` override**: Read the `"plansDirectory"` key
   following Claude Code's settings precedence — project-local
   `.claude/settings.local.json`, then project `.claude/settings.json`, then
   global `~/.claude/settings.json`. The first that sets it wins (a more specific
   layer takes precedence). Glob `*.md` files from that path and use the most
   recently modified file.
4. **Default fallback**: Use `Glob` on `${PWD}/docs/plans/*.md`, sort by
   modification time, and select the most recently modified file.

If no file can be found via any of these methods, tell the user and stop.

The deep grill is designed for implementation plans. If the resolved file is a
`SKILL.md` (filename is `SKILL.md` or frontmatter contains `name:` and
`description:` without plan-style headings), inform the user that the deep grill
targets plans, not skill files, and stop.

Announce the file: `"Deep grilling plan: path/to/plan.md"`

### Step 2 — Read and build design tree

Read the resolved plan file and extract the design tree:

1. **Identify decision nodes**: Scan the plan for architectural choices,
   technology selections, API designs, data models, integration points, file
   structure decisions, and any other points where an alternative approach
   exists.

2. **Organize into branches**: Group decision nodes by plan section or concern
   area. Each branch represents a related cluster of decisions.

3. **Present the outline**: Show a brief summary of the branches found:

   ```
   Found N decision branches:
   1. [Branch name] — [brief description]
   2. [Branch name] — [brief description]
   ...
   ```

4. **Ask the user** via `AskUserQuestion` whether to grill all branches or
   select specific ones:
   - **Question:** "Grill all branches or pick specific ones?"
   - **Options:** "Grill all branches" / "Let me pick specific branches"

   If the user picks specific branches, present the list with numbers and let
   them choose.

### Step 3 — Walk design-tree branches

For each selected branch, one at a time:

- Announce the current branch: `"Branch N/M: [branch name]"`
- For each decision node in the branch, ask a focused question and provide your
  recommended answer before waiting for the user's response.
- If the question can be answered by exploring the codebase, use `Glob`, `Grep`,
  or `Read` first, then present your finding as the recommended answer.
- After each response, check whether sub-questions exist for that branch. If so,
  resolve them before moving to the next branch.
- Collect all decisions and insights as you go.

After completing each branch (except the last), use `AskUserQuestion` to ask:

- **Question:** "Branch N complete. Continue to the next branch?"
- **Options (first = recommended):** "Yes, continue" / "No, stop and summarize"

If the user stops early, proceed directly to Step 4 with the branches examined
so far.

### Step 4 — Present deep grill summary

Output a structured summary:

```markdown
## Deep Grill Summary

### Plan

[path/to/plan.md]

### Branches Examined

[N/M branches completed]

### Key Decisions Resolved

- [Branch]: [Decision confirmed] — [rationale or codebase evidence]

### Open Questions Remaining

- [Any branches or sub-questions the user deferred or skipped]

### Recommendations

- [Amendments to the plan based on deep grill findings]
```
