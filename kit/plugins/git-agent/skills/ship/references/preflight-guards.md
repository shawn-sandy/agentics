# Pre-flight guard commands

Command detail for **Step 1 (Pre-flight Guards)** of `ship`. The guards
themselves live in SKILL.md — this file carries the table format and the
commands that implement them.

`ship-autonomous` keeps its own copy in
`skills/ship-autonomous/references/preflight-and-verify.md`. A skill can only
bundle files under its own directory, so the two are duplicated on purpose;
**both describe the same run-all-then-report contract** and any change to one
belongs in the other in the same commit.

## The combined report

**Run every guard before reporting any of them.** No guard stops the sweep: run
all of them against the unmutated tree, collect the results, print one table,
and only then decide whether to halt. **Never stop on the first failure** — a
session with a dirty tree, an unauthenticated CLI, and a worktree missing its
`.env` must cost one spin-up, not three. The halt itself is unchanged: **any
BLOCKED row STOPs the skill before any mutation**. It just stops knowing every
blocker at once.

| Guard | Status | Remediation |
|---|---|---|
| Clean working tree | PASS | — |
| Detached HEAD | PASS | — |
| On main or master | BLOCKED | `git checkout -b <feature-branch>` |
| CLI auth | BLOCKED | `gh auth login` |
| Worktree env parity | BLOCKED | `cp /path/to/main/.env /path/to/worktree/.env` |

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

**Headless (no `AskUserQuestion`):** this step raises no question of its own, so
there is nothing to default. Report the table and halt on any BLOCKED row
exactly as an interactive run would.

## Clean working tree

```
git status --porcelain
```

Empty → BLOCKED: "Nothing to ship — working tree is clean." Remediation: make a
change before shipping.

## Detached HEAD

```
git branch --show-current
```

Empty → BLOCKED: "Cannot ship: repository is in detached HEAD state. Checkout a
branch first." Remediation: `git checkout <branch>`.

## On main or master

Same command. `main` or `master` → BLOCKED: "Cannot ship from the default
branch. Switch to a feature branch first." Remediation:
`git checkout -b <feature-branch>`.

## CLI not available or not authenticated

Detect GitHub vs GitLab and verify the CLI per `platform-clis.md`. Missing or
unauthenticated → BLOCKED, carrying that file's install-and-login message.

## Worktree env parity

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
