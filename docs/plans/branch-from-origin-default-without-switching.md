# Plan: branch from `origin/<default>` without switching to it

## Context

The current `new-branch` skill at
[kit/plugins/git-agent/skills/new-branch/SKILL.md](kit/plugins/git-agent/skills/new-branch/SKILL.md)
forces the user through an unnecessary detour:

1. Hard-stops if the working tree is dirty (line 16-20)
2. Switches to the default branch (line 41)
3. Pulls (line 47)
4. Switches again to the new branch (line 126)

The user wants to be able to spawn a fresh branch *without leaving their
current branch as an intermediate step*, and *without being blocked by
uncommitted work* — they should at least be **asked** what to do, not
preemptively refused.

The investigation in the prior turn confirmed this is achievable with two
git commands instead of the current three:

```text
git fetch origin
git checkout -b <new> origin/<default>
```

`git fetch origin` is non-destructive (touches no working files, no HEAD,
no local branches), and `git checkout -b <new> origin/<default>` creates
the branch at the latest remote tip and switches to it in one step. Git
itself enforces safety: if uncommitted changes would conflict with files
that differ between the current branch and `origin/<default>`, git refuses
the checkout with a clear error and leaves the working tree alone.

## Decision (from prior clarification)

When the working tree is dirty, the skill **asks the user via
`AskUserQuestion`** what to do. No silent stash, no hard stop — the user
chooses. Two options:

1. **Proceed** — carry uncommitted changes onto the new branch. Git will
   refuse with a clear error if they conflict.
2. **Stop** — user will stash or commit first, then re-run.

(Auto-stash is intentionally out of scope — see Next Steps.)

## Files to modify

### 1. [kit/plugins/git-agent/skills/new-branch/SKILL.md](kit/plugins/git-agent/skills/new-branch/SKILL.md)

#### Header — line 7

Replace the opening summary:

> Guard the working tree, sync the default branch, scan existing branch
> naming patterns to inform a recommendation, then create a new branch.

with:

> Fetch the latest from origin, scan existing branch naming patterns to
> inform a recommendation, then create a new branch from `origin/<default>`
> without leaving the current branch as an intermediate step. Carries
> uncommitted changes forward when safe.

#### Step 1 — lines 9-20: replace hard guard with interactive confirmation

New body:

```markdown
## Step 1: Check Working Tree State

Run:
\`\`\`
git status --porcelain
\`\`\`

If the output is **empty**, continue silently to Step 2.

If the output is **non-empty**, the working tree has uncommitted changes.
Use `AskUserQuestion` to ask:

> "Working tree has uncommitted changes. They will be carried over to the
> new branch — git will refuse the checkout if they conflict with the
> default branch. How do you want to proceed?"

Options:
- "Proceed — carry changes to the new branch"
- "Stop — I'll stash or commit first"

If the user picks **Stop**, print `Stopped. Stash or commit your changes,
then re-run.` and **STOP**.

If the user picks **Proceed**, continue to Step 2.
```

#### Step 3 — lines 37-49: replace checkout+pull with fetch

New body:

```markdown
## Step 3: Fetch Latest from Origin

Run:
\`\`\`
git fetch origin
\`\`\`

This updates `refs/remotes/origin/*` (including `origin/HEAD`) without
touching the working tree, the index, HEAD, or any local branch. If it
fails (network error, auth, etc.), print the git error and **STOP**.

Do **not** check out the default branch. Do **not** pull. The new branch
will be created directly from `origin/<default>` in Step 5.
```

#### Step 5 — lines 122-137: create from `origin/<default>`

New body:

```markdown
## Step 5: Create the Branch from origin/<default>

Run:
\`\`\`
git checkout -b <branch> origin/<default>
\`\`\`

This creates `<branch>` pointing at the tip of `origin/<default>` and
switches to it in one step. The new branch is set to track
`origin/<default>` by default.

**On failure** — most commonly `error: Your local changes to the
following files would be overwritten by checkout: ...` — report git's
error verbatim and **STOP** with this guidance:

> Stash or commit your changes, then re-run the skill.

**On success**, run:
\`\`\`
git rev-parse --short HEAD
\`\`\`

Print one line:
\`\`\`
Created and checked out <branch> from origin/<default> @ <short-sha>
\`\`\`

The "from origin/<default>" wording is deliberate — it tells the user
their **local** `<default>` branch was not updated; only the new branch
sits on the latest remote tip.
```

#### Steps 2, 4 — unchanged

Step 2 (default detection), Step 4a (pattern scan), Step 4b/c/d/e/f
(name resolution and collision check) all work identically. They depend
only on remote refs and local branch refs, not on HEAD position. After
`git fetch origin`, `origin/HEAD` is current, so Step 2's primary path
(`git symbolic-ref refs/remotes/origin/HEAD --short`) still works.

### 2. [kit/plugins/git-agent/README.md](kit/plugins/git-agent/README.md)

Two small touch-ups in the **`new-branch` skill** sections:

- **Usage section** (around line 36-40): replace
  *"Verify the working tree is clean, switch to the default branch, pull
  the latest from `origin`, scan existing branch names…"*
  with
  *"Fetch the latest from `origin`, scan existing branch names for naming
  patterns, then create a new branch from `origin/<default>` without
  switching to the default branch first."*

- **Components section — `Guard` and `Pull strategy` bullets**: replace
  with:
  - **Working tree handling:** If uncommitted changes are present, asks
    the user whether to proceed (changes carry over to the new branch) or
    stop. Git refuses the checkout if changes would conflict.
  - **Sync strategy:** `git fetch origin` only — no local checkout, no
    pull. The new branch is created directly from `origin/<default>`.

The other component bullets (default branch detection, pattern scan, name
resolution, collision check) stay as they are.

## Verification

Test end-to-end inside `~/devbox/agentics` itself. The repo currently has
multiple branches with `feat/` and `fix/` prefixes, so the pattern scan
will produce a useful recommendation.

1. **Skill loads.**

   ```bash
   claude --plugin-dir ~/devbox/agentics/kit/plugins/git-agent
   ```

   Then in the session: ask *"create a new branch for testing the fetch
   change"*. Confirm the skill activates.

2. **Clean tree, happy path.** From a clean working tree, ask the skill
   to create a branch.
   - Expect: NO Step 1 prompt (silently continues).
   - Expect: `git fetch origin` runs.
   - Expect: NO `git checkout main` and NO `git pull`.
   - Expect: type prompt → branch created from `origin/main` → success
     line says `Created and checked out <branch> from origin/main @ <sha>`.
   - Verify: `git rev-parse <branch>` equals `git rev-parse origin/main`.

3. **Dirty tree, non-conflicting changes — Proceed.** Modify a file that
   does NOT differ between the current branch and `origin/main` (e.g.,
   add a new file with `touch /tmp/scratch && cp /tmp/scratch ./scratch`).
   - Expect: Step 1 asks the question with two options.
   - Pick "Proceed".
   - Expect: branch created, `scratch` file still present in working
     tree on the new branch.
   - Verify: `git status` shows the same uncommitted file on the new
     branch.

4. **Dirty tree, Stop.** Repeat with any modification, but pick "Stop".
   - Expect: prints the stop message; no fetch, no branch created.
   - Verify: `git branch --show-current` is unchanged.

5. **Dirty tree, conflicting changes — git refuses.** Modify a file that
   *does* differ between the current branch and `origin/main` (find one
   via `git diff --name-only HEAD origin/main`). Pick "Proceed".
   - Expect: `git checkout -b` fails at Step 5 with
     `error: Your local changes to the following files would be
     overwritten by checkout`.
   - Expect: skill prints git's error verbatim and STOPs with the
     stash-or-commit guidance.
   - Verify: `git branch --show-current` unchanged, working tree
     untouched.

6. **Stale `origin/HEAD` recovery.** Run
   `git remote set-head origin --delete` before invoking the skill.
   Step 2's fallback (`git remote show origin`) should still resolve
   the default. After `git fetch origin`, `origin/HEAD` is restored.

7. **Pattern scan still works.** From a fresh checkout, confirm the
   type prompt's first option is `fix` or `feat` (whichever currently
   dominates this repo's branch list) with the "(most used in this
   repo)" tag and the recommended full branch name appended.

## Next Steps (out of scope)

- **Auto-stash option.** A third runtime option (`Stash automatically,
  create branch, then pop`) would be convenient but introduces
  pop-conflict handling complexity. Worth adding once the simple
  Proceed/Stop flow has been used in practice.
- **Update local `<default>` after the fact.** The new flow leaves the
  local `main` branch behind `origin/main`. A follow-up skill or option
  could fast-forward the local default once the user is on the new
  branch (`git fetch origin main:main` works without checking out main).
- **Detached-HEAD recovery shortcut.** This new flow happens to be the
  textbook recovery from detached HEAD. Worth documenting as an
  intentional secondary use case in the skill's activation description.
