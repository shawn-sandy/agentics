---
name: post-merge-cleanup
description: "Removes merged branches and worktrees after checking for uncommitted work. Detects squash-merged branches and stale directories. Use when clearing up after a merge."
allowed-tools: Bash(git *), Bash(gh *), Bash(glab *), Bash(du *), Bash(ls *), Bash(rm *), Read, Grep, Glob, AskUserQuestion, ToolSearch, ExitPlanMode, mcp__ccd_session_mgmt__get_session
model: sonnet
---

Clear away a branch and its worktree once the work has landed — but only after
looking inside the worktree first, and only with the user's explicit yes on
every destructive step.

## Safety contract

These four are absolute. Nothing in this skill or its references overrides them.

1. **Never `git worktree remove --force`** (or `-f`). The unforced command
   refuses a dirty worktree, and that refusal is this skill's central safety
   property. Forcing past it is the exact behaviour this skill exists to avoid.
2. **Never remove a worktree whose `git status --porcelain` is non-empty** —
   untracked, staged, or unstaged alike. Report the files and stop.
3. **Never `git branch -D` without a confirmed merged pull request.** Ancestry
   deletion uses `-d` and accepts git's refusal. `-D` is reachable only for a
   squash-merged branch whose merged PR has been positively confirmed.
4. **Never `rm` a path outside the worktrees root,** and never one that
   detection did not itself produce.

## When not to use

- The branch has not landed. This skill cleans up *after* a merge; it never
  decides whether something is ready to merge — that is `/git-agent:merge`.
- You want the remote branch deleted. This skill is local-only.
- You want every `[gone]` branch gone regardless of state. That is a different,
  riskier job, and this skill deliberately will not do it unattended.

## Step 0 — Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Step 1 — Determine the scope

`/git-agent:post-merge-cleanup [<branch>|<worktree-path>] [--all] [--dirs]`

- **A target argument** — a branch name or a worktree path — names what to clean
  explicitly. This is what makes the flow usable from anywhere, including from
  the main checkout after stepping out of the worktree being removed.
- **No target and no flag:** operate on the current branch and its worktree.
- **`--all`:** repo-wide sweep. Read
  [references/sweep.md](references/sweep.md) and follow it instead of Step 3.
- **`--dirs`:** unregistered-directory pass only. Read
  [references/stale-directories.md](references/stale-directories.md).

Resolve a target argument before anything else: a value matching a branch name
selects that branch and whatever worktree holds it; otherwise treat it as a
worktree path and resolve it through `git worktree list` to find its branch.
Matching neither is an error — say what was tried and stop, rather than falling
back to the current branch. Silently cleaning something other than what was
named is the worst available outcome.

A sweep and a directory pass may both run; the single-branch flow is what you
get when neither flag is present.

## Step 2 — Detect

Read [references/detection.md](references/detection.md) and run its inventory.
It resolves the default branch, decides which branches are cleanable using
**both** signals — commit ancestry and merged pull requests — and reads each
candidate worktree's status.

**Ancestry alone is not enough.** A squash merge replays a branch's changes as
one commit with a new SHA, so the branch's own commits never become ancestors of
the default branch and `git branch --merged` cannot see it. Repos that squash by
default will have more squash-merged branches than ancestry-merged ones.

## Step 3 — Clean one branch

1. **Confirm it is cleanable** by either signal. Neither → say which checks ran
   and stop. Never delete a branch this step could not qualify.
2. **Refuse self-deletion.** If the current working directory is inside the
   target worktree, never remove it from there: removing the directory you are
   standing in leaves the shell in a path that no longer exists. Who finishes
   the job depends on who made the worktree, so call
   `mcp__ccd_session_mgmt__get_session` with `session_id: "self"`:

   - **It reports a `worktreePath` equal to the target.** This is a Claude
     desktop app session in the worktree the app made for it, and the app takes
     that worktree back when the session is archived. Carry on: step 5 deletes
     only the branch, then archives this session. Nothing goes back to the user.
   - **No `worktreePath`, a different one, or the tool does not load.** Stop.
     Do not stop at "`cd` out first": once the user leaves, the current branch
     is no longer the target, so a bare re-invocation would resolve to
     something else entirely. Tell the user to open Claude Code in
     `<repo-root>` and run `/git-agent:post-merge-cleanup <branch>`, naming the
     target explicitly. It is a slash command, so never print it in a shell
     code block, where zsh would try to run it as a path.

   A refusal that leaves the target unaddressable is a dead end, not a
   safeguard.
3. **Inspect for uncommitted work.** Run `git -C <worktree> status --porcelain`.
   Non-empty for any reason → print the file list, state that cleanup is
   blocked, and stop. Do not offer to force, and do not offer to delete the
   files.
4. **Ask before removing.** Show the worktree path and the branch, and get an
   explicit yes. When step 2 carried on inside an app session, the question
   also says this session will be archived and the conversation ends there.
5. **Remove, from outside the worktree:** `git worktree remove <path>`, then
   `git branch -d <name>` — or `git branch -D <name>` when a merged PR was the
   qualifying signal, since `-d` would refuse it. Print each command and its
   result.

   **Standing inside it in a desktop app session**, delete only the branch and
   leave the worktree to the app. git refuses to delete a branch that any
   worktree has checked out, so detach first, onto the default branch, which is
   where the app parks the worktrees it keeps for reuse:

   ```bash
   git -C <worktree> switch --detach origin/<default>
   git -C <worktree> branch -d <name>
   ```

   Both run in the worktree: `-d` judges against the HEAD where it runs, and
   only here is that `origin/<default>`, the ref detection used. The main
   checkout's local default branch may be stale. Use `-D` on the same terms as
   above. If git refuses the delete, stop and report it; do not archive.
   Otherwise confirm `git show-ref --verify refs/heads/<name>` fails, write the
   report described under Step 4 — Report, since archiving ends the
   conversation, and call `mcp__ccd_session_mgmt__archive_session` with
   `session_id: "self"`. It stays out of `allowed-tools` on purpose: the app's
   own approval card is what lets it archive a session that is open on screen.
   If the call is refused, report its reason. The branch is already gone, and
   the app takes the worktree back whenever the session is archived, which the
   user can do from the sidebar.

## Step 4 — Report

State what was removed, what was skipped and why, and what remains. A blocked
worktree is a normal outcome worth reporting plainly, not a failure.

## Degraded and restricted environments

- **No `gh`, unauthenticated, or a non-GitHub remote** → detection falls back to
  ancestry alone. Say so in the report: squash-merged branches cannot be seen in
  this mode, so the list is known-incomplete. Never present a degraded list as
  complete.
- **`rm` unavailable** — some environments deny it by policy. Print the exact
  command for the user to run instead, and carry on. A refused delete is
  reported, never worked around with `mv`, `find -delete`, or a shell builtin.
