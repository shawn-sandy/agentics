---
name: branch-agent
description:
  Use when the user asks to create a new branch, start a branch, branch off
  main, make a fresh branch, or branch from the default. Creates the branch from
  origin/<default> with no upstream tracking. Does not commit, push, or create
  PRs — use commit-agent or pr-agent for that.
allowed-tools:
  - Bash(git *)
  - Bash(date *)
  - ToolSearch
  - AskUserQuestion
  - ExitPlanMode
argument-hint: "[branch-name] (optional) — omit to auto-generate from uncommitted changes using <type>/<scope>-<description>"
disable-model-invocation: true
model: Haiku
---

Create a new branch from the latest `origin/<default>` with no upstream tracking
ref. When called with no argument and the working tree has uncommitted changes,
the branch name is auto-generated from those changes. A `-YYYY-MM-DD` date
suffix is always appended to the final branch name so branches sort and group
chronologically. Follow these steps in strict order. **STOP immediately after
step 6.**

## Step 0: Exit Plan Mode

Always call `ExitPlanMode` immediately when this skill is invoked, before any
other action. Branch creation is a git mutation and cannot proceed inside plan
mode. This skill is explicit-invocation only (`disable-model-invocation: true`),
so the user has already opted in to taking action.

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
dashes, truncate to 30 characters. Example: `"add allowed tools to skills"` →
`"add-allowed-tools-to-skills"`. Use the slug as the branch name and proceed
to Step 2b.

**Case C — `$ARGUMENTS` is already a valid branch name** (no spaces): Use it
verbatim as the branch name. Do not slugify, abbreviate, or transform it.
Proceed to Step 2b.

## Step 2a: Auto-Generate Branch Name from Changes

Use this format: `<type>/<scope>-<description>` (or `<type>/<description>` if
the scope is omitted). Total length ≤ 49 characters — this reserves 11 chars
for the `-YYYY-MM-DD` suffix appended in Step 2b so the final branch name
stays under 60 chars.

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

From the changed file basenames and `git diff --stat`, extract 2–5 keywords
that describe the change. Lowercase, hyphen-separated, alphanumeric only. Strip
non-alphanumeric characters; collapse repeated hyphens; trim leading/trailing
hyphens.

**Validation:**

- Lowercase only; characters in `[a-z0-9/-]`; no leading/trailing hyphens
- Total length ≤ 49 chars (truncate the description segment at a word boundary
  if needed; never truncate the type or scope)
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

If the final name exceeds 60 characters, truncate the description portion at
a word boundary until it fits. Never truncate the date suffix, the type
prefix, or the scope segment.

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

## Step 5: Create Branch with No Upstream Tracking

Run:

```
git checkout -b <branch> --no-track origin/<default>
```

The `--no-track` flag prevents git from setting `origin/<default>` as the
upstream. Without it, any future `git push` would target the wrong remote ref.

On failure (branch already exists, dirty-tree conflict, or other error): report
the git error verbatim and **STOP**. Do not retry. Do not force.

## Step 6: Confirm and STOP

Run `git rev-parse --short HEAD` to get the short SHA.

Output one line:

> Created and checked out `<branch>` from `origin/<default>` @ `<sha>` (no
> upstream tracking)

---

**STOP here. Do not stage, commit, push, create PRs, or take any further
action.**
