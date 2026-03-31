# Test Infrastructure Detection

Detailed lookup tables for Step 4 — detecting the project's test framework, existing tests, patterns, and coverage target.

## Table of Contents

- [4a. Finding the Test Framework](#4a-finding-the-test-framework)
- [4b. Finding Existing Test Files](#4b-finding-existing-test-files)
- [4c. Learning Existing Patterns](#4c-learning-existing-patterns)
- [4d. Detecting the Coverage Target](#4d-detecting-the-coverage-target)

---

## 4a. Finding the Test Framework

Search these config files:

| File | What to look for |
|------|-----------------|
| `package.json` | `jest`, `vitest`, `mocha`, `ava`, `playwright`, `cypress` in `devDependencies` or `scripts` |
| `jest.config.js` / `jest.config.ts` | Presence confirms Jest |
| `vitest.config.ts` | Presence confirms Vitest |
| `pytest.ini` | Presence confirms pytest |
| `pyproject.toml` | `[tool.pytest.ini_options]` section |
| `setup.cfg` | `[tool:pytest]` section |
| `Cargo.toml` | `[dev-dependencies]` with test crates |
| `go.mod` | Go uses the built-in `testing` package — no config needed |
| `.github/workflows/` | CI YAML files may reference `pytest`, `jest`, `go test`, etc. |
| `Makefile` or `justfile` | `test:` targets |

If no framework is detected, ask the user which framework they prefer before continuing.

---

## 4b. Finding Existing Test Files

Glob for test files near the target code:

**JavaScript / TypeScript**
- `**/*.test.ts`, `**/*.test.tsx`, `**/*.test.js`, `**/*.test.jsx`
- `**/*.spec.ts`, `**/*.spec.tsx`, `**/*.spec.js`, `**/*.spec.jsx`
- `__tests__/` directories

**Python**
- `**/test_*.py`
- `**/*_test.py`
- `tests/` directories

**Go**
- `**/*_test.go`

**Rust**
- Inline `#[cfg(test)]` modules (search within source files)
- `tests/` integration test directory

**General**
- `spec/` directories (Ruby, some JS projects)

---

## 4c. Learning Existing Patterns

If test files exist near the target (same directory or parallel `__tests__/` directory), read 1–2 of them and note:

- Import style (named imports, default imports, require)
- Assertion library (Jest's `expect`, Chai's `assert`, Python's `assert`, etc.)
- Mocking patterns (`jest.mock`, `vi.mock`, `unittest.mock`, `testify/mock`)
- Describe/it nesting conventions (flat vs. nested)
- Setup/teardown patterns (`beforeEach`, `afterAll`, fixtures, `setUp`)
- Naming conventions (camelCase, snake_case, sentence-style test names)
- Special infrastructure: factories/fixtures, test databases, mock servers, snapshot testing, parameterized/table-driven tests

If no tests exist at all, note: "No existing tests found. Suggestions will use [framework] based on project configuration."

---

## 4d. Detecting the Coverage Target

Search these locations for coverage thresholds:

| File | What to look for |
|------|-----------------|
| `jest.config.*` or `package.json` (`jest` key) | `coverageThreshold: { global: { branches, functions, lines, statements } }` |
| `pyproject.toml` | `[tool.coverage.report]` → `fail_under = 80` |
| `.nycrc` or `.nycrc.json` | `"check-coverage": true` with `"lines"`, `"branches"`, `"functions"` thresholds |
| `codecov.yml` | `coverage.status.project.default.target` |
| `.coveragerc` | `[report]` → `fail_under = 80` |
| `.github/workflows/` or CI config | `--coverage-threshold`, `--fail-under`, or similar flags in test commands |

Report: `"Coverage target: [X]% (from [config file])."`

If no target is found: `"No coverage target configured. Aiming for maximum practical coverage."`
