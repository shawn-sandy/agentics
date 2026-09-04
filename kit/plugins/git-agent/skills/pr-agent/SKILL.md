---
name: pr-agent
description: "Pushes the branch and creates a pull request. Supports GitHub and GitLab via gh and glab with auto-filled title and body. Use when the user asks to create a PR or open a pull request."
allowed-tools: Bash(git *), Bash(gh *), Bash(glab *), Read, Grep, Glob, Agent, ToolSearch, ExitPlanMode
disable-model-invocation: true
model: sonnet
---

Push the current branch if needed and create a GitHub pull request. This skill does not commit your working-tree changes or run tests (the sole commit it ever makes is Step 4.7's review-fix commit). Follow these steps in strict order. **STOP immediately after step 5.**

## When not to use

Does not commit your changes — use commit-agent first.

## Step 0: Exit Plan Mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

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

## Step 4.7: Adversarial Pre-PR Review

Mandatory — this is the last gate before the PR exists, and the author of a
diff is the worst-placed reviewer of it.

Spawn a fresh-context subagent with the `Agent` tool — `subagent_type:
code-review:agent-code-reviewer` when available, otherwise `general-purpose` —
substituting the Step 2 `<base>` literally (the subagent starts with no
context):

> Review the output of `git diff <base>...HEAD` as a hostile reviewer with no
> memory of the implementation. Report only defects you can prove with
> file:line evidence. Check specifically for: (a) no-op edits — changes that do
> not actually alter behavior (CSS losing to specificity, config that silently
> no-ops when a dependency is missing); (b) vacuous test assertions — any test
> that would still pass with the change reverted; (c) regressions introduced by
> the change itself; (d) unsafe auth/role/key lookups; (e) secrets or tokens in
> the diff; (f) accessibility regressions in CSS/UI changes; (g) pagination or
> sort tie-breakers — a sort with no unique final key, so equal rows reorder
> between pages and records repeat or vanish; (h) `parseInt`/`Number()` on user
> or query input with no validation — NaN, negative, or out-of-range reaching a
> query or an index; (i) derived state left stale after a client-side update —
> result counts, pagination links, labels, or cached totals still rendering
> pre-update data; (j) timezone-dependent date anchors — "today", midnight, or
> day boundaries computed in local time against UTC data; (k) scripts that
> continue after a failed step — a missing `set -e`, an unchecked exit code, or
> a default env var that silently no-ops.

The reviewer runs in the background with a 30-turn cap; when it hits the cap
the harness returns its output marked partial. **A partial or empty result, or
one missing its `### Summary` heading, is "no report."** Do not re-dispatch or
resume it. Run the same checklist inline against `git diff <base>...HEAD` and
add the line "Pre-PR review ran inline — reviewer agent returned no report."
under `## Review Notes` in the PR body (Step 5).

**Single pass — never loop the review.** Confirm each finding against the
actual source, fix only the confirmed ones, commit them as one
`fix(<scope>): <description>` commit (Step 4 already pushed, so add — never
amend), and `git push` again. A finding you cannot confirm goes in the PR body
(Step 5) under `## Review Notes` instead of blocking. **Exception:** a
confirmed secret or token (check e) already reached the remote in Step 4 —
report it verbatim, never name it in the PR body, and **STOP**: it needs
rotation, not a follow-up commit. No findings → proceed.

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

## Test Plan
- [ ] <command or check a reviewer runs to verify this>

## Linked Issues
Closes <url>
```

A filled worked example of this body — real title, a `[x]` naming its result, an honest `[ ]`, a real `Closes` URL — is in `../ship/references/pr-body.md` (Step 8 section, bundled with this plugin's ship skill); match its shape.

**Test Plan rules:** this skill does not run tests, so list what a reviewer
should run (the project's test/lint commands, plus any manual step for
user-facing changes). If a check was actually run earlier in this session,
mark it `[x]` and name the result. **Never mark a box that was not verified** —
an unchecked box is honest, a false checkmark is not.

**Verification marker:** when the invoking skill reports one (for example
`UNVERIFIED — no browser` from `ship-autonomous` Step 2.5), reproduce it
verbatim as its own line in `## Test Plan`. When none is reported, the section
is unchanged — never invent a marker. A verification that silently did not
happen reads to a reviewer exactly like one that passed.

Omit the `## Linked Issues` section entirely if Step 4.5 found no issue references.

Add a `## Review Notes` section — one line per finding — only when Step 4.7
left unconfirmed findings or ran inline; omit it entirely otherwise.

Output the PR URL returned by `gh pr create` and **STOP**.

---

**STOP here. Do not analyze code, run tests, review the diff, suggest follow-up tasks, or take any further action.**
