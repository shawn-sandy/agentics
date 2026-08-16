# Unregistered worktree directories

Directories sitting in the worktrees root that git no longer knows about. This
is the one place in the skill that performs a recursive delete, so every rule
here is load-bearing.

## Why `git worktree prune` does not cover this

`prune` scans the admin directories under `.git/worktrees/` and removes entries
whose checkout has vanished. These directories are the opposite case: the admin
entry is already gone and the checkout remains. `prune` has nothing to walk, so
it reports success while the directories stay on disk — sometimes megabytes of
them. `git worktree prune --dry-run --verbose` printing nothing is not evidence
that the worktrees root is clean.

## The three conditions

A directory qualifies as unregistered only when **all three** hold:

1. **Absent from `git worktree list`.**
   ```bash
   git worktree list --porcelain | awk '/^worktree /{print $2}'
   ```
2. **No admin directory.** `.git/worktrees/<name>` does not exist.
3. **Its `.git` file is dangling or missing.** If a `.git` file is present, read
   the `gitdir:` path out of it and confirm that path does not exist.
   ```bash
   sed 's/^gitdir: //' "<dir>/.git"
   ```

Each condition rules out a different way of being live. A directory still in
`worktree list` is in active use. One with an admin directory is registered and
must be removed with `git worktree remove`, not `rm`. One whose `.git` file
resolves is a working checkout that merely looks unfamiliar. Check all three —
any single check on its own will eventually delete something real.

A directory with no `.git` file at all was never a worktree. It still qualifies,
but say so in the report: it is ordinary disk, and the user may recognize it
when they would not recognize a stale checkout.

## Git cannot vouch for the contents

A dangling `.git` means `git status` does not work in these directories. There
is no way to ask whether they hold uncommitted work, so the skill cannot make
that judgment and must not pretend to. Print what can be observed and let the
human decide:

```bash
du -sh "<dir>"
ls -A "<dir>" | wc -l
find "<dir>" -type f -not -path '*/.git/*' -mtime -90 -print 2>/dev/null | head -10
```

Use `-mtime -90`, not `-newermt '-90 days'`. The relative-date form is a GNU
extension: BSD `find` rejects it, and `bfs` (a common macOS replacement) errors
with "Invalid timestamp" and demands ISO 8601. `-mtime` is POSIX and behaves the
same everywhere.

Report per directory: size, entry count, whether a `.git` file is present and
dangling, and the most recently modified files. Recent modifications are the
strongest available signal that something in there still matters.

## Removal rails

Removal requires **all** of the following:

1. **A per-directory confirmation.** Never one answer covering several
   directories. Each is a separate decision about different contents.
2. **A containment check.** Resolve the path and confirm it is inside the
   worktrees root before acting:
   ```bash
   case "$(cd "<dir>" && pwd -P)/" in
     "$(cd "<worktrees-root>" && pwd -P)"/*) ;;
     *) echo "refusing: outside the worktrees root"; exit 1 ;;
   esac
   ```
   Resolve both sides with `pwd -P` so symlinks and `..` segments cannot walk
   out of the root.
3. **The path came from detection.** Never accept a directory path from user
   input, a file, or a previous session's notes. The three conditions must have
   been evaluated in this run.
4. **Re-check immediately before removing.** State can change between the report
   and the confirmation.

Only then:

```bash
rm -rf "<resolved-path>"
```

## When `rm` is unavailable

Some environments deny `rm` by policy. That is a refusal to respect, not an
obstacle to route around. Print the exact command for the user to run, note that
the directory was left in place, and continue with the remaining items. Never
substitute `find -delete`, `mv` into a temporary location, or any other spelling
of the same action.
