---
status: completed
type: fix
created: 2026-10-26
modified: 2026-10-26
repo-name: agentics
workflow: never
glance: After a merge, post-merge-cleanup stops whenever the session is standing in the worktree it was asked to remove, which in the desktop app is almost always, and hands the user a command they cannot paste. When this lands, an app session deletes the merged branch itself and archives, and the app takes the worktree back, so nothing is left for the user to finish.
---

# Plan: Let post-merge-cleanup finish when the session stands in the worktree

## Objective

Make `/git-agent:post-merge-cleanup` complete a cleanup from inside a Claude
desktop app session's own worktree, instead of refusing and handing the job
back.

## Context

A usage-insights review found the same dead end in at least two `513` sessions
(the Google Play TWA plan and the check-in card): after the PR merged, the
skill confirmed the branch was cleanable and the worktree clean, then stopped
because the session was running inside that worktree. It printed
`cd <repo-root> && /git-agent:post-merge-cleanup <branch>` in a bash block,
which zsh cannot run.

Root cause: the skill assumes a hand-made worktree that only `git worktree
remove` can clear. A desktop app session's worktree belongs to the app.
Archiving the session hands a clean worktree back to the app, which parks it
detached on the default branch for reuse or reaps it, and keeps a dirty one on
disk. The app never deletes the branch. In `513`, the TWA session's worktree
was reused by a later session after it was archived, while its branch
`claude/pwa-appstore-install-888089` is still there. Removing the worktree was
never the user's job in the app. The branch was the part left over.

Tools checked in this environment:

| Tool | Removes the worktree the session stands in? |
|---|---|
| `ExitWorktree` | No. Only worktrees made by `EnterWorktree` in the same session; a no-op otherwise (called and confirmed). |
| `mcp__ccd_host__clean_up_worktrees` | No. Only sessions inactive 30+ days; never a running or open one. |
| PR monitor `auto_archive_on_close` | Yes, on PR merge or close, through archiving. On for this user (`auto_archive_on_pr_close`). Leaves the branch. |
| `mcp__ccd_session_mgmt__archive_session` | Yes, with `"self"`: ends the conversation, and the app takes a clean worktree back. Needs the user's approval. Leaves the branch. |

## Decisions

- The skill hands the worktree to the app instead of running `git worktree
  remove` on it. Removing an app worktree out from under the app leaves the
  session with no working directory and works against the app's reuse pool.
- App sessions are recognised by `get_session("self")` reporting a
  `worktreePath` equal to the target. The `.claude/worktrees/` path alone is
  not enough, because hand-made worktrees live there too.
- The branch is deleted before archiving, because the archive ends the
  conversation. git will not delete a branch checked out in any worktree, so
  the worktree is detached first, onto `origin/<default>`, which is where the
  app parks its reusable worktrees. The delete runs inside the worktree, where
  `-d` judges against `origin/<default>`; from the main checkout it would judge
  against a local default branch that may be stale, and refuse. A refused
  delete stops before the archive.
- `archive_session` stays out of `allowed-tools`. The app's own approval card is
  what lets it archive a session that is open on screen, and pre-approving the
  tool could skip that card.
- A `--all` sweep skips an app session's own worktree, because archiving would
  end the conversation mid-sweep.
- Outside an app session the skill still stops, but its handoff is now a slash
  command given inline rather than inside a shell block.
- `ExitWorktree` support for CLI `EnterWorktree` sessions is not added: none of
  the reported failures came from one, and it could not be exercised here.

## Files

- kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md (modified) — steps
  2, 4 and 5; `get_session` in `allowed-tools`
- kit/plugins/git-agent/skills/post-merge-cleanup/references/sweep.md
  (modified) — skip the session's own worktree in an app session
- README.md (regenerated) — plugin table version cell
- tests/plugins/test-post-merge-cleanup.sh (modified) — sections 11 and 12
- kit/plugins/git-agent/README.md (modified) — one sentence
- kit/plugins/git-agent/CHANGELOG.md (modified) — v4.23.1
- .claude-plugin/marketplace.json (modified) — git-agent 4.23.0 to 4.23.1

## Steps

1. [x] Add sections 11 and 12 to the test and watch them fail. Verify: 7 new
   checks fail on the unchanged skill.
2. [x] Rewrite step 2 to branch on `worktreePath`, extend steps 4 and 5 with
   the app path, add the tools. Verify: the test passes 41 of 41.
3. [x] Act on the adversarial review: make the fixture's branch land on an
   `origin/main` that moved on with local `main` stale, and pin the stop on a
   refused delete, the `allowed-tools` choice, the sweep skip and no `-D` in
   the block. Watch 5 checks fail, then move the delete into the worktree,
   drop `archive_session` from `allowed-tools` and update sweep.md. Verify:
   45 of 45 pass, and mutants that drop the detach target, delete from the
   repo root, or use `-D` each go red.
4. [x] Bump the version and add the changelog and README lines. Verify:
   `BASE_REF=main node scripts/check-plugin-versions.mjs` prints OK, and
   `node scripts/build-readme-table.mjs` regenerates the README table.
5. [x] Run the app path in a scratch repo shaped like an app session, from
   inside the worktree. Verify: the branch is gone, the worktree is clean and
   detached on `origin/main`, and the main checkout's HEAD, branch and status
   are unchanged, with the PR squash-merged on origin and local `main` stale.
6. [x] Run `bash scripts/verify.sh`. Verify: exit 0.

## Tests

- tests/plugins/test-post-merge-cleanup.sh extracts the skill's app-path block
  from SKILL.md and runs it from inside a fixture worktree; it fails if the
  block stops deleting the branch, parks the worktree anywhere but
  `origin/main`, removes the worktree itself, or touches the main checkout. Run: `bash tests/plugins/test-post-merge-cleanup.sh`

## Not verified

The archive call itself was not run: this session is not an app worktree
session, and archiving a real one needs the user's yes. The first real
post-merge cleanup in an app worktree session is that check.
