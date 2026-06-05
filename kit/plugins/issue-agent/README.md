# issue-agent

Create GitHub or GitLab issues from any context — selection, session, bug, or feature description — without leaving the Claude Code session. Automatically opens the created issue in your browser (use `--no-open` to suppress).

## Installation

### Via Marketplace (recommended)
```bash
/plugin install issue-agent@agentics-kit
```

### Local Development
```bash
claude --plugin-dir ./kit/plugins/issue-agent
```

## Usage

### Skills

#### `create-issue` — Manual invoke only — use `/issue-agent:create-issue` explicitly

Drafts and opens a GitHub or GitLab issue from any context source. Detects the git host from the remote URL and always shows a confirmation gate before creating the issue.

```bash
# File a bug from a description
/issue-agent:create-issue bug Login form crashes on empty password submit

# Request a feature
/issue-agent:create-issue feature Add dark mode toggle to settings panel

# Open an issue from highlighted/pasted text
/issue-agent:create-issue selection <paste the text here>

# Synthesize an issue from the current session
/issue-agent:create-issue session

# Without arguments — skill will ask you what you need
/issue-agent:create-issue
```

The skill requires `gh` (GitHub CLI) or `glab` (GitLab CLI) to be installed and authenticated. If not:

```bash
# Authenticate with GitHub
gh auth login

# Authenticate with GitLab
glab auth login
```

## Overview

`issue-agent` provides a single manual-invoke skill, `create-issue`, that:

- Detects the git host automatically (GitHub → `gh`, GitLab → `glab`)
- Ingests context from four sources: a text selection, the current session, a bug description, or a feature request
- Gathers repo context (related files, duplicate check, environment info for bugs)
- Drafts a structured issue body using per-type templates
- Always shows a confirmation gate before writing to the remote — no issue is created without your approval

## Features

| Component | Invocation | What it does |
|-----------|-----------|--------------| 
| `create-issue` skill | `/issue-agent:create-issue [bug\|feature\|selection\|session] [title]` | Drafts and creates an issue with confirmation gate |

## Plugin Structure

```
kit/plugins/issue-agent/
├── .claude-plugin/
│   └── plugin.json
├── CHANGELOG.md
├── README.md
└── skills/
    └── create-issue/
        ├── SKILL.md
        └── references/
            ├── bug-report.md          # Bug issue body skeleton
            ├── feature-request.md     # Feature request body skeleton
            ├── general-issue.md       # General/selection/session body skeleton
            └── host-commands.md       # gh vs glab flag equivalence table
```

## Components

### `create-issue` (Skill — manual-invoke)

**Invocation:** `/issue-agent:create-issue [source] [title or description]`

**Sources:**

| Source | What happens |
|--------|-------------|
| `bug` | Collects Node/npm versions, recent git log, related files, reproduction steps. Uses `[BUG]` title prefix. |
| `feature` | User-story + acceptance-criteria format. Uses `[FEATURE]` title prefix. |
| `selection` | Treats the provided text as the issue seed; structures it. |
| `session` | Synthesizes from the current conversation — the bug found or feature discussed. |

**Host detection:** reads `git remote get-url origin` and selects `gh` (GitHub) or `glab` (GitLab). Asks if the host is ambiguous.

**Confirmation gate:** always shows the drafted issue and asks — Create / Edit / Cancel — before calling `gh issue create` or `glab issue create`.

**Browser open:** after successful creation, the issue URL is opened in the default browser automatically. Pass `--no-open` to suppress this behavior.

**Fallback:** if the CLI call fails, opens the browser with `--web`.
