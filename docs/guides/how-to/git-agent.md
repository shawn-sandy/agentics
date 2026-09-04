# How do I... git-agent

Git workflow automation — branch, commit, pull request, merge, issue, and post-merge cleanup — across GitHub (`gh`) and GitLab (`glab`).

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install git-agent@agentics-kit`

## branch-agent

Creates a branch from the latest `origin/<default>` with no upstream tracking ref.

- **Command** — `/git-agent:branch-agent [branch-name]` (omit the name to auto-generate `<type>/<scope>-<description>` from uncommitted changes)
- **Say it instead** — Not available; this skill is command-only (`disable-model-invocation: true`).
- **What happens** — Guards for a git repo, a named branch, and an `origin` remote; fetches the default branch, then `git checkout -b <branch> --no-track origin/<default>` with a `-YYYY-MM-DD` suffix always appended, and prints the branch and short SHA.
- **Watch out** — A failed `git fetch` stops the run verbatim rather than branching off a stale ref; the skill never stages, commits, pushes, or opens PRs.

## commit-agent

Stages everything and writes a conventional commit message from the staged diff.

- **Command** — `/git-agent:commit-agent` — background variant `/git-agent:commit-bg [optional commit hint, e.g. 'fix typo in readme']`
- **Say it instead** — Not available; this skill is command-only (`disable-model-invocation: true`).
- **What happens** — Runs `git add -A`, analyzes `git diff --staged`, commits a `<type>(<scope>): <description>` message of 72 characters or less, prints the hash plus a `git reset HEAD~1` undo line, then asks whether to push.
- **Watch out** — The push only happens on an explicit approval prompt; a failing pre-commit hook is reported verbatim and stops the run — no retry, no `--no-verify`, no push reconciliation via pull, rebase, or force.

## create-issue

Drafts and opens a GitHub or GitLab issue from a bug, feature, selection, session, or plan file.

- **Command** — `/git-agent:create-issue [bug|feature|selection|session|plan] [title, description, or plan path]`
- **Say it instead** — "file a bug: the login form crashes on submit"
- **What happens** — Detects the host from `git remote get-url origin`, runs `gh`/`glab` auth pre-flight, gathers source-specific context, searches for near-duplicate issues, drafts from a template in `references/`, then creates the issue and opens it in the browser unless `--no-open` is passed.
- **Watch out** — Nothing is created until you pick "Create" at the confirmation gate; if the CLI create fails it falls back to a prefilled `--web` form, where no issue exists until you submit it yourself.

## merge

Runs the PR readiness gate on the current branch and squash-merges only when green and approved.

- **Command** — `/git-agent:merge` — background variant `/git-agent:merge-bg [optional PR url or number]`
- **Say it instead** — "is this PR ready to merge?"
- **What happens** — Resolves the branch's PR, gates on `mergeable`, `mergeStateStatus`, every required check via `gh pr checks --required`, and `reviewDecision`, re-fetches all of it, asks for approval, then runs `gh pr merge --squash --match-head-commit <headRefOid>`.
- **Watch out** — Green checks alone never authorize a merge, and `--delete-branch` is never passed; a dirty working tree triggers an ask (files listed) rather than a stop, and nothing is stashed, committed, or cleaned. An *absent* check is not a passing one: when the run list for the head commit is empty or its run has no jobs, CI never dispatched (a billing block, an expired token, a workflow awaiting approval) and the summary says so by name — never "CI green". A run whose jobs *started* is dispatched no matter what its logs return, so an unreadable log is reported as "CI failed — logs unavailable" and named down to the failing job and step, not written off as an external blocker.

## post-merge-cleanup

Removes a landed branch and its worktree after checking for uncommitted work.

- **Command** — `/git-agent:post-merge-cleanup [<branch>|<worktree-path>] [--all] [--dirs]`
- **Say it instead** — "clean up the branch and worktree now that it's merged"
- **What happens** — Qualifies the branch by commit ancestry *or* a confirmed merged PR, inspects `git status --porcelain` inside the worktree, asks for an explicit yes, then runs `git worktree remove` followed by `git branch -d` (or `-D` when a merged PR was the qualifying signal).
- **Watch out** — Never `git worktree remove --force`, never removes a worktree with any uncommitted or untracked file, and refuses to run from inside the target worktree (it prints a resume command instead); it is local-only, and without `gh` the detection degrades to ancestry alone and is reported as known-incomplete.

## pr-agent

Pushes the current branch and opens a pull request with an auto-filled title and body.

- **Command** — `/git-agent:pr-agent` — background variant `/git-agent:pr-bg [optional PR title or context hint]`
- **Say it instead** — Not available; this skill is command-only (`disable-model-invocation: true`).
- **What happens** — Guards against detached HEAD, the default branch, and an unauthenticated `gh`; stops on an existing open PR, pushes (with `-u` when there is no upstream), scans changed plan HTML for `plan-issue` URLs to add `Closes` lines, runs an adversarial pre-PR review of `git diff <base>...HEAD` in a fresh-context subagent (eleven checks: no-op edits, vacuous test assertions, self-introduced regressions, unsafe auth lookups, secrets, accessibility regressions, sort tie-breakers, unvalidated numeric input, stale derived state, timezone-dependent date anchors, and scripts that continue after a failed step), pushes any review fix commit, then prints the URL from `gh pr create`.
- **Watch out** — It runs no tests, so Test Plan boxes are only ticked for checks actually run in the session — and it does not commit your working-tree changes (the sole commit it makes is the review's fix commit), so run commit-agent first. The review is single-pass: unconfirmed findings ride in the PR body under `## Review Notes`, and a confirmed secret stops the run — it needs rotation, not a follow-up commit. The reviewer subagent runs in the background with a 30-turn cap: a partial or empty result, or one missing its `### Summary` heading, counts as no report, so the same checklist runs inline — never a re-dispatch — and `## Review Notes` says so.

