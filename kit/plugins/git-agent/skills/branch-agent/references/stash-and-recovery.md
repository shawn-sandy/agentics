# Checkout Conflict Detection and Stash Recovery (Steps 4.5, 5)

Bundled reference for the `branch-agent` skill. Covers deciding whether a
stash is needed before checkout, and the stash / checkout / pop sequence with
its recovery instructions.

## Step 4.5: Detect Checkout Conflicts

Compute the intersection of (a) tracked files modified in the working tree and
(b) files that differ between `HEAD` and `origin/<default>`:

```bash
bash -c 'comm -12 <(git diff --name-only HEAD | sort -u) <(git diff --name-only HEAD origin/<default> | sort -u)'
```

(The `bash -c` wrapper ensures process substitution works regardless of the invoking shell.)

- **Empty output** → no stash needed; uncommitted changes will carry forward to
  the new branch automatically. Proceed directly to Step 5.
- **Non-empty output** → the listed files would be overwritten by `git checkout`;
  a stash is required. Record the conflicting paths and set "stash needed".
  Proceed to Step 5.

Note: untracked files (`??` in `git status`) never appear in
`git diff --name-only HEAD` and never conflict — they always carry forward
untouched.

## Step 5: Create Branch with No Upstream Tracking

The `--no-track` flag prevents git from setting `origin/<default>` as the
upstream. Without it, any future `git push` would target the wrong remote ref.

**When stash is not needed** (Step 4.5 returned empty):

```bash
git checkout -b <branch> --no-track origin/<default>
```

On failure (branch already exists or other error): report the git error verbatim
and **STOP**. Do not retry. Do not force.

**When stash is needed** (Step 4.5 returned conflicting paths):

Run each command separately so failure is detectable at each step:

```bash
git stash push -m "branch-agent auto-stash <branch>"
```

On failure: report the error verbatim and **STOP**.

```bash
git checkout -b <branch> --no-track origin/<default>
```

On failure: report the error verbatim. Note that the stash is preserved — run
`git stash pop` to restore uncommitted changes. **STOP**. Do not retry. Do not force.

```bash
git stash pop
```

On failure (pop conflict): report the git error verbatim, then output:

> Your uncommitted changes are safe in the stash. To restore manually:
> 1. `git stash list` — confirm the stash entry is present
> 2. Resolve any conflicts in the listed files
> 3. `git add <resolved-files>` — stage the resolved files so the index reflects the resolved state
> 4. `git stash drop` to remove the stash entry
> Do not retry. Do not drop the stash before staging resolved files.

**STOP**.
