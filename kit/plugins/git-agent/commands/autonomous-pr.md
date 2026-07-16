---
description: Drive an objective from plan through implementation and hand off to ship-autonomous, which verifies, opens the PR, and gates the merge
---

# Autonomous PR

Take a feature request from objective to a merged-or-awaiting-approval PR.

Objective: `$ARGUMENTS`. If empty, ask for one via `AskUserQuestion` and stop
if unanswered.

This command is the **front half** only — planning and implementation. Once
there is code, `ship-autonomous` owns everything downstream and already does
it well. Do not verify, commit, poll CI, or merge here; that is its job, not
this command's.

## 1. Plan

Invoke `plan-agent:implementation-plan` with the objective. At its Step 8
menu, choose `Implement now`.

## 2. Implement

Work the plan's steps. Where a step touches testable application code, invoke
`code-testing-agent:tdd-loop` for that step rather than writing the code first
and the tests after.

Tick each step's `[x]` marker in the plan's markdown spec as you finish it,
and run the plan's acceptance-criteria gate before moving on.

## 3. Hand off

Invoke `git-agent:ship-autonomous`. It owns the rest of the pipeline:

- **Step 2.5** runs the project's tests and, when the change is observable in
  a browser, previews it and checks console and server logs across both
  themes — blocking on any error.
- **Steps 3–7** branch, commit, open the PR, subscribe to PR activity (or poll
  as fallback), autofix the safe allowlist at ≤3 attempts per check, and
  handle review comments.
- **Step 8** re-confirms green, re-fetches the live review decision, and gates
  the merge behind `AskUserQuestion` — with branch deletion requiring its own
  separate approval.

**You never merge from this command.** The merge decision belongs to the user,
and `ship-autonomous` Step 8 is where they make it. Do not front-run it,
pre-approve it, or answer its prompt on the user's behalf.

## 4. File out-of-scope findings

Anything worth fixing that would bloat this PR: invoke `git-agent:create-issue`
to file it. Do not fix it here — that is how a scoped PR becomes an unreviewable
one.
