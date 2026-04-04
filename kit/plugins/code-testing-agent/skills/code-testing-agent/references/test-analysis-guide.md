# Test Analysis Guide

Reference heuristics for analyzing code testability. Loaded by the code-testing-agent skill during Step 3.

## Behavioral Summary Heuristics

When writing the behavioral summary (Step 3a), answer these questions:

1. What does this code transform? (Input -> Output)
2. What side effects does it produce? (Database writes, API calls, file mutations, events)
3. What invariants does it maintain? (Data always consistent, totals always positive, order preserved)
4. Who calls this code and what do they expect?

## Critical Path Identification

### Happy Path Signals

- The primary return statement or resolved promise
- The path with the fewest conditionals
- The path documented in comments or docstrings
- The path matching the function name's implied behavior

### Error Path Signals

- `catch` blocks, `except` clauses, error middleware
- Validation functions that return early
- Status codes in the 4xx/5xx range
- Functions named `handle*Error`, `on*Failure`, `validate*`
- Default/fallback cases in switch statements

### State Transition Signals

- Database operations: `INSERT`, `UPDATE`, `DELETE`, `save()`, `create()`, `destroy()`
- File operations: `writeFile`, `unlink`, `rename`
- Cache operations: `set`, `invalidate`, `delete`
- Queue operations: `publish`, `enqueue`, `ack`

## Integration Point Analysis

### External Dependencies Worth Testing

| Dependency Type | Test Approach | Mock Strategy |
|----------------|---------------|---------------|
| HTTP API calls | Mock the HTTP client or use MSW/nock | Verify request shape and handle response variants |
| Database queries | Use test database or mock the ORM/driver | Verify query parameters and handle connection errors |
| File system | Use temp directories or mock `fs` | Verify paths and handle permission errors |
| Message queues | Mock the producer/consumer | Verify message shape and handle delivery failures |
| Third-party SDKs | Mock the SDK client | Verify correct API usage patterns |

### What NOT to Mock

- Pure utility functions in the same codebase (test them directly)
- Language standard library functions
- Simple data transformations with no side effects

## Implicit Contract Detection

Look for these patterns that indicate unstated promises:

- **Sorting:** Code sorts output but the sort is not reflected in types. Test: verify sort order.
- **Uniqueness:** Code deduplicates but callers assume uniqueness. Test: verify no duplicates in output.
- **Timing:** Code sets timeouts or debounces. Test: verify timing behavior.
- **Encoding:** Code base64-encodes or URL-encodes. Test: verify encoding/decoding roundtrip.
- **Pagination:** Code returns paginated results. Test: verify page boundaries and total counts.
- **Idempotency:** Code can be called multiple times safely. Test: call twice, verify same result.
- **Atomicity:** Code performs multiple operations that should all succeed or all fail. Test: simulate partial failure.

## Fragility Heuristics

### Regex Patterns

If the code uses regex, suggest tests for:
- The intended match case
- A near-miss that should NOT match
- Edge cases: empty string, very long string, special characters, unicode

### Numeric Operations

If the code does arithmetic, suggest tests for:
- Zero values
- Negative values (if applicable)
- Very large values (overflow)
- Decimal precision (floating point)

### String Manipulation

If the code processes strings, suggest tests for:
- Empty string
- String with only whitespace
- Unicode characters, emoji
- Very long strings
- Strings with special characters relevant to the context (HTML entities, SQL metacharacters, path separators)

### Collection Operations

If the code operates on arrays/lists/sets, suggest tests for:
- Empty collection
- Single-element collection
- Collection with duplicates (if relevant)
- Collection at boundary sizes (if pagination or batching is involved)

## Language-Specific Patterns

### TypeScript / JavaScript

- Async functions: test both resolved and rejected paths
- Optional chaining: test when the chain returns undefined
- Type narrowing: test each branch of discriminated unions
- Event handlers: test that events are properly bound and cleaned up

### Python

- Context managers: test `__enter__` and `__exit__` (especially cleanup on exception)
- Generators: test lazy evaluation and StopIteration
- Decorators: test that decorated functions retain expected behavior
- Exception hierarchies: test specific exception types, not just base Exception

### Go

- Error return values: test both `(result, nil)` and `(zero, error)` paths
- Goroutines: test concurrent behavior with race detector
- Interfaces: test against the interface, not the concrete type
- Table-driven tests: follow the `[]struct{ name string; ... }` pattern

### Rust

- `Result` types: test both `Ok` and `Err` variants
- `Option` types: test both `Some` and `None`
- Lifetime-sensitive code: test ownership transfer and borrowing
- `#[should_panic]` for expected panics
