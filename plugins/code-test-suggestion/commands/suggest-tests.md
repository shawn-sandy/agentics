---
description: Analyze code and suggest specific, purpose-driven tests tied to actual behavior and intent
argument-hint: [file-path] - path to file(s) to analyze; omit to use recent git changes
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Write, Edit, TodoWrite
---

# /code-test-suggestion:suggest-tests

Analyze code and suggest specific, purpose-driven tests. Each suggested test is tied to actual code behavior, not arbitrary coverage metrics.

## Usage

```
/code-test-suggestion:suggest-tests src/services/auth.ts          # analyze a specific file
/code-test-suggestion:suggest-tests src/services/                  # analyze all files in a directory
/code-test-suggestion:suggest-tests                                # analyze recent git changes
```

## Instructions

### Step 0 — Create progress todos

Before doing any other work, use `TodoWrite` to create todos for each step. This gives the user visibility into progress.

Create the following todos (all starting with `status: "pending"`):

- Step 1: Identify target code to analyze
- Step 2: Search for implementation plan or design context
- Step 3: Analyze code behavior and critical paths
- Step 4: Detect project test framework and patterns
- Step 5: Suggest tests with rationale
- Step 6: Offer to write test files

Mark each todo `status: "completed"` as you finish that step.

### Step 1 — Identify Target Code

Determine which code to analyze using this priority order:

1. **Explicit argument**: If `$ARGUMENTS` is provided, treat it as the file path and read it directly. If it's a directory, glob for source files and present the list for confirmation.
2. **Recent changes** — Run `git diff --name-only HEAD~1` (or `git diff --name-only --cached` for staged changes) to find recently changed files. Exclude test files, config files, and lock files. Present the list and ask the user to confirm which files to analyze.
3. **Ask if unclear** — "Which code would you like me to suggest tests for? Please provide a file path."

Once resolved, tell the user which file(s) will be analyzed before proceeding.

If multiple files are specified, process them together as a unit (they may interact). If more than 5 files are specified, ask the user to narrow scope or confirm they want a broad analysis.

Read each target file in full.

### Step 2 — Search for Implementation Plan

Understanding the developer's **intent** is critical. Tests should verify the code works as designed, not just that functions return values. Search for an implementation plan or design context:

**Search locations (stop at first match):**

1. The user's message — if they mention a plan or link to a document
2. `docs/plans/` directory — glob for `*.md` files; if multiple exist, match by filename similarity to the target code (e.g., if analyzing `auth-service.ts`, look for plans containing "auth" in the name)
3. `~/.claude/plans/` directory — same matching logic
4. PR description — if the code appears to be part of an active branch, check `git log --oneline -5` for commit messages that reference a plan or describe intent
5. Inline comments — look for `// TODO`, `// PLAN:`, `// PURPOSE:`, docstrings, or JSDoc `@description` tags in the target code itself

**If a plan is found:**

Read it and extract:
- **Goal** — What the code is supposed to accomplish
- **Key behaviors** — Expected inputs, outputs, side effects, error handling
- **Edge cases mentioned** — Any cases the author called out
- **Acceptance criteria** — Any defined success conditions

Report to the user: "Found plan: `[path]`. Using it to understand intended behavior."

**If no plan is found:**

Report: "No implementation plan found. I will infer intent from the code itself, commit messages, and surrounding context." This is not an error — proceed to Step 3.

### Step 3 — Analyze the Code

Read the target code and identify the following. Load `references/test-analysis-guide.md` for detailed heuristics on each category.

#### 3a. What the Code Does (Behavioral Summary)

Write a 2-4 sentence summary of the code's purpose and primary behavior. This anchors the entire analysis — every test suggestion in Step 5 must trace back to something identified here.

#### 3b. Critical Paths

Identify the paths through the code that matter most:

- **Happy path** — The primary success flow. What happens when inputs are valid and everything works?
- **Error paths** — How does the code handle failures? Look for try/catch, error returns, validation rejections, fallback behavior.
- **Branching logic** — Conditional paths (`if/else`, `switch`, early returns) that produce different outcomes.
- **State transitions** — Does the code change state in a database, file system, cache, or in-memory store? What triggers each transition?

#### 3c. Integration Points

Where does this code connect to other systems?

- External API calls (HTTP, gRPC, database queries)
- File system operations (read, write, delete)
- Event emissions or message queue interactions
- Calls to other internal modules or services
- Environment variable or configuration dependencies

#### 3d. Implicit Contracts

What does this code promise to its callers that is not enforced by types alone?

- Return value shape beyond type definitions (e.g., "always returns a sorted array")
- Side effects (e.g., "writes to the audit log before returning")
- Ordering guarantees (e.g., "processes items in FIFO order")
- Idempotency expectations
- Thread/concurrency safety assumptions

#### 3e. What Could Break

Identify fragile areas:

