# git-agent

Automated git commit and PR creation for Claude Code. Encodes a strict plan→commit→PR pipeline with hard STOP boundaries — no autonomous test runs, coverage analysis, or scope expansion after the task is done.

## Features

- **commit-agent** — Stages all changes, writes a conventional commit message, and commits. Stops immediately after.
- **pr-agent** — Detects the base branch, pushes if needed, checks for an existing PR, and creates one via `gh`. Stops immediately after.

## Installation

```bash
# Load locally for testing
claude --plugin-dir ~/devbox/agentics/plugins/git-agent

# Or install via marketplace
/plugin marketplace add ~/devbox/agentics
/plugin install git-agent@agentics-kit
```

## Usage

Both skills activate automatically when intent matches.

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

## Requirements

- `pr-agent` requires the [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated (`gh auth login`)

## Plugin Structure

```
plugins/git-agent/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── commit-agent/
│   │   └── SKILL.md
│   └── pr-agent/
│       └── SKILL.md
├── CHANGELOG.md
└── README.md
```
