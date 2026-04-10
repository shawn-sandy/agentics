# git-agent

Automated git commit and PR creation for Claude Code. Encodes a strict plan→commit→PR pipeline with hard STOP boundaries — no autonomous test runs, coverage analysis, or scope expansion after the task is done.

## Features

- **branch-agent** — Fetches latest from origin, creates a branch from the default branch with no upstream tracking, and switches to it. Accepts a branch name or a descriptive phrase — descriptive names are auto-slugified (e.g. `"add login page"` → `add-login-page`, max 30 chars). Stops immediately after.
- **commit-agent** — Stages all changes, writes a conventional commit message, and commits. Stops immediately after.
- **pr-agent** — Detects the base branch, pushes if needed, checks for an existing PR, and creates one via `gh`. Stops immediately after.
- **ship** — Stages, commits, pushes, and creates a PR in one flow. Use commit-agent or pr-agent for individual steps.

## Installation

```bash
# Load locally for testing
claude --plugin-dir ./kit/plugins/git-agent

# Or install via marketplace
/plugin marketplace add /path/to/agentics
/plugin install git-agent@agentics-kit
```

## Usage

All skills activate automatically when intent matches.

### branch-agent

Say any of:
- "create a new branch called feat/login-fix"
- "start a branch for dark mode"
- "branch off main for this feature"
- "make a fresh branch feat/signup"
- "branch off main" (with no name — auto-detected from working tree changes)

The skill will:
1. Guard: check for detached HEAD, verify `origin` remote exists
2. Resolve the branch name:
   - If you provided a valid branch name, use it verbatim
   - If you provided a descriptive phrase (with spaces), auto-slugify it to
     a 30-char kebab-case slug
   - If you didn't provide one and the working tree has uncommitted changes,
     auto-generate a `<type>/<scope>-<description>` name from those changes
     (mirrors `commit-agent`'s conventional types)
   - If you didn't provide one and the tree is clean, stop and ask for a name
3. Detect the default branch via `git symbolic-ref`, fall back to `main`/`master`
4. Run `git fetch origin <default>` to ensure the ref is current
5. Run `git checkout -b <branch> --no-track origin/<default>` (no upstream set)
6. Output the created branch name and short SHA

**STOPS after branch creation. Does not stage, commit, push, or create PRs.**

Use `commit-agent` to commit work on the new branch. Use `pr-agent` when ready to open a PR.

### commit-agent

Say any of:
- "commit my changes"
- "stage and commit"
- "commit all changes"
- "commit everything"

The skill will:
1. Check for a clean tree or detached HEAD (stops if either)
2. Run `git add -A`
3. Analyze `git diff --staged` and write a conventional commit message
4. Run `git commit -m "<message>"` and output the hash
5. Print an undo note: `git reset HEAD~1`

**STOPS after commit. Does not push, test, or take further action.**

### pr-agent

Say any of:
- "create a PR"
- "open a pull request"
- "make a PR"
- "push and create PR"

The skill will:
1. Guard: check for detached HEAD, default branch, `gh` auth
2. Detect base branch via `git symbolic-ref`, fall back to `main`/`master`
3. Check for existing PR (stops if one exists)
4. Push branch if no upstream tracking ref
5. Run `gh pr create` and output the PR URL

**STOPS after PR creation. Does not analyze code, run tests, or take further action.**

### ship

Say any of:
- "ship it"
- "commit and create a PR"
- "ship my changes"
- "send it"
- "land my work"

The skill will:
1. Guard: check for clean tree, detached HEAD, default branch, `gh` auth
2. Run `git add -A` and analyze `git diff --staged`
3. Write a conventional commit message and run `git commit`
4. Push the branch (with `-u` if no upstream)
5. If a PR already exists, report the URL and stop
6. Detect base branch, gather content, and run `gh pr create`

**STOPS after PR creation (or after pushing to an existing PR). Does not analyze code, run tests, or take further action.**

Use `commit-agent` or `pr-agent` if you only need one step.

## Requirements

- `pr-agent` requires the [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated (`gh auth login`)

## Plugin Structure

```
plugins/git-agent/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── branch-agent/
│   │   └── SKILL.md
│   ├── commit-agent/
│   │   └── SKILL.md
│   ├── pr-agent/
│   │   └── SKILL.md
│   └── ship/
│       └── SKILL.md
├── CHANGELOG.md
└── README.md
```
