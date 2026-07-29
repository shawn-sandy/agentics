---
name: merge
description: "Checks whether the branch's PR is ready and merges it when green. Runs the readiness gate, lint, and an approval prompt. Use when the user asks \"merge?\" or if a PR is ready to merge."
allowed-tools: Bash(git *), Bash(gh *), Bash(glab *), Bash(jq *), Bash(npm *), Bash(pnpm *), Bash(yarn *), Read, Grep, Glob, AskUserQuestion, ToolSearch, ExitPlanMode
model: sonnet
---

Check the current branch's pull request for merge readiness and merge it only
when everything is green **and** the user approves. When anything is pending,
failing, or ambiguous, print the status summary and ask — never guess.

## When not to use

Does not commit or push — run `commit-agent` / `pr-agent` first. Does not
create a PR.

## Step 0: Exit Plan Mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Step 1: Find the PR

```
gh pr view --json url,number,state,mergeable,reviewDecision,headRefOid
```

If that fails because the branch has no PR, look for one — note that `gh pr
list` defaults to open PRs, so pass `--state all` or the closed/merged case
below is unreachable:

```
gh pr list --head "$(git branch --show-current)" --state all --json url,number,state
```

No PR found → say so and **STOP** (suggest `pr-agent`). `state` is not `OPEN`
(already `MERGED` or `CLOSED`) → report it and **STOP**.

**On the fallback path, re-query the full field set** before Step 2 — `gh pr
list` returns none of `mergeable`, `reviewDecision`, or `headRefOid`, and Step 4
cannot pin the merge without `headRefOid`:

```
gh pr view <number> --json url,number,state,mergeable,reviewDecision,headRefOid
```

## Step 2: Readiness gate

Read the checks with `gh pr checks`, **not** `statusCheckRollup`. The rollup
mixes node types — a `CheckRun` carries `status` + `conclusion` (a pending run's
`conclusion` is null), a `StatusContext` carries `state` — so a single
"is it SUCCESS" test silently reads a running check as green. `gh pr checks`
normalizes all of them onto one `state` field:

```
gh pr checks <pr-url> --required --json name,state,link   # the blocking gate
gh pr checks <pr-url> --json name,state,link              # everything, for the summary
```

Merge only when **all** of these hold:

- `mergeable` is `MERGEABLE` (not `CONFLICTING`, not `UNKNOWN`)
- every **required** check is `SUCCESS` or `SKIPPED`
- `reviewDecision` is not `CHANGES_REQUESTED`
- no unresolved review threads:

```
gh api graphql -f query='{ repository(owner: "<owner>", name: "<repo>") {
  pullRequest(number: <n>) { reviewThreads(first: 100) {
    totalCount pageInfo { hasNextPage } nodes { isResolved } } } } }'
```

Fill `<owner>`, `<repo>`, and `<n>` from `gh repo view --json owner,name` and
the PR number — never from a guess. If `hasNextPage` is true, the thread list is
truncated: say so and ask rather than reporting a count you cannot trust.

`--required` is what branch protection actually enforces, so it — not the full
list — decides whether the merge is blocked. Never infer required-ness yourself
from a check's name. A non-required check that is pending or failing does not
block, but **always name it in the Step 4 summary** so the user approves with
the full picture rather than a filtered one.

When a repo has no branch protection, `--required` exits non-zero with
"no required checks reported" — that means *nothing is enforced*, not *nothing
passed*. Do not read it as a failure. In that case there is no automated gate at
all, so say so plainly in the Step 4 summary and let the full check list and the
user's judgement carry the decision.

If any of these fails — checks pending, checks failing, conflicts, changes
requested, unresolved threads, or anything ambiguous — print the status summary
(checks, review decision, unresolved-thread count) **and ask what to do**. Do
not merge.

Automated review bots re-fire on every push. A re-fired review on an
already-approved PR is not a new blocking concern — see the `review-bot-loops`
rule.

## Step 3: Lint gate

Before merging, run the project's lint script:

```
jq -r '.scripts | to_entries[] | select(.key | test("^lint")) | select(.key + " " + .value | test("--fix|watch") | not) | .key' package.json 2>/dev/null
```

The filter reads each script's **command**, not just its name — a script named
`lint` whose value is `eslint --fix .` would rewrite the working tree and change
the PR head out from under the verified commit.

**Run the first match** with the project's package manager — detect it from the
lockfile (`pnpm-lock.yaml` → `pnpm`, `yarn.lock` → `yarn`, otherwise `npm`) and
run `<pm> run <script>`. Listing the candidate scripts is not the gate; actually
executing one is.

- No match → note in one line that no lint script was found and continue.
- Non-zero exit → print the failing output verbatim, **do not merge**, and ask.
  Never auto-apply `--fix`: fixed files would change the head commit.
- If the detection command itself errors (no `package.json`, no `jq`), treat it
  as "no lint script" and say which — never let a broken probe read as green.

## Step 4: Re-check, ask, then merge

**Re-run the Step 2 queries first.** Lint can take minutes, and
`--match-head-commit` only catches a moved head — it does not catch a review
flipping to `CHANGES_REQUESTED`, a new unresolved thread, or a check turning red
on the same commit. Show the user state you fetched just now, not state you
remember. If anything regressed, go back to Step 2 and ask.

Green checks alone never authorize a merge. Use **AskUserQuestion** to confirm,
showing the PR URL, the check summary, the review decision, and the
unresolved-thread count.

On approval, pin the merge to the commit you verified:

```
gh pr merge <pr-url> --squash --match-head-commit <headRefOid>
```

`--match-head-commit` makes the merge fail rather than silently land commits
that arrived after verification.

If the repo disallows squash merges, the command fails with a message saying so.
Do **not** silently retry with `--merge` or `--rebase` — the approval you have is
for a squash. Report which merge methods the repo allows
(`gh repo view --json mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed`)
and ask which one to use.

**Never pass `--delete-branch`.** Branch deletion is a separate destructive
action that needs its own explicit yes.

## Step 5: Report

Print the merge result and the PR URL, then **STOP**.

## GitLab

With a `glab` remote, substitute the equivalent commands and apply the same
gates — pipeline green, no unresolved discussions, explicit approval:

```
glab mr view <id>              # state, pipeline status, commit
glab mr view <id> --unresolved # unresolved discussions only
glab mr merge <id>
```

`glab mr view` has no flag that prints approval state; query the API or open
`--web` rather than assuming approval.

**Never pass `-d` / `--remove-source-branch`** — that is GitLab's branch
deletion. Like its GitHub counterpart it needs its own explicit yes, never the
merge approval.
