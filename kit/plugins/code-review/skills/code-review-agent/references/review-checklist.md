# Review Checklist

Six-dimension checklist for code review. Apply each section to every file under review.

## Table of Contents

- [1. Code Quality](#1-code-quality)
- [2. Potential Bugs](#2-potential-bugs)
- [3. Security Vulnerabilities](#3-security-vulnerabilities)
- [4. Best Practices](#4-best-practices)
- [5. Code Complexity](#5-code-complexity)
- [6. Breaking Changes & Regressions](#6-breaking-changes--regressions)

---

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
- Are boolean variables named clearly (is*, has*, should\*)?
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

**Escape-Prone Classes:**

These five survive ordinary review often enough to warrant an explicit pass:

- Pagination or sort tie-breakers — a sort with no unique final key, so equal rows reorder between pages and records repeat or vanish
- `parseInt`/`Number()` on user or query input with no validation — NaN, negative, or out-of-range values reaching a query or an index
- Derived state left stale after a client-side update — result counts, pagination links, labels, or cached totals still rendering pre-update data
- Timezone-dependent date anchors — "today", midnight, or day boundaries computed in local time against UTC data
- Scripts that continue after a failed step — a missing `set -e`, an unchecked exit code, or a default env var that silently no-ops

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

- When reviewing multiple files, rate each file individually. Include an
  aggregate rating only when reviewing more than 3 files.
- For files under ~30 lines with a single responsibility, note
  `Low (trivially simple)` and omit the detailed breakdown.

### 6. Breaking Changes & Regressions

**Public API Surface**

- Are exported functions, classes, or types renamed or removed?
- Have function signatures changed (added required parameters, removed
  parameters, or reordered parameters)?
- Have return types or shapes changed in ways callers won't expect?
- Are previously thrown errors now suppressed, or new errors thrown that callers
  don't handle?

**Shared / Internal Contracts**

- Are widely-used utilities or helpers modified in ways that affect all call
  sites?
- Are base classes or interfaces changed in ways that break subclasses?
- Are default argument values, fallback behaviors, or guard conditions changed?

**Data & Config Contracts**

- Are environment variable names or config keys renamed or removed?
- Are serialized data formats, API request/response shapes, or wire formats
  changed?
- Are database schema changes present (NOT NULL columns added, columns dropped,
  type changes)? _(Apply only when reviewing migration files or schema
  definitions.)_

**Regression Risk**

- Does the change touch code that previously had bugs fixed? (Check surrounding
  comments or nearby history for context clues.)
- Are shared mutable states or global singletons modified?
- Are previously reliable invariants (e.g., "this function never returns null")
  broken?

**Call Site Assessment**

- Are there other files that import or call the changed symbol?
- Does the number of call sites suggest a high blast radius (3 or more callers)?
- Do any call sites pass arguments or rely on return values in ways that the new
  signature or behavior would break?
- If git history is unavailable, assess the API surface visually from the
  reviewed code only.
