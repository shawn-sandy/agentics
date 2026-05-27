---
name: code-testing-agent
description: "Suggests purpose-driven tests tied to actual behavior. Writes test files covering untested paths and behavior gaps in the codebase. Use when the user asks to suggest tests or find untested behavior."
allowed-tools: AskUserQuestion, Bash, Glob, Read, TodoWrite, Write
---

---

Analyze code and suggest specific, purpose-driven tests tied to actual behavior.
Strive to meet the project's coverage target, or maximize coverage when no
target is defined.

> **Freedom level: Flexible** — Follow these steps in order. Adapt depth to the
> code's complexity and the user's request.

## When not to use

Does not run tests — use running-tests. Does not review code quality — use code-review-agent.

## Table of Contents

- [Step 0 — Create Progress Todos](#step-0--create-progress-todos)
- [Step 1 — Identify Target Code](#step-1--identify-target-code)
- [Step 2 — Search for Implementation Plan](#step-2--search-for-implementation-plan)
- [Step 3 — Analyze the Code](#step-3--analyze-the-code)
- [Step 4 — Detect Project Test Infrastructure](#step-4--detect-project-test-infrastructure)
- [Step 5 — Suggest Tests with Rationale](#step-5--suggest-tests-with-rationale)
- [Step 6 — Offer to Write Test Files](#step-6--offer-to-write-test-files)

---

## Step 0 — Create Progress Todos

Use `TodoWrite` to create todos for Steps 1–6 (all `status: "pending"`). Mark
each `status: "completed"` as you finish.

---

## Step 1 — Identify Target Code

Resolve the target code using this priority order. Load
`references/input-resolution.md` for detailed parsing heuristics.

1. **File path argument** — parse the invocation message for a file path
2. **Function/method argument** — note any named function; scope Step 3 to it
   once a file is resolved
3. **Pasted code** — use the inline code block as an anonymous file
4. **Conversation context** — recently created, edited, or discussed file
5. **Recent changes** — `git diff --name-only HEAD~1` (exclude test/config/lock
   files); confirm with user
6. **Ask** — "Which code would you like me to suggest tests for?"

Report: file(s) to analyze, function scope if any, full-file vs. scoped. Read
each target file in full.

---

## Step 2 — Search for Implementation Plan

Search for design intent (stop at first match):

1. User's message
2. `docs/plans/` — match by filename similarity to target code
3. `~/.claude/plans/` — same matching logic
4. `git log --oneline -5` — commit messages describing intent
5. Inline `// TODO`, `// PLAN:`, `// PURPOSE:`, or JSDoc `@description` in the
   target code

If found: report
`"Found plan: [path]. Using it to understand intended behavior."` Extract goal,
key behaviors, edge cases, and acceptance criteria.

If not found: report
`"No implementation plan found. Inferring intent from code and context."`
Proceed to Step 3.

---

## Step 3 — Analyze the Code

Load `references/test-analysis-guide.md` for detailed heuristics. Analyze:

- **3a. Behavioral summary** — 2–4 sentences on purpose and primary behavior
- **3b. Critical paths** — happy path, error paths, branching logic, state
  transitions
- **3c. Integration points** — external APIs, file system, events, internal
  modules, env config
- **3d. Implicit contracts** — return shape, side effects, ordering, idempotency
  guarantees
- **3e. Fragility** — complex conditionals, regex, math, null chains, index
  arithmetic

---

## Step 4 — Detect Project Test Infrastructure

Load `references/test-infrastructure.md` for config file locations and glob
patterns. Detect:

- **4a. Test framework** — from `package.json`, `pytest.ini`, `Cargo.toml`, CI
  config, etc.
- **4b. Existing test files** — glob for `*.test.*`, `*.spec.*`, `*_test.*` near
  the target
- **4c. Existing patterns** — read 1–2 test files for import style, mocking,
  conventions
- **4d. Coverage target** — from `jest.config.*`, `pyproject.toml`, `.nycrc`,
  `codecov.yml`

Report:
`"Detected: [framework]. Existing tests use [patterns]. Coverage target: [X]%."`

---

## Step 5 — Suggest Tests with Rationale

Load `references/output-guide.md` for the full output template and suggestion
principles.

For each suggestion provide: **What** (behavior), **Why** (blast radius if
missing), **How** (approach + key assertions), **Where** (file path). Group by
file; prioritize by blast radius.

---

## Step 6 — Offer to Write Test Files

Ask: "Would you like me to write the test file(s)? I will create [path(s)] with
the tests above."

- **Yes** — write complete files using detected conventions (Priority 1 + 2;
  confirm before including Priority 3). Suggest `[test command]` to verify.
- **No** — "The suggestions above should give you a clear starting point."
- **Partial** — write only the requested subset.
