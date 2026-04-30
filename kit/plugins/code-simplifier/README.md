# code-simplifier Plugin

Analyze code for structural quality issues, code smells, and optimization
opportunities. Produces a prioritized refactoring plan with specific improvement
steps and before/after code examples, then applies approved changes.

## Purpose

Code review catches bugs and security issues, but structural quality problems
-- dead code, excessive complexity, duplication, poor cohesion -- accumulate
silently and slow teams down. This plugin applies a systematic nine-category
smell checklist to identify refactoring opportunities, creates a concrete plan
to address them, and applies the approved changes after developer review.

## How It Differs from code-review

The `code-review` plugin reviews code for bugs, security vulnerabilities,
breaking changes, and best practices. The `code-simplifier` plugin focuses
exclusively on **structural quality**: code smells, unnecessary complexity,
duplicated logic, and optimization opportunities. Together they cover
complementary dimensions of code quality.

## Skills

| Skill | Activation |
|-------|------------|
| `code-simplifier` | Triggers when the user asks to simplify code, find code smells, reduce complexity, identify refactoring opportunities, check for dead code, clean up messy code, or optimize structure |

All skills declare `allowed-tools` explicitly in their frontmatter for
consistent, session-independent tool access.

### Workflow

1. Resolve target files (explicit path, git changes, branch diff, or prompt)
2. Enter plan mode for read-only analysis
3. Analyze code against the nine-category smell checklist
4. Create a refactoring plan file with prioritized steps
5. Present findings and review with developer
6. Apply approved changes or discard

## Smell Checklist Overview

1. **Dead Code & Unused Declarations** -- unreachable paths, unused vars/imports
2. **Excessive Complexity** -- high cyclomatic complexity, deep nesting, long functions
3. **God Classes & God Functions** -- classes/functions doing too much
4. **Duplicated Logic** -- repeated code blocks, conditionals, error handling
5. **Coupling & Cohesion** -- circular deps, deep imports, catch-all utils
6. **Primitive Obsession & Feature Envy** -- bare strings for domain types, flag args
7. **Parameter Lists & Signatures** -- too many params, confusable positional args
8. **Naming & Consistency** -- inconsistent conventions, misleading names
9. **Performance Anti-Patterns** -- N+1 queries, missing memoization, resource leaks

## Agent (Internal)

The `agent-code-simplifier` is a background agent for delegation from other
agents or automated workflows. It is not intended for direct user requests.

| Field | Value |
|-------|-------|
| Model | Sonnet |
| Tools | Read, Glob, Grep, Bash |
| Disallowed Tools | Write, Edit, NotebookEdit |
| Permission Mode | plan (enforced read-only) |
| Max Turns | 10 |
| Memory | Project-scoped |
| Background | Yes (non-blocking) |

### When to use the agent

- Delegating a structural quality analysis to a sub-agent
- Getting a second opinion on code complexity and maintainability
- Running a proactive sweep for code smells after a merge or batch of commits

### Delegating to the agent

```
Agent(
  subagent_type: "code-simplifier:agent-code-simplifier",
  prompt: "Analyze the files in src/utils/ for code smells and structural issues.",
  run_in_background: true
)
```

### Agent memory

The agent uses project-scoped memory to learn recurring patterns, project
conventions, acceptable complexity thresholds, and categories to skip. Memory
is consulted at the start of each analysis and updated with new discoveries.

## Usage

### Automatic activation (skill)

The skill activates automatically when you say things like:

- "Find code smells in this file"
- "This code is messy, clean it up"
- "Simplify the utils folder"
- "Check for dead code"
- "Reduce the complexity of this module"
- "Identify refactoring opportunities"

### Providing specific code

```
Analyze src/services/auth.ts for code smells
```

```
Find refactoring opportunities in the components/ directory
```

### Analysis output format

1. **Summary** -- code purpose and structural quality
2. **Smell Severity Rating** -- Clean / Minor Issues / Needs Refactoring / Major
3. **Critical Smells** -- must-fix structural issues with code examples
4. **Moderate Smells** -- should-fix improvements
5. **Refactoring Plan** -- link to plan file with prioritized steps
6. **Positive Observations** -- good structural patterns

## Installation

```text
/plugin install code-simplifier@agentics-kit
```

Or load directly for local testing:

```bash
claude --plugin-dir ./kit/plugins/code-simplifier
```

## Plugin Structure

```
code-simplifier/
  .claude-plugin/
    plugin.json
  skills/
    code-simplifier/
      SKILL.md
      references/
        smell-checklist.md
        example-analysis.md
  agents/
    agent-code-simplifier.md
  README.md
  CHANGELOG.md
```
