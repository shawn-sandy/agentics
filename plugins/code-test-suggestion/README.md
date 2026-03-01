# code-test-suggestion Plugin

Analyze code and suggest specific, purpose-driven tests tied to actual behavior and intent. This plugin does not generate arbitrary unit tests for coverage metrics — it identifies what tests would be genuinely valuable and explains why each one matters.

## Purpose

Developers often face two problems with testing: either they write tests after the fact that verify implementation details rather than behavior, or they rely on coverage tools to tell them what to test — which leads to many tests that catch nothing useful and few tests that catch real bugs. This plugin takes a different approach: it reads the code, looks for the developer's plan or intent, identifies critical behaviors and fragile areas, and suggests the specific tests that would catch the most damaging failures.

## How It Differs from code-review

The `code-review` plugin reviews code for quality, bugs, security, and best practices — it tells you what is wrong with your code. The `code-test-suggestion` plugin tells you how to prove your code works correctly — it designs a test strategy based on what the code does and what the developer intended.

## Components

| Component | Type | Activation |
|-----------|------|-----------|
| `code-test-suggestion` | Skill | Auto-triggers when user asks to "suggest tests", "what tests should I write", "test this code", "review testability", or "find untested behavior" |
| `suggest-tests` | Command | Explicitly invoked via `/code-test-suggestion:suggest-tests [file-path]` |

## Usage

### Automatic activation (skill)

Describe what you want:

```
Suggest tests for src/services/auth.ts
What tests should I write for this function?
Help me test the checkout flow
What would you test in this code?
Review this module for testability
```

### Explicit command

```
/code-test-suggestion:suggest-tests src/services/auth.ts
/code-test-suggestion:suggest-tests src/services/
/code-test-suggestion:suggest-tests
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

## What the Skill Does

1. Identifies target code (from your message, conversation context, or recent git changes)
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
- **Tests NOT Suggested** — Explains why certain obvious-seeming tests would be low-value.

Each suggestion includes: what behavior to test, why the test matters, the code it validates, and a concrete test approach using your framework.

## Installation

### Install via Marketplace (Recommended)

```bash
# Register the marketplace
/plugin marketplace add https://github.com/shawn-sandy/agentics

# Install the plugin
/plugin install code-test-suggestion@agentics-kit
```

### Load Locally (Development)

```bash
claude --plugin-dir /path/to/agentics/plugins/code-test-suggestion
```

## Plugin Structure

```
plugins/code-test-suggestion/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   └── suggest-tests.md
├── skills/
│   └── code-test-suggestion/
│       ├── SKILL.md
│       └── references/
│           └── test-analysis-guide.md
├── README.md
└── CHANGELOG.md
```
