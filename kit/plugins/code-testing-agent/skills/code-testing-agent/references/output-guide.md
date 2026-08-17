# Output Guide

Output template and suggestion principles for Step 5 — suggesting tests with rationale.

## Table of Contents

- [Output Template](#output-template)
- [Suggestion Principles](#suggestion-principles)
- [Worked Example](#worked-example)

---

## Output Template

When analyzing multiple files, group suggestions by file. Use this template for each file:

~~~markdown
## Test Suggestions for `[filename]`

**Plan context:** [Brief note on what the plan says this code should do, or "No plan found — inferred from code"]
**Test framework:** [Detected framework]
**Suggested test file:** `[path/to/suggested.test.ts]`

### Priority 1: Critical Behavior Tests

These verify the code's core purpose — the tests you would write first.

#### Test: [Descriptive test name in sentence form]

**What:** [Specific behavior being tested]
**Why:** [What breaks or goes undetected without this test]
**Code reference:** [File:line or function name this validates]
**Approach:**

```[language]
// Pseudocode or concrete test code using project conventions
```

[Repeat for each Priority 1 test]

### Priority 2: Error Handling and Edge Cases

These verify the code fails gracefully.

[Same format as Priority 1]

### Priority 3: Integration Contract Tests

These verify the code works correctly with its dependencies.

[Same format as Priority 1]

### Priority 4: Coverage-Only Tests `[coverage-only]`

Tests for trivial code (simple getters, pass-through methods, one-line wrappers) that provide minimal behavioral value but are needed to meet the project's coverage target. Only include this section when the coverage target requires it.

[Same format as Priority 1, but each test is tagged `[coverage-only]` and includes a note explaining why it has limited behavioral value]

### Coverage Assessment

**Coverage target:** [X]% (from [config file]) | No target configured — aiming for maximum practical coverage
**Functions/methods covered by suggestions:** [list covered]
**Uncovered gaps:** [list functions, branches, or code paths not covered — with brief reason each is uncovered (e.g., "trivial getter — covered by Priority 4", "dead code", "unreachable branch")]

### Tests NOT Suggested (and Why)

[List 1–3 tests that might seem obvious but are not valuable here, with brief explanation]
~~~

---

## Suggestion Principles

1. **Behavior over implementation.** Test what the code does, not how it does it internally. "When given an expired token, returns 401" is good. "Calls `jwt.verify()` once" is bad — it tests implementation detail.

2. **Plan intent drives design; coverage validates completeness.** Use the plan to determine *what* to test and *why*. Use coverage analysis to ensure nothing important is missed. If the plan says "users must not access other users' data", suggest a cross-user isolation test — even if a coverage tool would not flag its absence.

3. **One reason to fail per test.** Each suggested test should have exactly one reason to fail. A test that asserts five things is five tests.

4. **Name tests as behavior sentences.** "should reject negative quantities in order line items" is good. "test order processing" is bad.

5. **Prioritize by blast radius.** Suggest the tests that catch the most damaging failures first. A missing auth check matters more than a missing null guard on an optional field.

6. **Acknowledge existing coverage.** If existing tests already cover a behavior, do not re-suggest it. Note: "Already covered by [existing test file/name]."

7. **Specify mocking strategy when relevant.** If a test requires mocking an external service, database, or file system, state what to mock and why — do not leave it implicit.

8. **Cover thoroughly, not trivially.** Aim for 5–10 behavior-driven suggestions for a typical file; add more if needed to reach the coverage target. Tag trivial tests `[coverage-only]` with a note explaining their limited behavioral value. Never leave coverage gaps unacknowledged — if a function or branch is intentionally not tested, explain why in the Coverage Assessment.

---

## Worked Example

One filled-in suggestion at the specificity Step 5 expects. Target: a small
helper `parseDuration(input: string): number` in `src/utils/duration.ts` that
converts strings like `"1h30m"` into milliseconds. Framework: Vitest.

~~~markdown
#### Test: should convert "1h30m" to 5,400,000 milliseconds

**What:** Parsing a combined hours-and-minutes string returns the exact
millisecond total (90 minutes at 60,000 ms each).
**Why:** Every scheduler delay flows through this helper — a silent unit mixup
(seconds vs. milliseconds) makes every timeout 1000x off with no error thrown.
**Code reference:** `src/utils/duration.ts:12` — `parseDuration()`
**Approach:**

```ts
import { describe, expect, it } from "vitest";
import { parseDuration } from "../src/utils/duration";

describe("parseDuration", () => {
  it("should convert '1h30m' to 5,400,000 milliseconds", () => {
    expect(parseDuration("1h30m")).toBe(5_400_000);
  });
});
```
~~~

What makes this complete: the name is a behavior sentence, **What** states one
observable behavior, **Why** names the blast radius, the code reference is a
real location, and the snippet runs as written with one reason to fail.
