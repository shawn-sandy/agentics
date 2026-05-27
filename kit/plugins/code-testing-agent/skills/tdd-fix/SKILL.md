---
name: tdd-fix
description: "Fixes bugs via TDD with up to 10 red-green iterations. Writes a failing test then autonomously iterates until the bug is resolved. Use when the user asks to TDD-fix a bug or run a red-green cycle."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
disable-model-invocation: true
---

Given a bug description, write a failing test that reproduces it, then
enter an autonomous loop — run tests, analyze failures, edit code, re-run —
until green or 10 iterations. Log each iteration's hypothesis. After
passing, run the full suite, commit with a `fix:` prefix, and open a PR.

> **Freedom level: Strict** — Follow these steps in order. Do not skip or
> combine steps. Stop at each hard-stop marker.

## When not to use

Does not design tests from scratch — use code-testing-agent. Does not review test quality — use reviewing-tests.

## Table of Contents

- [Step 0: Create Progress Todos](#step-0-create-progress-todos)
- [Step 1: Parse Bug Description](#step-1-parse-bug-description)
- [Step 2: Write the Failing Test (Red Phase)](#step-2-write-the-failing-test-red-phase)
- [Step 3: Autonomous Fix Loop (max 10 iterations)](#step-3-autonomous-fix-loop-max-10-iterations)
- [Step 4: Hard Cap — Loop Exhausted](#step-4-hard-cap--loop-exhausted)
- [Step 5: Regression Sweep](#step-5-regression-sweep)
- [Step 6: Summarize the Fix](#step-6-summarize-the-fix)
- [Step 7: Commit via commit-agent](#step-7-commit-via-commit-agent)
- [Step 8: Open PR via pr-agent](#step-8-open-pr-via-pr-agent)
- [Step 9: Stop](#step-9-stop)

---

## Step 0: Create Progress Todos

Use `TodoWrite` to create todos for Steps 1–9, all `status: "pending"`.
Mark each `status: "completed"` as you finish it.

---

## Step 1: Parse Bug Description

Extract from the invocation message:

| Field | What to extract |
|-------|----------------|
| **Symptom** | What the code currently does wrong |
| **Expected behavior** | What it should do instead |
| **Affected file(s)** | Source file(s) containing the bug — explicit path, or inferred from symptom |
| **Test file** | Corresponding test file (infer from naming convention if not given) |

**If any field is missing and cannot be inferred**, use `AskUserQuestion`
with a focused question for the missing field only. Do not ask for everything
at once.

**Do not open any source file yet.** Only parse the message.

---

## Step 2: Write the Failing Test (Red Phase)

1. **Locate the test file.** Use `Glob` to find it:
   - `*.test.ts`, `*.test.js`, `*.spec.ts`, `*.spec.js` (JS/TS)
   - `test_*.py`, `*_test.py` (Python)
   - `*_test.go` (Go)
   - `*_test.rs` (Rust)
   - `*.test.sh`, `*.bats` (shell)

   If multiple candidates exist, prefer the one closest in the directory tree
   to the affected source file.

2. **Read the test file** (`Read`) to understand its structure, assertion
   style, and import pattern.

3. **Append a new test case** that will fail because of the bug. Use `Edit`
   (not `Write`) to add to the existing file. The test must:
   - Target exactly the behavior described in Step 1
   - Use the project's existing assertion style
   - Include a comment `# tdd-fix: reproducing <symptom>` (or language
     equivalent) to identify it later

4. **Do NOT edit any production code in this step.**

5. Run the test once (`Bash`) to confirm it fails. If it unexpectedly
   **passes**, stop and use `AskUserQuestion`:
   > "The new test passed without any code changes — the bug may already be
   > fixed, or the test may not be reproducing it correctly. How do you want
   > to proceed?"

---

## Step 3: Autonomous Fix Loop (max 10 iterations)

Initialize an iteration log. Render it as a markdown table and update it
live after each iteration:

```
| # | Hypothesis | Change Made | Result |
|---|------------|-------------|--------|
```

For each iteration `i` from 1 to 10:

### 3a — Form a hypothesis

Read the failure output from the previous run (or from Step 2 on iteration
1). In one sentence, state **why** the test is failing and **what** in the
production code is responsible. Write the hypothesis to the iteration log.

Examples of well-formed hypotheses:
- "Operator in `add()` is subtraction, not addition."
- "`parseDate` does not handle the `Z` timezone suffix."
- "Off-by-one: loop ends at `< n` but should be `<= n`."

### 3b — Edit the production file

Use `Edit` (not `Write`) to apply the minimal change implied by the
hypothesis. Record a one-line diff summary in the log.

Do not refactor unrelated code. Do not add unrelated tests. Change only
what the hypothesis requires.

### 3c — Run the scoped test

Run only the test written in Step 2 via `Bash`. Record the result (`PASS`
or `FAIL + excerpt`) in the iteration log.

- **If PASS**: exit the loop and proceed to Step 5.
- **If FAIL**: if `i < 10`, increment and go to 3a. If `i == 10`, proceed
  to Step 4.

**Show the updated iteration log after every iteration.**

---

## Step 4: Hard Cap — Loop Exhausted

If the loop reaches 10 iterations without a passing test:

1. Print the full iteration log.
2. Surface the last three hypotheses and why each failed.
3. Output:

```
tdd-fix stopped after 10 iterations. The test is still failing.
No commit or PR will be created.

Suggestions for next steps:
- Review the iteration log above for patterns.
- Consider whether the bug is in a different file than expected.
- The test file and any partial edits remain on disk for manual inspection.
```

4. **STOP.** Do not commit, do not open a PR.

---

## Step 5: Regression Sweep

Once the scoped test passes, run the **full** test suite with no scope
filter. Use `Bash` with the appropriate full-suite command for the project:

- Node/JS: `npm test`, `yarn test`, `pnpm test`, or `npx vitest run`
- Python: `pytest`, `python -m pytest`
- Go: `go test ./...`
- Shell: run the top-level test runner script if one exists

If any **previously-passing** test now fails:

1. Report the regressions — test names and failure excerpts.
2. Do not commit.
3. Output:

```
Regression detected. The fix broke existing tests (listed above).
No commit or PR will be created. The changes remain on disk.
```

4. **STOP.**

If all tests pass, continue to Step 6.

---

## Step 6: Summarize the Fix

Print a summary block before committing:

```
## tdd-fix Summary

Bug:        <symptom from Step 1>
Fix:        <final hypothesis from Step 3>
Iterations: <i of 10>
Files changed:
  - <production file(s) edited>
  - <test file appended>
Full suite: PASS
```

---

## Step 7: Commit via commit-agent

Invoke the `commit-agent` skill. When it drafts the commit message, ensure:

- Type is `fix`
- Scope is the most-changed top-level directory
- Description summarizes the symptom in imperative mood

Example: `fix(tests/demo): correct add() operator from subtraction to addition`

The `commit-agent` skill handles staging, pre-commit hooks, and conventional
format — do not duplicate that logic here.

---

## Step 8: Open PR via pr-agent

Invoke the `pr-agent` skill. When it drafts the PR body, include the
iteration log from Step 3 under a `## How it was found (tdd-fix)` section.

The `pr-agent` skill handles push, platform detection (GitHub/GitLab), and
branch checks — do not duplicate that logic here.

---

## Step 9: Stop

**STOP here.** Do not analyze code further, do not re-run tests, do not
suggest refactors or cleanup, do not open additional issues. The fix is
complete when the PR URL is returned by `pr-agent`.
