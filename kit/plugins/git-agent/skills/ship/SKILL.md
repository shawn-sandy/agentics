---
name: ship
description: "Ships changes by staging, committing, pushing, and opening a PR. Supports GitHub and GitLab in a single guided flow. Use when the user asks to ship changes or commit and create a PR."
allowed-tools: Bash(git *), Bash(gh *), Bash(glab *), Read, Edit, Grep, Glob, Agent, ToolSearch, ExitPlanMode
disable-model-invocation: true
---

Stage, commit, push, and create a pull/merge request in one flow. Supports
GitHub (`gh`) and GitLab (`glab`). Follow these steps in strict order. **STOP
immediately after step 8.**

## When not to use

For commit-only use commit-agent, for PR-only use pr-agent.

## Step 0: Exit Plan Mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Step 1: Pre-flight Guards

**Run every guard before reporting any of them.** Run all five against the
unmutated tree, then print one PASS/BLOCKED table with a verbatim remediation
command per BLOCKED row. **Never stop on the first failure** — three blockers
must cost one spin-up, not three. Any BLOCKED row then **STOPs** before any
mutation. **Never remediate automatically:** no re-auth, no stash, no env copy.

Commands: `references/preflight-guards.md`. The five guards:

- **Clean working tree** — "Nothing to ship — working tree is clean."
- **Detached HEAD** — no current branch.
- **On main or master** — "Cannot ship from the default branch. Switch to a
  feature branch first."
- **CLI not available or not authenticated** — detect GitHub vs GitLab, then
  verify per `references/platform-clis.md`.
- **Worktree env parity** — linked worktrees only: report `.env*` files the main
  checkout has and this worktree lacks, one `cp` each. **Never copy.**

## Step 2: Stage Changes

Run `git add -A` to stage all changes.

This trusts `.gitignore` to exclude sensitive or generated files.

## Step 3: Analyze Diff and Write Commit Message

Run `git diff --staged`, then write a `<type>(<scope>): <description>` message —
format rules in `references/commit-message.md`.

## Step 4: Commit

Run:

```
git commit -m "<message>"
```

Output the commit hash and message on success.

**If a pre-commit hook fails:** report the hook's output verbatim and **STOP**.
Do not retry, do not use `--no-verify`, do not modify the staged files — let the
user fix it.

## Step 4.5: Self-Review Before Push

Runs by default; `--no-review` skips it entirely.

Resolve `<base>` via **Step 7: Detect Base Branch**, then reuse it there
rather than detecting twice. If none resolves, output "Skipping self-review:
cannot resolve a base branch." and continue to Step 5.

Read `references/self-review.md` — the fresh-context subagent dispatch, the
six adversarial checks, and the amend procedure.

This step never blocks the ship — sole exception, a confirmed secret
(reference). It fixes what it confirms and reports the rest.

## Step 5: Push

Run:

```
git rev-parse --abbrev-ref --symbolic-full-name @{u}
```

Non-zero exit (no upstream tracking ref) → `git push -u origin <current-branch>`.
Zero exit → `git push`.

## Step 6: Check for Existing PR/MR

Read `references/pr-body.md` (bundled with this skill) — its Step 6 section.
**STOP** only on an **open** PR/MR; merged or closed → Step 7.

## Step 7: Detect Base Branch

Same reference, its Step 7 section — resolve `<base>` from `origin/HEAD`.

## Step 7.5: Scan for Issue References

Same reference, its Step 7.5 section — collect plan-file issue URLs for the
body's `## Linked Issues`.

## Step 8: Create Pull/Merge Request

Same reference, its Step 8 section — title rules, body template, and the
`gh`/`glab` create commands. **Never mark a Test Plan box that was not
verified.** Output the URL and **STOP**.

---

**STOP here. Do not analyze code, run tests, review the diff, suggest follow-up
tasks, or take any further action.**
