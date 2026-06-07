---
name: pr-agent
description: "Pushes the branch and creates a pull request. Supports GitHub and GitLab via gh and glab with auto-filled title and body. Use when the user asks to create a PR or open a pull request."
allowed-tools: Bash(git *), Bash(gh *), Bash(glab *), Read, Grep, Glob, ToolSearch, ExitPlanMode
disable-model-invocation: true
---

Push the current branch if needed and create a GitHub pull request. This skill does not commit changes or run tests. Follow these steps in strict order. **STOP immediately after step 5.**

## When not to use

Does not commit changes — use commit-agent first.

## Step 0: Exit Plan Mode

**If currently in plan mode**, call `ExitPlanMode` first and silently before any other action — Pushing and creating a pull request are remote mutations and cannot proceed inside plan mode. Skip this step entirely when not in plan mode. `ExitPlanMode` is a deferred tool — use `ToolSearch` with `select:ExitPlanMode` first, then call it silently.

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

## Step 2: Detect Base Branch and Gather PR Content

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
gh pr view --json state,url
```

If the result contains `"state":"OPEN"`, output: "A pull request already exists: <url>" and **STOP**. Do not create a duplicate.

If the result contains `"state":"MERGED"` or `"state":"CLOSED"`, or if the command exits non-zero (no PR found), proceed to Step 4.

## Step 4: Push if Needed

Run:
```
git rev-parse --abbrev-ref --symbolic-full-name @{u}
```

If the command exits non-zero (no upstream tracking ref), run:
```
git push -u origin <current-branch>
```

If the command exits zero (upstream exists), run:
```
git push
```

## Step 4.5: Scan for Issue References

Look for plan files on this branch that link to GitHub or GitLab issues.

Run:
```
git diff --name-only <base>...HEAD -- 'docs/plans/*.html' 'docs/plans/**/*.html'
```

For each file listed, use `Grep` to search for the pattern `<meta name="plan-issue" content="` and extract the URL value. Collect all unique URLs found.

If any URLs are found, include a `## Linked Issues` section in the PR body (Step 5) with one `Closes <url>` line per unique URL. If no plan files are found or none contain issue references, skip this section entirely.

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

## Linked Issues
Closes <url>
```

Omit the `## Linked Issues` section entirely if Step 4.5 found no issue references.

Output the PR URL returned by `gh pr create` and **STOP**.

---

**STOP here. Do not analyze code, run tests, review the diff, suggest follow-up tasks, or take any further action.**
