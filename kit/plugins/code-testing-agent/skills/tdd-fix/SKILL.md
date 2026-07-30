---
name: tdd-fix
description: "Fixes bugs via TDD with up to 10 red-green iterations. Writes a failing test then autonomously iterates until the bug is resolved. Use when the user asks to TDD-fix a bug or run a red-green cycle."
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, TodoWrite, AskUserQuestion
disable-model-invocation: true
---

Given a bug description, write a failing test that reproduces it, then loop —
run tests, analyze failures, edit code, re-run — until green or 10 iterations,
logging each hypothesis. Then sweep the full suite, commit with a `fix:` prefix,
and open a PR.

> **Freedom level: Strict** — Follow these steps in order. Do not skip or
> combine steps. Stop at each hard-stop marker.

## When not to use

Does not design tests from scratch — use code-testing-agent. Does not review test quality — use reviewing-tests.

## References

- `references/fix-loop.md` — Step 2's red phase, Step 3's iteration log and 3a–3c, Step 4's hard cap
- `references/handoff.md` — Step 5's regression sweep, Step 6's summary block, Steps 7–8's commit-agent and pr-agent handoffs

---

## Step 0: Create Progress Todos

Use `TodoWrite` to create todos for Steps 1–9, all `status: "pending"`.
Mark each `status: "completed"` as you finish it.

---

## Step 1: Parse Bug Description

Extract from the invocation message:

| Field | What to extract |
|-------|----------------|
| **Symptom** | What the code currently does wrong |
| **Expected behavior** | What it should do instead |
| **Affected file(s)** | Source file(s) holding the bug — explicit path, or inferred |
| **Test file** | Its test file (infer from naming convention if not given) |

**If a field is missing and cannot be inferred**, use `AskUserQuestion` for
that field only. Do not ask for everything at once.

**Do not open any source file yet.** Only parse the message.

---

## Step 2: Write the Failing Test (Red Phase)

Read `references/fix-loop.md` now and follow its Step 2: locate the test file,
append one failing case, edit **no** production code, run it once to confirm it
fails. A test that passes here is a hard stop — ask, do not enter the loop.

---

## Step 3: Autonomous Fix Loop (max 10 iterations)

Per `references/fix-loop.md` Step 3: hypothesis (3a), minimal `Edit` (3b), scoped
test run (3c), logging and showing every iteration. PASS exits to Step 5; FAIL at
`i == 10` goes to Step 4.

---

## Step 4: Hard Cap — Loop Exhausted

Ten iterations without green is the cap. Print the full log and the stop message
from `references/fix-loop.md`, then **STOP** — no commit, no PR.

---

## Step 5: Regression Sweep

Read `references/handoff.md` and run its Step 5: the **full** suite, no scope
filter. A previously-passing test that now fails is a hard stop — report the
regressions and **STOP** without committing.

---

## Step 6: Summarize the Fix

Print the summary block defined in `references/handoff.md` before committing.

---

## Step 7: Commit via commit-agent

Invoke `commit-agent` per `references/handoff.md`: type `fix`, scope from the
most-changed top-level directory. Do not duplicate its staging or hook logic.

---

## Step 8: Open PR via pr-agent

Invoke `pr-agent` per `references/handoff.md`, including the Step 3 log under a
`## How it was found (tdd-fix)` section.

---

## Step 9: Stop

**STOP here.** Do not analyze code further, re-run tests, suggest refactors or
cleanup, or open additional issues. The fix is complete when `pr-agent` returns
the PR URL.
