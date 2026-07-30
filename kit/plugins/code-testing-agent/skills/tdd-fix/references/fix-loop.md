# The red phase and the fix loop

Loaded before Step 2. Covers Steps 2, 3, and 4.

## Step 2: Write the Failing Test (Red Phase)

1. **Locate the test file.** Use `Glob` to find it:
   - `*.test.ts`, `*.test.js`, `*.spec.ts`, `*.spec.js` (JS/TS)
   - `test_*.py`, `*_test.py` (Python)
   - `*_test.go` (Go)
   - `*_test.rs` (Rust)
   - `*.test.sh`, `*.bats` (shell)

   If multiple candidates exist, prefer the one closest in the directory tree
   to the affected source file.

2. **Read the test file** (`Read`) to understand its structure, assertion
   style, and import pattern.

3. **Append a new test case** that will fail because of the bug. Use `Edit`
   (not `Write`) to add to the existing file. The test must:
   - Target exactly the behavior described in Step 1
   - Use the project's existing assertion style
   - Include a comment `# tdd-fix: reproducing <symptom>` (or language
     equivalent) to identify it later

4. **Do NOT edit any production code in this step.**

5. Run the test once (`Bash`) to confirm it fails. If it unexpectedly
   **passes**, stop and use `AskUserQuestion`:
   > "The new test passed without any code changes — the bug may already be
   > fixed, or the test may not be reproducing it correctly. How do you want
   > to proceed?"

---

## Step 3: Autonomous Fix Loop (max 10 iterations)

Initialize an iteration log. Render it as a markdown table and update it
live after each iteration:

```
| # | Hypothesis | Change Made | Result |
|---|------------|-------------|--------|
```

For each iteration `i` from 1 to 10:

### 3a — Form a hypothesis

Read the failure output from the previous run (or from Step 2 on iteration
1). In one sentence, state **why** the test is failing and **what** in the
production code is responsible. Write the hypothesis to the iteration log.

Examples of well-formed hypotheses:
- "Operator in `add()` is subtraction, not addition."
- "`parseDate` does not handle the `Z` timezone suffix."
- "Off-by-one: loop ends at `< n` but should be `<= n`."

### 3b — Edit the production file

Use `Edit` (not `Write`) to apply the minimal change implied by the
hypothesis. Record a one-line diff summary in the log.

Do not refactor unrelated code. Do not add unrelated tests. Change only
what the hypothesis requires.

### 3c — Run the scoped test

Run only the test written in Step 2 via `Bash`. Record the result (`PASS`
or `FAIL + excerpt`) in the iteration log.

- **If PASS**: exit the loop and proceed to Step 5.
- **If FAIL**: if `i < 10`, increment and go to 3a. If `i == 10`, proceed
  to Step 4.

**Show the updated iteration log after every iteration.**

---

## Step 4: Hard Cap — Loop Exhausted

If the loop reaches 10 iterations without a passing test:

1. Print the full iteration log.
2. Surface the last three hypotheses and why each failed.
3. Output:

```
tdd-fix stopped after 10 iterations. The test is still failing.
No commit or PR will be created.

Suggestions for next steps:
- Review the iteration log above for patterns.
- Consider whether the bug is in a different file than expected.
- The test file and any partial edits remain on disk for manual inspection.
```

4. **STOP.** Do not commit, do not open a PR.
