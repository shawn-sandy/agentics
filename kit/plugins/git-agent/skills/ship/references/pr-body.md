# PR/MR Detection, Base Branch, Issue Links, and Body Template

Procedure detail for **Step 6**, **Step 7**, **Step 7.5**, and **Step 8**. Run
these in the same strict order as the steps in `SKILL.md`.

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

## Test Plan
- [ ] <command or check a reviewer runs to verify this>

## Linked Issues
Closes <url>
```

**Test Plan rules:** this skill does not run tests, so list what a reviewer
should run (the project's test/lint commands, plus any manual step for
user-facing changes). If a check was actually run earlier in this session,
mark it `[x]` and name the result. **Never mark a box that was not verified** —
an unchecked box is honest, a false checkmark is not.

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
