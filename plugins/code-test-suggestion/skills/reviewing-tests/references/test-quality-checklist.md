# Test Quality Checklist

Reference heuristics for reviewing existing test quality. Loaded by the reviewing-tests skill during Step 6.

## 1. Behavior vs Implementation

### Implementation Coupling Anti-Patterns

Flag these — they test *how* the code works, not *what* it does:

- **Spy on internal methods:** `expect(spy).toHaveBeenCalledWith(...)` on a private/internal method of the system under test. The test should verify the outcome, not the call chain.
- **Asserting call order:** `expect(mockA).toHaveBeenCalledBefore(mockB)` unless the order is part of the public contract (e.g., middleware pipeline).
- **Verifying internal state:** Accessing private fields or internal data structures to assert on. Test through the public API instead.
- **Testing function composition:** Asserting that function A calls function B internally. If B's behavior matters, test it through A's output.

### Behavior Testing Patterns (Good)

- Asserting on return values given specific inputs
- Asserting on side effects visible to the caller (database state, HTTP response, emitted events)
- Asserting on error types/messages for invalid inputs
- Asserting on observable state changes (UI updates, file contents)

## 2. Test Naming

### Anti-Patterns

- `test1`, `test2`, `testFunction` — no indication of what behavior is tested
- `it('works')`, `it('should work')` — what does "works" mean?
- `it('handles edge case')` — which edge case?
- Single-word names: `test('login')`, `test('validation')`
- Implementation names: `test('calls processOrder')` — names the implementation, not the behavior

### Good Patterns

- `it('should reject negative quantities in order line items')`
- `it('returns 401 when the auth token is expired')`
- `test('preserves sort order when merging two sorted arrays')`
- `it('sends a confirmation email after successful registration')`

### Heuristic

A good test name answers: "If this test fails, what behavior is broken?" If the name doesn't answer that question, flag it.

## 3. Assertion Focus

### Multi-Assertion Anti-Pattern

Flag tests with 5+ assertions that test different behaviors:

```javascript
// BAD — three different behaviors in one test
it('processes order', () => {
  const result = processOrder(order);
  expect(result.status).toBe('confirmed');     // behavior 1: status
  expect(result.total).toBe(99.99);            // behavior 2: calculation
  expect(sendEmail).toHaveBeenCalled();        // behavior 3: side effect
  expect(inventory.count).toBe(4);             // behavior 4: inventory update
  expect(auditLog.entries).toHaveLength(1);    // behavior 5: audit logging
});
```

### Exceptions (Not Anti-Patterns)

- Multiple assertions on the *same* return object shape (verifying a single data structure)
- Setup assertions followed by the real assertion (e.g., asserting preconditions)
- Parameterized/table-driven tests with one assertion per case

## 4. Coverage Gaps

### How to Cross-Reference

For each critical path identified in the source code analysis (Step 4):

1. Search the test file for test names or assertions that exercise that path
2. Check if the test actually reaches that code path (not just calling the function — does it trigger the specific branch?)
3. Flag missing paths with their priority level:
   - **P1** — Happy path not tested, or primary error path not tested
   - **P2** — Specific branch/edge case not tested
   - **P3** — Integration contract not verified

### Common Gaps to Check

- Error handling paths (catch blocks, error returns)
- Boundary conditions (empty input, max values, zero)
- Conditional branches that only execute under specific conditions
- Async rejection/error paths
- Cleanup/teardown code (finally blocks, defer statements)

## 5. Mock Hygiene

### Over-Mocking (Flag)

- Mocking the module under test itself
- Mocking pure utility functions with no side effects
- Mocking language standard library functions
- Mocking every dependency — leaving nothing real to test
- "Mock sandwich": mocking A, which calls B (also mocked), which calls C (also mocked) — at this point you're testing your mocks

### Under-Mocking (Flag)

- Real HTTP calls in unit tests (flaky, slow, environment-dependent)
- Real database queries in unit tests without a test database
- Real file system operations without temp directories
- Real third-party SDK calls (API rate limits, costs, network dependency)

### Stale Mocks (Flag)

Signs that a mock doesn't match the real implementation:

- Mock returns a data structure the real API no longer uses
- Mock accepts parameters the real function no longer takes
- Mock doesn't simulate error conditions the real service now produces
- Mock was copy-pasted from another test and not adapted

### How to Detect Stale Mocks

