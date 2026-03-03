---
name: running-tests
description: Identifies changed files, finds related test files, detects the test framework, runs tests, and reports pass/fail/error results. Use when the user asks to "run tests for my changes", "check if tests pass", "test this file", "verify my changes don't break tests", or "are there missing tests". Also checks for missing test files and advises on what to create. Does not review test quality or suggest tests from scratch — use reviewing-tests for that.
---

## Overview

Adaptive + Sequential skill that detects the test framework per changed file, runs scoped test commands via Bash, and reports pass/fail/error counts. Also identifies source files with no corresponding test file and advises the user on what to create.

Follow these steps exactly.

## Table of Contents

- [Step 0: Create Progress Todos](#step-0-create-progress-todos)
- [Step 1: Identify Changed Files](#step-1-identify-changed-files)
- [Step 2: Find Related Test Files](#step-2-find-related-test-files)
- [Step 3: Detect Test Framework](#step-3-detect-test-framework)
- [Step 4: Run Tests](#step-4-run-tests)
- [Step 5: Report Results and Advise on Missing Tests](#step-5-report-results-and-advise-on-missing-tests)

---

## Step 0: Create Progress Todos

Before doing any other work, use `TodoWrite` to create todos for each step. This gives the user visibility into progress.

Create the following todos (all starting with `status: "pending"`):

- Step 1: Identify changed files
- Step 2: Find related test files
- Step 3: Detect test framework
- Step 4: Run tests
- Step 5: Report results and advise on missing tests

Mark each todo `status: "completed"` as you finish that step.

---

## Step 1: Identify Changed Files

Resolve the list of changed source files using the following priority order:

1. **Explicit path** — if the user provided a file path in their message, use it directly
2. **Git diff** — run `git diff --name-only HEAD` via Bash to get changed files
3. **Conversation context** — if a file was recently discussed, use it
4. **Ask the user** — use `AskUserQuestion` to request a file path

**Filter out** the following — they are not testable source files:
- Binary files (images, compiled artifacts)
- Lock files (`package-lock.json`, `yarn.lock`, `Cargo.lock`, `poetry.lock`)
- Generated files (`dist/`, `build/`, `.next/`, `__pycache__/`)
- Config-only files that have no corresponding test convention (`.env`, `*.config.js` unless the framework has config tests)

**Empty-state short-circuit:** If `git diff --name-only HEAD` returns empty output and the user did not provide an explicit path, stop immediately and output:

```
No changed files detected. Please provide a file path directly, for example:
  "run tests for src/utils/parser.ts"
```

Do not proceed to Step 2.

---

## Step 2: Find Related Test Files

For each changed file identified in Step 1, locate the corresponding test file using the naming conventions in `references/test-runner-guide.md` (Section 1: Test File Naming Conventions).

Produce a **resolved pairs table**:

| Source File | Test File | Status |
|-------------|-----------|--------|
| `src/utils/parser.ts` | `src/utils/parser.test.ts` | Found |
| `src/api/auth.py` | `tests/test_auth.py` | Found |
| `src/lib/helpers.go` | `src/lib/helpers_test.go` | Not found |

- Search the directories listed in the naming conventions table for each file extension
- Mark files with no discovered test file as **Not found** — they will be addressed in Step 5
- If multiple candidate test files exist, prefer the one closest to the source file in the directory tree

---

## Step 3: Detect Test Framework

For each changed source file, detect the test framework by inspecting config files per the signal table in `references/test-runner-guide.md` (Section 2: Framework Detection Signals + Run Commands).

Inspect these config files (in priority order):

1. `package.json` — check `"scripts"."test"` and `"devDependencies"` / `"dependencies"` keys
2. `pytest.ini`, `pyproject.toml` — presence signals pytest
3. `go.mod` — presence signals `go test`
4. `Cargo.toml` — presence signals `cargo test`
5. `Makefile` — check for a `test:` target

**Monorepo tie-breaking:** In repositories with multiple framework config files, use the **nearest ancestor config file** relative to the changed source file as the tie-breaker. See Section 5 of `references/test-runner-guide.md` for the full rule.

**If still ambiguous** after checking all signals, use `AskUserQuestion`:
> "I found multiple test frameworks in this repository. Which should I use to test `<filename>`?"

---

## Step 4: Run Tests

For each detected framework, run the scoped test command from Section 2 of `references/test-runner-guide.md`, substituting the resolved test file path(s).

Use the `Bash` tool to execute the command. Scope the run to only the test files resolved in Step 2 — do not run the full suite.

**Example:** For Jest with resolved test file `src/utils/parser.test.ts`:
```bash
npx jest src/utils/parser.test.ts
```

**On failure:**
- Capture the exit code
- Surface stderr output directly in the report (Step 5)
- Do not retry or modify the test command

**Skip** test files marked "Not found" in Step 2 — those are handled in Step 5.

---

## Step 5: Report Results and Advise on Missing Tests

### Results Table

Output a results table summarizing test outcomes for all executed test files:

| Test File | Result | Pass | Fail | Error |
|-----------|--------|------|------|-------|
| `src/utils/parser.test.ts` | PASS | 12 | 0 | 0 |
| `tests/test_auth.py` | FAIL | 3 | 1 | 0 |

Use result parsing signals from Section 3 of `references/test-runner-guide.md` to extract counts. If counts are not parseable from output, report the raw exit code result (pass/fail).

**On failure:** Display the relevant stderr excerpt below the table.

### Missing Test Advisory

For each source file marked "Not found" in Step 2, output a file-level advisory using the templates from Section 4 of `references/test-runner-guide.md`:

```
Missing test files detected:

  src/lib/helpers.go
    → Suggested test file: src/lib/helpers_test.go
    → Create this file and add tests for the functions you changed.
```

This advisory is file-level only — do not parse function signatures or suggest specific test cases. For detailed test suggestions, direct the user to the `reviewing-tests` skill.
