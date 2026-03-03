---
name: code-review
description: Reviews code for best practices, bugs, and security vulnerabilities. Use when the user asks to review code, check a file for problems, review changed files, or analyze code quality. Does not cover architecture reviews or testing strategy.
---

When reviewing code, systematically check for common issues across multiple dimensions. Provide specific, actionable feedback with line numbers and code examples. Adapt the checklist depth to the code's complexity and context.

## Table of Contents

- [Step 0: Resolve Target Files](#step-0-resolve-target-files)
- [Review Checklist](#review-checklist)
  - [1. Code Quality](#1-code-quality)
  - [2. Potential Bugs](#2-potential-bugs)
  - [3. Security Vulnerabilities](#3-security-vulnerabilities)
  - [4. Best Practices](#4-best-practices)
- [Review Format](#review-format)
- [Example Review](#example-review)
- [Tips for Effective Reviews](#tips-for-effective-reviews)
- [Scope](#scope)

## Step 0: Resolve Target Files

Before reviewing, identify which files to check using this priority order:

1. **Explicit path in message** — If the user named a file or directory, use it directly. Skip to the Review Checklist.

2. **Local changes (git status)** — If no file was specified, run:
   `git status --short`
   - If this fails (not a git repo), skip to step 4.
   - If files are listed, show the list and ask: "I found these changed files — which would you like me to review?" Review confirmed files. Skip binaries, lock files (*.lock, package-lock.json, yarn.lock), and generated files; note any skipped.
   - If no files are listed, continue to step 3.

3. **Branch diff** — Run each in order until files are returned:
   - `git diff main...HEAD --name-only`
   - `git diff master...HEAD --name-only`
   - `git diff HEAD~1 --name-only`
   If files are returned, show the list and confirm before reviewing. Skip non-reviewable files as above.
   If all return empty or fail (e.g., detached HEAD), continue to step 4.

4. **Fallback** — Ask: "Which file or files would you like me to review?"

Once target files are confirmed, proceed to the Review Checklist for each file.

## Review Checklist

### 1. Code Quality

**Readability:**
- Are variable and function names descriptive and meaningful?
- Is the code properly indented and formatted?
- Are there magic numbers that should be named constants?
- Is complex logic broken into well-named functions?

**Maintainability:**
- Is there excessive code duplication (DRY principle)?
- Are functions doing too many things (Single Responsibility)?
- Is the code modular and well-organized?
- Are there overly long functions (>50 lines)?

**Naming Conventions:**
- Do names follow language conventions (camelCase, PascalCase, snake_case)?
- Are boolean variables named clearly (is*, has*, should*)?
- Are function names verb-based and descriptive?

### 2. Potential Bugs

**Common Errors:**
- Off-by-one errors in loops and array indexing
- Null/undefined/None reference errors
- Type mismatches and implicit conversions
- Incorrect operator precedence
- Missing return statements
- Infinite loops or recursion without base cases

**Edge Cases:**
- Empty arrays, strings, or collections
- Boundary conditions (min/max values)
- Null, undefined, or None inputs
- Division by zero
- Overflow/underflow conditions

**Async/Concurrency:**
- Missing await/async keywords
- Race conditions
- Unhandled promise rejections
- Callback hell or promise chains that could be simplified

### 3. Security Vulnerabilities

**Input Validation:**
- Is user input validated and sanitized?
- Are there SQL injection vulnerabilities?
- Are there XSS (Cross-Site Scripting) risks?
- Is there command injection potential?
- Are file paths validated to prevent traversal attacks?

**Authentication & Authorization:**
- Are authentication checks present where needed?
- Is authorization verified before sensitive operations?
- Are passwords and secrets handled securely?
- Is sensitive data logged or exposed?

**Data Exposure:**
- Are API keys, tokens, or passwords hardcoded?
- Is sensitive data transmitted over secure channels?
- Are error messages revealing too much information?
- Is PII (Personally Identifiable Information) properly protected?

**Dependencies:**
- Are there known vulnerabilities in dependencies?
- Are dependencies up to date?
- Are untrusted inputs passed to dangerous functions?

### 4. Best Practices

**Error Handling:**
- Are errors caught and handled appropriately?
- Are error messages helpful and informative?
- Are resources cleaned up in finally blocks or with context managers?
- Are exceptions used for exceptional cases (not control flow)?

**Type Safety:**
- Are types explicit where they improve clarity?
- Are type assertions necessary or can they be avoided?
- Is `any` type used unnecessarily (TypeScript)?
- Are union types handled exhaustively?

**Performance:**
- Are there obvious performance bottlenecks?
- Is data being unnecessarily copied or transformed?
- Are there N+1 query problems?
- Could expensive operations be cached?

**Documentation:**
- Are complex algorithms or business logic commented?
- Are function/method signatures clear about their behavior?
- Are TODOs or FIXMEs accompanied by context?
- Is public API documented?

## Review Format

Structure the review as follows:

### Summary
Brief overview of the code's purpose and overall quality (1-2 sentences).

### Critical Issues
Issues that could cause bugs, security vulnerabilities, or data loss. **Must be fixed.**

### Improvements
Non-critical issues that would improve code quality, maintainability, or performance.

### Positive Observations
Things the code does well. Reinforce good practices.

## Example Review

```markdown
### Summary
This function validates user input and creates a new user record. The logic is mostly sound, but there are security and error handling concerns.

### Critical Issues

**1. SQL Injection Vulnerability (Line 15)**
```python
query = f"INSERT INTO users (name, email) VALUES ('{name}', '{email}')"
```
Using string interpolation for SQL queries allows SQL injection attacks.

**Fix:**
```python
query = "INSERT INTO users (name, email) VALUES (?, ?)"
cursor.execute(query, (name, email))
```

**2. Missing Email Validation (Line 10)**
The function doesn't validate email format, which could lead to invalid data in the database.

**Fix:**
```python
import re
email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
if not re.match(email_pattern, email):
    raise ValueError("Invalid email format")
```

### Improvements

**1. Error Handling (Line 20)**
Database errors should be caught and handled gracefully:
```python
try:
    cursor.execute(query, (name, email))
except sqlite3.Error as e:
    logger.error(f"Database error: {e}")
    raise UserCreationError("Failed to create user")
```

**2. Input Sanitization (Line 8)**
Trim whitespace from inputs:
```python
name = name.strip()
email = email.lower().strip()
```

### Positive Observations
- Good use of descriptive variable names
- Function has a clear, single responsibility
- Appropriate use of docstring
```

## Tips for Effective Reviews

1. **Be Specific**: Reference exact line numbers and code snippets
2. **Provide Solutions**: Don't just identify problems, suggest fixes
3. **Prioritize**: Distinguish between critical issues and improvements
4. **Be Constructive**: Frame feedback positively when possible
5. **Consider Context**: Some "issues" may be intentional design choices
6. **Stay Focused**: Review the code as written, not what it could become

## Scope

- Review only the code provided or specified by the user
- Don't review entire codebases unless explicitly asked
- Focus on substantive issues, not purely stylistic preferences
- Adapt review depth to the code's complexity and context
