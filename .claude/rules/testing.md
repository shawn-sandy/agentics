---
paths:
  - "tests/**"
---

# Test Fixtures

## Location and Purpose

`tests/fixtures/` contains minimal plugins for automated validation testing:

- `valid-plugin/` — Passes all validation checks; use for success-path tests
- `invalid-plugin/` — Missing required fields; use for error-handling tests

## When to Add a Fixture

- Testing a new validation rule
- Reproducing a specific error condition
- Testing edge cases in plugin parsing

## Fixture Design Rules

- **Keep fixtures minimal** — include only what is necessary for the specific test scenario
- Do not reuse existing fixtures for new test scenarios; create a focused new one
- Fixtures represent plugin structure, not real plugin functionality
