---
name: pr-agent
description: Use when the user asks to create a PR, open a pull request, make a PR, push and create a PR, or submit their branch for review. Does not enter plan mode. Does not commit changes — use commit-agent first.
---

Push the current branch if needed and create a GitHub pull request. Follow these steps in strict order. **STOP immediately after step 5.**

## Step 1: Guards

Run all checks before proceeding. Stop on the first failure.

**Detached HEAD:**
Run `git branch --show-current`. If the output is empty, output: "Cannot create PR: repository is in detached HEAD state. Checkout a named branch first." and **STOP**.

**On main or master:**
If the current branch is `main` or `master`, output: "Cannot create PR from the default branch. Switch to a feature branch first." and **STOP**.

**GitHub CLI not available or not authenticated:**
Run `gh auth status`. If `gh` is not installed or returns an auth error, output:
```
GitHub CLI is required. Install it from https://cli.github.com/ and run `gh auth login`.
```
and **STOP**.

## Step 2: Detect Base Branch

Run:
```
git symbolic-ref refs/remotes/origin/HEAD
```

Strip the `refs/remotes/origin/` prefix to get the base branch name. If this command fails, fall back to `main`, then `master` (try `git rev-parse --verify main` to confirm existence before falling back).

Run to gather PR content:
```
git log <base>..HEAD --oneline
git diff <base>...HEAD --stat
```

## Step 3: Check for Existing PR

Run:
```
gh pr view --json url
```

If a PR already exists, output: "A pull request already exists: <url>" and **STOP**. Do not create a duplicate.

## Step 4: Push if Needed

Run `git status` to check for a remote tracking reference.

If the branch has no upstream tracking ref, run:
```
git push -u origin <current-branch>
```

If the branch already has a tracking ref and is ahead of remote, run:
```
git push
```

## Step 5: Create Pull Request

Run:
```
gh pr create --title "<title>" --body "<body>"
```

**Title:** short summary of the branch's changes (≤ 70 characters), imperative mood.

**Body:** use this structure:
```
## Summary
- <bullet 1>
- <bullet 2>

## Changes
<brief description of what changed and why>
```

Output the PR URL returned by `gh pr create` and **STOP**.

---

**STOP here. Do not analyze code, run tests, review the diff, suggest follow-up tasks, or take any further action.**
