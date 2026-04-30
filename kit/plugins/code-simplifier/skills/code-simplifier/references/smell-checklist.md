# Smell Checklist

Nine-category checklist for structural code analysis. Apply each section to
every file under review.

## Table of Contents

1. [Dead Code & Unused Declarations](#1-dead-code--unused-declarations)
2. [Excessive Complexity](#2-excessive-complexity)
3. [God Classes & God Functions](#3-god-classes--god-functions)
4. [Duplicated Logic](#4-duplicated-logic)
5. [Coupling & Cohesion](#5-coupling--cohesion)
6. [Primitive Obsession & Feature Envy](#6-primitive-obsession--feature-envy)
7. [Parameter Lists & Signatures](#7-parameter-lists--signatures)
8. [Naming & Consistency](#8-naming--consistency)
9. [Performance Anti-Patterns](#9-performance-anti-patterns)

---

### 1. Dead Code & Unused Declarations

- Are there unreachable code paths (after return, break, unconditional throws)?
- Are there unused variables, parameters, or function arguments?
- Are there unused imports or require statements?
- Are there commented-out code blocks that should be removed?
- Are there unused private methods or class members?
- Are there dead feature flags or configuration paths?
- Are there TODO/FIXME comments referencing completed or abandoned work?

### 2. Excessive Complexity

**Cyclomatic Complexity:**

- Do any functions have more than 10 branching paths?
- Are there deeply nested conditionals (>3 levels)?
- Are there long if/else chains that could be replaced with lookup tables or
  strategy patterns?
- Are there complex boolean expressions that should be extracted into named
  predicates?

**Cognitive Load:**

- Can a developer understand the function without scrolling?
- Are there chained ternaries or nested ternaries?
- Are there multi-step transformations without intermediate variables?
- Is control flow non-linear (early returns mixed with deep nesting)?

**Function Length:**

- Are any functions over 50 lines?
- Are any functions over 100 lines (critical)?

### 3. God Classes & God Functions

- Does any class/module have more than 5 public methods serving different
  concerns?
- Does any class/module exceed 300 lines?
- Does any single function handle more than one responsibility?
- Does a class/module name contain "Manager", "Handler", "Processor", "Service",
  or "Utils" with mixed responsibilities?
- Are there classes/modules that would require more than one sentence to describe
  their purpose?

### 4. Duplicated Logic

- Are there blocks of 5+ lines that are nearly identical across files?
- Are there repeated conditional checks that could be extracted into a shared
  predicate?
- Are there repeated transformations or formatting logic?
- Are there copy-pasted error handling patterns that should use a shared utility?
- Are there parallel class hierarchies with duplicated structure?

### 5. Coupling & Cohesion

**Inappropriate Coupling:**

- Do modules import deeply from other modules' internals?
- Are there circular dependencies between modules?
- Is there temporal coupling (functions that must be called in a specific order
  without enforcement)?
- Are distant modules sharing mutable state?

**Poor Cohesion:**

- Does a module contain functions that do not relate to its primary purpose?
- Are there utility files that have grown into catch-all collections?
- Are data and the functions that operate on them separated across different
  modules?

### 6. Primitive Obsession & Feature Envy

**Primitive Obsession:**

- Are there bare strings used where a domain type would be clearer (email, URL,
  currency, status)?
- Are there magic numbers or string literals used as configuration?
- Are there arrays/tuples used where a named object/struct would add clarity?
- Are there boolean parameters that control branching (flag arguments)?

**Feature Envy:**

- Do any functions primarily access data from another class/module rather than
  their own?
- Are there functions that extract multiple fields from a parameter to perform
  operations that belong on the parameter's own type?

### 7. Parameter Lists & Signatures

- Do any functions accept more than 4 parameters?
- Could an options/config object replace positional parameters?
- Are there boolean flags in function signatures?
- Are there output parameters (parameters modified by the function)?
- Are there functions where the parameter order is easy to confuse (e.g., two
  string parameters with no type distinction)?

### 8. Naming & Consistency

- Are there inconsistent naming conventions within the same file or module?
- Are there abbreviations that reduce readability?
- Do function names accurately describe their side effects?
- Are there misleading names (function name suggests one thing, body does
  another)?
- Are there generic names (data, info, result, temp, val) used for
  domain-specific concepts?
- Are there naming pattern breaks across related files (e.g., getUser in one
  file, fetchUser in a sibling)?

### 9. Performance Anti-Patterns

- Are there N+1 query patterns (loop with a database/API call per iteration)?
- Are there unnecessary re-renders in component frameworks (missing memoization,
  inline object literals as props)?
- Are there synchronous operations that block the main thread unnecessarily?
- Are there repeated expensive computations that could be cached or memoized?
- Are there large data structures loaded into memory when only a subset is
  needed?
- Are there string concatenation patterns in tight loops instead of builder
  patterns?
- Are there resource leaks (event listeners, timers, connections not cleaned up)?

---

## Smell Severity Rating Guide

| Rating | Signals |
|--------|---------|
| Clean | 0-1 minor smells, well-structured code |
| Minor Issues | 2-4 minor/moderate smells, generally well-structured |
| Needs Refactoring | 5+ smells or any critical smell present |
| Major Refactoring Needed | Multiple critical smells; structural rework advised |

**Notes:**

- Rate each file individually for multi-file analyses
- For files under ~30 lines with a single responsibility, note
  `Clean (trivially simple)` and omit the detailed breakdown
- When reviewing multiple files, include an aggregate rating only when reviewing
  more than 3 files
