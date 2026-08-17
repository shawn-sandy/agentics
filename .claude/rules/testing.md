---
paths:
  - "tests/**"
---

# Testing

## Running tests

`bash tests/run-all.sh` runs every test under `tests/` — new files matching
`test-*.sh` / `test-*.mjs` / `*.test.mjs` are picked up automatically, so a
new test needs no CI wiring. The skip list, with a reason per entry, lives at
the top of the runner. CI runs the same script on every PR
(`check-plugin-versions.yml`).

# Test Fixtures

`tests/fixtures/valid-plugin/` passes every validation check — use it for
success paths. `invalid-plugin/` is missing required fields — use it for
error handling. The rest are scenario-specific.

Add a fixture for each new validation rule, error condition, or parsing edge
case. Keep it minimal, and do not stretch an existing fixture to cover a new
scenario — create a focused one instead. Fixtures model plugin *structure*,
not working plugin behavior.
