---
name: reviewing-tests
description: "Audits tests for quality, coverage, and code alignment. Identifies gaps, redundant tests, and misaligned assertions. Use when the user asks to review, audit, or improve a test suite."
allowed-tools: AskUserQuestion, Bash, Edit, Glob, Read, TodoWrite, Write
---

Review existing tests against the source code they cover. Identify quality issues, coverage gaps, and misalignment with developer intent. Every finding is tied to a specific test and explains why it matters.

> **Freedom level: Flexible** — Follow these steps in order. Adapt depth to the test suite's size and the user's request.

## When not to use

Does not run the project's existing suites — use running-tests; Step 7 does execute the test file(s) it edits, to verify its own fixes. Does not suggest broad new test suites — use code-testing-agent. It may suggest targeted new P1 tests to cover critical gaps as described in Step 7.

## Table of Contents

- [Step 0 — Create Progress Todos](#step-0--create-progress-todos)
- [Step 1 — Identify Target Tests](#step-1--identify-target-tests)
- [Step 2 — Locate Source Code Under Test](#step-2--locate-source-code-under-test)
- [Step 3 — Search for Implementation Plan](#step-3--search-for-implementation-plan)
- [Step 4 — Analyze Source Code](#step-4--analyze-source-code)
- [Step 5 — Detect Test Infrastructure & Coverage Target](#step-5--detect-test-infrastructure--coverage-target)
- [Step 6 — Review Existing Tests](#step-6--review-existing-tests)
- [Step 7 — Offer to Apply Fixes](#step-7--offer-to-apply-fixes)

---

## Step 0 — Create Progress Todos

Before doing any other work, use `TodoWrite` to create todos for each step. This gives the user visibility into progress.

Create the following todos (all starting with `status: "pending"`):

- Step 1: Identify target test files
- Step 2: Locate source code under test
- Step 3: Search for implementation plan or design context
- Step 4: Analyze source code behavior and critical paths
- Step 5: Detect test framework, patterns, and coverage target
- Step 6: Review existing tests against source analysis
- Step 7: Offer to apply fixes

Mark each todo `status: "completed"` as you finish that step.

---

## Step 1 — Identify Target Tests

Determine which test files to review using this priority order:

1. **Explicit path in message** — If the user provided a test file path, use it directly.
2. **Conversation context** — If a test file was recently created, edited, or discussed, use that.
3. **Tests near recent changes** — Run `git diff --name-only HEAD~1` to find recently changed files. For each changed source file, glob for matching test files:
   - `[name].test.{ts,tsx,js,jsx}`, `[name].spec.{ts,tsx,js,jsx}`
   - `test_[name].py`, `[name]_test.py`, `[name]_test.go`
   - Check `__tests__/`, `tests/`, `spec/` directories
   Present the list and ask the user to confirm which test files to review.
4. **Ask if unclear** — "Which test files would you like me to review? Please provide a file path."

Once resolved, tell the user which test file(s) will be reviewed before proceeding.

Read each target test file in full.

---

## Step 2 — Locate Source Code Under Test

For each test file, find the implementation code it covers:

1. **Imports** — Read the test file's import statements. The primary import target is usually the source file under test.
2. **Naming convention** — If the test is `auth.test.ts`, look for `auth.ts` in the same directory or a parent `src/` directory.
3. **Directory structure** — If tests are in `__tests__/` or `tests/`, the source is usually in a parallel `src/` or project root directory.
4. **Ask if ambiguous** — If the source file cannot be determined, ask: "Which source file does `[test-file]` test?"

Read each source file in full. Tell the user: "Reviewing tests in `[test-file]` against source code in `[source-file]`."

---

## Step 3 — Search for Implementation Plan

Understanding the developer's **intent** is critical. Tests should verify the code works as designed. Search for an implementation plan or design context:

**Search locations (stop at first match):**

1. The user's message — if they mention a plan or link to a document
2. `docs/plans/` directory — glob for `*.md` files; if multiple exist, match by filename similarity to the source code (e.g., if reviewing tests for `auth-service.ts`, look for plans containing "auth" in the name)
3. `~/.claude/plans/` directory — same matching logic
4. PR description — if the code appears to be part of an active branch, check `git log --oneline -5` for commit messages that reference a plan or describe intent
5. Inline comments — look for `// TODO`, `// PLAN:`, `// PURPOSE:`, docstrings, or JSDoc `@description` tags in the source code itself

**If a plan is found:**

Read it and extract:
- **Goal** — What the code is supposed to accomplish
- **Key behaviors** — Expected inputs, outputs, side effects, error handling
- **Edge cases mentioned** — Any cases the author called out
- **Acceptance criteria** — Any defined success conditions

Report to the user: "Found plan: `[path]`. Using it to evaluate test alignment with intended behavior."

**If no plan is found:**

Report: "No implementation plan found. I will evaluate tests against behavior inferred from the source code." This is not an error — proceed to Step 4.

---

## Step 4 — Analyze Source Code

Read the source code and identify the following.

### 4a. What the Code Does (Behavioral Summary)

Write a 2-4 sentence summary of the code's purpose and primary behavior. This anchors the review — every coverage gap in Step 6 traces back to something identified here.

### 4b. Critical Paths

Identify the paths through the code that matter most:

- **Happy path** — The primary success flow.
- **Error paths** — How the code handles failures: try/catch, error returns, validation rejections, fallback behavior.
- **Branching logic** — Conditional paths (`if/else`, `switch`, early returns) that produce different outcomes.
- **State transitions** — State changes in database, file system, cache, or in-memory store.

### 4c. Integration Points

Where does this code connect to other systems?

- External API calls (HTTP, gRPC, database queries)
- File system operations (read, write, delete)
- Event emissions or message queue interactions
- Calls to other internal modules or services
- Environment variable or configuration dependencies

### 4d. Implicit Contracts

What does this code promise to its callers that is not enforced by types alone?

- Return value shape beyond type definitions
- Side effects
- Ordering guarantees
- Idempotency expectations
- Thread/concurrency safety assumptions

### 4e. What Could Break

Identify fragile areas:

- Complex conditionals with multiple predicates
- String manipulation or regex patterns
- Math operations (rounding, overflow, precision)
- Null/undefined propagation chains
- Index arithmetic or off-by-one risk areas
- Hardcoded values that could become stale
- Assumptions about input format or encoding

---

## Step 5 — Detect Test Infrastructure & Coverage Target

### 5a. Find the Test Framework

Search for test configuration:

- `package.json` — look for `jest`, `vitest`, `mocha`, `ava`, `playwright`, `cypress` in `devDependencies` or `scripts`
- `pytest.ini`, `pyproject.toml`, `setup.cfg` — Python test configuration
- `Cargo.toml` — Rust `[dev-dependencies]` section
- `go.mod` — Go uses built-in `testing` package
- `.github/workflows/` — CI config may reference test commands
- `Makefile` or `justfile` — may define test targets

### 5b. Detect Coverage Target

Search for coverage thresholds in project configuration:

- `jest.config.*` or `package.json` — look for `coverageThreshold`
- `pyproject.toml` — look for `[tool.coverage.report]` with `fail_under`
- `.nycrc` or `.nycrc.json` — look for `check-coverage` and threshold values
- `codecov.yml` — look for `coverage.status.project.default.target`
- `.coveragerc` — look for `[report]` with `fail_under`
- `.github/workflows/` or CI config — look for coverage enforcement flags

Report the detected target: "Coverage target: [X]% (from [config file])."

If no target is found: "No coverage target configured. Will evaluate coverage completeness against all identified code paths."

---

## Step 6 — Review Existing Tests

This is the core output. Load `references/test-quality-checklist.md` for detailed heuristics on each review dimension. If the file is unavailable, apply the nine review dimensions using the criteria defined in the Review Dimensions list below.

Read every test in the target file(s) and evaluate against the source code analysis from Step 4. For each finding, reference the specific test by name and line number.

### Review Dimensions

Evaluate each test across these 9 dimensions:

1. **Behavior vs Implementation** — Does the test verify what the code does or how it does it? Flag tests that would break on refactor without behavior change.
2. **Test Naming** — Are tests named as behavior sentences? Flag vague names like "test1", "testFunction", "it works".
3. **Assertion Focus** — Does each test have one reason to fail? Flag tests with 5+ assertions testing different behaviors.
4. **Coverage Gaps** — Cross-reference source code analysis (Step 4) against what the tests actually cover. Identify critical paths, error paths, and edge cases with no test.
5. **Mock Hygiene** — Are mocks appropriate? Flag over-mocking (mocking internals of the system under test), under-mocking (real calls to external services), stale mocks (mock behavior doesn't match current API). A stale-mock finding must quote both sides as evidence: the mock's return shape or signature **and** the current real signature from the source it stands in for. No paired quotes, no finding.
6. **Test Fragility** — Will the test break if implementation changes but behavior stays the same? Flag: testing internal method calls, asserting on specific log messages, snapshot tests of unstable output.
7. **Setup/Teardown Isolation** — Is shared state leaking between tests? Flag: missing cleanup, global variable mutation, database state not reset.
8. **Plan Alignment** — If a plan exists, do the tests verify the plan's key behaviors, edge cases, and acceptance criteria? List plan requirements with no corresponding test.
9. **Coverage Target Progress** — How do existing tests compare to the project's coverage target? List functions/branches that are uncovered and contribute to the gap.

### Output Format

When reviewing multiple test files, group findings **by test file**:

~~~markdown
## Test Review for `[test-filename]`

**Source code:** `[source-file]`
**Plan context:** [Brief note or "No plan found — evaluating against inferred behavior"]
**Test framework:** [Detected framework]

### Summary

[2-3 sentence overview: how many tests, what they cover well, where the biggest gaps are]

### Critical Issues

Issues that make tests unreliable, misleading, or actively harmful.

#### Issue: [Descriptive name]

**Test:** `[test name or describe block]` (line [N])
**Problem:** [What's wrong]
**Impact:** [Why this matters — false confidence, missed bugs, CI noise]
**Fix:**

```[language]
// Before → After, or concrete replacement code
```

[Repeat for each critical issue]

### Improvements

Non-critical issues that would make tests more valuable or maintainable.

[Same format as Critical Issues]

### Coverage Gaps

Behaviors identified in the source code analysis (Step 4) that have no corresponding test.

| Untested Behavior | Source Reference | Priority | Why It Matters |
|-------------------|-----------------|----------|----------------|
| [behavior] | [file:line] | P1/P2/P3 | [what breaks undetected] |

**Coverage target:** [X]% | No target configured
**Estimated current gap:** [qualitative: "3 of 8 exported functions have no test"]

### What's Working Well

[1-3 things the tests do right — reinforce good practices]
~~~

### Review Principles

Follow these rules when evaluating tests:

1. **Behavior over implementation.** Flag tests that assert on internal method calls rather than outcomes. "When given an expired token, returns 401" is good. "Calls `jwt.verify()` once" is bad — it breaks on refactor.

2. **Plan intent drives review, coverage validates completeness.** Check tests against plan requirements. Use coverage analysis to verify nothing important is missed. If the project defines a coverage target, evaluate how existing tests contribute to or fall short of it.

3. **One reason to fail per test.** Flag tests with multiple unrelated assertions. A test that checks login success, email format, and database write is three tests.

4. **Name tests as behavior sentences.** Flag vague test names. "should reject negative quantities in order line items" is good. "test order processing" is bad.

5. **Prioritize by blast radius.** Focus review attention on tests that guard the most critical code paths first. A missing test for an auth bypass matters more than a poorly named test for a tooltip.

6. **Acknowledge what's covered.** Credit existing tests that work well. Not every test needs improvement.

7. **Evaluate mocking strategy.** Flag over-mocking (mocking the thing you're testing), under-mocking (real HTTP calls in unit tests), and stale mocks (mock returns data in a format the real API no longer uses).

8. **Coverage gaps over trivial style issues.** Missing tests for critical paths matter more than test naming conventions. Prioritize findings that would actually catch bugs over aesthetic preferences.

---

## Step 7 — Offer to Apply Fixes

After presenting the review, ask:

> "Would you like me to apply the fixes? I can update the test file(s) to address the critical issues and improvements above."

**If the user says yes:**

Apply fixes to the test file(s) using the project's conventions. Include:
- All critical issue fixes
- Improvement fixes if the user confirms
- New tests for P1 coverage gaps (ask before adding P2/P3)
- Updated test names where flagged
- Proper cleanup for isolation issues

**Then verify the edits — applying fixes is not done.** Done means the edits are applied **and** the runner has executed them. Run the edited test file(s) via `Bash` using the framework detected in Step 5, scoped to only the file(s) touched (e.g. `[test command] [edited-test-file]`), and interpret the results:

- **All green** — report: "Applied [N] fixes. Ran `[test command]`: [X] passed." Include the runner's output.
- **Collection errors, or previously-passing tests now failing** — the edits broke the suite. Fix and re-run — max 3 iterations. Still broken at iteration 3 is a hard stop: revert the breaking edit(s), re-run to confirm the suite is back to its pre-review state, and report which fixes were reverted and why — do not claim success.
- **A new P1 gap test failing against the current source** — that is the coverage gap being confirmed: a finding, not a defect. Report it as such — never weaken the test to force a pass.

**If the user says no or wants to fix manually:**

Respond: "The review above should guide your improvements. Let me know if you want to discuss any finding in more detail."

**If the user asks to fix only specific issues:**

Apply only the requested fixes. Do not add unrequested changes.
