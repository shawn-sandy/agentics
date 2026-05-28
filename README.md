# agentics

A **marketplace system for Claude Code plugins** — enabling discovery, distribution, and installation of AI-powered plugins that extend Claude's capabilities across code review, planning, testing, git workflows, accessibility, and more.

**Marketplace:** `agentics-kit` v3.9.0 · **18 plugins** · Requires Claude Code 1.0.33+

---

## Table of Contents

- [Quick Start](#quick-start)
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Installation](#installation)
  - [Install via Marketplace (Recommended)](#install-via-marketplace-recommended)
  - [Load Locally for Testing](#load-locally-for-testing)
  - [Troubleshooting](#troubleshooting)
- [Usage Guide](#usage-guide)
  - [Commands vs Skills vs Agents vs Hooks](#commands-vs-skills-vs-agents-vs-hooks)
  - [Single Plugin](#single-plugin)
  - [Multiple Plugins](#multiple-plugins)
- [Plugins](#plugins)
  - [Code Quality](#code-quality)
  - [Testing](#testing)
  - [Planning](#planning)
  - [Git & Workflow](#git--workflow)
  - [Accessibility & Performance](#accessibility--performance)
  - [Plugin Development](#plugin-development)
  - [Productivity](#productivity)
- [Plugin Reference Table](#plugin-reference-table)
- [Contributing](#contributing)
  - [Reporting Bugs](#reporting-bugs)
  - [Creating a New Plugin](#creating-a-new-plugin)
  - [Pull Request Process](#pull-request-process)
  - [Versioning](#versioning)
- [Development](#development)
- [CI/CD](#cicd)
- [Resources](#resources)
- [License](#license)

---

## Quick Start

**Install from the marketplace (no cloning required):**

```
# 1. Register the agentics-kit marketplace in Claude Code
/plugin marketplace add shawn-sandy/agentics

# 2. Install the plugins you want
/plugin install code-review@agentics-kit
/plugin install git-agent@agentics-kit
/plugin install memory-tools@agentics-kit
```

**Or load any plugin directly for local testing:**

```bash
git clone https://github.com/shawn-sandy/agentics.git
cd agentics
claude --plugin-dir ./kit/plugins/code-review
# Then ask: "Review this code for issues"
```

---

## Overview

The agentics project serves two purposes:

| Purpose | What it contains |
|---------|-----------------|
| **Example Plugins** | 18 reference implementations in `kit/plugins/` demonstrating Claude Code plugin structure — commands, skills, agents, and hooks |
| **Marketplace Infrastructure** | `agentics-kit` marketplace manifest (`marketplace.json`) that enables installation via `/plugin install` |

Every plugin in this repo is a working, production-quality tool you can install and use immediately.

---

## Prerequisites

### Required

- **Claude Code CLI** version 1.0.33 or later

```bash
# Verify version
claude --version
```

Install from the [official docs](https://code.claude.com/docs/en/installation) if not present.

### Optional

- **Git** — for cloning the repository locally
- **GitHub CLI (`gh`)** — used by the `git-agent` plugin for PR creation
- **`jq`** — JSON processor, useful for debugging plugin manifests

### Platform Support

| Platform | Support |
|----------|---------|
| macOS 12.0+ | Full support |
| Linux (Ubuntu 20.04+) | Full support |
| Windows (WSL2) | Recommended over native Windows |

---

## Project Structure

```
agentics/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace manifest — the agentics-kit registry
├── .claude/
│   ├── rules/                    # Scoped authoring rules (plugin patterns, marketplace, testing)
│   └── settings.json             # Project-level Claude Code settings and hooks
├── kit/
│   └── plugins/                  # 17 plugin source directories
│       ├── agent-creator/
│       ├── agent-reviewer/
│       ├── agentic-plugin-dev/
│       ├── code-review/
│       ├── code-share/           # (social-media-tools dir)
│       ├── code-simplifier/
│       ├── code-testing-agent/
│       ├── git-agent/
│       ├── issue-agent/
│       ├── marketplace-builder/
│       ├── memory-tools/
│       ├── plan-agent/
│       ├── plan-interview/
│       ├── product-plans/
│       ├── react-perf-analyzer/
│       ├── settings-sync/
│       ├── skill-reviewer/
│       └── wcag-compliance-reviewer/
├── tests/
│   └── fixtures/                 # Validation test fixtures
├── docs/plans/                   # Plan files (committed alongside plugin changes)
├── examples/                     # Demo scripts
├── CONTRIBUTING.md
├── CHANGELOG.md
└── README.md
```

---

## Installation

### Install via Marketplace (Recommended)

The marketplace approach uses sparse cloning — only the plugin you install is fetched, not the entire repository.

**Step 1: Register the marketplace**

```
/plugin marketplace add shawn-sandy/agentics
```

**Step 2: Install individual plugins**

```
/plugin install code-review@agentics-kit
/plugin install plan-interview@agentics-kit
/plugin install memory-tools@agentics-kit
/plugin install git-agent@agentics-kit
/plugin install skill-reviewer@agentics-kit
/plugin install code-testing-agent@agentics-kit
/plugin install wcag-compliance-reviewer@agentics-kit
/plugin install agent-reviewer@agentics-kit
/plugin install code-simplifier@agentics-kit
/plugin install react-perf-analyzer@agentics-kit
/plugin install product-plans@agentics-kit
/plugin install plan-agent@agentics-kit
/plugin install settings-sync@agentics-kit
/plugin install code-share@agentics-kit
/plugin install agent-creator@agentics-kit
/plugin install marketplace-builder@agentics-kit
/plugin install agentic-plugin-dev@agentics-kit
/plugin install issue-agent@agentics-kit
```

**Or install all at once** — paste the full block above into your Claude Code session.

### Load Locally for Testing

Clone the repo and load any plugin directly with `--plugin-dir`:

```bash
git clone https://github.com/shawn-sandy/agentics.git
cd agentics

# Load a single plugin (starts an interactive Claude session)
claude --plugin-dir ./kit/plugins/code-review

# Load multiple plugins simultaneously
claude --plugin-dir ./kit/plugins/code-review \
       --plugin-dir ./kit/plugins/plan-interview \
       --plugin-dir ./kit/plugins/git-agent

# Or run with a prompt directly (non-interactive)
claude --plugin-dir ./kit/plugins/code-review "Review this file for bugs"
```

### Troubleshooting

#### `claude: command not found`

Claude Code CLI is not installed or not in your `PATH`.

- Install from: https://code.claude.com/docs/en/installation
- Verify: `claude --version` — need 1.0.33+
- macOS/Linux: ensure `~/.local/bin` is in your `PATH`
- Windows: use WSL2 and follow the Linux steps

#### Plugin not loading

The path may be wrong or the manifest may be missing.

```bash
# Verify the plugin directory exists and has a manifest
ls -la ./kit/plugins/code-review/.claude-plugin/plugin.json

# Use an absolute path if relative paths don't work
claude --plugin-dir /full/path/to/agentics/kit/plugins/code-review
```

#### Permission errors

```bash
ls -la ./kit/plugins/code-review
chmod -R +r ./kit/plugins/code-review
```

#### "Input must be provided" error with `--plugin-dir`

This occurs when Claude Code can't start the interactive session. Try:

```bash
# Provide a prompt directly
claude --plugin-dir ./kit/plugins/code-review "List available commands"

# Or pipe stdin
echo "Review this code" | claude --plugin-dir ./kit/plugins/code-review

# Verify manifest is valid JSON
cat kit/plugins/code-review/.claude-plugin/plugin.json | jq
```

---

## Usage Guide

### Commands vs Skills vs Agents vs Hooks

Plugins can include four types of components:

| Type | Invocation | Example | Use When |
|------|-----------|---------|----------|
| **Commands** | Explicit: `/plugin:name` | `/plan-interview:deep-grill plan.md` | User controls exactly when it runs |
| **Skills** | Automatic: matches your intent | "Review this code for bugs" | Claude detects the need from conversation |
| **Agents** | Delegated: spawned as subprocesses | Background git commit | Work should run without blocking |
| **Hooks** | Event-driven: lifecycle triggers | Pre-commit filename validation | Actions must happen automatically |

Most plugins use **skills** (automatic activation). Ask naturally and Claude activates the right skill.

### Single Plugin

```bash
# Start an interactive session with a plugin loaded
claude --plugin-dir ./kit/plugins/git-agent

# Inside the session, use naturally:
# "Commit my changes with a conventional message"
# "Create a PR for this branch"
# /git-agent:ship-bg
```

### Multiple Plugins

```bash
claude --plugin-dir ./kit/plugins/code-review \
       --plugin-dir ./kit/plugins/git-agent \
       --plugin-dir ./kit/plugins/plan-interview

# All skills and commands from all three plugins are available
```

Use `/help` inside any Claude session to list all active commands.

---

## Plugins

### Code Quality

---

#### `code-review` v3.3.0

Structured multi-dimensional code review across quality, bugs, security, best practices, complexity rating, breaking changes, and regressions. Includes an autonomous `/code-review:fix-branch` command that reviews and applies fixes across the entire branch.

**Commands:**

| Command | Description |
|---------|-------------|
| `/code-review:fix-branch` | Autonomously review the current branch and apply fixes |

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `code-review-agent` | Review code, check for bugs, analyze quality, look for security issues, or detect breaking changes |

```bash
claude --plugin-dir ./kit/plugins/code-review
# "Review this function for security issues"
# "Check for breaking changes in my last commit"
# /code-review:fix-branch
```

[View Documentation](./kit/plugins/code-review/README.md)

---

#### `code-simplifier` v1.0.1

Analyzes code for structural quality issues, code smells, and optimization opportunities: dead code, high complexity, god classes, duplication, tight coupling, and performance anti-patterns.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `code-simplifier` | Simplify code, find smells, reduce complexity, identify refactoring opportunities, or check for dead code |

```bash
claude --plugin-dir ./kit/plugins/code-simplifier
# "Find code smells in this file"
# "Simplify this function"
# "What dead code can I remove?"
```

[View Documentation](./kit/plugins/code-simplifier/README.md)

---

### Testing

---

#### `code-testing-agent` v3.4.0

Analyzes code and suggests specific, purpose-driven tests tied to actual behavior and intent — not arbitrary coverage targets. Includes TDD fix/loop workflows for bug-driven and feature-driven development.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `code-testing-agent` | Suggest tests for code based on behavior and intent |
| `reviewing-tests` | Review existing tests for quality, coverage gaps, and alignment |
| `tdd-fix` | Reproduce a bug with a failing test, then fix it (red-green cycle) — manual invoke only |
| `tdd-loop` | Drive a new feature through a full TDD loop — manual invoke only |

```bash
claude --plugin-dir ./kit/plugins/code-testing-agent
# "What tests should I write for this function?"
# "Review my test suite for gaps"
# "TDD fix this bug — write a failing test then make it green"
```

[View Documentation](./kit/plugins/code-testing-agent/README.md)

---

#### `react-perf-analyzer` v1.3.0

Identifies React component source patterns that commonly correlate with poor INP, CLS, Long Animation Frames, and Long Tasks scores. Produces a heuristic report with recommendations. Manual-invoke only.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `react-perf-analyzer` | Analyze React components for performance issues or web vitals problems — manual invoke |

```bash
claude --plugin-dir ./kit/plugins/react-perf-analyzer
# "Analyze this component for performance issues"
# "What's causing poor INP on this page?"
```

[View Documentation](./kit/plugins/react-perf-analyzer/README.md)

---

### Planning

---

#### `plan-interview` v2.2.0

Stress-tests implementation plans with structured multi-round interviews before coding begins. Auto-routes product plans to the panel review skill (Step 1.5 router). Always emits an interview HTML artifact. Use `--quick` flag to bypass routing.

**Commands:**

| Command | Description |
|---------|-------------|
| `/plan-interview:plan-interview [file]` | Run a structured interview against a plan file |
| `/plan-interview:deep-grill [file]` | Walk through each decision branch and stress-test individual decisions |
| `/plan-interview:plan-status [file]` | Check, update, or determine the implementation status of a plan |
| `/plan-interview:update-plan-status [file]` | Update a plan's status metadata |
| `/plan-interview:plan-hygiene` | Pre-commit check for randomly-named plan files that need renaming |
| `/plan-interview:review-rename-plans` | Review and rename plan files with non-descriptive names |
| `/plan-interview:documenting-plans [file]` | Generate prose documentation from completed plan files |

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `plan-interview` | Stress-test, validate, interview, or find gaps in a plan |
| `deep-grill` | Deep grill a plan or stress-test individual design decisions |
| `plan-status` | Check or determine the implementation status of a plan file |
| `documenting-plans` | Document a plan or turn a plan into reference docs |

```bash
claude --plugin-dir ./kit/plugins/plan-interview
# /plan-interview:plan-interview docs/plans/my-plan.md
# /plan-interview:deep-grill docs/plans/my-plan.md
# "Stress-test this plan"
```

[View Documentation](./kit/plugins/plan-interview/README.md)

---

#### `product-plans` v3.4.2

Improve, optimize, and update product plans, PRDs, and feature proposals using a cross-functional agent team (PM, Lead Developer, UX, Frontend, Accessibility, Security). Produces a 15-section consolidated report, applies improvements to the source plan, and appends findings to any existing plan-interview HTML artifact. Background mode available via `/product-plans:product-plans-bg`.

**Commands:**

| Command | Description |
|---------|-------------|
| `/product-plans:product-plans-bg` | Run the full panel review in the background |

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `plan-review-agents` | Review a product plan, PRD, or feature proposal with a cross-functional team |

```bash
claude --plugin-dir ./kit/plugins/product-plans
# "Review this PRD with your full panel"
# "What would the security reviewer say about this plan?"
# /product-plans:product-plans-bg
```

[View Documentation](./kit/plugins/product-plans/README.md)

---

#### `plan-agent` v0.5.0

Plan creation on demand — invoke `/plan-agent:planning <objective>` to run the full §0–§7 workflow and produce a self-contained interactive HTML plan. Supports multiple plan templates (`default`, `minimal`, `adr`, `spike`), granular flags (`--quick`, `--type`, `--template`, `--priority`, `--interview`), and an automatic `validate-plan-filename` hook that enforces verb-target kebab-case naming on every write.

**Skills** (manual-invoke only):

| Skill | Description |
|-------|-------------|
| `planning` | Author a new HTML plan from a free-text objective — invoke as `/plan-agent:planning <objective>` |

```bash
claude --plugin-dir ./kit/plugins/plan-agent
# /plan-agent:planning "Add dark mode support to the settings page"
# /plan-agent:planning --quick --type fix "Patch the login redirect"
# /plan-agent:planning --template adr "Decide on database ORM strategy"
# /plan-agent:planning --template spike --priority high "Investigate websocket feasibility"
```

[View Documentation](./kit/plugins/plan-agent/README.md)

---

### Git & Workflow

---

#### `git-agent` v3.9.1

Automated git workflow — create branches, commit with conventional messages, and open PRs. Includes background subagents and slash commands for fire-and-forget operations, plus a supervised full pipeline via `ship-autonomous`.

**Commands:**

| Command | Description |
|---------|-------------|
| `/git-agent:commit-bg` | Fire-and-forget background commit |
| `/git-agent:pr-bg` | Fire-and-forget background PR creation |
| `/git-agent:ship-bg` | Fire-and-forget background commit + push + PR |

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `branch-agent` | Create a new branch or branch off main |
| `commit-agent` | Stage changes and create a conventional commit |
| `pr-agent` | Create a PR, push, or open a branch for review |
| `ship` | Commit, push, and open a PR in one flow |

**Agents:**

| Agent | Purpose |
|-------|---------|
| `agent-commit` | Background git commit — non-blocking |
| `agent-pr` | Background PR creation — non-blocking |
| `agent-ship` | Background end-to-end commit + push + PR |

```bash
claude --plugin-dir ./kit/plugins/git-agent
# "Commit my changes"
# "Create a branch for this feature"
# "Ship it"
# /git-agent:ship-bg
```

[View Documentation](./kit/plugins/git-agent/README.md)

---

#### `settings-sync` v1.0.0

Back up and restore Claude Code user settings to a dedicated git repo. Routine-compatible for automated weekly or daily backups.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `settings-sync` | Sync, back up, or restore Claude Code settings to/from a git repo |

```bash
claude --plugin-dir ./kit/plugins/settings-sync
# "Back up my Claude Code settings"
# "Restore my settings from my backup repo"
```

[View Documentation](./kit/plugins/settings-sync/README.md)

---

#### `issue-agent` v0.1.0

Create GitHub and GitLab issues from any context — a text selection, the current session, a bug description, or a feature request. Auto-detects the git host (`gh` for GitHub, `glab` for GitLab) and always shows a confirmation gate before writing to the remote. Manual-invoke only.

**Skills** (manual-invoke only):

| Skill | Invocation | Description |
|-------|-----------|-------------|
| `create-issue` | `/issue-agent:create-issue [bug\|feature\|selection\|session] [title]` | Draft and create a structured issue with a confirmation gate |

```bash
claude --plugin-dir ./kit/plugins/issue-agent
# /issue-agent:create-issue bug "Login form crashes on empty password"
# /issue-agent:create-issue feature "Add dark mode toggle to settings panel"
# /issue-agent:create-issue session
# /issue-agent:create-issue selection <paste text here>
```

[View Documentation](./kit/plugins/issue-agent/README.md)

---

### Accessibility & Performance

---

#### `wcag-compliance-reviewer` v1.2.1

Reviews HTML/CSS and React/TypeScript code for WCAG 2.2 Level AA accessibility compliance. Covers ARIA, color contrast, keyboard navigation, screen reader compatibility, and more.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `wcag-compliance-reviewer` | Review code for accessibility, WCAG 2.2 compliance, or a11y issues |

```bash
claude --plugin-dir ./kit/plugins/wcag-compliance-reviewer
# "Check this component for accessibility issues"
# "Is this page WCAG 2.2 AA compliant?"
# "Audit the ARIA usage in this form"
```

[View Documentation](./kit/plugins/wcag-compliance-reviewer/README.md)

---

### Plugin Development

---

#### `agentic-plugin-dev` v1.2.1

Create, manage, and validate Claude Code plugins — scaffold new plugins, manage marketplace entries, and audit plugin structure.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `plugin-creator` | Create or scaffold a new Claude Code plugin |
| `plugin-manager` | Add, update, or remove a plugin from marketplace.json |
| `plugin-validator` | Validate a plugin's structure and manifest |

```bash
claude --plugin-dir ./kit/plugins/agentic-plugin-dev
# "Create a new plugin called my-plugin"
# "Validate the structure of this plugin"
# "Add my-plugin to the marketplace"
```

[View Documentation](./kit/plugins/agentic-plugin-dev/README.md)

---

#### `agent-creator` v1.1.1

Scaffolds Claude Code agent-based plugins with guided, opinionated workflows.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `generating-agents` | Create, scaffold, or generate a new agent-based plugin |

```bash
claude --plugin-dir ./kit/plugins/agent-creator
# "Create a new agent plugin called deployment-agent"
```

[View Documentation](./kit/plugins/agent-creator/README.md)

---

#### `agent-reviewer` v1.0.1

Performs a structured, scored audit of Claude Code subagent definition files (`agents/*.md`) against official best practices. Covers frontmatter compliance, tool configuration, description quality, system prompt quality, and security posture. Produces a graded report (Excellent / Good / Needs Work / Rewrite) with a unified diff of suggested corrections.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `reviewing-agents` | Review, audit, score, or check an agent definition file against best practices |

```bash
claude --plugin-dir ./kit/plugins/agent-reviewer
# "Review my agent definition at agents/agent-commit.md"
# "Audit this agent file"
# "Score my agent definition against best practices"
```

[View Documentation](./kit/plugins/agent-reviewer/README.md)

---

#### `skill-reviewer` v2.2.1

Review and optimize Claude Code skill files — score SKILL.md quality, plan and scaffold new skills, audit `allowed-tools` permissions, and enforce the three-part 200-character description format.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `reviewing-skills` | Audit or review a SKILL.md file for quality and best practices |
| `planning-skills` | Plan, design, or scaffold a new Claude Code skill |
| `auditing-allowed-tools` | Audit, recommend, or fix the `allowed-tools` frontmatter |
| `running-tests` | Run tests for changed files, detect test framework, report results |

```bash
claude --plugin-dir ./kit/plugins/skill-reviewer
# "Review this SKILL.md file"
# "Help me plan a new skill"
# "What allowed-tools should this skill have?"
```

[View Documentation](./kit/plugins/skill-reviewer/README.md)

---

#### `marketplace-builder` v1.1.1

Evaluates a repository and scaffolds Claude Code marketplace infrastructure — audits readiness, generates missing files, and guides marketplace setup.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `building-marketplaces` | Scaffold, audit, or set up a Claude Code plugin marketplace |

```bash
claude --plugin-dir ./kit/plugins/marketplace-builder
# "Help me set up a plugin marketplace for this repo"
# "Audit my repo for marketplace readiness"
```

[View Documentation](./kit/plugins/marketplace-builder/README.md)

---

### Productivity

---

#### `memory-tools` v3.1.0

Audits and optimizes CLAUDE.md project memory files against Claude Code best practices. Enforces the principle: keep only rules that actually change Claude's behavior. Also advises on path-specific scoped rules.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `agentic-memory-doctor` | Optimize, audit, clean up, or diagnose a CLAUDE.md file — also activates when Claude is ignoring instructions |
| `path-rules-advisor` | Create path-specific rules, organize rules by file type/directory, or check if the project needs scoped rules in `.claude/rules/` |

```bash
claude --plugin-dir ./kit/plugins/memory-tools
# "Audit my CLAUDE.md file"
# "Claude keeps ignoring my instructions — what's wrong?"
# "Create path-specific rules for my src/ directory"
```

[View Documentation](./kit/plugins/memory-tools/README.md)

---

#### `code-share` v0.9.0

Discover shareable code, blog posts, videos, and GitHub snippets — scrub for secrets, draft platform-aware copy, and generate styled dark-mode social cards for LinkedIn, Twitter/X, and Bluesky. The `social-share` router skill classifies any share request and dispatches the right workflow in the background automatically.

**Commands:**

| Command | Description |
|---------|-------------|
| `/code-share:social-share-bg` | Fire-and-forget background share — router dispatches the right card workflow |
| `/code-share:digest` | Interactive digest — discover and share the best recent work |
| `/code-share:digest-bg` | Background digest scan |

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `social-share` | Route any share request — classifies intent and dispatches the right card skill in the background |
| `code-share` | Share a code change or git diff — draft copy and generate a dark-mode social card |
| `blog-share` | Share a blog post or article — fetch metadata and generate a card |
| `video-share` | Share a YouTube or Vimeo video — fetch metadata and generate a card |
| `selection-share` | Share selected, highlighted, or pasted code — scrub and generate a card |
| `security-scrub` | Check code for secrets or credentials before sharing |

```bash
claude --plugin-dir ./kit/plugins/social-media-tools
# "Share what I just built"
# "Post today's changes to LinkedIn"
# /code-share:social-share-bg share my latest commit
# /code-share:digest
```

[View Documentation](./kit/plugins/social-media-tools/README.md)

---

## Plugin Reference Table

| Plugin | Version | Category | Components |
|--------|---------|----------|------------|
| [code-review](./kit/plugins/code-review/README.md) | 3.3.0 | development | 1 command, 1 skill, 1 agent |
| [code-simplifier](./kit/plugins/code-simplifier/README.md) | 1.0.1 | development | 1 skill |
| [code-testing-agent](./kit/plugins/code-testing-agent/README.md) | 3.4.0 | testing | 4 skills |
| [react-perf-analyzer](./kit/plugins/react-perf-analyzer/README.md) | 1.3.0 | testing | 1 skill |
| [plan-interview](./kit/plugins/plan-interview/README.md) | 2.2.0 | development | 7 commands, 4 skills |
| [product-plans](./kit/plugins/product-plans/README.md) | 3.4.2 | productivity | 1 command, 1 skill |
| [plan-agent](./kit/plugins/plan-agent/README.md) | 0.5.0 | productivity | 1 skill, 1 hook |
| [git-agent](./kit/plugins/git-agent/README.md) | 3.9.1 | development | 3 commands, 4 skills, 3 agents |
| [settings-sync](./kit/plugins/settings-sync/README.md) | 1.0.0 | productivity | 1 skill |
| [issue-agent](./kit/plugins/issue-agent/README.md) | 0.1.0 | development | 1 skill |
| [wcag-compliance-reviewer](./kit/plugins/wcag-compliance-reviewer/README.md) | 1.2.1 | security | 1 skill |
| [agentic-plugin-dev](./kit/plugins/agentic-plugin-dev/README.md) | 1.2.1 | development | 3 skills |
| [agent-creator](./kit/plugins/agent-creator/README.md) | 1.1.1 | development | 1 skill |
| [agent-reviewer](./kit/plugins/agent-reviewer/README.md) | 1.0.1 | development | 1 skill |
| [skill-reviewer](./kit/plugins/skill-reviewer/README.md) | 2.2.1 | development | 4 skills |
| [marketplace-builder](./kit/plugins/marketplace-builder/README.md) | 1.1.1 | development | 1 skill |
| [memory-tools](./kit/plugins/memory-tools/README.md) | 3.1.0 | development | 2 skills |
| [code-share](./kit/plugins/social-media-tools/README.md) | 0.9.0 | productivity | 3 commands, 6 skills, 2 agents |

---

## Contributing

### Reporting Bugs

Open a [GitHub Issue](https://github.com/shawn-sandy/agentics/issues/new) with:

- Plugin name and version
- Claude Code CLI version (`claude --version`)
- Steps to reproduce
- Expected vs actual behavior
- Error messages or screenshots

### Creating a New Plugin

**Step 1: Scaffold the directory structure**

```
kit/plugins/my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Required: name, description (NO version field)
├── commands/                 # Slash commands — optional
│   └── my-command.md
├── skills/                   # Auto-activated skills — optional
│   └── my-skill/
│       └── SKILL.md
├── agents/                   # Background subagent definitions — optional
│   └── my-agent.md
└── README.md
```

**Step 2: Create the plugin manifest**

```json
{
  "name": "my-plugin",
  "description": "What this plugin does"
}
```

> **Version rule:** `version` belongs **only** in `.claude-plugin/marketplace.json`. Adding it to `plugin.json` silently overrides the marketplace version and causes conflicts.

**Step 3: Test locally**

```bash
claude --plugin-dir ./kit/plugins/my-plugin

# Inside the session, test your commands/skills:
# /my-plugin:my-command
# "Invoke my-plugin on this file"
```

**Step 4: Register in the marketplace**

Add an entry to `.claude-plugin/marketplace.json`:

```json
{
  "name": "my-plugin",
  "source": {
    "source": "git-subdir",
    "url": "https://github.com/shawn-sandy/agentics.git",
    "path": "kit/plugins/my-plugin"
  },
  "version": "1.0.0",
  "description": "What this plugin does",
  "category": "development",
  "tags": ["specific", "relevant", "tags"]
}
```

**Available categories:** `development` · `testing` · `productivity` · `security` · `documentation` · `learning`

### Pull Request Process

1. Create a feature branch from `main`
2. Build and test your plugin locally with `--plugin-dir`
3. Bump the plugin's `version` in `marketplace.json` (must be higher than `main`)
4. Include the relevant plan file from `docs/plans/` in your commit
5. Submit a PR with a clear description

**PR Checklist:**

- [ ] `plugin.json` has `name` and `description` — **no `version` field**
- [ ] Version bumped in `marketplace.json` and higher than version on `main`
- [ ] Plugin tested locally with `claude --plugin-dir`
- [ ] `README.md` included in plugin directory
- [ ] Homepage URL points to the plugin directory: `https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/my-plugin`
- [ ] `CHANGELOG.md` updated (for existing plugins)
- [ ] Plan file committed alongside changes

### Versioning

| Bump | When |
|------|------|
| **PATCH** `x.y.Z` | Bug fix, typo, metadata correction |
| **MINOR** `x.Y.z` | New command, skill, agent, or hook added |
| **MAJOR** `X.y.z` | Removing/renaming a command/skill/agent, changing argument format |

**Commit message conventions:**

```
fix(kit/plugins/my-plugin): bump version to 1.0.1     # patch
feat(kit/plugins/my-plugin): bump version to 1.1.0    # minor
feat(kit/plugins/my-plugin)!: bump version to 2.0.0   # major
```

See [CONTRIBUTING.md](./CONTRIBUTING.md) for the full guide.

---

## Development

### Authoring Rules

Detailed patterns live in `.claude/rules/`:

| File | Scope | Content |
|------|-------|---------|
| `plugin-patterns.md` | `kit/plugins/**` | Command/skill patterns, progressive disclosure, pitfalls |
| `marketplace.md` | global | Categories, tagging, versioning, registration |
| `testing.md` | `tests/**` | Test fixture guidelines |
| `plan-hygiene.md` | `**/plans/**` | Pre-commit plan file rename checks |
| `skill-authoring.md` | global | Skill description format, `allowed-tools`, trigger phrases |

### Project Hooks (Auto-Active)

Three hooks run automatically after every file Write/Edit:

1. **JSON validation** — validates `marketplace.json` syntax
2. **Uncommitted plan warning** — alerts if plan files are unstaged alongside plugin changes
3. **Version guard** — checks that the plugin version was bumped when `marketplace.json` was modified

### Running Tests

```bash
# Run the demo test suite
bash tests/demo/run.sh

# Check fixture validity
ls tests/fixtures/valid-plugin/
```

---

## CI/CD

Two GitHub Actions workflows run on every PR and push:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `claude.yml` | `@claude` mention in issues/PRs | Respond to questions and implement requested changes |
| `claude-code-review.yml` | PR opened / synchronized / reopened | Automated code review as PR comments |
| `update-readme.yml` | Every Sunday at 00:00 UTC | Keep the README in sync with `marketplace.json` |

To trigger Claude in any issue or PR comment, mention `@claude`:

```
@claude Can you review the skill descriptions in this plugin?
```

---

## Resources

| Resource | Link |
|----------|------|
| Claude Code Docs | https://code.claude.com/docs/en |
| Plugin Creation Guide | https://code.claude.com/docs/en/plugins |
| Plugin Reference | https://code.claude.com/docs/en/plugins-reference |
| Plugin Marketplaces | https://code.claude.com/docs/en/plugin-marketplaces |
| Discover Plugins | https://code.claude.com/docs/en/discover-plugins |
| Changelog | [CHANGELOG.md](./CHANGELOG.md) |
| Roadmap | [ROADMAP.md](./ROADMAP.md) |
| Security Policy | [SECURITY.md](./SECURITY.md) |
| Code of Conduct | [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) |

---

## License

MIT License — Copyright (c) 2026 Shawn Sandy

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
