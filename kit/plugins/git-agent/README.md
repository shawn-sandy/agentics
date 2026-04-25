# git-agent

Automated git commit and PR creation for Claude Code. Encodes a strict plan→commit→PR pipeline with hard STOP boundaries — no autonomous test runs, coverage analysis, or scope expansion after the task is done.

## Features

### Skills (synchronous)

- **branch-agent** — Fetches latest from origin, creates a branch from the default branch with no upstream tracking, and switches to it. Accepts a branch name or a descriptive phrase — descriptive names are auto-slugified (e.g. `"add login page"` → `add-login-page`, max 30 chars). Always appends a `-YYYY-MM-DD` date suffix to the final branch name (e.g. `feat/login-fix-2026-04-17`). Stops immediately after.
- **commit-agent** — Stages all changes, writes a conventional commit message, and commits. Stops immediately after.
- **pr-agent** — Detects the base branch, pushes if needed, checks for an existing PR, and creates one via `gh`. Stops immediately after.
- **ship** — Stages, commits, pushes, and creates a PR in one flow. Use commit-agent or pr-agent for individual steps.

### Subagents (background, fire-and-forget)

For workflows where you want git operations to run in the background while you keep working in the main session, the plugin ships three background subagents that mirror the corresponding skills:

- **agent-commit** — Background version of `commit-agent`.
- **agent-pr** — Background version of `pr-agent`.
- **agent-ship** — Background version of `ship` (full commit + push + PR pipeline).

There is no `agent-branch` — branch creation is synchronous by design (you need to be on the new branch before continuing).

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
3. Append a `-YYYY-MM-DD` date suffix (today's date) to the resolved name
4. Detect the default branch via `git symbolic-ref`, fall back to `main`/`master`
5. Run `git fetch origin <default>` to ensure the ref is current
6. Run `git checkout -b <branch> --no-track origin/<default>` (no upstream set)
7. Output the created branch name and short SHA

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

## Background subagents

The skills above run synchronously in the foreground — your session waits for them to complete. The agents in `agents/` are background subagents that run independently while you keep working.

### Skill vs. agent

| Use the skill | Use the agent |
|---|---|
| You want the work to finish before you continue. | You want to fire and forget — keep typing while git work happens in the background. |
| You want to see and approve each step. | You're confident in the operation and don't need to babysit it. |
| You're driving the operation directly. | An orchestrator (or you) is dispatching the work as part of a larger flow. |

### Available agents

#### agent-commit

Trigger phrases:
- "commit in the background"
- "commit and keep going"
- "fire off a commit while I work"

Mirrors `commit-agent`: guards → `git add -A` → conventional commit message → `git commit`. Reports the commit hash on completion.

#### agent-pr

Trigger phrases:
- "open a PR in the background"
- "create an MR summary while I work"
- "fire off a PR"

Mirrors `pr-agent`: guards → detect base → check for existing PR → push if needed → `gh pr create`. Reports the PR URL on completion.

#### agent-ship

Trigger phrases:
- "ship it in the background"
- "ship and keep working"
- "land my work without blocking me"

Mirrors `ship`: guards → stage → commit → push → check for existing PR/MR → create PR/MR (GitHub via `gh`, GitLab via `glab`). Reports the PR/MR URL on completion.

### Caveat: working-tree snapshot

Background agents commit, push, and ship whatever is in the working tree at the moment they start running. If you keep editing files in the main session after dispatching an agent, those edits **may or may not** be included depending on timing. This is the inherent fire-and-forget tradeoff. If you need a guaranteed snapshot, use the synchronous skill instead.

## Requirements

- `pr-agent` requires the [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated (`gh auth login`)

## Plugin Structure

```
plugins/git-agent/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── agent-commit.md
│   ├── agent-pr.md
│   └── agent-ship.md
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
