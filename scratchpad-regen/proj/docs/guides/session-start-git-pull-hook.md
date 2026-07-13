# SessionStart Hook: Auto-Pull Default Branch

## Problem

When Claude Code creates a git worktree (via `EnterWorktree` or `isolation: "worktree"` on a subagent), the new branch is based on the **local** copy of the default branch. If the local `main` is behind `origin/main`, the worktree starts from stale code — and there is no `EnterWorktree` hook event to intercept this.

The same issue affects regular branch creation: `git checkout -b feature-x` branches from whatever `main` is locally, which may be days behind the remote.

## Solution

A `SessionStart` hook that fetches the latest default branch from origin at the start of every session. This ensures `main` (or whatever the default branch is) is current before any worktrees or branches are created.

### User-level (all projects)

Add to `~/.claude/settings.json` under `hooks`:

```json
"SessionStart": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0; DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'); test -n \"$DEFAULT_BRANCH\" || exit 0; CURRENT=$(git branch --show-current 2>/dev/null); if [ \"$CURRENT\" = \"$DEFAULT_BRANCH\" ]; then git pull --ff-only origin \"$DEFAULT_BRANCH\" 2>/dev/null; else git fetch origin \"$DEFAULT_BRANCH\":\"$DEFAULT_BRANCH\" 2>/dev/null; fi && echo \"OK: $DEFAULT_BRANCH is up to date with origin\" || true",
        "timeout": 15
      }
    ]
  }
]
```

### Project-level (all contributors)

Add the same block to `.claude/settings.json` in the project root. Project hooks run alongside user-level hooks (they don't override each other).

## How It Works

The hook runs three guard clauses before doing anything:

1. **`git rev-parse --is-inside-work-tree`** -- exits early if the session isn't in a git repo (safe for non-git directories).
2. **`git symbolic-ref refs/remotes/origin/HEAD`** -- dynamically resolves the default branch name (`main`, `master`, etc.) rather than hardcoding. Exits if no remote is configured.
3. **Branch detection** -- checks whether the current branch is the default branch or not:
   - **On the default branch:** runs `git pull --ff-only` to fast-forward. `--ff-only` refuses to merge if local and remote have diverged, so no work is destroyed.
   - **On a feature branch (or in a worktree):** runs `git fetch origin main:main` to update the local `main` ref directly without switching branches.

The trailing `|| true` ensures the hook never blocks session start if the network is unavailable or the fetch fails for any reason.

## Limitations

- **Runs once per session.** If `origin/main` advances mid-session, worktrees created later still branch from the state fetched at session start. For most workflows this is a non-issue.
- **Requires `refs/remotes/origin/HEAD` to be set.** If this ref is missing (uncommon), run `git remote set-head origin --auto` once to fix it.
- **`--ff-only` will silently skip** if local `main` has divergent commits. This is intentional (no destructive operations), but means you'll need to manually reconcile in that rare case.

## Verifying It Works

Start a new Claude Code session in any git repo and look for this line in the session output:

```
OK: main is up to date with origin
```

If the hook is silent, it either exited early (not a git repo, no remote) or the fetch failed gracefully.