Compare the mock's return value shape against the actual function's return type/signature. If they've diverged, the test gives false confidence.

## 6. Test Fragility

### Fragility Signals

- **Snapshot tests of unstable output:** Snapshots that change on every run (timestamps, random IDs, build hashes)
- **Testing internal method calls:** `expect(internalMethod).toHaveBeenCalled()` — breaks when you refactor internals
- **Hardcoded values from external systems:** Asserting on specific database IDs, API response bodies, or file contents that could change
- **Timing-dependent tests:** `setTimeout(() => expect(...), 100)` — flaky across environments
- **Order-dependent tests:** Tests that pass only when run in a specific sequence
- **Environment-dependent tests:** Tests that rely on specific OS, timezone, locale, or environment variables without setup

### Resilience Patterns (Good)

- Testing behavior through public API
- Using matchers instead of exact values (`expect.objectContaining`, `toMatch`)
- Isolating tests with proper setup/teardown
- Using factories or builders for test data instead of hardcoded fixtures

## 7. Setup/Teardown Isolation

### State Leakage Anti-Patterns

- **Global variable mutation:** Test A sets a global variable, test B reads it — tests pass in sequence but fail in isolation or parallel
- **Missing database cleanup:** Test inserts rows but doesn't clean up — later tests see unexpected data
- **Shared mock state:** Mock accumulates call history across tests without `mockClear()` or `mockReset()`
- **Module-level side effects:** Importing a module triggers side effects (file writes, HTTP calls) that persist across tests
- **Singleton mutation:** Test modifies a singleton/cache that persists across test files

### Isolation Patterns (Good)

- `beforeEach`/`afterEach` for per-test setup and cleanup
- Test databases with transaction rollback
- `jest.restoreAllMocks()` or equivalent in `afterEach`
- Factory functions that create fresh test data per test
- Temp directories for file system tests

## 8. Plan Alignment

### How to Check

For each key behavior, edge case, and acceptance criterion extracted from the plan (Step 3):

1. Search the test file for a test that explicitly verifies it
2. Note whether the test name references the plan requirement
3. Flag plan requirements with no corresponding test

### Output Format

```markdown
| Plan Requirement | Test Coverage | Status |
|-----------------|---------------|--------|
| Users cannot access other users' data | `should deny access to other user's profile` | Covered |
| Login rate limiting after 5 failures | (none) | **Missing** |
| Password reset token expires after 1 hour | (none) | **Missing** |
```

## 9. Coverage Target Progress

### How to Evaluate

List all exported functions/methods in the source file. For each one, check if any test exercises it:

- **Covered:** At least one test calls or exercises this function
- **Partially covered:** The function is called but not all branches are tested
- **Uncovered:** No test exercises this function

Report qualitatively (never guess a percentage — Claude cannot run the coverage tool):

> "6 of 9 exported functions have at least one test. Uncovered: `validateInput`, `handleTimeout`, `cleanupExpiredSessions`."

If a coverage target exists, note whether the gaps are likely to push coverage below the target.

## Language-Specific Review Patterns

### TypeScript / JavaScript

- Flag `any` in test types — tests should use correct types
- Check for unhandled promise rejections in async tests (missing `await`, missing `.rejects`)
- Flag `@ts-ignore` or `@ts-expect-error` that suppress real type issues in tests
- Check that `jest.mock()` calls match the module's actual export shape

### Python

- Flag bare `except` clauses in test assertions — test specific exception types
- Check that `unittest.mock.patch` targets are correct (common mistake: patching where defined vs where used)
- Flag `assert` statements instead of `self.assert*` methods (bare assert gives unhelpful failure messages)
- Check that `pytest.raises` uses the specific exception type, not bare `Exception`

### Go

- Flag tests that don't use `t.Helper()` in helper functions (error locations will be wrong)
- Check for missing `t.Parallel()` in tests that could run concurrently
- Flag tests that ignore error returns: `result, _ := functionUnderTest()`
- Check table-driven test structure: each case should have a descriptive `name` field

### Rust

- Flag tests that use `unwrap()` instead of `?` or explicit error matching
- Check that `#[should_panic]` tests verify the panic message, not just that a panic occurs
- Flag tests that assert on `Debug` output (format can change between Rust versions)
- Check that async tests use the correct runtime attribute (`#[tokio::test]`, `#[actix_rt::test]`)
