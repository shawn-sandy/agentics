---
name: branch-agent
description: "Creates a git branch from origin/<default> with no upstream tracking. Auto-names the branch from staged or unstaged changes in the working tree. Use when the user asks to create or start a new branch."
allowed-tools: Bash(git *), Bash(date *), ToolSearch, AskUserQuestion, ExitPlanMode
argument-hint: "[branch-name] (optional) — omit to auto-generate from uncommitted changes using <type>/<scope>-<description>"
disable-model-invocation: true
model: haiku
---

Create a new branch from the latest `origin/<default>` with no upstream tracking
ref. When called with no argument and the working tree has uncommitted changes,
the branch name is auto-generated from those changes. A `-YYYY-MM-DD` date
suffix is always appended to the final branch name so branches sort and group
chronologically. Follow these steps in strict order. **STOP immediately after
step 6.**

## When not to use

Does not commit, push, or create PRs — use commit-agent or pr-agent for that.

## Step 0: Exit Plan Mode

**If currently in plan mode**, call `ExitPlanMode` first and silently before any other action — Branch creation is a git mutation and cannot proceed inside plan mode. Skip this step entirely when not in plan mode. `ExitPlanMode` is a deferred tool — use `ToolSearch` with `select:ExitPlanMode` first, then call it silently.

## Step 1: Guards

Run all checks before proceeding. Stop on the first failure.

**Not a git repository:** Run `git rev-parse --is-inside-work-tree`. If it
fails, output: "Not a git repository." and **STOP**.

**Detached HEAD:** Run `git branch --show-current`. If the output is empty,
output: "Cannot create branch: repository is in detached HEAD state. Checkout a
named branch first." and **STOP**.

**No origin remote:** Run `git remote get-url origin`. If it fails, output:
"branch-agent requires a remote named 'origin'." and **STOP**.

## Step 2: Resolve Branch Name

Read `$ARGUMENTS`.

**Case A — `$ARGUMENTS` is empty or whitespace-only:** Run
`git status --porcelain=v1`.

- **If output is empty** (clean working tree): output "Provide a branch name.
  Example: branch-agent feat/login-fix" and **STOP**.
- **If output is non-empty** (working tree has changes): auto-generate the
  branch name as described in Step 2a, then proceed to Step 2b.

**Case B — `$ARGUMENTS` contains spaces or reads as a descriptive phrase:**
Convert it to a human-readable slug — lowercase, replace spaces and special
characters with `-`, collapse consecutive dashes, strip leading/trailing
dashes. Keep the user's words whole; if the slug exceeds 60 characters, drop
trailing words (never chop mid-word). If a single word alone exceeds 60
characters (so no word boundary exists to trim at), hard-truncate that word
at 60 characters as a last resort. Example:
`"add allowed tools to skills"` → `"add-allowed-tools-to-skills"`. Use the
slug as the branch name and proceed to Step 2b.

**Case C — `$ARGUMENTS` is already a valid branch name** (no spaces): Use it
verbatim as the branch name. Do not slugify, abbreviate, or transform it.
Proceed to Step 2b.

## Step 2a: Auto-Generate Branch Name from Changes

Use this format: `<type>/<scope>-<description>` (or `<type>/<description>` if
the scope is omitted). Total length ≤ 60 characters — this reserves 11 chars
for the `-YYYY-MM-DD` suffix appended in Step 2b so the final branch name
stays within 72 chars.

**Type inference (first match wins):**

1. Only markdown / `docs/**` / `README*` changed → `docs`
2. Only test files (`**/test/**`, `**/tests/**`, `*.test.*`, `*_test.*`,
   `tests/fixtures/**`) → `test`
3. Only CI configs (`.github/workflows/**`, `.gitlab-ci.yml`, `.circleci/**`)
   → `ci`
4. Only build/dependency manifests (`package.json`, `pnpm-lock.yaml`,
   `Cargo.toml`, `pyproject.toml`, etc.) → `build`
5. Diff is pure renames/moves with no logic delta → `refactor`
6. New files added under source dirs → `feat`
7. Existing source files modified, diff < 20 lines → `fix`
8. Existing source files modified, diff ≥ 20 lines → `feat`
9. Otherwise → `chore`

**Scope inference:**

Run `git status --porcelain=v1` and group changed paths by their first path
segment. Pick the group with the most files and use that segment as `<scope>`.
If the top group contains ≤50% of changed files, OR more than 2 groups contain
files, **omit the scope** entirely (use `<type>/<description>`).

**Description inference:**

From the changed file basenames and `git diff --stat`, write the description
as a short verb-led phrase (3–7 words) that reads like a commit subject a
human would write: start with an imperative verb (`add`, `fix`, `update`,
`remove`, `rename`, `improve`, …) followed by what changed. Lowercase,
hyphen-separated, alphanumeric only. Strip non-alphanumeric characters;
collapse repeated hyphens; trim leading/trailing hyphens.

Readability rules:

- Use whole dictionary words — never abbreviate a word to save space
  (`validation`, not `valid` or `val`; `config`, not `cfg`)
- Prefer describing *what the change does* over listing filenames
- If the name runs long, drop the least important trailing words instead of
  shortening individual words

Examples:

| Change | Good | Bad |
|--------|------|-----|
| New login validation in `src/auth/` | `feat/src-add-login-form-validation` | `feat/src-login-form-valid` |
| Typo fixes across README files | `docs/fix-readme-typos` | `docs/rdme-typo-fx` |
| CI workflow updated to Node 22 | `ci/update-workflow-to-node-22` | `ci/wf-node22` |

**Validation:**

- Lowercase only; characters in `[a-z0-9/-]`; no leading/trailing hyphens
- Total length ≤ 60 chars (drop trailing description words to fit; never chop
  mid-word; never truncate the type or scope)
- Must contain a `/` separator after the type

If validation fails, regenerate once with `chore` as the type and a shortened
description. If it still fails, fall back to `chore/auto-branch` and proceed.

Output one line before continuing:

> Auto-generated branch name from working tree changes: `<branch>`

Then proceed to Step 2b.

## Step 2b: Append Date Suffix

Run:

```
date +%Y-%m-%d
```

Append the result to the resolved branch name with a `-` separator, producing
the final branch name: `<branch>-<YYYY-MM-DD>` (e.g. `feat/login-fix` →
`feat/login-fix-2026-04-17`). This always runs, regardless of whether the
name came from Case A, B, or C.

If the final name exceeds 72 characters, drop trailing words from the
description portion until it fits. Never chop mid-word, and never truncate
the date suffix, the type prefix, or the scope segment.

Use this date-suffixed name as `<branch>` for the rest of the flow. Proceed
to Step 3.

## Step 3: Detect Default Branch

Run:

```
git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null
```

Strip the `origin/` prefix to get the default branch name.

If that fails, run:

```
git remote show origin | grep 'HEAD branch'
```

Extract the branch name after `HEAD branch:`.

If both fail, try `git rev-parse --verify --quiet main`, then
`git rev-parse --verify --quiet master`. Use the first that succeeds.

If none resolve, report the git error verbatim and **STOP**.

## Step 4: Fetch Latest from Origin

Run:

```
git fetch origin <default>
```

**On failure** (offline, network error, auth required): report the git error
verbatim and **STOP**. Do not proceed with a stale ref.

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

## Step 6: Confirm and STOP

Run `git rev-parse --short HEAD` to get the short SHA.

Output one line:

> Created and checked out `<branch>` from `origin/<default>` @ `<sha>` (no
> upstream tracking)

---

**STOP here. Do not stage, commit, push, create PRs, or take any further
action.**
