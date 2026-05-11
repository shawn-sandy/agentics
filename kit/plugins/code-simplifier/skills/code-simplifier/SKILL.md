---
name: code-simplifier
description: "Use when the user asks to simplify code, find code smells, reduce complexity, or refactor. Creates a refactoring plan and applies approved changes."
allowed-tools: AskUserQuestion, Bash(git *), Edit, EnterPlanMode, ExitPlanMode, Glob, Grep, Read, Write
---

Analyze code for structural quality issues and code smells. Create a prioritized
refactoring plan with specific improvement steps and before/after code examples.
After developer approval, apply the approved changes. Adapt analysis depth to
the code's complexity and scope.

## Table of Contents

- [Step 0: Resolve Target Files](#step-0-resolve-target-files)
- [Step 1: Enter Plan Mode](#step-1-enter-plan-mode)
- [Step 2: Analyze Code Smells](#step-2-analyze-code-smells)
- [Step 3: Create Refactoring Plan](#step-3-create-refactoring-plan)
- [Step 4: Present Findings](#step-4-present-findings)
- [Step 5: Review with Developer](#step-5-review-with-developer)
- [Step 6: Apply or Discard](#step-6-apply-or-discard)
- [Analysis Format](#analysis-format)
- [Example Analysis](#example-analysis)
- [Tips for Effective Analysis](#tips-for-effective-analysis)
- [Scope](#scope)

## Step 0: Resolve Target Files

Before analyzing, identify which files to check using this priority order:

1. **Explicit path in message** — If the user named a file or directory, use it
   directly. For directories, use `Glob` to list source files within them
   (exclude binaries, lock files, generated files, `node_modules/`, `dist/`,
   `.git/`). Skip to Step 1.

2. **Local changes (git status)** — If no file was specified, run:
   `git status --short`
   - If this fails (not a git repo), skip to step 4.
   - If files are listed, show the list and ask: "I found these changed files —
     which would you like me to analyze?" Analyze confirmed files.
   - If no files are listed, continue to step 3.

3. **Branch diff** — Run each in order until files are returned:
   - `git diff main...HEAD --name-only`
   - `git diff master...HEAD --name-only`
   - `git diff HEAD~1 --name-only`
   If files are returned, show the list and confirm before analyzing. If all
   return empty or fail, continue to step 4.

4. **Fallback** — Use `AskUserQuestion` to ask: "Which file or files would you
   like me to analyze for code smells?"

Once target files are confirmed, proceed to Step 1.

## Step 1: Enter Plan Mode

Call `EnterPlanMode` immediately after resolving target files. All analysis and
plan creation happen within plan mode to prevent premature edits. Do not read
or analyze files until plan mode is active.

## Step 2: Analyze Code Smells

Read [references/smell-checklist.md](references/smell-checklist.md) for the full
nine-category checklist. Apply each category to every file under review.

For each smell detected, record:

- **Category** — which of the nine checklist categories
- **Smell name** — specific issue (e.g., "god function", "duplicated validation")
- **Location** — file path and approximate line number(s)
- **Severity** — Critical (must refactor) / Moderate (should refactor) / Minor
  (nice to have)
- **Confidence** — High or Medium only. Discard Low-confidence findings.
- **Explanation** — brief description of why it matters

When analyzing multiple files, use `Grep` to check for duplicated patterns
across files and `Glob` to find related modules when assessing coupling.

## Step 3: Create Refactoring Plan

Resolve the project's plans directory:

1. Check `.claude/settings.json` for a `plansDirectory` key
2. Fall back to `docs/plans/`
3. Create the directory if it doesn't exist

Write a plan file at `<plansDirectory>/simplify-<scope-slug>.md` where
`<scope-slug>` is derived from the target (e.g., `simplify-session-manager.md`,
`simplify-utils-folder.md`). The plan file must include:

- Summary of findings (1-2 sentences)
- Prioritized refactoring steps (ordered by impact, highest first)
- Before/after code examples for the top 3 findings
- Estimated effort per step (trivial / small / moderate / large)

## Step 4: Present Findings

Structure findings using the [Analysis Format](#analysis-format) below. Include
the plan file path so the developer can reference it.

## Step 5: Review with Developer

Use `AskUserQuestion` to ask the developer to review the findings and plan:

> I've analyzed the code and created a refactoring plan at `<path>`. Here are the
> key findings: [1-2 sentence summary].

Offer three options:

1. **Approve and apply** — exit plan mode and apply the refactoring steps
2. **Adjust the plan** — tell me what to change (loop back to Step 3)
3. **Discard** — delete the plan file and exit without changes

If the developer requests adjustments, update the plan file and present the
revised findings. Loop until the developer approves or discards.

## Step 6: Apply or Discard

**If approved:**

1. Call `ExitPlanMode`
2. Apply each refactoring step from the plan using `Edit` and `Write`
3. After applying, briefly summarize what was changed

**If discarded:**

1. Delete the plan file
2. Call `ExitPlanMode`
3. Confirm: "Plan discarded. No changes were made."

## Analysis Format

Structure the analysis output as follows:

### Summary

Brief overview of the code's purpose and structural quality (1-2 sentences).

### Smell Severity Rating

**[Clean / Minor Issues / Needs Refactoring / Major Refactoring Needed]** —
One-sentence rationale.

### Critical Smells

Issues that significantly harm readability, maintainability, or performance.
Must be addressed. For each:

- Smell name with file path and line number
- Code snippet showing the problem
- Explanation of structural impact
- Suggested refactoring with code example

### Moderate Smells

Non-critical issues that would improve code structure and maintainability.

### Refactoring Plan

Link to the generated plan file with a step summary.

### Positive Observations

Structural patterns the code does well. Reinforce good practices.

## Example Analysis

See [references/example-analysis.md](references/example-analysis.md) for a
complete sample demonstrating the expected output format.

## Tips for Effective Analysis

1. **Prioritize by impact** — a god function affecting 10 callers matters more
   than a missing constant
2. **Show before/after** — concrete code examples are more actionable than
   abstract advice
3. **Respect intent** — some "smells" are deliberate trade-offs; flag them as
   observations, not issues
4. **Check for duplication across files** — use `Grep` to find repeated patterns
   that may not be obvious within a single file
5. **Consider the ecosystem** — a 200-line React component may be normal; a
   200-line utility function is not
6. **Be constructive** — frame findings as improvement opportunities, not
   criticisms

## Scope

- Analyze only the code provided or specified by the user
- Don't analyze entire codebases unless explicitly asked
- Focus on structural quality, not bugs or security (those belong to
  code-review-agent)
- Skip generated files, lock files, binaries, and vendored dependencies
- Adapt analysis depth to the code's complexity and context
