---
name: branch-agent
description: "Creates a git branch from origin/<default> with no upstream tracking. Auto-names the branch from staged or unstaged changes in the working tree. Use when the user asks to create or start a new branch."
allowed-tools: Bash(git *), Bash(date *), ToolSearch, AskUserQuestion, ExitPlanMode
argument-hint: "[branch-name] (optional) — omit to auto-generate from uncommitted changes using <type>/<scope>-<description>"
disable-model-invocation: true
model: haiku
---

Create a new branch from the latest `origin/<default>` with no upstream tracking
ref. When called with no argument and the working tree has uncommitted changes,
the branch name is auto-generated from those changes. A `-YYYY-MM-DD` date
suffix is always appended to the final branch name so branches sort and group
chronologically.

## When not to use

Does not commit, push, or create PRs — use commit-agent or pr-agent for that.

## Step 0: Exit Plan Mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

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

Read `references/branch-naming.md` (bundled with this skill) — its Step 2
resolves `$ARGUMENTS` into a branch name.

## Step 2a: Auto-Generate Branch Name from Changes

Follow Step 2a of `references/branch-naming.md` — type and scope inference,
description rules, validation.

## Step 2b: Append Date Suffix

Follow Step 2b of `references/branch-naming.md` — always append the
`date +%Y-%m-%d` suffix; use the result as `<branch>`.

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

## Step 4.5: Detect Checkout Conflicts

Read `references/stash-and-recovery.md` (bundled with this skill) — its Step 4.5
intersection check decides whether a stash is needed.

## Step 5: Create Branch with No Upstream Tracking

The `--no-track` flag prevents git from setting `origin/<default>` as the
upstream. Without it, any future `git push` would target the wrong remote ref.

**When stash is not needed** (Step 4.5 returned empty):

```bash
git checkout -b <branch> --no-track origin/<default>
```

On failure (branch already exists or other error): report the git error verbatim
and **STOP**. Do not retry. Do not force.

**When stash is needed** (Step 4.5 returned conflicting paths): follow Step 5 of
`references/stash-and-recovery.md` for the stash / checkout / pop sequence.

## Step 6: Confirm and STOP

Run `git rev-parse --short HEAD` to get the short SHA.

Output one line:

> Created and checked out `<branch>` from `origin/<default>` @ `<sha>` (no
> upstream tracking)

---

**STOP here. Do not stage, commit, push, create PRs, or take any further
action.**
