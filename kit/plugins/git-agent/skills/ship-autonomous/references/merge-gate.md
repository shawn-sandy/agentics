# Green / Done and Merge Gate Commands

Exact commands for **Step 7 (Green / Done)** and **Step 8 (Merge)** of
`ship-autonomous`. Every gate these commands serve — green-only merge, the
AskUserQuestion approval, `--match-head-commit`, and the separate branch-deletion
approval — is stated in SKILL.md and is not restated as optional here.

## Step 7: Green / Done

When all checks are green (every `state` is `SUCCESS` or `SKIPPED`):

1. Mark the PR ready if it was opened as draft: `gh pr ready <pr-url>`.
2. Comment: `gh pr comment <pr-url> --body "CI is green — ready for review."`
3. Update the TodoWrite checklist and post a final status update to the user
   with the PR URL.

Then go to Step 8.

In **fallback (polling) mode**, you are done after Step 8 — **STOP**.

In **subscription mode**, keep the subscription active so later review comments
are still handled per Step 6. Call `mcp__github__unsubscribe_pr_activity` (with
`owner`, `repo`, `pullNumber`) and stop pushing changes only when the PR merges
or closes, or when the user asks you to stop watching.

## Step 8: Re-confirm the checks

Re-confirm every check is `SUCCESS` or `SKIPPED` immediately before merging
(`state` is the field that carries this — `gh pr checks` has no `conclusion`):

```
gh pr checks <pr-url> --json name,state,link
```

If any check is failing, pending, or unresolved, return to Step 6 — do not
merge.

## Step 8: Re-confirm the review state

Fetch the **current** review state, not a remembered one — an approval or a
change request may have landed since the last event:

```
gh pr view <pr-url> --json reviewDecision,headRefOid
gh api graphql -f query='{ repository(owner: "<owner>", name: "<repo>") {
  pullRequest(number: <n>) { reviewThreads(first: 50) { nodes { isResolved } } } } }'
```

A `CHANGES_REQUESTED` decision or any unresolved thread blocks the merge —
return to Step 6.

Merging is outward-facing and hard to undo. Use **AskUserQuestion** to confirm
before merging, showing the PR URL, the check summary, the review decision, and
the count of unresolved threads.

## Step 8: Merge, pinned to the verified commit

On approval, pin the merge to the exact commit you verified — passing
`headRefOid` as `--match-head-commit` makes the merge fail rather than silently
land commits that arrived after your checks:

```
gh pr merge <pr-url> --squash --match-head-commit <headRefOid>
```

If it fails because the head moved, re-run the checks above and ask again — a
new commit is unverified work, and prior approval does not extend to it.

## Step 8: Branch deletion (separate approval)

"Merge it" does not authorize `--delete-branch` — never pass that flag on the
strength of a merge approval. After a successful merge, ask separately whether
to delete the branch, and only on a clear yes run:

```
git push origin --delete <branch>
git branch -d <branch>        # local copy, only if it is checked out locally
```

If the user does not clearly say yes, leave the branch in place.

Then post the merge URL and **STOP**.