## ship

Stages, commits, self-reviews, pushes, and opens the PR or MR in one guided flow.

- **Command** — `/git-agent:ship` (accepts `--no-review`) — background variant `/git-agent:ship-bg [optional commit/PR hint]`
- **Say it instead** — Not available; this skill is command-only (`disable-model-invocation: true`).
- **What happens** — Runs all five pre-flight guards against the unmutated tree and prints a single PASS/BLOCKED table with remediation commands, then stages, commits, self-reviews before pushing (a fresh-context subagent runs the same eleven adversarial checks as pr-agent against `git diff <base>...HEAD`, amending confirmed fixes into the commit), pushes, and creates the PR/MR through `gh` or `glab`, printing the URL.
- **Watch out** — Any BLOCKED row stops the run before any mutation and is never auto-remediated (no re-auth, no stash, no `.env` copy); a pre-commit hook failure is reported verbatim and stops. `--no-review` skips the self-review; when it runs, only a confirmed secret blocks the ship — everything unconfirmed is reported, not fixed. A reviewer subagent that returns no report (partial, empty, or missing its `### Summary` heading) is not re-dispatched — the checklist runs inline and the step report says so.

## ship-autonomous

Runs the whole pipeline — branch, verify, commit, PR, CI watch, bounded autofix, gated merge.

- **Command** — `/git-agent:ship-autonomous`
- **Say it instead** — "ship this autonomously and watch CI until it's green"
- **What happens** — Checks the session length first (Step 0) and offers to clear, background, or continue, then branches, runs tests, lint, and a browser preview, delegates the commit to commit-agent and the PR to pr-agent, and finally subscribes to PR events (falling back to polling `gh pr checks`) and ends the turn, handling each event as it arrives.
- **Watch out** — The context guard is skipped on a short session, and picking `clear` **stops** the run — a skill cannot clear its own context, so you run `/clear` and re-invoke; `background` chains `ship-bg` then `ship-ci-bg` for fresh context windows but still returns to the foreground to merge. Failing tests or lint, or any console or server error, stop the pipeline; autofix is capped at 3 attempts per failing check and limited to lint, typecheck, and peer-deps; the merge needs an explicit approval on green pinned to `headRefOid`, and branch deletion requires its own separate yes.

## Related commands

- `/git-agent:ship-ci-bg` — Fires the `agent-ship-ci` subagent in the background to watch an already-open PR's checks, apply the two deterministic autofixes (lint `--fix`, lockfile reinstall), and report; it requires an existing PR and never merges or edits source.
