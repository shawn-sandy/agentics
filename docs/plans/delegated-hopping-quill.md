# Plan: Add `test-review` Skill to `code-test-suggestion` Plugin

## Context

The `code-test-suggestion` plugin currently has one skill (suggest new tests) and one command. The user wants a companion skill that reviews *existing* tests using the same analysis parameters and principles, then recommends improvements.

**Key difference**: `code-test-suggestion` answers "what tests should I write?" while `test-review` answers "how good are my existing tests and how can I improve them?"

## What Changes

### New Files (3)

1. **`plugins/code-test-suggestion/skills/test-review/SKILL.md`** — core skill
2. **`plugins/code-test-suggestion/skills/test-review/references/test-quality-checklist.md`** — progressive disclosure reference for review dimensions
3. **`plugins/code-test-suggestion/commands/review-tests.md`** — explicit command with full workflow

### Modified Files (4)

4. **`plugins/code-test-suggestion/.claude-plugin/plugin.json`** — bump to 1.1.0, add `test-review` keyword
5. **`.claude-plugin/marketplace.json`** — bump version to 1.1.0
6. **`plugins/code-test-suggestion/README.md`** — add test-review skill docs
7. **`plugins/code-test-suggestion/CHANGELOG.md`** — add 1.1.0 entry

## Skill Design: `test-review`

### Activation Triggers (Non-Overlapping)

```
description: Reviews existing tests for quality, coverage gaps, and alignment with code behavior
and developer intent. Use when the user asks to review tests, audit test quality, check test
coverage, improve tests, or asks "are my tests good". Also use when the user says "review these
tests", "audit my test suite", "what's wrong with my tests", or "how can I improve my tests".
Does not suggest new tests from scratch — reviews and improves what already exists. Not a code
quality review or a test runner.
```

**Boundary with other skills:**
| Phrase | Activates |
|--------|-----------|
| "suggest tests for this code" | `code-test-suggestion` |
| "review my tests" | `test-review` |
| "review this code" | `code-review` |

### Workflow (7 steps)

| Step | Purpose |
|------|---------|
| **Step 0** | Create `TodoWrite` progress todos |
| **Step 1 — Identify Target Tests** | Find existing test files: explicit path → conversation context → glob for test files near recent changes → ask user |
| **Step 2 — Locate Source Code Under Test** | Find the implementation files those tests cover (infer from imports, naming conventions, directory structure) |
| **Step 3 — Search for Implementation Plan** | Same as code-test-suggestion Step 2 — search docs/plans/, ~/.claude/plans/, commit messages, inline comments |
| **Step 4 — Analyze Source Code** | Same 5 dimensions as code-test-suggestion Step 3 — behavioral summary, critical paths, integration points, implicit contracts, fragility areas. Loads shared `../code-test-suggestion/references/test-analysis-guide.md` |
| **Step 5 — Detect Test Infrastructure & Coverage Target** | Same as code-test-suggestion Step 4 (4a-4d) — framework, existing patterns, coverage target |
| **Step 6 — Review Existing Tests** | Core output: evaluate each test against the source code analysis and review principles. Load `references/test-quality-checklist.md` for detailed review dimensions |
| **Step 7 — Offer to Apply Fixes** | Ask user if they want improvements applied to the test files |

### Step 6 Review Dimensions (from `test-quality-checklist.md`)

1. **Behavior vs Implementation** — Does the test verify what the code does or how it does it? Flag tests that would break on refactor without behavior change.
2. **Test Naming** — Are tests named as behavior sentences? Flag vague names like "test1", "testFunction", "it works".
3. **Assertion Focus** — Does each test have one reason to fail? Flag tests with 5+ assertions testing different behaviors.
4. **Coverage Gaps** — Cross-reference source code analysis (Step 4) against what the tests actually cover. Identify critical paths, error paths, and edge cases with no test.
5. **Mock Hygiene** — Are mocks appropriate? Flag over-mocking (mocking internals of the system under test), under-mocking (real calls to external services), stale mocks (mock behavior doesn't match current API).
6. **Test Fragility** — Will the test break if implementation changes but behavior stays the same? Flag: testing internal method calls, asserting on specific log messages, snapshot tests of unstable output.
7. **Setup/Teardown Isolation** — Is shared state leaking between tests? Flag: missing cleanup, global variable mutation, database state not reset.
8. **Plan Alignment** — If a plan exists, do the tests verify the plan's key behaviors, edge cases, and acceptance criteria? List plan requirements with no corresponding test.
9. **Coverage Target Progress** — How do existing tests compare to the project's coverage target? List functions/branches that are uncovered and contribute to the gap.

### Step 6 Output Format

```markdown
## Test Review for `[test-filename]`

**Source code:** `[source-file]`
**Plan context:** [Brief note or "No plan found"]
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
```

### Review Principles (Shared from code-test-suggestion)

The same 8 principles from code-test-suggestion, adapted for review context:

1. **Behavior over implementation** — Flag tests that assert on internal calls rather than outcomes
2. **Plan intent drives review, coverage validates completeness** — Check tests against plan requirements, verify coverage target progress
3. **One reason to fail per test** — Flag multi-assertion tests that conflate different behaviors
4. **Name tests as behavior sentences** — Flag vague or generic test names
5. **Prioritize by blast radius** — Focus review on tests that guard the most critical code paths
6. **Acknowledge what's covered** — Credit existing tests that already work well
7. **Evaluate mocking strategy** — Flag over-mocking, under-mocking, and stale mocks
8. **Coverage gaps over trivial style issues** — Missing tests for critical paths matter more than naming conventions

## Reference File: `test-quality-checklist.md`

Progressive disclosure reference loaded during Step 6. Contains detailed heuristics for each of the 9 review dimensions listed above, with language-specific patterns (same languages as test-analysis-guide.md: TS/JS, Python, Go, Rust).

Includes specific anti-patterns to flag:
- Implementation coupling patterns (e.g., `expect(spy).toHaveBeenCalledWith(...)` on internal methods)
- Snapshot test fragility signals
- Test order dependency signs
- Shared mutable state patterns
- Assertion-free tests ("tests that can never fail")
- Hardcoded values that should be parameterized

## Version Bump

This is a MINOR version bump (1.0.0 → 1.1.0): new skill added, backward compatible.

- `plugins/code-test-suggestion/.claude-plugin/plugin.json`: version → "1.1.0"
- `.claude-plugin/marketplace.json`: code-test-suggestion entry version → "1.1.0"

## Command: `review-tests.md`

Same pattern as `suggest-tests.md` — full 7-step workflow duplicated with `$ARGUMENTS` for explicit test file paths.

```markdown
---
description: Review existing tests for quality, coverage gaps, and alignment with code behavior
argument-hint: [test-file-path] - path to test file(s) to review; omit to find tests near recent changes
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Write, Edit, TodoWrite
---
```
