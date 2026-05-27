---
name: running-tests
description: "Detects the test framework and runs scoped tests. Reports pass/fail results with output and identifies failing assertions. Use when the user asks to run tests, check if tests pass, or verify changes."
allowed-tools: AskUserQuestion, Bash, Glob, Read, TodoWrite
---

Detect the test framework per changed file, run scoped test commands via Bash,
and report pass/fail/error counts. Advise on missing test files.

> **Freedom level: Adaptive** — Follow these steps exactly.

## When not to use

Does not review test quality — use reviewing-tests. Does not suggest new tests — use code-testing-agent.

## Table of Contents

- [Step 0: Create Progress Todos](#step-0-create-progress-todos)
- [Step 1: Identify Changed Files](#step-1-identify-changed-files)
- [Step 2: Find Related Test Files](#step-2-find-related-test-files)
- [Step 3: Detect Test Framework](#step-3-detect-test-framework)
- [Step 4: Run Tests](#step-4-run-tests)
- [Step 5: Report Results and Advise on Missing Tests](#step-5-report-results-and-advise-on-missing-tests)

---

## Step 0: Create Progress Todos

Use `TodoWrite` to create todos for Steps 1-5 (all `status: "pending"`).
Mark each `status: "completed"` as you finish.

---

## Step 1: Identify Changed Files

Resolve the list of changed source files using the following priority order:

1. **Explicit path** — if the user provided a file path in their message, use it directly
2. **Git diff** — run `git diff --name-only HEAD` via Bash to get changed files
3. **Conversation context** — if a file was recently discussed, use it
4. **Ask the user** — use `AskUserQuestion` to request a file path

Filter out non-testable files: binary files, lock files (`package-lock.json`, `yarn.lock`, `Cargo.lock`, `poetry.lock`), generated files (`dist/`, `build/`, `.next/`, `__pycache__/`), and config-only files (`.env`, `*.config.js` unless the framework has config tests).

**Empty-state short-circuit:** If `git diff --name-only HEAD` returns empty and no explicit path was given, tell the user no changed files were detected and stop.

---

## Step 2: Find Related Test Files

For each changed file from Step 1, locate the corresponding test file.
Load `references/test-runner-guide.md` Section 1 for naming conventions and search directories.

Produce a **resolved pairs table**:

| Source File | Test File | Status |
|-------------|-----------|--------|
| `src/utils/parser.ts` | `src/utils/parser.test.ts` | Found |

If multiple candidates exist, prefer the one closest in the directory tree.
Mark files with no test as **Not found** — they are addressed in Step 5.

---

## Step 3: Detect Test Framework

For each changed source file, detect the test framework by inspecting config files.
Load `references/test-runner-guide.md` Section 2 for detection signals and run commands.

**Monorepo tie-breaking:** See Section 5 for the nearest-ancestor rule.

**If still ambiguous** after checking all signals, use `AskUserQuestion`:
> "I found multiple test frameworks in this repository. Which should I use to test `<filename>`?"

---

## Step 4: Run Tests

Use `Bash` to run the scoped test command for each detected framework.
Load `references/test-runner-guide.md` Section 2 for command templates.

Scope the run to only the test files resolved in Step 2 — do not run the full suite.

**On failure:**
- Capture the exit code
- Surface stderr output directly in the report (Step 5)
- Do not retry or modify the test command

**Skip** test files marked "Not found" in Step 2 — those are handled in Step 5.

---

## Step 5: Report Results and Advise on Missing Tests

### Results Table

Output a results table: `Test File | Result | Pass | Fail | Error`.
Load `references/test-runner-guide.md` Section 3 for result parsing patterns to extract counts.
If counts are not parseable, report exit code only (PASS for 0, FAIL for non-zero).

**On failure:** Display the relevant stderr excerpt below the table.

### Missing Test Advisory

For each source file marked "Not found" in Step 2, output a file-level advisory.
Load `references/test-runner-guide.md` Section 4 for per-language advisory templates.

Advisory is file-level only — do not parse function signatures or suggest specific test cases.
For detailed test suggestions, direct the user to the `reviewing-tests` skill.
