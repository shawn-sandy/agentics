---
name: code-review-agent
description: >
  Performs structured, multi-dimensional code review covering six areas: code quality,
  potential bugs, security vulnerabilities, best practices, code complexity rating
  (Low/Medium/High/Very High), and breaking changes with regression risk assessment.
  Automatically resolves which files to review from git status, branch diffs, or explicit
  paths. Use this skill whenever the user asks to review code, check files for problems,
  look over a PR or branch diff, assess code quality or complexity, find bugs or security
  issues, detect breaking changes, or evaluate whether a change could cause a regression.
  Also triggers for informal requests like "take a look at this" or "anything wrong with
  this code." Produces a structured report with severity-ranked findings. Does not cover
  system architecture reviews, testing strategy, or accessibility audits.
---

When reviewing code, systematically check for common issues across multiple dimensions. Provide specific, actionable feedback with line numbers and code examples. Adapt checklist depth to the code's complexity and context — this is a flexible guide, not a rigid process.

## Table of Contents

- [Step 0: Resolve Target Files](#step-0-resolve-target-files)
- [Review Checklist](#review-checklist)
  - [1. Code Quality](#1-code-quality)
  - [2. Potential Bugs](#2-potential-bugs)
  - [3. Security Vulnerabilities](#3-security-vulnerabilities)
  - [4. Best Practices](#4-best-practices)
  - [5. Code Complexity](#5-code-complexity)
  - [6. Breaking Changes & Regressions](#6-breaking-changes--regressions)
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

### 5. Code Complexity

Assess the overall complexity and rate it: **Low / Medium / High / Very High**

**Structural Complexity:**
- Nesting depth (>3 levels of conditionals/loops is a signal)
- Cyclomatic complexity (number of branching paths per function)
- Function/method length (>50 lines raises cognitive load)
- Number of responsibilities per module or class

**Coupling & Cohesion:**
- Number of imports relative to the file's purpose and language conventions
- How tightly modules depend on each other
- Whether data flows are easy to trace end-to-end

**Cognitive Load:**
- Is the logic easy to follow without deep context?
- Are there chained operations that are hard to debug?
- Are there global or shared mutable states?

**Rating Guide:**
| Rating | Signals |
|--------|---------|
| Low | Flat structure, few branches, clear data flow, imports typical for the language/framework |
| Medium | Some nesting or branching, moderate length, manageable coupling |
| High | Deep nesting, many branches, long functions, tight coupling |
| Very High | Multiple complexity signals combined; refactoring strongly advised |

**Notes:**
- When reviewing multiple files, rate each file individually. Include an aggregate rating only when
  reviewing more than 3 files.
- For files under ~30 lines with a single responsibility, note `Low (trivially simple)` and omit
  the detailed breakdown.

### 6. Breaking Changes & Regressions

**Public API Surface**
- Are exported functions, classes, or types renamed or removed?
- Have function signatures changed (added required parameters, removed parameters, or reordered parameters)?
- Have return types or shapes changed in ways callers won't expect?
- Are previously thrown errors now suppressed, or new errors thrown that callers don't handle?

**Shared / Internal Contracts**
- Are widely-used utilities or helpers modified in ways that affect all call sites?
- Are base classes or interfaces changed in ways that break subclasses?
- Are default argument values, fallback behaviors, or guard conditions changed?

**Data & Config Contracts**
- Are environment variable names or config keys renamed or removed?
- Are serialized data formats, API request/response shapes, or wire formats changed?
- Are database schema changes present (NOT NULL columns added, columns dropped, type changes)? *(Apply only when reviewing migration files or schema definitions.)*

**Regression Risk**
- Does the change touch code that previously had bugs fixed? (Check surrounding comments or nearby history for context clues.)
- Are shared mutable states or global singletons modified?
- Are previously reliable invariants (e.g., "this function never returns null") broken?

**Call Site Assessment**
- Are there other files that import or call the changed symbol?
- Does the number of call sites suggest a high blast radius (3 or more callers)?
- Do any call sites pass arguments or rely on return values in ways that the new signature or behavior would break?
- If git history is unavailable, assess the API surface visually from the reviewed code only.

## Review Format

Structure the review as follows:

### Summary
Brief overview of the code's purpose and overall quality (1-2 sentences).

### Complexity Rating
**[Low / Medium / High / Very High]** — One-sentence rationale (e.g., "Deep nesting in 3 core
functions and tightly coupled imports drive the rating.").

### Breaking Changes & Regressions
List any changes that break existing callers, alter contracts, or risk reintroducing previously fixed behavior.
For each:
- **What changed** — the specific symbol, config key, schema field, or behavior
- **Who is affected** — call sites, dependents, consumers
- **Severity** — Breaking (callers will fail) / Risky (callers may silently misbehave)
- **Migration path** — what callers must do to adapt

If none detected: `No breaking changes or regression risks identified.`

> If a breaking change also qualifies as a Critical Issue, list it here only — omit it from Critical Issues to avoid duplication.

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

### Complexity Rating
**Medium** — Single-responsibility function with straightforward flow, but missing validation adds implicit branching paths that increase cognitive load.

### Breaking Changes & Regressions

**1. Renamed export — `createUser` → `createUserRecord` (Line 1)**
- **What changed:** The exported function `createUser` was renamed to `createUserRecord`
- **Who is affected:** All callers importing `createUser` from this module
- **Severity:** Breaking — callers will fail with a missing export error at runtime
- **Migration path:** Update all import sites to use `createUserRecord`; search with `grep -r "createUser"` or your IDE's find-references

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
- Complexity rating covers code-level coupling and nesting depth, not system architecture
