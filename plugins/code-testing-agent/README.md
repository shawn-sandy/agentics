# code-testing-agent Plugin

Analyze code and suggest specific, purpose-driven tests tied to actual behavior and intent. This plugin does not generate arbitrary unit tests for coverage metrics — it identifies what tests would be genuinely valuable and explains why each one matters.

## Purpose

Developers often face two problems with testing: either they write tests after the fact that verify implementation details rather than behavior, or they rely on coverage tools to tell them what to test — which leads to many tests that catch nothing useful and few tests that catch real bugs. This plugin takes a different approach: it reads the code, looks for the developer's plan or intent, identifies critical behaviors and fragile areas, and suggests the specific tests that would catch the most damaging failures. At the same time, it ensures suggested tests would meet the project's coverage target — or maximize coverage when no target is defined — so you get both meaningful and thorough test suites.

## How It Differs from code-review

The `code-review` plugin reviews code for quality, bugs, security, and best practices — it tells you what is wrong with your code. The `code-testing-agent` plugin tells you how to prove your code works correctly — it designs a test strategy based on what the code does and what the developer intended.

## Components

| Component | Type | Activation |
|-----------|------|-----------|
| `code-testing-agent` | Skill | Auto-triggers when user asks to "suggest tests", "what tests should I write", "test this code", "review testability", or "find untested behavior" |
| `reviewing-tests` | Skill | Auto-triggers when user asks to "review my tests", "audit test quality", "improve my tests", "are my tests good", or "what's wrong with my tests" |

## Usage

### Suggest tests (skill)

Describe what you want — the skill parses file paths and function names directly from your message:

```
Suggest tests for `src/services/auth.ts`
Suggest tests for the `validateToken` function in `src/services/auth.ts`
What tests should I write for this function?
Help me test the checkout flow
What would you test in this code?
Review this module for testability
```

### With a specific function scope

Mention a function or method name to limit analysis to that function only:

```
Test the `parseJWT` method in src/utils/token.ts
Suggest tests for the `render` function in src/components/Button.tsx
```

### With a plan

If you have an implementation plan, mention it:

```
Suggest tests for src/services/auth.ts based on docs/plans/auth-refactor.md
I just implemented the plan in ~/.claude/plans/checkout-flow.md — what tests do I need?
```

### For recent changes

```
Suggest tests for my recent changes
What should I test in my current branch?
```

### Review existing tests (reviewing-tests skill)

```
Review my tests for src/services/auth.test.ts
Are my tests good?
Audit my test suite
What's wrong with my tests?
How can I improve these tests?
```

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

## Installation

### Install via Marketplace (Recommended)

```bash
# Register the marketplace
/plugin marketplace add https://github.com/shawn-sandy/agentics

# Install the plugin
/plugin install code-testing-agent@agentics-kit
```

### Load Locally (Development)

```bash
claude --plugin-dir /path/to/agentics/plugins/code-testing-agent
```

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
│   └── reviewing-tests/
│       ├── SKILL.md
│       └── references/
│           └── test-quality-checklist.md
├── README.md
└── CHANGELOG.md
```
