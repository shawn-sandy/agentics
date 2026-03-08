# Test Runner Guide

Reference data for the `running-tests` skill. Used in Steps 2–5 of the SKILL.md workflow.

---

## Section 1: Test File Naming Conventions

| Source Extension | Conventional Test File Patterns | Directories to Search |
|------------------|---------------------------------|-----------------------|
| `.ts`, `.tsx` | `<name>.test.ts`, `<name>.spec.ts`, `<name>.test.tsx`, `<name>.spec.tsx` | Same dir as source; `__tests__/` sibling; `tests/` at project root |
| `.js`, `.jsx` | `<name>.test.js`, `<name>.spec.js`, `<name>.test.jsx`, `<name>.spec.jsx` | Same dir as source; `__tests__/` sibling; `tests/` at project root |
| `.py` | `test_<name>.py`, `<name>_test.py` | `tests/` at project root; `test/` at project root; same dir as source |
| `.go` | `<name>_test.go` | Same dir as source (Go convention — always co-located) |
| `.rs` | Same file (Rust uses `#[cfg(test)]` inline modules); separate integration test at `tests/<name>.rs` | Same file (inline); `tests/` at project root |
| `.rb` | `<name>_spec.rb`, `<name>_test.rb` | `spec/` mirroring source dir; `test/` mirroring source dir |

**Matching rules:**
- Strip leading `src/`, `lib/`, or `app/` prefix when searching in `tests/` directories
- For TypeScript/JavaScript, check both `src/__tests__/` and `__tests__/` at project root
- For Python, `test_<module>.py` is the pytest convention; `<module>_test.py` is also accepted

---

## Section 2: Framework Detection Signals + Run Commands

| Config File / Dependency Key | Detected Framework | Run Command Template |
|------------------------------|--------------------|----------------------|
| `package.json` → `"jest"` in devDependencies or `"test": "jest"` in scripts | **Jest** | `npx jest <test-file>` |
| `package.json` → `"vitest"` in devDependencies or `"test": "vitest"` in scripts | **Vitest** | `npx vitest run <test-file>` |
| `package.json` → `"mocha"` in devDependencies or `"test": "mocha"` in scripts | **Mocha** | `npx mocha <test-file>` |
| `package.json` → `"test"` script present (no recognized framework) | **npm test fallback** | `npm test` (no file scoping) |
| `pytest.ini` present OR `[tool.pytest.ini_options]` in `pyproject.toml` | **pytest** | `python -m pytest <test-file> -v` |
| `pyproject.toml` present without pytest section | **pytest** (default Python) | `python -m pytest <test-file> -v` |
| `go.mod` present | **go test** | `go test ./<package-dir>/...` |
| `Cargo.toml` present | **cargo test** | `cargo test --test <test-name>` |
| `Makefile` with `test:` target | **make test** | `make test` (no file scoping) |

**Notes:**
- For Jest and Vitest, pass the resolved test file path directly to scope the run
- For `go test`, use the package directory (the directory containing the `_test.go` file), not the file path
- For `cargo test`, the `<test-name>` is the integration test file stem under `tests/`
- npm test fallback and make test do not support file-level scoping — the full suite runs

---

## Section 3: Result Parsing Patterns

| Framework | Pass Signal | Fail Signal | Error Signal |
|-----------|-------------|-------------|--------------|
| **Jest** | `Tests: N passed` or `✓` / `✅` lines | `Tests: N failed` or `✗` / `✕` lines | `Test suite failed to run` |
| **Vitest** | `✓ N tests passed` | `✗ N tests failed` | `Error:` in stderr |
| **Mocha** | `N passing` | `N failing` | `Error:` before test output |
| **pytest** | `N passed` in summary line | `N failed` in summary line | `ERROR` in summary line |
| **go test** | `ok` prefix on package line | `FAIL` prefix on package line | `panic:` in output |
| **cargo test** | `test result: ok.` | `test result: FAILED.` | `error[E...]` in stderr |
| **make test** | Exit code 0 | Exit code non-zero | Non-zero exit with stderr |

**Extraction rule:** Scan the last 20 lines of stdout for the summary line. If no recognizable summary is found, report the exit code only (PASS for 0, FAIL for non-zero).

---

## Section 4: Missing Test Advisory Templates

Use these file-level message templates when a source file has no corresponding test file.

**TypeScript / JavaScript:**
```
  <source-file>
    → Suggested test file: <conventional-test-path>
    → Create this file and add tests for the functions/components you changed.
    → For test content suggestions, use the reviewing-tests skill.
```

**Python:**
```
  <source-file>
    → Suggested test file: <conventional-test-path>
    → Create this file and add pytest test functions for the code you changed.
    → For test content suggestions, use the reviewing-tests skill.
```

**Go:**
```
  <source-file>
    → Suggested test file: <conventional-test-path>
    → Create this file in the same package and add Test* functions.
    → For test content suggestions, use the reviewing-tests skill.
```

**Rust:**
```
  <source-file>
    → Add a #[cfg(test)] mod tests block at the bottom of this file,
      or create tests/<name>.rs for integration tests.
    → For test content suggestions, use the reviewing-tests skill.
```

**Ruby:**
```
  <source-file>
    → Suggested test file: <conventional-test-path>
    → Create this file and add RSpec examples or Minitest methods for the code you changed.
    → For test content suggestions, use the reviewing-tests skill.
```

**Advisory scope:** File-level only. Do not parse function signatures. Do not generate test stubs. Direct the user to `reviewing-tests` (code-testing-agent plugin) for detailed test content.

---

## Section 5: Monorepo Tie-breaking Rule

In a monorepo with multiple test framework config files (e.g., a root `package.json` with Jest AND a subdirectory `pytest.ini`), use the **nearest ancestor config file** relative to the changed source file.

**Algorithm:**

1. Walk up the directory tree from the changed source file's directory toward the project root
2. At each level, check for the presence of a framework config file (in the order listed in Section 2)
3. Use the **first** config file found — that is the nearest ancestor
4. If two config files are found at the **same directory level**, use the Section 2 priority order (Jest > Vitest > Mocha > npm fallback > pytest > go test > cargo test > make)

**Example:**

```
repo/
├── package.json          ← Jest (root)
├── services/
│   └── auth/
│       ├── pyproject.toml  ← pytest (nearest ancestor for files under services/auth/)
│       └── src/
│           └── token.py    ← changed file → use pytest
└── frontend/
    └── src/
        └── Login.tsx       ← changed file → use Jest (walks up, finds package.json first)
```

If no config file is found anywhere in the tree, fall back to asking the user.
