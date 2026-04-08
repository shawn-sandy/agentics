---
name: branching-agent
description: Use when the user asks to create a new branch, make a branch, start a new branch, or branch off for a feature, fix, or any new work. Does not commit, push, or create PRs.
allowed-tools: Bash(git *), AskUserQuestion
argument-hint: "new branch for the login fix", "start a feature for dark mode"
---

Fetch the latest from origin, scan existing branch naming patterns to inform a
recommendation, then create a new branch from `origin/<default>` without leaving
the current branch as an intermediate step. Carries uncommitted changes forward
when safe. Follow these steps in strict order. **STOP immediately after
Step 5.**

## Step 1: Check Working Tree State

Run:

```
git status --porcelain
```

If the output is **empty**, continue silently to Step 2.

If the output is **non-empty**, use `AskUserQuestion` to ask:

> "Working tree has uncommitted changes. They will be carried over to the new
> branch — git will refuse the checkout if they conflict with the default
> branch. How do you want to proceed?"

Options:

- "Proceed — carry changes to the new branch"
- "Stop — I'll stash or commit first"

If the user picks **Stop**, print
`Stopped. Stash or commit your changes, then re-run.` and **STOP**.

If the user picks **Proceed**, continue to Step 2.

## Step 2: Detect the Default Branch

Run:

```
git symbolic-ref refs/remotes/origin/HEAD --short
```

- On success the output looks like `origin/main`. Strip the `origin/` prefix to
  get the default branch name (e.g., `main`).
- If this fails (remote HEAD not set), run:
  ```
  git remote show origin
  ```
  and extract the value after `HEAD branch:`.
- If both fail, print the git error and **STOP**. Do not guess `main` or
  `master`.

## Step 3: Fetch Latest from Origin

Run:

```
git fetch origin
```

This updates `refs/remotes/origin/*` (including `origin/HEAD`) without touching
the working tree, the index, HEAD, or any local branch. If it fails (network
error, auth, etc.), print the git error and **STOP**.

Do **not** check out the default branch. Do **not** pull. The new branch will be
created directly from `origin/<default>` in Step 5.

## Step 4: Resolve Branch Name

### 4a. Scan branch naming patterns

Run:

```
git branch -a --format='%(refname:short)'
```

Analyze the output in-Claude — do not print the raw list. Extract:

1. **Type prefixes in use** — scan for `<word>/` or `<word>-` prefixes (e.g.,
   `feat/`, `fix/`, `chore/`, `hotfix/`). Count how often each appears across
   all branches.
2. **Most-used type** — the prefix with the highest count. If there is a tie,
   prefer the one from local branches.
3. **Separator convention** — determine whether this repo uses `/` (e.g.,
   `feat/dark-mode`) or `-` with no prefix (e.g., `dark-mode-toggle`). Default
   to `/` if mixed or unclear.
4. **Case convention** — detect whether names are kebab-case, snake_case, or
   other. Default to kebab-case if mixed.

Store these findings for use in steps 4b and 4c.

### 4b. Description source

Check the user's message for a branch description or subject:

- If the user's message already names the work, extract **only the core
  subject** — the noun phrase that describes the actual work, not the request.
  Strip meta-phrases like "new branch for", "start a feature for", "make a
  branch to", "I need a branch that", "can you create a branch for", etc.
  Examples:
  - "new branch for the login fix" → subject: `login fix`
  - "start a feature for dark mode" → subject: `dark mode`
  - "I need a branch to add auth middleware" → subject: `auth middleware`
- If the user's message contains no usable subject, use `AskUserQuestion` to
  ask:
  > "What should the new branch be called? Enter a name or describe the work in
  > a few words."

### 4c. Build a concise, readable slug

Transform the subject from 4b into a short, readable slug in-Claude:

1. From the subject, identify the core noun phrase that names the work — drop
   articles (`a`, `an`, `the`), filler verbs (`add`, `make`, `create`, `update`,
   `fix`, `start`, `implement`), and filler prepositions (`for`, `of`, `to`,
   `with`, `about`, `on`) unless removing them would make the slug ambiguous.
2. Aim for **≤20 characters** in the final slug. If the phrase is longer,
   shorten using well-known abbreviations first:
   - `authentication` → `auth`
   - `configuration` → `config`
   - `middleware` → `mw` (only if needed to fit)
   - `database` → `db`
   - `repository` → `repo`

   Then drop the least-essential word. Never truncate mid-word except as a
   last resort.
3. Normalize: lowercase, replace any run of characters that are not `a–z`,
   `0–9`, or `-` with a single `-`, trim leading/trailing `-`.
4. Hard cap: if the result still exceeds 40 characters, truncate at the last `-`
   before 40.

**Examples:**

| Subject extracted in 4b           | Final slug        |
| --------------------------------- | ----------------- |
| `login fix`                       | `login-fix`       |
| `dark mode`                       | `dark-mode`       |
| `auth middleware`                 | `auth-middleware` |
| `onboarding tour redesign`        | `onboarding-tour` |
| `fix flaky test for payments API` | `payments-api`    |

If the resulting slug is empty, print
`Could not derive a branch name from that input.` and **STOP**.

### 4d. Type prefix

Build the slug now (per step 4c, already completed) so you can show a concrete
recommendation.

Build the option list for `AskUserQuestion` dynamically:

- Place the **most-used type** from the scan first, with the note "(most used in
  this repo)" and the recommended full branch name appended — e.g.,
  `fix — most used in this repo → fix/dark-mode-toggle`.
- Fill remaining slots with the other common types not already at the top:
  - `feat` — new feature
  - `fix` — bug fix
  - `chore` — tooling, refactor, or housekeeping
  - `docs` — documentation only
- Limit to 4 options total (the most-used type + 3 others). ("Other" is
  automatic.)

Question text:
`"What type of work is this? Based on existing branches, '${most_used_type}' is most common here."`

("Other" is automatically available for any other type.)

### 4e. Final branch name

Combine as `<type>/<slug>` — for example `fix/login-redirect`.

### 4f. Collision check

Run:

```
git rev-parse --verify --quiet <branch>
```

If the branch already exists locally, print:

> Branch `<branch>` already exists locally. Choose a different name.

and **STOP**. Do not append a numeric suffix.

## Step 5: Create the Branch from origin/<default>

Run:

```
git checkout -b <branch> origin/<default>
```

This creates `<branch>` pointing at the tip of `origin/<default>` and switches
to it in one step. The new branch is set to track `origin/<default>` by default.

**On failure** — most commonly
`error: Your local changes to the following files would be overwritten by checkout: ...`
— report git's error verbatim and **STOP** with:

> Stash or commit your changes, then re-run the skill.

On success, run:

```
git rev-parse --short HEAD
```

Print one line:

```
Created and checked out <branch> from origin/<default> @ <short-sha>
```

The `origin/<default>` wording is deliberate — it tells the user their local
`<default>` branch was not updated; only the new branch sits on the latest
remote tip.

---

**STOP here. Do not stage, commit, push, or take any further action.**

## Examples

User messages that activate this skill:

- "create a new branch"
- "start a new branch for the login redirect fix"
- "I need a fresh branch for dark mode"
- "new branch from main"
