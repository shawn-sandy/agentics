# Detection and inventory

Read-only. Nothing here mutates anything, so it is safe to run and re-run while
deciding what to clean.

## Resolve the default branch

```bash
git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||'
```

Empty (common in clones that never ran `git remote set-head`) → fall back to:

```bash
gh repo view --json defaultBranchRef -q .defaultBranchRef.name
```

Both empty → ask the user rather than assuming `main`. A wrong default branch
silently changes which branches look merged, and that error is invisible in the
output.

**Compare against the remote-tracking ref, `origin/<default>`, not the local
branch.** A local `main` that is behind the remote reports fewer merged branches
than actually merged, and the difference does not announce itself.

## Signal 1 — commit ancestry

```bash
git branch --merged "origin/<default>" --format='%(refname:short)|%(worktreepath)'
```

Lists branches whose commits are ancestors of the default branch. This is what
`git branch -d` checks, so anything appearing here can be deleted with `-d`.

## Signal 2 — a merged pull request

```bash
gh pr list --head "<branch>" --state merged --limit 1 --json number,mergedAt
```

Non-empty → the branch landed, whatever ancestry says.

**Why this signal is not optional.** A squash merge replays the branch's changes
as a single new commit with a different SHA. The branch's own commits never
become ancestors of the default branch, so Signal 1 cannot see it — not as an
edge case, but by construction. In a repo that squashes by default, this is the
majority of merged branches.

A branch qualifies as cleanable when **either** signal fires. Record which one
did: it decides whether Step 3 may use `-d` or needs `-D`.

| Qualifying signal | Deletion flag | Why |
|---|---|---|
| Ancestry (Signal 1) | `git branch -d` | git's own check passes |
| Merged PR only (Signal 2) | `git branch -D` | `-d` applies the ancestry test and would refuse |
| Both | `git branch -d` | prefer the flag that keeps git's check in play |
| Neither | none — not cleanable | nothing establishes that the work landed |

### Batching the PR lookup

One `gh` call per branch is fine for a single-branch run. For a sweep over
hundreds of branches, prefer one bulk call and match locally:

```bash
gh pr list --state merged --limit 500 --json number,headRefName -q '.[].headRefName' | sort -u
```

Then intersect that list with the local branch names. Fall back to per-branch
lookups only for branches the bulk call did not cover.

## Degraded mode

`gh` missing, unauthenticated, or a non-GitHub remote → run Signal 1 only.

```bash
command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 && echo full || echo degraded
```

In degraded mode the report **must** state:

> Degraded detection: `gh` unavailable, so squash-merged branches cannot be
> detected. This list covers ancestry-merged branches only and is incomplete.

Never present a degraded list as complete. A user who believes they have seen
every cleanable branch will not go looking for the rest.

## Worktree status

For each candidate that has a worktree path:

```bash
git -C "<worktree>" status --porcelain
```

Any non-empty output blocks cleanup for that worktree — untracked (`??`),
staged, and unstaged alike. Count the lines for the summary table and keep the
list for the blocked-item report.

## Unregistered directories on disk

The worktrees root is the common parent of the registered worktree paths (in
this repo, `.claude/worktrees/`). Compare what is on disk against what git knows:

```bash
git worktree list --porcelain | awk '/^worktree /{print $2}'
ls -1 "<worktrees-root>"
```

Directories on disk with no matching registration are candidates for
[stale-directories.md](stale-directories.md). Note that
`git worktree prune` will **not** find these: prune scans the admin directories
under `.git/worktrees/`, so a directory whose admin entry is already gone is
invisible to it.
