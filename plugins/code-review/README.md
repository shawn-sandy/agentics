# code-review Plugin

Structured, multi-dimensional code review across quality, bugs, security, best practices, complexity, and breaking changes. Provides specific, actionable feedback with line numbers and suggested fixes.

## Purpose

Code review is most effective when it's structured and consistent. This plugin applies a repeatable checklist across six dimensions so nothing slips through. It automatically resolves which files to review from git status, branch diffs, or explicit paths, and produces a structured report with severity-ranked findings.

## Skills

| Skill | Activation |
|-------|-----------|
| `code-review-agent` | Triggers when user asks to review code, check files for problems, look over a PR or diff, assess quality or complexity, find bugs or security issues, detect breaking changes, or evaluate regression risk. Also triggers for informal requests like "take a look at this." |

## Review Checklist Overview

The skill checks across six dimensions:

1. **Code Quality** — readability, maintainability, naming conventions, DRY principle
2. **Potential Bugs** — common errors, edge cases, async/concurrency issues
3. **Security Vulnerabilities** — input validation, auth/authz, data exposure, dependency risks
4. **Best Practices** — error handling, type safety, performance, documentation
5. **Code Complexity** — structural complexity, coupling/cohesion, cognitive load (Low/Medium/High/Very High rating)
6. **Breaking Changes & Regressions** — public API surface, shared contracts, data/config contracts, regression risk

## Usage

### Automatic activation (skill)

Describe what you want reviewed:

```
Review this function for bugs
Check this file for security issues
Analyze the code quality in src/api/users.ts
Look for problems in my authentication module
```

### Providing specific code

Paste code directly in your message or reference a file:

```
Review this code: [paste code]
Check src/components/LoginForm.tsx for security issues
```

### Review output format

Reviews are structured as:
1. **Summary** — brief overview of code purpose and overall quality
2. **Complexity Rating** — Low/Medium/High/Very High with a one-sentence rationale
3. **Breaking Changes & Regressions** — changes that break callers, alter contracts, or risk regressions
4. **Critical Issues** — bugs, security vulnerabilities, data loss risks (must fix)
5. **Improvements** — non-critical quality and maintainability suggestions
6. **Positive Observations** — what the code does well

## Installation

```
/plugin install code-review@agentics-kit
```

Or load directly for local testing:

```bash
claude --plugin-dir ./plugins/code-review
```
