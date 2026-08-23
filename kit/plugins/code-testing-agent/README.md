# code-testing-agent Plugin

Analyze code and suggest specific, purpose-driven tests tied to actual behavior and intent. This plugin does not generate arbitrary unit tests for coverage metrics — it identifies what tests would be genuinely valuable and explains why each one matters.

## Installation

### Via Marketplace (recommended)

```bash
/plugin install code-testing-agent@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ./kit/plugins/code-testing-agent
```

## Usage

### Skills

All skills declare `allowed-tools` explicitly in their frontmatter for consistent, session-independent tool access.

| Skill | Activation | Trigger phrases |
|-------|-----------|----------------|
| `code-testing-agent` | Auto | "suggest tests", "what tests should I write", "test this code", "find untested behavior" |
| `reviewing-tests` | Auto | "review my tests", "audit test quality", "improve my tests", "are my tests good" |
| `running-tests` | Auto | "run tests", "check if tests pass", "verify changes" |
| `tdd-fix` | Manual invoke only | `/code-testing-agent:tdd-fix` |
| `tdd-loop` | Manual invoke only | `/code-testing-agent:tdd-loop` |
| `verified-change` | Auto | "prove this is merge-ready", "verify my change locally", "run the merge gate" |

#### code-testing-agent — suggest new tests

Auto-activated. Describe what you want — the skill parses file paths and function names directly from your message:

```
Suggest tests for `src/services/auth.ts`
Suggest tests for the `validateToken` function in `src/services/auth.ts`
What tests should I write for this function?
Help me test the checkout flow
What would you test in this code?
Review this module for testability
```

With a specific function scope:

```
Test the `parseJWT` method in src/utils/token.ts
Suggest tests for the `render` function in src/components/Button.tsx
```

With a plan:

```
Suggest tests for src/services/auth.ts based on docs/plans/auth-refactor.md
I just implemented the plan in ~/.claude/plans/checkout-flow.md — what tests do I need?
```

For recent changes:

```
Suggest tests for my recent changes
What should I test in my current branch?
```

#### reviewing-tests — review existing tests

Auto-activated. Reviews test files for quality, coverage, and alignment with source behavior:

```
Review my tests for src/services/auth.test.ts
Are my tests good?
Audit my test suite
What's wrong with my tests?
How can I improve these tests?
```

#### running-tests — run tests and report results

Auto-activated. Detects the test framework, runs tests scoped to the target, and reports pass/fail:

```
Run tests for src/services/auth.ts
Check if tests pass
Run my tests and show me what's failing
Verify my changes didn't break anything
```

#### tdd-fix — fix a bug via TDD

Manual invoke only — use `/code-testing-agent:tdd-fix` explicitly.

Writes a failing test that captures the bug, then iterates (up to 10 red-green cycles) until the bug is resolved:

```
/code-testing-agent:tdd-fix the login redirect bug in src/services/auth.ts
/code-testing-agent:tdd-fix null pointer when user has no email
```

#### tdd-loop — implement a feature via TDD

Manual invoke only — use `/code-testing-agent:tdd-loop` explicitly.

Writes failing tests first, then iterates (up to 20 red-green-refactor rounds) until all tests pass:

```
/code-testing-agent:tdd-loop add rate limiting to the API client
/code-testing-agent:tdd-loop implement the password reset flow in src/auth/
```

#### verified-change — change working code under a local merge gate

Auto-activates on "prove this is merge-ready", "verify my change locally", "run the merge gate".

For code that already works, where a test written after the fact can pass for the wrong reason. Writes the assertion first, breaks the implementation on purpose to prove the assertion can fail, restores under a `trap` with a `cmp -s` proof, implements, then loops on `scripts/verify.sh` up to 8 times before stopping and reporting what it ruled out.

Use `tdd-loop` instead for a brand-new feature — red is free there and needs no mutation.

Install the gate into any repo with the bundled wrapper, run from the repo root:

```
install-verify-gate
```

It writes `scripts/verify.sh` and refuses to overwrite an existing one without `--force`. The gate runs typecheck, lint, unit, then e2e, detecting each stage's tooling in the directory it was invoked from and printing either a real result or `SKIP (not configured)`. It stops at the first failure.

The gate executes whatever tooling the target repo declares, so run it only in repos you already trust.

## Purpose

Developers often face two problems with testing: either they write tests after the fact that verify implementation details rather than behavior, or they rely on coverage tools to tell them what to test — which leads to many tests that catch nothing useful and few tests that catch real bugs. This plugin takes a different approach: it reads the code, looks for the developer's plan or intent, identifies critical behaviors and fragile areas, and suggests the specific tests that would catch the most damaging failures. At the same time, it ensures suggested tests would meet the project's coverage target — or maximize coverage when no target is defined — so you get both meaningful and thorough test suites.

