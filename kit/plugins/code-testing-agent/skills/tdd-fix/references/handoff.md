# Regression sweep, summary, and handoff

Loaded once the scoped test passes. Covers Steps 5 through 8.

## Step 5: Regression Sweep

Once the scoped test passes, run the **full** test suite with no scope
filter. Use `Bash` with the appropriate full-suite command for the project:

- Node/JS: `npm test`, `yarn test`, `pnpm test`, or `npx vitest run`
- Python: `pytest`, `python -m pytest`
- Go: `go test ./...`
- Shell: run the top-level test runner script if one exists

If any **previously-passing** test now fails:

1. Report the regressions — test names and failure excerpts.
2. Do not commit.
3. Output:

```
Regression detected. The fix broke existing tests (listed above).
No commit or PR will be created. The changes remain on disk.
```

4. **STOP.**

If all tests pass, continue to Step 6.

---

## Step 6: Summarize the Fix

Print a summary block before committing:

```
## tdd-fix Summary

Bug:        <symptom from Step 1>
Fix:        <final hypothesis from Step 3>
Iterations: <i of 10>
Files changed:
  - <production file(s) edited>
  - <test file appended>
Full suite: PASS
```

---

## Step 7: Commit via commit-agent

Invoke the `commit-agent` skill. When it drafts the commit message, ensure:

- Type is `fix`
- Scope is the most-changed top-level directory
- Description summarizes the symptom in imperative mood

Example: `fix(tests/demo): correct add() operator from subtraction to addition`

The `commit-agent` skill handles staging, pre-commit hooks, and conventional
format — do not duplicate that logic here.

---

## Step 8: Open PR via pr-agent

Invoke the `pr-agent` skill. When it drafts the PR body, include the
iteration log from Step 3 under a `## How it was found (tdd-fix)` section.

The `pr-agent` skill handles push, platform detection (GitHub/GitLab), and
branch checks — do not duplicate that logic here.
