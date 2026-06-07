---
name: ship
description: "Ships changes by staging, committing, pushing, and opening a PR. Supports GitHub and GitLab in a single guided flow. Use when the user asks to ship changes or commit and create a PR."
allowed-tools: Bash(git *), Bash(gh *), Bash(glab *), Read, Grep, Glob, ToolSearch, ExitPlanMode
disable-model-invocation: true
---

Stage, commit, push, and create a pull/merge request in one flow. Supports
GitHub (`gh`) and GitLab (`glab`). Follow these steps in strict order. **STOP
immediately after step 8.**

## When not to use

For commit-only use commit-agent, for PR-only use pr-agent.

## Step 0: Exit Plan Mode

**If currently in plan mode**, call `ExitPlanMode` first and silently before any other action — staging, committing, pushing, and creating a pull/merge request are mutations and cannot proceed inside plan mode. Skip this step entirely when not in plan mode. `ExitPlanMode` is a deferred tool — use `ToolSearch` with `select:ExitPlanMode` first, then call it silently.

## Step 1: Pre-flight Guards

Run all checks before any mutation. Stop on the first failure.

**Clean working tree:** Run `git status`. If nothing to commit, output: "Nothing
to ship — working tree is clean." and **STOP**.

**Detached HEAD:** Run `git branch --show-current`. If the output is empty,
output: "Cannot ship: repository is in detached HEAD state. Checkout a branch
first." and **STOP**.

**On main or master:** If the current branch is `main` or `master`, output:
"Cannot ship from the default branch. Switch to a feature branch first." and
**STOP**.

**Detect platform:** Run `git remote get-url origin`. Determine the platform
from the URL:

- Contains `github.com` → **GitHub** (use `gh` commands below)
- Contains `gitlab.com` or `gitlab` → **GitLab** (use `glab` commands below)
- If unclear, check which CLI is available: try `gh --version` then
  `glab --version`. Use whichever is installed.
- If neither can be determined, ask the user which platform they use and
  **STOP**.

**CLI not available or not authenticated:**

For GitHub: run `gh auth status`. If `gh` is not installed or returns an auth
error, output:

```
GitHub CLI is required. Install it from https://cli.github.com/ and run `gh auth login`.
```

and **STOP**.

For GitLab: run `glab auth status`. If `glab` is not installed or returns an
auth error, output:

```
GitLab CLI is required. Install it from https://gitlab.com/gitlab-org/cli and run `glab auth login`.
```

and **STOP**.

## Step 2: Stage Changes

Run `git add -A` to stage all changes.

This trusts `.gitignore` to exclude sensitive or generated files. The user is
responsible for `.gitignore` correctness.

## Step 3: Analyze Diff and Write Commit Message

Run `git diff --staged` to inspect all staged changes.

Write a conventional commit message:

```
<type>(<scope>): <description>
```

**Rules:**

- Total length: ≤ 72 characters
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `style`,
  `ci`, `build`
- Scope: the most-changed top-level directory (e.g., `plugins/git-agent` →
  `plugins/git-agent`)
- Omit scope entirely if changes span more than 2 top-level directories
- Description: imperative mood, lowercase, no trailing period

## Step 4: Commit

Run:

```
git commit -m "<message>"
```

Output the commit hash and message on success.

**If a pre-commit hook fails:** report the hook's output verbatim and **STOP**.
Do not retry. Do not use `--no-verify`. Do not modify the staged files. Let the
user fix the issue.

## Step 5: Push

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

## Step 6: Check for Existing PR/MR

For GitHub, run:

```
gh pr view --json url
```

For GitLab, run:

```
glab mr view --output json
```

If a PR/MR already exists, output: "Pushed to existing PR/MR: <url>" and
**STOP**. The new commit is already on the remote.

## Step 7: Detect Base Branch

Run:

```
git symbolic-ref refs/remotes/origin/HEAD
```

Strip the `refs/remotes/origin/` prefix to get the base branch name. If this
command fails, fall back to `main`, then `master` (try
`git rev-parse --verify main` to confirm existence before falling back).

## Step 7.5: Scan for Issue References

Look for plan files on this branch that link to GitHub or GitLab issues.

Run:
```
git diff --name-only <base>...HEAD -- 'docs/plans/*.html' 'docs/plans/**/*.html'
```

For each file listed, use `Grep` to search for the pattern `<meta name="plan-issue" content="` and extract the URL value. Collect all unique URLs found.

If any URLs are found, include a `## Linked Issues` section in the PR/MR body (Step 8) with one `Closes <url>` line per unique URL. If no plan files are found or none contain issue references, skip this section entirely.

## Step 8: Create Pull/Merge Request

Gather content:

```
git log <base>..HEAD --oneline
git diff <base>...HEAD --stat
```

**Title:** short summary of the branch's changes (≤ 70 characters), imperative
mood.

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

Omit the `## Linked Issues` section entirely if Step 7.5 found no issue references.

For GitHub, run:

```
gh pr create --title "<title>" --body "<body>"
```

For GitLab, run:

```
glab mr create --title "<title>" --description "<body>"
```

Output the PR/MR URL and **STOP**.

---

**STOP here. Do not analyze code, run tests, review the diff, suggest follow-up
tasks, or take any further action.**