## How It Differs from code-review

The `code-review` plugin reviews code for quality, bugs, security, and best practices — it tells you what is wrong with your code. The `code-testing-agent` plugin tells you how to prove your code works correctly — it designs a test strategy based on what the code does and what the developer intended.

## What the Skills Do

### code-testing-agent (suggest new tests)

1. Identifies target code — parses your message for a file path and optional function/method name; falls back to conversation context or recent git changes if none provided
2. Searches for an implementation plan to understand your intent
3. Analyzes the code: behavioral summary, critical paths, integration points, implicit contracts, fragility areas
4. Detects your project's test framework and existing test patterns
5. Suggests prioritized tests with rationale — each referencing specific code it validates
6. Offers to write the test file(s) using your project's conventions

## Output Structure

Suggestions are organized by file, then by priority within each file:

- **Priority 1: Critical Behavior Tests** — Verify the code's core purpose. Write these first.
- **Priority 2: Error Handling and Edge Cases** — Verify graceful failure.
- **Priority 3: Integration Contract Tests** — Verify correct interaction with dependencies.
- **Priority 4: Coverage-Only Tests** — Trivial code tests tagged `[coverage-only]`, included only when needed to meet the project's coverage target.
- **Coverage Assessment** — Lists covered functions and uncovered gaps (qualitative, not a guessed percentage).
- **Tests NOT Suggested** — Explains why certain obvious-seeming tests would be low-value.

Each suggestion includes: what behavior to test, why the test matters, the code it validates, and a concrete test approach using your framework.

### reviewing-tests (review existing tests)

1. Identifies target test files (from your message, conversation context, or near recent changes)
2. Locates the source code those tests cover (from imports, naming conventions, directory structure)
3. Searches for an implementation plan to understand intended behavior
4. Analyzes the source code across 5 dimensions (same as code-testing-agent)
5. Detects test framework and coverage target
6. Reviews each test against the source analysis across 9 dimensions: behavior vs implementation, naming, assertion focus, coverage gaps, mock hygiene, fragility, isolation, plan alignment, coverage target progress
7. Offers to apply fixes to the test files

### reviewing-tests Output Structure

Reviews are organized by test file:

- **Summary** — Overview of test count, strengths, and biggest gaps.
- **Critical Issues** — Tests that are unreliable, misleading, or harmful. Each with test name, line number, problem, impact, and concrete fix.
- **Improvements** — Non-critical issues that would make tests more valuable.
- **Coverage Gaps** — Behaviors from the source code analysis with no corresponding test, ranked by priority.
- **What's Working Well** — Things the tests do right.

### running-tests (run tests and report results)

1. Detects the test framework from project config (`package.json`, `pytest.ini`, `Cargo.toml`, etc.)
2. Scopes the test run to the target file or directory specified in your message
3. Runs the tests and captures output
4. Reports pass/fail results, highlights failing assertions, and surfaces error messages

### tdd-fix (bug fix via TDD)

1. Reads the bug description and locates the relevant source file
2. Writes a minimal failing test that reproduces the bug (red)
3. Applies the smallest fix that makes the test pass (green)
4. Repeats up to 10 iterations if the fix introduces new failures
5. Stops and reports when all tests pass or the iteration limit is reached

### tdd-loop (feature implementation via TDD)

1. Reads the feature description and scopes the implementation target
2. Writes a set of failing tests that define the expected behavior (red)
3. Implements the feature incrementally to pass each test (green)
4. Refactors after each passing cycle without breaking tests (refactor)
5. Repeats up to 20 red-green-refactor rounds until all tests pass

### verified-change (change working code with proof)

1. Runs the gate once before anything changes, so a pre-existing failure is not mistaken for a new one
2. Writes the regression assertion before touching the implementation
3. Mutates the implementation on purpose and confirms the assertion goes red
4. Restores from a scratchpad copy under a `trap` and proves it with `cmp -s`
5. Implements the change, then loops on `scripts/verify.sh` (max 8 attempts)
6. Browser-verifies rendered changes at 390px and 1280px, both themes, with an axe run
7. Emits a VERIFICATION section recording what was actually run

## Plugin Structure

```
plugins/code-testing-agent/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── code-testing-agent/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── test-analysis-guide.md
│   ├── reviewing-tests/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── test-quality-checklist.md
│   ├── running-tests/
│   │   └── SKILL.md
│   ├── tdd-fix/
│   │   └── SKILL.md
│   ├── tdd-loop/
│   │   └── SKILL.md
│   └── verified-change/
│       ├── SKILL.md
│       ├── assets/
│       │   ├── install-verify-gate.sh
│       │   └── verify.sh
│       └── references/
│           ├── mutation-check.md
│           └── verification-section.md
├── bin/
│   └── install-verify-gate
├── README.md
└── CHANGELOG.md
```