- Complex conditionals with multiple predicates
- String manipulation or regex patterns
- Math operations (rounding, overflow, precision)
- Null/undefined propagation chains
- Index arithmetic or off-by-one risk areas
- Hardcoded values that could become stale
- Assumptions about input format or encoding

### Step 4 — Detect Project Test Infrastructure

Before suggesting tests, understand the project's existing patterns so suggestions feel native, not foreign.

#### 4a. Find the Test Framework

Search for test configuration:

- `package.json` — look for `jest`, `vitest`, `mocha`, `ava`, `playwright`, `cypress` in `devDependencies` or `scripts`
- `pytest.ini`, `pyproject.toml`, `setup.cfg` — Python test configuration
- `Cargo.toml` — Rust `[dev-dependencies]` section
- `go.mod` — Go uses built-in `testing` package
- `.github/workflows/` — CI config may reference test commands
- `Makefile` or `justfile` — may define test targets

#### 4b. Find Existing Test Files

Glob for test files near the target code:

- `**/*.test.{ts,tsx,js,jsx}`, `**/*.spec.{ts,tsx,js,jsx}`
- `**/*_test.go`, `**/*_test.py`, `**/test_*.py`
- `tests/`, `__tests__/`, `spec/` directories

#### 4c. Learn Existing Patterns

If test files exist nearby (same directory or in a parallel `__tests__/` directory):

- Read 1-2 existing test files to learn: import style, assertion library, mocking patterns, describe/it nesting conventions, setup/teardown patterns, naming conventions
- Note whether the project uses: factories/fixtures, test databases, mock servers, snapshot testing, parameterized tests

Report the detected framework and patterns to the user: "Detected: [framework]. Existing tests use [patterns]."

If no tests exist at all, note this: "No existing tests found. Suggestions will use [framework] based on project configuration." If no framework is detected either, ask the user which framework they prefer.

### Step 5 — Suggest Tests with Rationale

This is the core output. For each suggestion, explain:
1. **What** to test (specific behavior, not implementation detail)
2. **Why** this test matters (what breaks if this test does not exist)
3. **How** to test it (approach and key assertions, using the project's framework)
4. **Where** to put it (file path following existing conventions)

#### Output Format

When analyzing multiple files, group suggestions **by file** with priorities within each file:

```markdown
## Test Suggestions for `[filename]`

**Plan context:** [Brief note on what the plan says this code should do, or "No plan found — inferred from code"]
**Test framework:** [Detected framework]
**Suggested test file:** `[path/to/suggested.test.ts]`

### Priority 1: Critical Behavior Tests

These verify the code's core purpose — the tests you would write first.

#### Test: [Descriptive test name in sentence form]

**What:** [Specific behavior being tested]
**Why:** [What breaks or goes undetected without this test]
**Code reference:** [File:line or function name this validates]
**Approach:**

```[language]
// Pseudocode or concrete test code using project conventions
```

### Priority 2: Error Handling and Edge Cases

These verify the code fails gracefully.

### Priority 3: Integration Contract Tests

These verify the code works correctly with its dependencies.

### Tests NOT Suggested (and Why)

[List 1-3 tests that might seem obvious but are not valuable here]
```

#### Suggestion Principles

Follow these rules when deciding what to suggest:

1. **Behavior over implementation.** Test what the code does, not how it does it internally. "When given an expired token, returns 401" is good. "Calls `jwt.verify()` once" is bad.

2. **Plan intent over arbitrary coverage.** If the plan says "users must not be able to access other users' data", suggest a test that verifies cross-user data isolation.

3. **One reason to fail per test.** Each suggested test should have exactly one reason to fail.

4. **Name tests as behavior sentences.** "should reject negative quantities in order line items" is good. "test order processing" is bad.

5. **Prioritize by blast radius.** Suggest the tests that catch the most damaging failures first.

6. **Acknowledge existing coverage.** If existing tests already cover a behavior, do not re-suggest it.

7. **Suggest mocking strategy when relevant.** Specify what to mock and why.

8. **Limit suggestions to what matters.** Aim for 5-10 test suggestions for a typical file.

### Step 6 — Offer to Write Test Files

After presenting the suggestions, ask:

> "Would you like me to write the test file(s)? I will create [suggested test file path(s)] with the tests above."

**If the user says yes:**

Write the complete test file(s) using the project's conventions detected in Step 4. Include:
- All Priority 1 and Priority 2 tests
- Priority 3 tests only if the user confirms they want integration tests
- Proper imports, setup, teardown
- Comments referencing the specific code behavior each test validates

After writing, suggest: "Run `[test command]` to verify the tests pass."

**If the user says no or wants to write them manually:**

Respond: "The suggestions above should give you a clear starting point. Let me know if you want to discuss any of them in more detail."

**If the user asks to write only specific tests:**

Write only the requested subset. Do not add unrequested tests.

---

Arguments: $ARGUMENTS
