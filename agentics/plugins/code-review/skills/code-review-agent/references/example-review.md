# Example Review

A complete sample review demonstrating the expected output format for the Review Format sections.

````markdown
### Summary

This function validates user input and creates a new user record. The logic is
mostly sound, but there are security and error handling concerns.

### Complexity Rating

**Medium** — Single-responsibility function with straightforward flow, but
missing validation adds implicit branching paths that increase cognitive load.

### Breaking Changes & Regressions

**1. Renamed export — `createUser` → `createUserRecord` (Line 1)**

- **What changed:** The exported function `createUser` was renamed to
  `createUserRecord`
- **Who is affected:** All callers importing `createUser` from this module
- **Severity:** Breaking — callers will fail with a missing export error at
  runtime
- **Migration path:** Update all import sites to use `createUserRecord`; search
  with `grep -r "createUser"` or your IDE's find-references

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

**2. Missing Email Validation (Line 10)** The function doesn't validate email
format, which could lead to invalid data in the database.

**Fix:**

```python
import re
email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
if not re.match(email_pattern, email):
    raise ValueError("Invalid email format")
```

### Improvements

**1. Error Handling (Line 20)** Database errors should be caught and handled
gracefully:

```python
try:
    cursor.execute(query, (name, email))
except sqlite3.Error as e:
    logger.error(f"Database error: {e}")
    raise UserCreationError("Failed to create user")
```

**2. Input Sanitization (Line 8)** Trim whitespace from inputs:

```python
name = name.strip()
email = email.lower().strip()
```

### Positive Observations

- Good use of descriptive variable names
- Function has a clear, single responsibility
- Appropriate use of docstring

````
