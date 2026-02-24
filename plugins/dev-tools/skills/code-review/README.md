# code-review Skill

Automatic code review skill for the `dev-tools` plugin. Activates when you ask Claude to review code, check for bugs, or assess code quality.

## Overview

The `code-review` skill provides systematic, structured feedback across four dimensions: code quality, potential bugs, security vulnerabilities, and best practices. It activates automatically — no slash command required.

## Activation

The skill triggers when your request indicates code review intent. Claude matches against the skill's description to decide when to activate.

**Phrases that activate the skill:**
```
"Review this code"
"Check for bugs"
"Is this secure?"
"Any improvements you'd suggest?"
"Can you look at this function?"
"What's wrong with this code?"
```

**Phrases that do NOT activate the skill:**
```
"What does this code do?"     → (analysis, not review)
"Explain this algorithm"      → (explanation, not review)
"Translate this to Python"    → (conversion, not review)
```

## What It Reviews

### 1. Code Quality
- **Readability** — descriptive names, proper indentation, no magic numbers
- **Maintainability** — DRY principle, Single Responsibility, function length (<50 lines)
- **Naming Conventions** — language-appropriate casing (camelCase, snake_case, PascalCase)

### 2. Potential Bugs
- **Common Errors** — off-by-one, null references, type mismatches, missing returns
- **Edge Cases** — empty inputs, boundary values, division by zero, overflow
- **Async/Concurrency** — missing await, race conditions, unhandled promise rejections

### 3. Security
- **Input Validation** — SQL injection, XSS, command injection, path traversal
- **Authentication & Authorization** — missing auth checks, insecure password handling
- **Data Exposure** — hardcoded secrets, sensitive data in logs, overly verbose errors

### 4. Best Practices
- **Error Handling** — caught exceptions, helpful messages, resource cleanup
- **Type Safety** — explicit types, avoiding `any`, exhaustive union handling
- **Performance** — obvious bottlenecks, N+1 queries, unnecessary copies
- **Documentation** — complex logic commented, public API documented

## Output Format

Reviews follow a consistent four-section structure:

```markdown
### Summary
Brief overview of the code's purpose and overall quality (1-2 sentences).

### Critical Issues
Issues that could cause bugs, security vulnerabilities, or data loss. Must be fixed.

### Improvements
Non-critical issues that would improve quality, maintainability, or performance.

### Positive Observations
Things the code does well. Reinforces good practices.
```

Each issue includes:
- The specific line number(s)
- A code snippet showing the problem
- A concrete fix with corrected code

## Examples

**Example activation:**
```
User: "Can you review this API endpoint for issues?"
[pastes code]

Claude: Reviews the code using the code-review skill, providing structured feedback
        organized into Critical Issues, Improvements, and Positive Observations.
```

**Example output shape:**
```markdown
### Summary
This route handler validates user input and writes to the database. The logic
is mostly sound but has a SQL injection vulnerability and missing error handling.

### Critical Issues
1. SQL Injection (Line 12) — string interpolation used in query
2. Missing auth check (Line 5) — endpoint accessible without authentication

### Improvements
1. Add try/catch around database call (Line 18)
2. Sanitize email input before comparison (Line 8)

### Positive Observations
- Clear variable names throughout
- Good use of early returns for validation
```

## Scope

**What the skill reviews:**
- Code provided directly in the conversation
- Files specified by path in your request
- Focused code snippets and functions

**What it does NOT do:**
- Full codebase scans (unless explicitly requested)
- Style-only nitpicking without substance
- Rewriting code without being asked
- Replacing dedicated security audit tools

## Tips

- **Paste the code** — the skill works on code you share directly in the chat
- **Specify a file** — "Review `src/auth/login.ts` for security issues" scopes the review
- **Mention what matters** — "Focus on security" or "Check for async bugs" guides the depth
- **Context helps** — sharing what the code is supposed to do produces more relevant feedback
