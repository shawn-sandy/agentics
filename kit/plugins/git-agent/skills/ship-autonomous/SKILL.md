---
name: ship-autonomous
description: "Runs the full ship pipeline with CI polling and bounded autofix. Chains commit, PR, CI poll, and autofix in one supervised flow. Use when the user asks to autonomously ship or watch CI."
allowed-tools: Bash(git *), Bash(gh *), Bash(npm *), Bash(pnpm *), Bash(yarn *), Bash(jq *), Skill, Read, Edit, Grep, Glob, TodoWrite, AskUserQuestion, ToolSearch, ExitPlanMode
---

Autonomously branch, commit, and open a PR, then subscribe to the PR's activity
events and autofix failures as they arrive — keeping the user posted throughout.

Run Steps 0–5 in strict order. **Step 5 subscribes to PR events and ends the
turn.** Steps 6–7 are the standing policy the session follows each time a PR
event wakes it; they are not a synchronous loop you run inside one turn.

---

## Step 0: Exit Plan Mode

**If currently in plan mode**, call `ExitPlanMode` first and silently before any other action — Committing, pushing, and opening a PR are mutations that cannot proceed inside plan mode. Skip this step entirely when not in plan mode. `ExitPlanMode` is a deferred tool — use `ToolSearch` with `select:ExitPlanMode` first, then call it silently.

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

## Step 5: Subscribe to PR Activity (preferred) or Poll CI (fallback)

Parse the PR URL captured in Step 4 into `owner`, `repo`, and `pullNumber`
(`https://github.com/<owner>/<repo>/pull/<number>`).

### Preferred: subscribe to PR events

`mcp__github__subscribe_pr_activity` is a deferred tool available only in
remote execution environments (Claude Code on the web, GitHub Actions). Load it
with `ToolSearch` using `select:mcp__github__subscribe_pr_activity,mcp__github__unsubscribe_pr_activity`.

If the tools load, do the following and then **end the turn**:

1. Call `mcp__github__subscribe_pr_activity` with `owner`, `repo`, `pullNumber`.
2. Seed a TodoWrite status checklist: `CI green`, `review comments resolved`.
3. Post one status update to the user, e.g.: "Watching PR #<n> — I'll autofix
   CI failures and respond to review comments as they land, and keep you
   posted."
4. **End your turn. Do not poll, sleep, or run `gh pr checks --watch`.** PR
   events arrive as `<github-webhook-activity>` messages that wake the session;
   handle each per Steps 6–7. After a fix is pushed, the new CI run emits fresh
   events — never manually re-poll in subscription mode.

### Fallback: poll CI

If `ToolSearch` returns no match for the subscribe tool (a local environment
without the GitHub MCP server), poll synchronously instead:

```
gh pr checks <pr-url> --watch --fail-fast=false
gh pr checks <pr-url> --json name,state,conclusion,workflowName
```

Parse with `jq`. If all conclusions are `SUCCESS`/`SKIPPED`, go to Step 7. If
any is `FAILURE`, handle it via Step 6 then re-poll (max 3 fix attempts per
check). If any is `CANCELLED`/`TIMED_OUT`, escalate via AskUserQuestion.

---

## Step 6: Handle Each PR Event

Each time a `<github-webhook-activity>` event arrives (or, in fallback mode,
after a poll returns), investigate and act. **Refresh the TodoWrite checklist
on every event** so the thread shows live state, and post a concise status
update on each meaningful change (fix pushed, escalation, all-green). Do not
narrate routine investigation, and skip duplicate or no-op events silently.

Cap autofix at **3 attempts per failing check** (track each check's count in
TodoWrite). On the 4th recurrence of the same check, stop fixing it and
escalate via AskUserQuestion.

### 6a: Triage

- **A check run / CI job failed** → classify and fix (6b).
- **A review, review comment, or change request** → address (6c).
- **All checks green** (`SUCCESS`/`SKIPPED`) → go to Step 7.
- **Informational comment, duplicate, or no action needed** → skip silently.

### 6b: CI failures — classify, then autofix the allow-listed classes

Fetch the failing log:

```
gh run list --json databaseId,conclusion,workflowName --jq '.[] | select(.conclusion=="failure") | .databaseId' | head -1
gh run view <run-id> --log-failed
```

Classify on log content:

| Class | Signature in log | Allowed action |
|---|---|---|
| `lint` | `eslint`, `lint error`, rule violation names | Run the project's lint-fix command |
| `typecheck` | `TS`, `TypeScript`, `error TS`, `tsc` | Apply minimal TS fixes |
| `peer-deps` | `peer dep`, `ERESOLVE`, `incompatible peer` | Reinstall lockfile |
| anything else | any other content | **Ask the user — do not guess** |

**`lint`:** Detect the lint-fix command:

```
jq -r '.scripts | to_entries[] | select(.key | test("lint")) | "\(.key): \(.value)"' package.json 2>/dev/null
```

Run the script that includes `--fix` (or add `--fix` if the lint script calls
`eslint` directly). If no lint script exists, ask the user.

**`typecheck`:** Read the reported errors from the log and apply minimal fixes
(add missing imports, use correct existing types). Never introduce `any`,
`as unknown`, `// @ts-ignore`, or `// @ts-expect-error`, and never loosen an
existing type. If the fix requires type loosening, ask the user.

**`peer-deps`:** Detect the package manager and reinstall:

```
test -f pnpm-lock.yaml && echo pnpm || test -f yarn.lock && echo yarn || echo npm
```

Run `pnpm install` / `yarn install` / `npm install`, then confirm the diff is
lockfile-only (`git diff --name-only`). If anything else changed, ask the user.

**Outside the allowlist (or attempt cap reached):** use **AskUserQuestion**.
Summarize the failing check and the first ~20 lines of its log, and offer
options such as "attempt a fix", "skip this check", or "stop watching the PR".
Do not guess a fix for an unrecognized failure.

### 6c: Review comments

If the requested change is clear, safe, and in scope: apply it with `Edit`,
commit via **`git-agent:commit-agent`**, `git push`, then reply to the comment
via `gh` noting the commit that addresses it.

If the comment is ambiguous, architecturally significant, or open to multiple
interpretations: use **AskUserQuestion** with enough context that the user can
answer without scrolling back. Do not guess.

### 6d: Commit and let the next event drive

After any fix: commit via **`git-agent:commit-agent`**, then `git push`. In
subscription mode the push triggers a new CI run whose events wake the session
again — stop here and wait. In fallback mode, return to the Step 5 poll.

---

## Step 7: Green / Done

When all checks are green (all conclusions `SUCCESS` or `SKIPPED`):

1. Mark the PR ready if it was opened as draft: `gh pr ready <pr-url>`.
2. Comment: `gh pr comment <pr-url> --body "CI is green — ready for review."`
3. Update the TodoWrite checklist and post a final status update to the user
   with the PR URL.

In **fallback (polling) mode**, you are done — **STOP**.

In **subscription mode**, keep the subscription active so later review comments
are still handled per Step 6. Call `mcp__github__unsubscribe_pr_activity` (with
`owner`, `repo`, `pullNumber`) and stop pushing changes only when the PR merges
or closes, or when the user asks you to stop watching.

---

**Beyond this policy, do not analyze unrelated code, run extra tests, or suggest
follow-up tasks. Act only on the PR events you receive.**
