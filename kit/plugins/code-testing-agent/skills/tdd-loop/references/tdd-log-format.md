# TDD Iteration Log Format

Shared schema used by `tdd-loop` (and referenced by `tdd-fix` in a future
update). All autonomous loop skills should emit logs in this format so
reviewers have a consistent reading experience across PRs.

---

## Table Schema

```
| #  | Phase | Hypothesis                                    | Files Touched      | Failing Before | Failing After |
|----|-------|-----------------------------------------------|--------------------|----------------|---------------|
```

### Column definitions

| Column | Type | Description |
|--------|------|-------------|
| `#` | integer or string | Iteration number. Use `1`, `2`, … for impl iterations (Step 4). Use `g1`, `g2`, … for gate-fix iterations (Step 5). |
| `Phase` | string | `impl` for implementation iterations; `gate` for quality-gate fix iterations. |
| `Hypothesis` | string | One sentence: what the failure reason is and what change is expected to fix it. Append `(test edited: <reason>)` if the test-edit escape hatch was used. |
| `Files Touched` | string | Comma-separated relative paths of files modified in this iteration. |
| `Failing Before` | string | Number of failing tests (impl) or gate names (gate) at the start of the iteration. |
| `Failing After` | string | Number of failing tests (impl) or gate names (gate) after the edit. Use `0` for green; `typecheck:0, lint:1` style for gate columns. |

### Phase indicator

- An `*` appended to the `#` cell marks a test-edit iteration (consumes 2 cap slots).
- Example: `| 5* | impl | Fixed wrong aria-controls value (test edited: assertion used wrong id format) | src/Tabs.tsx, src/Tabs.test.tsx | 3 | 2 |`

---

## Full Example (tdd-loop Tabs run)

```
| #  | Phase | Hypothesis                                                                     | Files Touched                           | Failing Before | Failing After |
|----|-------|--------------------------------------------------------------------------------|-----------------------------------------|----------------|---------------|
| 1  | impl  | Need role=tablist on the container element                                     | src/Tabs.tsx                            | 9              | 7             |
| 2  | impl  | aria-selected must be a string "true"/"false", not a boolean                  | src/Tabs.tsx                            | 7              | 5             |
| 3  | impl  | Hidden panels need the HTML hidden attribute, not CSS display:none            | src/Tabs.tsx                            | 5              | 3             |
| 4  | impl  | ArrowRight handler must wrap from last to first (modulo)                      | src/Tabs.tsx                            | 3              | 2             |
| 5* | impl  | Home key index off-by-one (test edited: test expected index 0, not 1)         | src/Tabs.tsx, src/Tabs.test.tsx         | 2              | 0             |
| g1 | gate  | tsc: implicit any on TabProps.tabs array                                      | src/Tabs.tsx                            | typecheck:2    | typecheck:0   |
```

---

## Embedding in PR Bodies

Include the log under a `## TDD iterations` section. Gate-fix rows can be
combined in the same table (they self-identify via Phase = `gate`) or split
into a separate `## Gate fixes` section for clarity.

Omit the `## Gate fixes` section entirely if no gate-fix iterations occurred.
