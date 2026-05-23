---
name: ship-autonomous
description: >
  Use when the user asks to autonomously ship, ship and watch CI, auto-fix CI
  failures, or ship it and fix what breaks. Chains branch creation (if needed),
  commit, PR, CI polling, and a bounded autofix loop into one supervised flow.
allowed-tools: Bash(git *), Bash(gh *), Bash(npm *), Bash(pnpm *), Bash(yarn *), Bash(jq *), Skill, Read, Edit, Grep, Glob, TodoWrite, AskUserQuestion, ToolSearch, ExitPlanMode
---

Autonomously branch, commit, open a PR, poll CI, and fix allow-listed failures
— up to 3 iterations. Follow these steps in strict order. **STOP immediately
after Step 7.**

---

## Step 0: Exit Plan Mode

Call `ExitPlanMode` immediately and silently — always, unconditionally, before
any other action. This is a no-op when plan mode is already off, so it is safe
to call regardless. Committing, pushing, and opening a PR are mutations that
cannot proceed inside plan mode.

`ExitPlanMode` is a deferred tool. Use `ToolSearch` with `select:ExitPlanMode`
first to load its schema, then call `ExitPlanMode`. Both steps run silently
with no user-visible output.

---

## Step 1: Pre-flight Guards

Run all checks before any mutation.

**Clean working tree:**

```
git status --porcelain
```

If empty, output: "Nothing to ship — working tree is clean." and **STOP**.

**Uncommitted plan files:**

```
git ls-files --others --modified --exclude-standard docs/plans/
```

If any plan files are listed, output them and ask:

> Uncommitted plan files detected. How would you like to proceed?
> - `include` — stage them with the rest of the changes
> - `stash` — `git stash` them before branching (you can restore after)
> - `abort` — stop here; commit or clean up plan files first

Use AskUserQuestion with those three options. On `abort`, **STOP**.

**Detached HEAD:**

```
git branch --show-current
```

If empty, output: "Cannot ship: repository is in detached HEAD state. Checkout
a branch first." and **STOP**.

**GitHub CLI auth:**

```
gh auth status
```

If not installed or not authenticated, output:

```
GitHub CLI is required. Install from https://cli.github.com/ and run `gh auth login`.
```

and **STOP**.

---

## Step 2: Branch

Check current branch:

```
git branch --show-current
```

Detect the default branch:

```
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```

If the current branch **is** the default branch (or `main`/`master` as
fallback), invoke the existing `git-agent:branch-agent` skill with no
arguments. It will auto-generate a `<type>/<scope>-<desc>` slug from the
working tree and branch from `origin/HEAD --no-track`.

If already on a feature branch, continue without creating a new branch.

---

## Step 3: Commit

Invoke the existing **`git-agent:commit-agent`** skill. It stages all changes,
analyzes the diff, writes a conventional commit message, and commits.

**If commit-agent stops due to a pre-commit hook failure:** propagate the
failure message verbatim and **STOP**. Do not retry. Do not use `--no-verify`.

---

## Step 4: Open PR

Invoke the existing **`git-agent:pr-agent`** skill. It:

- Pushes the branch (sets upstream if needed)
- Checks for an existing open PR (skips creation if OPEN; creates if
  MERGED/CLOSED/missing — v3.3.2 fix)
- Generates a Summary/Changes PR body from `git log base..HEAD`
- Opens the PR via `gh pr create`

Capture the PR URL from pr-agent's final output — look for the line containing
`https://github.com/.*/pull/\d+`.

---

## Step 5: Poll CI

Run:

```
gh pr checks <pr-url> --watch --fail-fast=false
```

This blocks until every check reaches a terminal state (success, failure,
skipped, cancelled).

After it exits, retrieve the structured results:

```
gh pr checks <pr-url> --json name,state,conclusion,workflowName
```

Parse with `jq`. If **all conclusions are `SUCCESS` or `SKIPPED`**, jump
directly to Step 7 (request review).

If any conclusion is `FAILURE`, proceed to Step 6.

If any conclusion is `CANCELLED` or `TIMED_OUT`, escalate:

> CI check `<name>` was cancelled/timed out. Manual intervention may be
> needed. PR: <url>

and **STOP**.

---

## Step 6: Autofix Loop (max 3 iterations)

Track the iteration counter with TodoWrite. Label the task
`autofix-iteration-N` and mark it `in_progress` at the start of each cycle.

### 6a: Classify the failure

For each failing check, fetch the log:

```
gh run list --json databaseId,conclusion,workflowName --jq '.[] | select(.conclusion=="failure") | .databaseId' | head -1
```

Then:

```
gh run view <run-id> --log-failed
```

Classify based on log content:

| Class | Signature in log | Allowed action |
|---|---|---|
| `lint` | `eslint`, `lint error`, rule violation names | Run the project's lint-fix command |
| `typecheck` | `TS`, `TypeScript`, `error TS`, `tsc` | Apply minimal TS fixes |
| `peer-deps` | `peer dep`, `ERESOLVE`, `incompatible peer` | Reinstall lockfile |
| anything else | any other content | **Escalate — do not attempt fix** |

### 6b: Apply fix (allow-listed classes only)

**`lint`:** Detect the project's lint-fix command:

```
jq -r '.scripts | to_entries[] | select(.key | test("lint")) | "\(.key): \(.value)"' package.json 2>/dev/null
```

Run the script that includes `--fix` (or add `--fix` if the lint script uses
`eslint` directly). If no lint script exists, escalate.

**`typecheck`:** Read the reported TypeScript errors from the log. Apply
minimal fixes: add missing imports, use correct existing types. Never introduce
`any`, `as unknown`, `// @ts-ignore`, or `// @ts-expect-error`. Never loosen
an existing type. If the error requires type loosening, escalate.

**`peer-deps`:** Detect the package manager:

```
test -f pnpm-lock.yaml && echo pnpm || test -f yarn.lock && echo yarn || echo npm
```

Run `pnpm install` / `yarn install` / `npm install`. Then verify the diff is
lockfile-only:

```
git diff --name-only
```

If any non-lockfile files changed, escalate (something unexpected mutated).

**Escalation format for disallowed classes:**

```
Cannot auto-fix: check '<name>' (class: unknown) failed with:
<first 20 lines of log>

PR: <url>
Iteration: N/3
```

Then **STOP**.

### 6c: Commit the fix and re-poll

After applying a fix:

1. Invoke **`git-agent:commit-agent`** for the fix commit. Message will be
   auto-generated (it should produce something like
   `fix(scope): address lint failures`).
2. Run `git push`.
3. Return to Step 5 to re-poll checks.

### 6d: Hard cap

If the iteration counter reaches 3 and checks are still failing:

```
gh pr comment <pr-url> --body "Autonomous autofix reached 3-iteration cap. Remaining failures require manual intervention. See CI logs for details."
```

Output:

```
Autofix cap reached (3/3). PR comment added. Manual action required.
PR: <url>
```

and **STOP**.

---

## Step 7: Request Review

When all checks are green (all conclusions `SUCCESS` or `SKIPPED`):

Mark the PR ready if it was opened as draft:

```
gh pr ready <pr-url>
```

Add a review-ready comment:

```
gh pr comment <pr-url> --body "CI is green — ready for review."
```

Output the PR URL and **STOP**.

---

**STOP here. Do not analyze code, run tests, review the diff, suggest
follow-up tasks, or take any further action.**
