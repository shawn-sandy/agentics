---
description: Review existing tests for quality, coverage gaps, and alignment with code behavior
argument-hint: [test-file-path] - path to test file(s) to review; omit to find tests near recent changes
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Write, Edit, TodoWrite
---

# /code-test-suggestion:review-tests

Review existing tests against the source code they cover. Identify quality issues, coverage gaps, and misalignment with developer intent. Every finding is tied to a specific test and explains why it matters.

## Usage

```
/code-test-suggestion:review-tests src/services/__tests__/auth.test.ts    # review specific test file
/code-test-suggestion:review-tests src/services/                           # find and review tests in directory
/code-test-suggestion:review-tests                                         # find tests near recent changes
```

## Instructions

### Step 0 — Create progress todos

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

### Step 1 — Identify Target Tests

Determine which test files to review using this priority order:

1. **Explicit argument**: If `$ARGUMENTS` is provided, treat it as the test file path and read it directly. If it's a directory, glob for test files (`**/*.test.*`, `**/*.spec.*`, `**/test_*`, `**/*_test.*`) and present the list for confirmation.
2. **Tests near recent changes** — Run `git diff --name-only HEAD~1` to find recently changed files. For each changed source file, glob for matching test files. Present the list and ask the user to confirm.
3. **Ask if unclear** — "Which test files would you like me to review? Please provide a file path."

Once resolved, tell the user which test file(s) will be reviewed before proceeding.

Read each target test file in full.

### Step 2 — Locate Source Code Under Test

For each test file, find the implementation code it covers:

1. **Imports** — Read the test file's import statements. The primary import target is usually the source file under test.
2. **Naming convention** — If the test is `auth.test.ts`, look for `auth.ts` in the same directory or a parent `src/` directory.
3. **Directory structure** — If tests are in `__tests__/` or `tests/`, the source is usually in a parallel `src/` or project root directory.
4. **Ask if ambiguous** — If the source file cannot be determined, ask: "Which source file does `[test-file]` test?"

Read each source file in full. Tell the user: "Reviewing tests in `[test-file]` against source code in `[source-file]`."

### Step 3 — Search for Implementation Plan

Understanding the developer's **intent** is critical. Search for an implementation plan or design context:

**Search locations (stop at first match):**

1. The user's message — if they mention a plan or link to a document
2. `docs/plans/` directory — glob for `*.md` files; match by filename similarity to the source code
3. `~/.claude/plans/` directory — same matching logic
4. PR description — check `git log --oneline -5` for commit messages that reference a plan
5. Inline comments — look for `// TODO`, `// PLAN:`, `// PURPOSE:`, docstrings in the source code

**If a plan is found:**

Read it and extract: Goal, Key behaviors, Edge cases mentioned, Acceptance criteria.

Report to the user: "Found plan: `[path]`. Using it to evaluate test alignment with intended behavior."

**If no plan is found:**

Report: "No implementation plan found. I will evaluate tests against behavior inferred from the source code."

### Step 4 — Analyze Source Code

Read the source code and identify the following. Load `references/test-analysis-guide.md` (from the sibling `code-test-suggestion` skill directory) for detailed heuristics.

#### 4a. What the Code Does (Behavioral Summary)

Write a 2-4 sentence summary of the code's purpose and primary behavior.

#### 4b. Critical Paths

- **Happy path** — The primary success flow.
- **Error paths** — Failure handling: try/catch, error returns, validation rejections.
- **Branching logic** — Conditional paths producing different outcomes.
- **State transitions** — State changes in database, file system, cache.

#### 4c. Integration Points

- External API calls, file system operations, event emissions, internal module calls, configuration dependencies.

#### 4d. Implicit Contracts

- Return value shape beyond types, side effects, ordering guarantees, idempotency, concurrency assumptions.

#### 4e. What Could Break

- Complex conditionals, string/regex manipulation, math operations, null propagation, index arithmetic, hardcoded values, input format assumptions.

### Step 5 — Detect Test Infrastructure & Coverage Target

#### 5a. Find the Test Framework

Search for test configuration in: `package.json`, `pytest.ini`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `.github/workflows/`, `Makefile`.

#### 5b. Detect Coverage Target

Search for coverage thresholds in: `jest.config.*`, `package.json` (`coverageThreshold`), `pyproject.toml` (`fail_under`), `.nycrc`, `codecov.yml`, `.coveragerc`, CI config.

Report the detected target or: "No coverage target configured."

### Step 6 — Review Existing Tests

This is the core output. Load `references/test-quality-checklist.md` for detailed heuristics on each review dimension.

Read every test in the target file(s) and evaluate against the source code analysis from Step 4.

#### Review Dimensions

Evaluate each test across these 9 dimensions:

1. **Behavior vs Implementation** — Flag tests that would break on refactor without behavior change.
2. **Test Naming** — Flag vague names like "test1", "it works".
3. **Assertion Focus** — Flag tests with 5+ assertions testing different behaviors.
4. **Coverage Gaps** — Cross-reference source analysis against what tests cover.
5. **Mock Hygiene** — Flag over-mocking, under-mocking, stale mocks.
6. **Test Fragility** — Flag timing-dependent, order-dependent, or environment-dependent tests.
7. **Setup/Teardown Isolation** — Flag shared state leaking between tests.
8. **Plan Alignment** — Check tests against plan requirements.
9. **Coverage Target Progress** — Evaluate how tests contribute to the coverage target.

#### Output Format

```markdown
## Test Review for `[test-filename]`

**Source code:** `[source-file]`
**Plan context:** [Brief note or "No plan found"]
**Test framework:** [Detected framework]

### Summary

[2-3 sentence overview]

### Critical Issues

#### Issue: [Descriptive name]

**Test:** `[test name]` (line [N])
**Problem:** [What's wrong]
**Impact:** [Why this matters]
**Fix:**

```[language]
// Before → After
```

### Improvements

[Same format as Critical Issues]

### Coverage Gaps

| Untested Behavior | Source Reference | Priority | Why It Matters |
|-------------------|-----------------|----------|----------------|
| [behavior] | [file:line] | P1/P2/P3 | [what breaks undetected] |

**Coverage target:** [X]% | No target configured
**Estimated current gap:** [qualitative assessment]

### What's Working Well

[1-3 things the tests do right]
```

#### Review Principles

1. **Behavior over implementation.** Flag tests that assert on internal calls rather than outcomes.
2. **Plan intent drives review, coverage validates completeness.** Check tests against plan requirements and coverage target.
3. **One reason to fail per test.** Flag multi-assertion tests that conflate behaviors.
4. **Name tests as behavior sentences.** Flag vague or generic test names.
5. **Prioritize by blast radius.** Focus on tests guarding the most critical code paths.
6. **Acknowledge what's covered.** Credit tests that work well.
7. **Evaluate mocking strategy.** Flag over-mocking, under-mocking, stale mocks.
8. **Coverage gaps over trivial style issues.** Missing tests for critical paths matter more than naming conventions.

### Step 7 — Offer to Apply Fixes

After presenting the review, ask:

> "Would you like me to apply the fixes? I can update the test file(s) to address the critical issues and improvements above."

**If the user says yes:**

Apply fixes to the test file(s). Include:
- All critical issue fixes
- Improvement fixes if confirmed
- New tests for P1 coverage gaps (ask before P2/P3)
- Updated test names where flagged

After applying, suggest: "Run `[test command]` to verify the updated tests pass."

**If the user says no:**

Respond: "The review above should guide your improvements. Let me know if you want to discuss any finding in more detail."

**If the user asks to fix only specific issues:**

Apply only the requested fixes.

---

Arguments: $ARGUMENTS
