# git-agent

Automated git workflow for Claude Code — branch creation, commits, PRs, ship pipelines, and GitHub/GitLab issue creation. Encodes a strict plan→commit→PR pipeline with hard STOP boundaries — no autonomous test runs, coverage analysis, or scope expansion after the task is done. Automatically links plan issue references (from `<meta name="plan-issue">` tags) in PR descriptions.

## Features

### Skills (foreground)

- **branch-agent** — Fetches latest from origin, creates a branch from the default branch with no upstream tracking, and switches to it. Accepts a branch name or a descriptive phrase — descriptive names are auto-slugified into readable, whole-word slugs (e.g. `"add login page"` → `add-login-page`, max 60 chars; long names drop trailing words rather than abbreviating). Auto-generated names read like commit subjects (e.g. `feat/add-login-form-validation`). Always appends a `-YYYY-MM-DD` date suffix to the final branch name (e.g. `feat/login-fix-2026-04-17`). Stops immediately after. Auto-activates on intent match.
- **commit-agent** — Stages all changes, writes a conventional commit message, and commits. Stops immediately after. Manual invoke only — does not auto-activate on intent match.
- **pr-agent** — Detects the base branch, pushes if needed, checks for an existing PR, and creates one via `gh`. Stops immediately after. Manual invoke only — does not auto-activate on intent match.
- **ship** — Stages, commits, pushes, and creates a PR in one flow. Manual invoke only — does not auto-activate on intent match. Use commit-agent or pr-agent for individual steps.
- **ship-autonomous** — Supervised full pipeline: branches (if on default), commits, opens a PR, then subscribes to the PR's activity events to autofix CI failures (lint/typecheck/peer-deps, ≤3 attempts per check) and respond to review comments, posting regular status updates. Asks before any fix outside the safe allowlist. Falls back to CI polling when run locally without the GitHub MCP server. Auto-activates on intent match. Use when you want to ship and walk away.
- **create-issue** — Drafts and creates a GitHub or GitLab issue from any context source — `bug`, `feature`, `selection`, or `session`. Auto-detects the git host from the remote URL (`gh` for GitHub, `glab` for GitLab) and always shows a confirmation gate before writing. After creation, opens the issue in the browser (`--no-open` to suppress). Manual invoke only — does not auto-activate on intent match.

### Subagents (background, fire-and-forget)

For workflows where you want git operations to run in the background while you keep working in the main session, the plugin ships three background subagents that mirror the corresponding skills:

- **agent-commit** — Background version of `commit-agent`.
- **agent-pr** — Background version of `pr-agent`.
- **agent-ship** — Background version of `ship` (full commit + push + PR pipeline).

There is no `agent-branch` — branch creation is synchronous by design (you need to be on the new branch before continuing).

## Installation

### Via Marketplace (recommended)

```bash
/plugin install git-agent@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ./kit/plugins/git-agent
```

## Usage

### Commands

| Command | Description |
|---|---|
| `/git-agent:commit-bg [hint]` | Dispatch `agent-commit` in the background — stage and commit while you keep working. Optional hint sets commit message context. |
| `/git-agent:pr-bg [hint]` | Dispatch `agent-pr` in the background — push and open a GitHub PR while you keep working. Optional hint sets PR title/body context. |
| `/git-agent:ship-bg [hint]` | Dispatch `agent-ship` in the background — full commit + push + PR pipeline end-to-end. Optional hint sets commit/PR context. |

### Skills

| Skill | Activation | Trigger |
|---|---|---|
| `branch-agent` | Auto-activated | "create a new branch", "start a branch", "branch off main", "make a fresh branch" |
| `commit-agent` | Manual invoke only — use `/git-agent:commit-agent` explicitly | "commit my changes", "stage and commit", "commit all changes" |
| `pr-agent` | Manual invoke only — use `/git-agent:pr-agent` explicitly | "create a PR", "open a pull request", "make a PR", "push and create PR" |
| `ship` | Manual invoke only — use `/git-agent:ship` explicitly | "ship it", "commit and create a PR", "ship my changes", "send it", "land my work" |
| `ship-autonomous` | Auto-activated | "ship it autonomously", "ship and watch the PR", "ship and fix what breaks", "ship and autofix CI failures" |
| `create-issue` | Manual invoke only — use `/git-agent:create-issue` explicitly | "file a bug", "open an issue", "create a feature ticket", "log this as an issue" |

### Agents

Agents are background subagents dispatched via the corresponding slash commands or directly by an orchestrator.

