# code-review Plugin

Systematic code review across quality, bugs, security vulnerabilities, and best practices. Provides specific, actionable feedback with line numbers and suggested fixes.

## Purpose

Code review is most effective when it's structured and consistent. This plugin applies a repeatable checklist across four dimensions — code quality, potential bugs, security vulnerabilities, and best practices — so nothing slips through. It's optimized for giving Claude the right framing to produce actionable reviews rather than vague observations.

## Skills

| Skill | Activation |
|-------|-----------|
| `code-review` | Triggers when user asks to "review code", "check for problems", "analyze code quality", or "look for bugs/security issues". |

## Review Checklist Overview

The skill checks across four dimensions:

1. **Code Quality** — readability, maintainability, naming conventions, DRY principle
2. **Potential Bugs** — common errors, edge cases, async/concurrency issues
3. **Security Vulnerabilities** — input validation, auth/authz, data exposure, dependency risks
4. **Best Practices** — error handling, type safety, performance, documentation

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
- **Summary** — brief overview of code purpose and overall quality
- **Critical Issues** — bugs, security vulnerabilities, data loss risks (must fix)
- **Improvements** — non-critical quality and maintainability suggestions
- **Positive Observations** — what the code does well

## Installation

```
/plugin install code-review@agentics-kit
```

Or load directly for local testing:

```bash
claude --plugin-dir ./plugins/code-review
```
