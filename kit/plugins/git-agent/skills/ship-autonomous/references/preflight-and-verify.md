# Pre-flight and Verify Commands

Command detail for **Step 1 (Pre-flight Guards)** and **Step 2.5 (Verify Before
Committing)** of `ship-autonomous`. The guards themselves live in SKILL.md —
this file only carries the commands that implement them.

## Step 1: Pre-flight Guards

**Run every guard before reporting any of them.** No guard stops the sweep: run
all of them against the unmutated tree, collect the results, print one table,
and only then decide whether to halt. **Never stop on the first failure** — a
session with an unauthenticated `gh`, a dirty tree, and a worktree missing its
`.env` must cost one spin-up, not three. The halt itself is unchanged: **any
BLOCKED row STOPs the skill before any mutation**. It just stops knowing every
blocker at once.

Report one table, one row per guard that ran:

| Guard | Status | Remediation |
|---|---|---|
| Clean working tree | PASS | — |
| Uncommitted plan files | PASS | — |
| Detached HEAD | PASS | — |
| GitHub CLI auth | BLOCKED | `gh auth login` |
| Worktree env parity | BLOCKED | `cp /path/to/main/.env /path/to/worktree/.env` |
| Browser availability | UNVERIFIED — no browser | — |

- **PASS** — the guard is satisfied.
- **FAIL** — the guard could not run (binary absent, command errored). Report
  its error verbatim and treat the row as BLOCKED; a guard that cannot answer
  has not cleared anything.
- **BLOCKED** — the guard ran and found a blocker. Every BLOCKED row carries a
  **verbatim remediation command** the user can paste.

**Never remediate automatically.** No `gh auth login`, no `git stash`, no
copying an env file. Re-auth is an interactive browser flow that cannot succeed
unattended, and a silent stash or env copy moves the user's own data without
asking. The Remediation column is text for the user to run, never a command to
execute here.

**Headless (no `AskUserQuestion`):** take each gate's named default below and
log it. Never improvise at a gate that exists to stop the run.

### Clean working tree

```
git status --porcelain
```

Empty → BLOCKED: "Nothing to ship — working tree is clean." Remediation: make a
change before shipping.

### Uncommitted plan files

```
git ls-files --others --modified --exclude-standard docs/plans/
```

If any plan files are listed, output them and ask:

> Uncommitted plan files detected. How would you like to proceed?
> - `include` — stage them with the rest of the changes
> - `stash` — `git stash` them before branching (you can restore after)
> - `abort` — stop here; commit or clean up plan files first

Use AskUserQuestion with those three options. On `abort`, the row is BLOCKED.
**Headless default: `abort`** — say the default was taken and why. Stashing or
staging the user's plan files unasked is the outcome this gate exists to
prevent, so the fallback is the one that touches nothing.

### Detached HEAD

```
git branch --show-current
```

Empty → BLOCKED: "Cannot ship: repository is in detached HEAD state. Checkout a
branch first." Remediation: `git checkout <branch>`.

### GitHub CLI auth

```
gh auth status
```

Not installed or not authenticated → BLOCKED:

```
GitHub CLI is required. Install from https://cli.github.com/ and run `gh auth login`.
```

### Worktree env parity

Gitignored env files do not travel with `git worktree add`, so every linked
worktree starts without them — and the failure presents as a code defect in
whatever was edited last, which is the most expensive way to learn about it.

First, is this a linked worktree at all?

```
git rev-parse --git-dir
git rev-parse --git-common-dir
```

Identical → not a linked worktree. **Omit the row entirely**; there is nothing
to compare against.

Different → linked worktree. The main checkout is the path on the **first** line
of:

```
git worktree list
```

List the gitignored env files on each side — tracked ones travel with the
worktree already, so only ignored ones can be missing:

```
git -C <main-checkout-path> ls-files --others --ignored --exclude-standard -- '.env*'
git ls-files --others --ignored --exclude-standard -- '.env*'
```

Any file in the first list and absent from the second → BLOCKED, with one
remediation line per missing file:

```
cp <main-checkout-path>/.env <this-worktree-path>/.env
```

**Never run it.** These files hold secrets; a silent copy is the wrong default
even when copying is the right action. Detection is the deliverable — the `cp`
stays the user's decision.

### Browser availability

Probe whether `preview_start` is reachable, and record the result for Step 2.5.

This row is **never BLOCKED** — an absent browser degrades verification, it does
not stop a ship. Reachable → PASS. Unreachable → the row reads
`UNVERIFIED — no browser`, and Step 2.5 carries that exact string forward.

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

**Probe availability before the preview block.** Establish whether
`preview_start` is reachable (Step 1's Browser availability guard already
recorded this; re-probe here if it did not run). The tool is absent in headless
and other non-interactive sessions, and a browser step that is merely skipped
leaves a PR body that reads as though the change was verified — the honest
marker is the convention this repo already chose.

- **Unreachable** → skip steps 1–3 below, state `UNVERIFIED — no browser` in the
  session output, and carry that exact string forward as the verification
  result. Step 4 reports it to `git-agent:pr-agent`, whose Step 5 writes it into
  the PR body's Test Plan. Never omit the claim, and never mark a Test Plan box
  the browser would have verified.
- **Reachable** → run steps 1–3 and report no marker.

1. `preview_start` with the `name` from `.claude/launch.json`.
2. Check `read_console_messages` and `preview_logs`. **Any console or server
   error blocks the pipeline** — fix it and re-run both checks until they are
   clear before going on. A broken page proves nothing.
3. `resize_window` with `colorScheme: light`, then `colorScheme: dark` —
   screenshot each. Report any theme-specific breakage and fix before
   continuing.