| Agent | Invocation | Description |
|---|---|---|
| `agent-commit` | `/git-agent:commit-bg` or `Agent` tool with `subagent_type: agent-commit` | Stages all working-tree changes and creates a conventional commit. Reports the commit hash on completion. |
| `agent-pr` | `/git-agent:pr-bg` or `Agent` tool with `subagent_type: agent-pr` | Pushes the current branch if needed and opens a GitHub PR with an auto-generated summary. Reports the PR URL on completion. |
| `agent-ship` | `/git-agent:ship-bg` or `Agent` tool with `subagent_type: agent-ship` | Stages, commits, pushes, and opens a PR/MR end-to-end (GitHub via `gh`, GitLab via `glab`). Reports the PR/MR URL on completion. |

---

### branch-agent

Auto-activates when you say any of:
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
     a readable, whole-word kebab-case slug (max 60 chars; long phrases drop
     trailing words rather than abbreviating)
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

**Manual invoke only** — does not respond to natural-language intent matching. Invoke explicitly with `/git-agent:commit-agent` or dispatch via `/git-agent:commit-bg` for background operation.

The skill will:
1. Check for a clean tree or detached HEAD (stops if either)
2. Run `git add -A`
3. Analyze `git diff --staged` and write a conventional commit message
4. Run `git commit -m "<message>"` and output the hash
5. Print an undo note: `git reset HEAD~1`

**STOPS after commit. Does not push, test, or take further action.**

### pr-agent

**Manual invoke only** — does not respond to natural-language intent matching. Invoke explicitly with `/git-agent:pr-agent` or dispatch via `/git-agent:pr-bg` for background operation.

The skill will:
1. Guard: check for detached HEAD, default branch, `gh` auth
2. Detect base branch via `git symbolic-ref`, fall back to `main`/`master`
3. Check for existing PR (stops if one exists)
4. Push branch if no upstream tracking ref
5. Run `gh pr create` and output the PR URL

**STOPS after PR creation. Does not analyze code, run tests, or take further action.**

### ship

**Manual invoke only** — does not respond to natural-language intent matching. Invoke explicitly with `/git-agent:ship` or dispatch via `/git-agent:ship-bg` for background operation.

The skill will:
1. Guard: check for clean tree, detached HEAD, default branch, `gh` auth
2. Run `git add -A` and analyze `git diff --staged`
3. Write a conventional commit message and run `git commit`
4. Push the branch (with `-u` if no upstream)
5. If a PR already exists, report the URL and stop
6. Detect base branch, gather content, and run `gh pr create`

**STOPS after PR creation (or after pushing to an existing PR). Does not analyze code, run tests, or take further action.**

Use `commit-agent` or `pr-agent` if you only need one step.

### ship-autonomous

Auto-activates when you say any of:
- "ship it autonomously"
- "ship and watch the PR"
- "ship and fix what breaks"
- "ship and autofix CI failures"

The skill will:
1. Exit plan mode (Step 0) — no-op when already off
2. Guard: check for clean tree, uncommitted plan files, detached HEAD, `gh` auth
3. Branch: if on the default branch, auto-generate and create a feature branch via `branch-agent`; otherwise continue on current branch
4. Commit via `commit-agent` (stages, conventional message, commits)
5. Open PR via `pr-agent` (pushes, checks for existing PR, creates one)
6. Subscribe to the PR's activity events via `subscribe_pr_activity`, post an initial status update, and **end the turn** — CI failures and review comments then arrive as events that wake the session
7. On each event: refresh a live TodoWrite status checklist and post a concise update, then
   - **CI failure** → classify and autofix allow-listed classes (`lint`, `typecheck`, `peer-deps`), ≤3 attempts per check; commit + push the fix (which triggers the next CI run)
   - **Review comment** → apply clear, in-scope changes (commit, push, reply); ask first if ambiguous or architectural
   - **Anything outside the safe allowlist, or ambiguous** → ask via `AskUserQuestion` instead of guessing
8. When all checks are green: marks the PR ready, posts "CI is green — ready for review.", and sends a final status update with the PR URL. Keeps watching for later review comments until the PR merges/closes or you say stop (then unsubscribes)

**Environment:** event subscription requires a remote execution environment (Claude Code on the web or GitHub Actions). Run locally without the GitHub MCP server, the skill falls back to synchronous CI polling (`gh pr checks --watch`) with the same ≤3-attempt autofix, and stops once CI is green.

Use `ship` if you don't want CI watching or autofix — it's simpler and stops after PR creation.

### create-issue

**Manual invoke only** — does not respond to natural-language intent matching. Invoke explicitly with `/git-agent:create-issue [source] [title or description]`.

