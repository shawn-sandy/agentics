---
paths:
  - "tests/**"
---

# Test Fixtures

`tests/fixtures/valid-plugin/` passes every validation check — use it for
success paths. `invalid-plugin/` is missing required fields — use it for
error handling. The rest are scenario-specific.

Add a fixture for each new validation rule, error condition, or parsing edge
case. Keep it minimal, and do not stretch an existing fixture to cover a new
scenario — create a focused one instead. Fixtures model plugin *structure*,
not working plugin behavior.
