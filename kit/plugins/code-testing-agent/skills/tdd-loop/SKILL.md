---
name: tdd-loop
description: "Implements features via TDD with up to 20 red-green-refactor rounds. Writes failing tests first, then iterates until all pass. Use when the user asks to TDD a new feature or write tests first."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, TodoWrite, Skill, ToolSearch, ExitPlanMode
disable-model-invocation: true
---

Given a feature description, write a failing test suite that covers every
acceptance criterion, commit it, then loop autonomously — run tests, form a
hypothesis, edit production code, re-run — up to 20 iterations. On green,
run typecheck and lint (up to 5 gate-fix iterations), commit the implementation
with a separate `feat:` commit, and open a PR.

> **Freedom level: Strict** — Follow these steps in order. Do not skip or
> combine steps. Stop at each hard-stop marker.

## When not to use

Does not fix existing bugs — use tdd-fix. Does not suggest tests without implementing — use code-testing-agent.

## Table of Contents

- [Step 0: Pre-flight and TodoWrite](#step-0-pre-flight-and-todowrite)
- [Step 1: Parse Feature Spec and Detect Framework](#step-1-parse-feature-spec-and-detect-framework)
- [Step 2: Write Failing Test Suite (Red Phase)](#step-2-write-failing-test-suite-red-phase)
- [Step 3: Commit the Tests](#step-3-commit-the-tests)
- [Step 4: Autonomous Implementation Loop (max 20)](#step-4-autonomous-implementation-loop-max-20)
- [Step 5: Quality Gates (max 5)](#step-5-quality-gates-max-5)
- [Step 6: Commit the Implementation](#step-6-commit-the-implementation)
- [Step 7: Open PR](#step-7-open-pr)
- [Step 8: Stop](#step-8-stop)

---

## Step 0: Pre-flight and TodoWrite

### Exit Plan Mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

### Repository guards

Run `git status --porcelain`. If the output is non-empty, output:

```
Working tree is dirty. Commit or stash changes before running tdd-loop.
```

**STOP.**

Run `git branch --show-current`. If empty (detached HEAD), output:

```
Cannot run: repository is in detached HEAD state. Checkout a branch first.
```

**STOP.**

If the current branch is `main` or `master`, output:

```
Create a feature branch first (e.g., invoke git-agent:branch-agent), then re-run.
```

**STOP.**

### Seed todos

Use `TodoWrite` to create todos for Steps 1–8, all `status: "pending"`.
Mark each `status: "completed"` as you finish it.

---

## Step 1: Parse Feature Spec and Detect Framework

Extract from the invocation message:

| Field | Source |
|-------|--------|
| **Feature name** | Explicit, or derived from description |
| **Acceptance criteria** | Numbered list from message or a linked file |
| **Target file** | Explicit path, or infer from feature name + project layout |
| **Test file** | Explicit path, or infer from target file using naming conventions |

If acceptance criteria cannot be enumerated from the message, output:

```
Cannot proceed: no acceptance criteria found. Re-invoke with a numbered list
of behaviors the implementation must satisfy.
```

**STOP.**

### Framework detection

Use the heuristics from the `running-tests` skill (inspect `package.json`,
`vitest.config.*`, `pytest.ini`, `pyproject.toml`, `go.mod`, `Cargo.toml`,
and nearest-ancestor `Makefile`) to identify the correct test runner.

**If no framework is detected** (language not yet covered — Rust, Ruby, Java,
Elixir, etc.), the skill is permitted exactly **one** `AskUserQuestion` call:

> "No recognized test framework was detected. Choose one:"
> - Use the `tests/demo/` Bash fixture pattern as a zero-dependency fallback (Recommended)
> - Abort — I will add framework support first, then re-run

This is the only `AskUserQuestion` call allowed in this skill. The Step 4 loop
is completely forbidden from calling it.

---

## Step 2: Write Failing Test Suite (Red Phase)

Create the test file at the path resolved in Step 1. Do not create the
production file yet.

Write one test block per acceptance criterion (minimum one assertion per
block). Use `describe` / `it` grouping where idiomatic. Use the project's
existing assertion style (read a nearby test file with `Read` to infer).

Run the scoped test suite (`Bash`):

- **All tests fail** → correct. Proceed to Step 3.
- **Any test passes** before any production code exists → the test is wrong
  (likely too lenient, trivially true, or the feature already exists).
  Output:

  ```
  Test passed without any production code — likely too lenient or already
  implemented. Review the failing/passing breakdown before proceeding.
  ```

  **STOP.**

---

## Step 3: Commit the Tests

Invoke the `commit-agent` skill. When it drafts the commit message, ensure:

- Type is `test`
- Description summarizes the feature in imperative mood
- Example: `test(src/Tabs): failing suite for accessible Tabs component`

The `commit-agent` handles staging, pre-commit hooks, and conventional format.
Do not duplicate that logic here.

**STOP here — do not write production code yet.**

---

## Step 4: Autonomous Implementation Loop (max 20 iterations)

Initialize an iteration log (see `references/tdd-log-format.md` for schema).
Render it as a markdown table and update it live after every iteration.

### Loop rules

For each iteration `i` from 1 to 20:

**4a — Read failures.** Run the scoped test suite. Capture the failure output.

**4b — Form a hypothesis.** In one sentence, state why the test is failing
and what production-code change is responsible.

**4c — Edit production code only.** Use `Edit` (never `Write` to replace the
full file). Change only what the hypothesis requires. Do not refactor unrelated
code.

**4d — Re-run scoped tests.** Record the result in the iteration log.

**4e — Check for green.** If failing-count = 0, exit the loop and proceed to
Step 5.

**Show the updated iteration log after every iteration.**

### Iteration-1 early-green check

If failing-count was N > 0 at the end of Step 2, and goes to 0 after a single
edit in iteration 1, output:

```
EARLY_GREEN: tests went green in one iteration.
This may mean the tests were too lenient or the feature was already partially
implemented. Diff of iteration-1 changes:
[paste the diff]

Review the test suite for adequacy before proceeding.
```

**STOP.** Do not commit. Do not open a PR.

### Hard rules inside the loop

- **Forbidden edits:** deleting tests, `.skip`, `xfail`, `@ts-ignore`,
  `as any`, mocking the unit under test, modifying test assertions (except via
  the escape hatch below).
- **No `AskUserQuestion`** — forbidden inside the loop.
- **No plan mode** — forbidden inside the loop.
- **No commits** — commits happen in Steps 3 and 6 only.

### Test-edit escape hatch (single use)

If, mid-loop, a test has a genuine defect (typo, wrong assertion discovered
during implementation):

- One test edit is allowed per full loop run.
- Append `(test edited: <reason>)` to the Hypothesis cell of the iteration row.
- **Count this iteration as 2** against the 20-cap.
- If a second test edit is attempted in the same loop run → STOP and escalate.

### Hard-cap behavior

If iteration 20 ends with failing tests:

1. Print the full iteration log.
2. Output:

   ```
   tdd-loop stopped after 20 iterations. Tests are still failing.
   No implementation commit or PR will be created.
   The test: commit is on the branch; partial code changes are on disk (uncommitted).
   Next steps: inspect the iteration log above, continue manually, or reset the branch.
   ```

3. **STOP.** Do not auto-revert. Leave the branch as-is for manual inspection.

---

## Step 5: Quality Gates (max 5 iterations)

Run all three gates in sequence:

1. **Typecheck** — `npx tsc --noEmit` if `tsconfig.json` exists; else `mypy`,
   `go vet`, `cargo check`, or equivalent.
2. **Lint** — `npm run lint` if the script exists; else `eslint`, `ruff`,
   `golangci-lint`, as appropriate.
3. **Full test suite** — not scoped; must cover all previously-passing tests
   (regression sweep).

If all pass → proceed to Step 6.

If any fail → enter a separate gate-fix loop (max **5** iterations). For each
gate-fix iteration:

- Read the failure.
- Edit production code only (same forbidden list as Step 4).
- Re-run all three gates.
- Log to the gate-fix section of the iteration log (phase `gate`, numbered
  `g1`, `g2`, etc. — see `references/tdd-log-format.md`).

If gate-fix cap (5) is exhausted → output:

```
Quality gates failed after 5 fix iterations.
No implementation commit or PR will be created.
Gate failure details: [last output of each failing gate]
```

**STOP.**

---

## Step 6: Commit the Implementation

Invoke the `commit-agent` skill. When it drafts the commit message, ensure:

- Type is `feat`
- Scope and description match the feature name from Step 1
- Example: `feat(src/Tabs): accessible Tabs component (WAI-ARIA tablist pattern)`

Result: the branch now has exactly two feature commits — `test: …` then
`feat: …`.

---

## Step 7: Open PR

Invoke the `pr-agent` skill. When it drafts the PR body, include:

- A `## TDD iterations` section with the full iteration log from Step 4.
- A `## Gate fixes` section with the gate-fix log from Step 5 (omit if empty).
- A `## tdd-loop summary` line: "N/20 impl iterations, M/5 gate iterations."

**Note:** Do not chain this skill with `ship-autonomous` in the same session.
Both access `gh pr checks` and may interleave state unpredictably.

---

## Step 8: Stop

Print a summary line:

```
tdd-loop complete. N/20 impl iterations, M/5 gate iterations.
PR: <url>
```

**STOP here.** Do not poll CI, re-run tests, suggest refactors, or take any
further action. CI watching is `ship-autonomous`'s responsibility.
