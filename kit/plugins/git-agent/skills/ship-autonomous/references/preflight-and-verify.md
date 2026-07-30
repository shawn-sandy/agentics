# Pre-flight and Verify Commands

Command detail for **Step 1 (Pre-flight Guards)** and **Step 2.5 (Verify Before
Committing)** of `ship-autonomous`. The guards themselves live in SKILL.md —
this file only carries the commands that implement them.

## Step 1: Pre-flight Guards

Run all checks before any mutation.

**Clean working tree:**

```
git status --porcelain
```

If empty, output: "Nothing to ship — working tree is clean." and **STOP**.

**Uncommitted plan files:**

```
git ls-files --others --modified --exclude-standard docs/plans/
```

If any plan files are listed, output them and ask:

> Uncommitted plan files detected. How would you like to proceed?
> - `include` — stage them with the rest of the changes
> - `stash` — `git stash` them before branching (you can restore after)
> - `abort` — stop here; commit or clean up plan files first

Use AskUserQuestion with those three options. On `abort`, **STOP**.

**Detached HEAD:**

```
git branch --show-current
```

If empty, output: "Cannot ship: repository is in detached HEAD state. Checkout
a branch first." and **STOP**.

**GitHub CLI auth:**

```
gh auth status
```

If not installed or not authenticated, output:

```
GitHub CLI is required. Install from https://cli.github.com/ and run `gh auth login`.
```

and **STOP**.

## Step 2: Branch detection commands

Check current branch:

```
git branch --show-current
```

Detect the default branch:

```
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
```

If the current branch **is** the default branch (or `main`/`master` as
fallback), invoke the existing `git-agent:branch-agent` skill with no
arguments. It will auto-generate a `<type>/<scope>-<desc>` slug from the
working tree and branch from `origin/HEAD --no-track`.

If already on a feature branch, continue without creating a new branch.

## Step 2.5: Verify Before Committing

**Tests.** Prefer the exact `test` script; it is the one that runs once and
exits:

```
jq -r '.scripts | keys[] | select(. == "test")' package.json 2>/dev/null
```

If there is no exact `test` script, fall back to a single-run variant, excluding
persistent ones (`watch`, `dev`, `ui`, `serve`) that never terminate:

```
jq -r '.scripts | keys[] | select(startswith("test")) | select(test("watch|dev|ui|serve") | not)' package.json 2>/dev/null
```

Run the first match. If tests fail, report the failing output verbatim and
**STOP** — do not commit a red tree. If neither query matches, say so and
continue — never start a watch-mode script, which would hang the pipeline
forever.

**Lint.** Detect a lint script:

```
jq -r '.scripts | to_entries[] | select(.key | test("^lint")) | select(.key + " " + .value | test("--fix|watch") | not) | .key' package.json 2>/dev/null
```

The filter reads each script's **command**, not just its name — a script named
plainly `lint` whose value is `eslint --fix .` would otherwise rewrite the
working tree at exactly the stage that forbids it.

Run the first match. If lint fails, report the failing output verbatim and
**STOP** — catching it here saves a full CI round-trip through Step 6b. Do not
auto-apply `--fix` at this stage; the user has not seen the diff yet. If no
lint script exists, say so and continue.

**Browser preview.** Only if the change is observable in a browser (it renders,
serves, or logs something the dev server exercises). Skip otherwise — a server
that can't prove anything is wasted time.

1. `preview_start` with the `name` from `.claude/launch.json`.
2. Check `read_console_messages` and `preview_logs`. **Any console or server
   error blocks the pipeline** — fix it and re-run both checks until they are
   clear before going on. A broken page proves nothing.
3. `resize_window` with `colorScheme: light`, then `colorScheme: dark` —
   screenshot each. Report any theme-specific breakage and fix before
   continuing.
