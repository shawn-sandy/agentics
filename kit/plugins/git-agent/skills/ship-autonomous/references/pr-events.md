# PR Event Mechanics

Detail for **Step 5 (subscribe vs poll)**, **Step 6a (triage)**, and
**Step 6c (review comments)** of `ship-autonomous`. The guards live in
SKILL.md; this file carries the mechanics.

## Steps 3–4: what the delegated skills do

**`git-agent:commit-agent`** stages all changes, analyzes the diff, writes a
conventional commit message, and commits. Every invocation from this skill is a
delegated one, so it stops there and never raises its push prompt — the caller
pushes.

**`git-agent:pr-agent`**:

- Pushes the branch (sets upstream if needed)
- Checks for an existing open PR (skips creation if OPEN; creates if
  MERGED/CLOSED/missing — v3.3.2 fix)
- Generates a Summary/Changes PR body from `git log base..HEAD`
- Opens the PR via `gh pr create`

Capture the PR URL from pr-agent's final output — look for the line containing
`https://github.com/.*/pull/\d+`.

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
gh pr checks <pr-url> --json name,state,workflow,link
```

`gh pr checks` reports check status in `state`; it has no `conclusion` or
`workflowName` field (its JSON fields are `bucket`, `completedAt`,
`description`, `event`, `link`, `name`, `startedAt`, `state`, `workflow`). Do
not confuse it with `gh run list`, which does use `conclusion`.

Parse with `jq`. If all states are `SUCCESS`/`SKIPPED`, go to Step 7. If
any is `FAILURE`, handle it via Step 6 then re-poll (max 3 fix attempts per
check). If any is `CANCELLED`/`TIMED_OUT`, escalate via AskUserQuestion.

## Step 6a: Triage

Each time a `<github-webhook-activity>` event arrives (or, in fallback mode,
after a poll returns), investigate and act. **Refresh the TodoWrite checklist on
every event** so the thread shows live state, and post a concise status update on
each meaningful change (fix pushed, escalation, all-green). Do not narrate
routine investigation, and skip duplicate or no-op events silently.

- **A check run / CI job failed** → classify and fix (6b).
- **A review, review comment, or change request** → address (6c).
- **All checks green** (`SUCCESS`/`SKIPPED`) → go to Step 7.
- **Informational comment, duplicate, or no action needed** → skip silently.

## Step 6c: Review comments

If the requested change is clear, safe, and in scope: apply it with `Edit`,
commit via **`git-agent:commit-agent`** (delegated — no push prompt), `git push`,
then reply to the comment via `gh` noting the commit that addresses it.

If the comment is ambiguous, architecturally significant, or open to multiple
interpretations: use **AskUserQuestion** with enough context that the user can
answer without scrolling back. Do not guess.

If the finding is **wrong** — it misreads the code, describes state that no
longer exists, or repeats something already declined on this PR: do not push a
no-op fix to silence it. Reply once on the thread with the specific reason
(`gh pr comment` for a top-level review, `gh api` on the review-comment id for
an inline thread), resolve the thread, and move on. Keep the reply to a
sentence or two — a re-firing bot will not remember it next round. If the same
bot raises the same refuted finding again, skip it silently rather than
replying twice.

**A refuted finding submitted as a formal `CHANGES_REQUESTED` review is not
cleared by replying or resolving the thread.** The review decision still reads
`CHANGES_REQUESTED`, which Step 8 blocks on — leaving the PR unmergeable and
the finding marked "handled". Check which form it took:

```
gh pr view <pr-url> --json reviewDecision
```

If the decision is `CHANGES_REQUESTED`, post the refutation, then identify the
review that raised it:

```
gh api repos/<owner>/<repo>/pulls/<n>/reviews --jq '.[] | select(.state=="CHANGES_REQUESTED") | {id, user: .user.login}'
```

Then **escalate via AskUserQuestion** — the options are dismissing that review
by its `id` (`gh api -X PUT
repos/<owner>/<repo>/pulls/<n>/reviews/<review-id>/dismissals
-f message="<reason>" -f event=DISMISS`, which needs write access and is a
visible act on someone else's review) or asking the reviewer to re-review.
Never dismiss a review on your own initiative, and never merge around a
standing change request.