The skill will:
1. Exit plan mode if active (Phase 0 — no-op when already off)
2. Detect the git host from `git remote get-url origin` (`gh` for GitHub, `glab` for GitLab); ask if ambiguous
3. Pre-flight check that the relevant CLI is installed and authenticated (stops with a helpful message if not)
4. Resolve the source (`bug`, `feature`, `selection`, `session`) and title from `$ARGUMENTS`, asking if missing
5. Gather repo context — duplicate-issue search, related files via `Grep`/`Glob`, plus environment info for `bug` sources
6. Draft the issue body using the matching template under `references/`
7. Show a Create / Edit / Cancel confirmation gate — **never creates without explicit approval**
8. Run `gh issue create` / `glab issue create` with the drafted title, body, and labels
9. Open the issue in the browser (skip with `--no-open`)

**STOPS after issue creation. Does not push, commit, or take further git action.**

Sources:

| Source | What happens |
|---|---|
| `bug` | Collects Node/npm versions, recent git log, related files. Uses `[BUG]` title prefix. |
| `feature` | User-story + acceptance-criteria format. Uses `[FEATURE]` title prefix. |
| `selection` | Treats provided text as the issue seed; structures it. |
| `session` | Synthesizes from the current conversation context. |

Examples:

```
/git-agent:create-issue bug Login form crashes on empty password submit
/git-agent:create-issue feature Add dark mode toggle to settings panel
/git-agent:create-issue selection <paste the text here>
/git-agent:create-issue session
/git-agent:create-issue                  # asks what you need
/git-agent:create-issue bug --no-open    # create but skip browser
```

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

Dispatched via `/git-agent:commit-bg [hint]` or directly by an orchestrator.

Mirrors `commit-agent`: guards → `git add -A` → conventional commit message → `git commit`. Reports the commit hash on completion.

#### agent-pr

Dispatched via `/git-agent:pr-bg [hint]` or directly by an orchestrator.

Mirrors `pr-agent`: guards → detect base → check for existing PR → push if needed → `gh pr create`. Reports the PR URL on completion.

#### agent-ship

Dispatched via `/git-agent:ship-bg [hint]` or directly by an orchestrator.

Mirrors `ship`: guards → stage → commit → push → check for existing PR/MR → create PR/MR (GitHub via `gh`, GitLab via `glab`). Reports the PR/MR URL on completion.

### Caveat: working-tree snapshot

Background agents commit, push, and ship whatever is in the working tree at the moment they start running. If you keep editing files in the main session after dispatching an agent, those edits **may or may not** be included depending on timing. This is the inherent fire-and-forget tradeoff. If you need a guaranteed snapshot, use the synchronous skill instead.

## Slash commands (explicit background dispatch)

Three slash commands give you a one-line way to fire off the background agents without waiting for natural-language matching:

- `/git-agent:commit-bg [hint]` — dispatches `agent-commit` in the background.
- `/git-agent:pr-bg [hint]` — dispatches `agent-pr` in the background.
- `/git-agent:ship-bg [hint]` — dispatches `agent-ship` in the background.

Each command invokes the corresponding agent with `run_in_background: true` and returns control immediately; you'll be notified automatically when the agent completes. The optional argument is passed to the agent as a hint for the commit message or PR summary.

Example:

```
/git-agent:ship-bg fix off-by-one in pagination
```

## Requirements

- `pr-agent`, `ship`, `ship-autonomous`, `agent-pr`, `agent-ship`, and `create-issue` all require the [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated (`gh auth login`)
- GitLab support (`agent-ship`, `create-issue` on GitLab repos) additionally requires `glab` installed and authenticated

## Plugin Structure

```
plugins/git-agent/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── agent-commit.md
│   ├── agent-pr.md
│   └── agent-ship.md
├── commands/
│   ├── commit-bg.md
│   ├── pr-bg.md
│   └── ship-bg.md
├── scripts/
│   └── extract-plan-issues.sh    # Extracts plan-issue meta tags for PR descriptions
├── skills/
│   ├── branch-agent/
│   │   └── SKILL.md
│   ├── commit-agent/
│   │   └── SKILL.md
│   ├── create-issue/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── bug-report.md
│   │       ├── feature-request.md
│   │       ├── general-issue.md
│   │       └── host-commands.md
│   ├── pr-agent/
│   │   └── SKILL.md
│   ├── ship/
│   │   └── SKILL.md
│   └── ship-autonomous/
│       └── SKILL.md
├── CHANGELOG.md
└── README.md
```
