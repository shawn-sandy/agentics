---
name: branch-agent
description:
  Use when the user asks to create a new branch, start a branch, branch off
  main, make a fresh branch, or branch from the default. Creates the branch from
  origin/<default> with no upstream tracking. Does not commit, push, or create
  PRs — use commit-agent or pr-agent for that.
allowed-tools:
  - Bash(git *)
  - ToolSearch
  - AskUserQuestion
argument-hint:
  Branch name (optional; defaults to "feature/auto-branch" if not provided)
---

Create a new branch from the latest `origin/<default>` with no upstream tracking
ref. Follow these steps in strict order. **STOP immediately after step 6.**

## Step 1: Guards

Run all checks before proceeding. Stop on the first failure.

**Not a git repository:** Run `git rev-parse --is-inside-work-tree`. If it
fails, output: "Not a git repository." and **STOP**.

**Detached HEAD:** Run `git branch --show-current`. If the output is empty,
output: "Cannot create branch: repository is in detached HEAD state. Checkout a
named branch first." and **STOP**.

**No origin remote:** Run `git remote get-url origin`. If it fails, output:
"branch-agent requires a remote named 'origin'." and **STOP**.

## Step 2: Resolve Branch Name

Read `$ARGUMENTS`.

- If `$ARGUMENTS` is empty or contains only whitespace, output: "Provide a
  branch name. Example: branch-agent feat/login-fix" and **STOP**.
- If `$ARGUMENTS` contains spaces or reads as a descriptive phrase, convert it
  to a human readable slug: lowercase, replace spaces and special characters
  with `-`, collapse consecutive dashes, strip leading/trailing dashes, truncate
  to 30 characters. Example: `"add allowed tools to skills"` →
  `"add-allowed-tools-to-skills"`.
- Otherwise use `$ARGUMENTS` verbatim as the branch name.

## Step 3: Detect Default Branch

Run:

```
git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null
```

Strip the `origin/` prefix to get the default branch name.

If that fails, run:

```
git remote show origin | grep 'HEAD branch'
```

Extract the branch name after `HEAD branch:`.

If both fail, try `git rev-parse --verify --quiet main`, then
`git rev-parse --verify --quiet master`. Use the first that succeeds.

If none resolve, report the git error verbatim and **STOP**.

## Step 4: Fetch Latest from Origin

Run:

```
git fetch origin <default>
```

**On failure** (offline, network error, auth required): report the git error
verbatim and **STOP**. Do not proceed with a stale ref.

## Step 5: Create Branch with No Upstream Tracking

Run:

```
git checkout -b <branch> --no-track origin/<default>
```

The `--no-track` flag prevents git from setting `origin/<default>` as the
upstream. Without it, any future `git push` would target the wrong remote ref.

On failure (branch already exists, dirty-tree conflict, or other error): report
the git error verbatim and **STOP**. Do not retry. Do not force.

## Step 6: Confirm and STOP

Run `git rev-parse --short HEAD` to get the short SHA.

Output one line:

> Created and checked out `<branch>` from `origin/<default>` @ `<sha>` (no
> upstream tracking)

---

**STOP here. Do not stage, commit, push, create PRs, or take any further
action.**
