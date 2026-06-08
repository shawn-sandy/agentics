# agentics

A **marketplace system for Claude Code plugins** — enabling discovery, distribution, and installation of AI-powered plugins that extend Claude's capabilities across code review, planning, testing, git workflows, accessibility, and more.

**Marketplace:** `agentics-kit` v4.0.0 · **12 plugins** · Requires Claude Code 1.0.33+ · [View all plugins](#plugin-reference-table) · [Browse docs](https://shawn-sandy.github.io/agentics/)

> **Breaking change — v4.0.0:** Six plugins have been removed from the marketplace: `agent-creator`, `agent-reviewer`, `agentic-plugin-dev`, `code-simplifier`, `marketplace-builder`, and `react-perf-analyzer`. Their source directories are retained in the repository but are no longer installable via the marketplace. See [CHANGELOG.md](./CHANGELOG.md) for details.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Installation](#installation)
  - [Install via Marketplace (Recommended)](#install-via-marketplace-recommended)
  - [Auto-enable for Your Team (Declarative Config)](#auto-enable-for-your-team-declarative-config)
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
- [Removed Plugins](#removed-plugins)
- [Contributing](#contributing)
  - [Reporting Bugs](#reporting-bugs)
  - [Creating a New Plugin](#creating-a-new-plugin)
  - [Pull Request Process](#pull-request-process)
  - [Versioning](#versioning)
- [Development](#development)
  - [Browsing Docs Online](#browsing-docs-online)
  - [Browsing Docs Locally](#browsing-docs-locally)
- [CI/CD](#cicd)
- [Resources](#resources)
- [License](#license)

---

## Quick Start

**Install from the marketplace (no cloning required):**

```
# 1. Register the agentics-kit marketplace in Claude Code
/plugin marketplace add shawn-sandy/agentics-kit

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
| **Active Plugins** | 12 marketplace plugins in `kit/plugins/` — installable via `/plugin install`, covering code review, planning, testing, git workflows, accessibility, and more |
| **Archived Plugins** | 6 removed plugins with source directories retained in `kit/plugins/` — loadable locally via `--plugin-dir` but not available via `/plugin install` |
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
- **GitHub CLI (`gh`)** — used by the `git-agent` plugin for GitHub PR creation
- **GitLab CLI (`glab`)** — used by `agent-ship` for GitLab MR creation
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
│   └── plugins/                  # 12 plugins in marketplace (6 archived directories retained)
│       ├── agent-creator/
│       ├── agent-reviewer/
│       ├── agentic-plugin-dev/
│       ├── code-review/
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
│       ├── social-media-tools/
│       └── wcag-compliance-reviewer/
├── tests/
│   └── fixtures/                 # Validation test fixtures
├── docs/
│   ├── index.html                # Landing hub — links to Plans gallery & Social cards
│   ├── plans/                    # HTML plan files & filterable gallery (index.html)
│   ├── media/social/             # Social media card gallery
│   └── guides/                   # Reference guides (auto-load setup, etc.)
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
/plugin install product-plans@agentics-kit
/plugin install plan-agent@agentics-kit
/plugin install settings-sync@agentics-kit
/plugin install social-media-tools@agentics-kit
/plugin install issue-agent@agentics-kit
```

**Or install all at once** — paste the full block above into your Claude Code session.

### Auto-enable for Your Team (Declarative Config)

Instead of every contributor running `/plugin marketplace add` and `/plugin install` for each plugin, you can declare the kit once in `settings.json` using two keys: `extraKnownMarketplaces` (makes Claude Code aware of the marketplace) and `enabledPlugins` (marks which plugins should be enabled by default).

This repo ships these keys in **project scope** (`.claude/settings.json`). On first use, Claude Code prompts the user to trust the repo and add the marketplace; once added, the listed plugins are enabled by default — no per-plugin install commands. To enable the same kit across **all your other repos**, add the two keys to your personal **user settings** (`~/.claude/settings.json`):

```json
{
  "extraKnownMarketplaces": {
    "agentics-kit": {
      "source": { "source": "github", "repo": "shawn-sandy/agentics" }
    }
  },
  "enabledPlugins": {
    "memory-tools@agentics-kit": true,
    "code-review@agentics-kit": true,
    "plan-interview@agentics-kit": true,
    "wcag-compliance-reviewer@agentics-kit": true,
    "skill-reviewer@agentics-kit": true,
    "code-testing-agent@agentics-kit": true,
    "git-agent@agentics-kit": true,
    "product-plans@agentics-kit": true,
    "settings-sync@agentics-kit": true,
    "social-media-tools@agentics-kit": true,
    "plan-agent@agentics-kit": true,
    "issue-agent@agentics-kit": true
  }
}
```

> This config lives in `settings.json`, **not** `CLAUDE.md`. `enabledPlugins` is an object (`"name@agentics-kit": true`), not an array. Merge these keys into any existing settings rather than overwriting the file.

> **Heads-up on first run and web sessions:** the marketplace add is gated by a one-time trust/consent prompt. In a non-interactive context (such as a fresh Claude Code on the web session that can't answer prompts or run `/plugin`), the kit may not load until that prompt is accepted. If a session doesn't pick up the plugins, accept the trust prompt or run `/plugin marketplace add shawn-sandy/agentics` once.

See the full team setup guide — including scope choices and caveats — in [docs/plugin-auto-load-setup.md](./docs/plugin-auto-load-setup.md).

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

#### `code-review` v3.3.1

Systematic code review across quality, bugs, security, and best practices with severity-ranked findings, actionable feedback, and line numbers.

**Commands:**

| Command | Description |
|---------|-------------|
| `/code-review:fix-branch` | Review all branch changes vs the default branch, then autonomously fix blocking, major, and minor issues until the branch is clean. Refuses on a dirty working tree. Leaves fixes uncommitted. |

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `code-review-agent` | Review code, check files for problems, look over a PR or diff, assess quality or complexity, find bugs or security issues, detect breaking changes, or evaluate regression risk |

**Agents:**

| Agent | Purpose |
|-------|---------|
| `agent-code-reviewer` | Internal background code review agent for delegation from other agents or automated workflows |

```bash
claude --plugin-dir ./kit/plugins/code-review
# "Review this function for security issues"
# "Check for breaking changes in my last commit"
# /code-review:fix-branch
```

[View Documentation](./kit/plugins/code-review/README.md)

---

### Testing

---

#### `code-testing-agent` v3.4.1

Analyze code and suggest specific, purpose-driven tests tied to actual behavior and intent — not arbitrary coverage.

**Skills:**

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `code-testing-agent` | Suggest tests, identify what to test, or find untested behavior |
| `reviewing-tests` | Review tests, audit test quality, or improve a test suite |
| `running-tests` | Run tests, check if tests pass, or verify changes |
| `tdd-fix` | TDD-fix a bug or run a red-green cycle — manual invoke only |
| `tdd-loop` | TDD a new feature or write tests first — manual invoke only |

```bash
claude --plugin-dir ./kit/plugins/code-testing-agent
# "What tests should I write for this function?"
# "Review my test suite for gaps"
# "TDD fix this bug — write a failing test then make it green"
```

[View Documentation](./kit/plugins/code-testing-agent/README.md)

---

### Planning

---

#### `plan-interview` v2.2.4

Stress-test implementation plans with structured multi-round interviews before coding begins.

**Commands:**

| Command | Description |
|---------|-------------|
| `/plan-interview:plan-interview [plan-file-path]` | Stress-test a plan with a structured interview across technical, UX, edge case, and out-of-scope domains |
| `/plan-interview:deep-grill [plan-file-path]` | Walk each decision branch in an implementation plan with focused questions and codebase exploration |
| `/plan-interview:plan-status [plan-file-path]` | Check and update the lifecycle status of a plan file (todo, in-progress, completed) with type classification |
| `/plan-interview:update-plan-status [directory-path] [--force]` | Process multiple plan files in a directory — analyze codebase evidence and add/update YAML frontmatter in bulk |
| `/plan-interview:plan-hygiene [directory-path]` | Scan plan directories for randomly-named files and rename them to descriptive kebab-case names |
| `/plan-interview:review-rename-plans [plan-file-or-directory]` | Review plan filenames and offer to rename files whose names don't match their intent |
| `/plan-interview:documenting-plans [plan-file-path]` | Generate developer-friendly documentation at docs/<slug>.md from a completed plan file |
| `/plan-interview:markdown-to-html [file-path] [--theme=default\|developer\|document\|minimal] [--mode=auto\|plan\|doc] [--background] [--no-open]` | Convert a markdown file or plan to a rich, self-contained HTML document viewable in any browser |
| `/plan-interview:plan-maintenance [--archive] [--index] [--variants] [--all] [--background]` | Archive completed plans as HTML, generate a README index, and review variant/duplicate files |
| `/plan-interview:plan-to-html [plan-file-path]` | Deprecated — use /plan-interview:markdown-to-html instead |

**Skills:**

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `plan-interview` | Stress-test or validate a technical plan |
| `deep-grill` | Deep grill or stress-test a plan — manual invoke only |
| `documenting-plans` | Document a completed plan — manual invoke only |
| `markdown-to-html` | Convert a markdown file or plan to HTML |
| `plan-status` | Check or update a plan's status |
| `plan-to-html` | Convert a plan to HTML |

**Agents:**

| Agent | Purpose |
|-------|---------|
| `plan-documenter` | Batch documentation agent that scans the plans directory for completed plans without corresponding documentation in docs/, then invokes the documenting-plans skill for each one |

```bash
claude --plugin-dir ./kit/plugins/plan-interview
# /plan-interview:plan-interview docs/plans/my-plan.md
# /plan-interview:deep-grill docs/plans/my-plan.md
# "Stress-test this plan"
```

[View Documentation](./kit/plugins/plan-interview/README.md)

---

#### `product-plans` v3.4.6

Improve, optimize, and update product plans, PRDs, and feature proposals using a simulated cross-functional team — PM, Lead Developer, UX Designer, Frontend Engineer, Accessibility Expert, and Security Expert.

**Commands:**

| Command | Description |
|---------|-------------|
| `/product-plans:product-plans-bg <path>` | Run the product-plans review panel in the background |

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `plan-review-agents` | Review or improve a product plan, PRD, or feature proposal with comprehensive PM, Dev, UX, Frontend, A11y, and Security coverage |

**Agents:**

| Agent | Purpose |
|-------|---------|
| `agent-product-plans` | Background product-plan panel agent — runs the full six-reviewer cross-functional panel without blocking the parent session |
| `product-reviewer-pm` | Product Manager reviewer teammate |
| `product-reviewer-lead-developer` | Lead Developer reviewer teammate |
| `product-reviewer-ux-designer` | UX Designer reviewer teammate |
| `product-reviewer-frontend-engineer` | Lead Frontend Engineer reviewer teammate |
| `product-reviewer-accessibility-expert` | Accessibility Expert reviewer teammate |
| `product-reviewer-security-expert` | Security Expert reviewer teammate |

```bash
claude --plugin-dir ./kit/plugins/product-plans
# "Review this PRD with your full panel"
# "What would the security reviewer say about this plan?"
# /product-plans:product-plans-bg docs/plans/my-feature.md
```

[View Documentation](./kit/plugins/product-plans/README.md)

---

#### `plan-agent` v1.0.0

Plan creation and completion on demand — invoke `/plan-agent:implementation-plan <objective>` to run the full Steps 0–8 planning workflow with built-in structured interview, or `/plan-agent:finalize-plan` to review and mark a plan completed. Accepts GitHub/GitLab issue URLs and `#n` references to auto-seed plans. Generates self-contained interactive HTML plans with copy-paste implement prompts and optional workflow prompts for complex plans. A PostToolUse hook auto-regenerates the plans gallery index; a filename hook enforces verb-target kebab-case.

**Skills:**

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `implementation-plan` | Create a plan via `/plan-agent:implementation-plan <objective>` — manual invoke only |
| `finalize-plan` | Review a plan for completion evidence and mark it completed — manual invoke only |
| `plans-library` | Browse plans, view plan history, or open the plans index |
| `plans-open` | Reopen the plans gallery without rebuilding |

**Hooks:**

| Hook | Trigger | Purpose |
|------|---------|---------|
| `validate-plan-filename` | `PostToolUse` (Write/Edit) | Enforces verb-target kebab-case filenames on plan files |
| `rebuild-plans-index` | `PostToolUse` (Write/Edit/MultiEdit) | Auto-regenerates the gallery index when plans change |

```bash
claude --plugin-dir ./kit/plugins/plan-agent
# /plan-agent:implementation-plan "Add dark mode support to the settings page"
# /plan-agent:implementation-plan https://github.com/org/repo/issues/42
# /plan-agent:implementation-plan #42 --quick
# /plan-agent:finalize-plan add-dark-mode-toggle.html
# "Browse my plans"
```

[View Documentation](./kit/plugins/plan-agent/README.md)

---

### Git & Workflow

---

#### `git-agent` v3.10.3

Automated git workflow — create branches, commit with conventional messages, and create PRs. Auto-links plan issue references in PR descriptions.

**Commands:**

| Command | Description |
|---------|-------------|
| `/git-agent:commit-bg` | Fire off the agent-commit subagent in the background to stage and commit the working tree, then return control immediately |
| `/git-agent:pr-bg` | Fire off the agent-pr subagent in the background to push the current branch and open a GitHub PR, then return control immediately |
| `/git-agent:ship-bg` | Fire off the agent-ship subagent in the background to commit, push, and open a PR/MR end-to-end, then return control immediately |

**Skills:**

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `branch-agent` | Create or start a new branch — manual invoke only |
| `commit-agent` | Commit or save work to git — manual invoke only |
| `pr-agent` | Create a PR or open a pull request — manual invoke only |
| `ship` | Ship changes or commit and create a PR — manual invoke only |
| `ship-autonomous` | Autonomously ship or watch CI — runs the full ship pipeline with CI polling and bounded autofix |

**Agents:**

| Agent | Purpose |
|-------|---------|
| `agent-commit` | Background git commit agent — stages all working-tree changes and creates a conventional commit message without user interaction |
| `agent-pr` | Background pull-request creation agent — pushes the current branch if needed and opens a GitHub pull request with an auto-generated summary |
| `agent-ship` | Background end-to-end ship agent — stages, commits, pushes, and opens a pull/merge request in one autonomous flow |

```bash
claude --plugin-dir ./kit/plugins/git-agent
# "Commit my changes"
# "Create a branch for this feature"
# "Ship it"
# /git-agent:ship-bg
```

[View Documentation](./kit/plugins/git-agent/README.md)

---

#### `settings-sync` v1.0.1

Back up and restore Claude Code user settings to a dedicated git repo. Routine-compatible for automated backups.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `settings-backup` | Back up, save, or sync Claude Code settings to a git repo — also activates for routine-scheduled setting backups |
| `settings-restore` | Restore, import, or recover Claude Code settings from a backup git repo |

```bash
claude --plugin-dir ./kit/plugins/settings-sync
# "Back up my Claude Code settings"
# "Restore my settings from my backup repo"
```

[View Documentation](./kit/plugins/settings-sync/README.md)

---

### Accessibility & Performance

---

#### `wcag-compliance-reviewer` v1.2.2

Review HTML/CSS and React/TypeScript code for WCAG 2.2 Level AA accessibility compliance.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `wcag-compliance-reviewer` | Check WCAG compliance, audit accessibility, review HTML/CSS and React code for WCAG 2.2 Level AA violations, or identify and fix accessibility issues |

```bash
claude --plugin-dir ./kit/plugins/wcag-compliance-reviewer
# "Check this component for accessibility issues"
# "Is this page WCAG 2.2 AA compliant?"
# "Audit the ARIA usage in this form"
```

[View Documentation](./kit/plugins/wcag-compliance-reviewer/README.md)

---

#### `skill-reviewer` v2.2.4

Review and plan Claude Code skills, and run tests for changed files — audit SKILL.md files, scaffold new skills, and verify test coverage.

**Commands:**

| Command | Description |
|---------|-------------|
| `/skill-reviewer:check-description` | Measure description-frontmatter length for one or more SKILL.md files and warn if any exceed the 200-char budget |

**Skills:**

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `reviewing-skills` | Review, audit, or score a skill |
| `planning-skills` | Plan or scaffold a new skill |
| `auditing-allowed-tools` | Audit, fix, or review tool permissions |
| `optimizing-skill-frontmatter` | Optimize SKILL.md frontmatter — manual invoke only |

```bash
claude --plugin-dir ./kit/plugins/skill-reviewer
# "Review this SKILL.md file"
# "Help me plan a new skill"
# "What allowed-tools should this skill have?"
```

[View Documentation](./kit/plugins/skill-reviewer/README.md)

---

### Productivity

---

#### `memory-tools` v3.1.2

Audit and optimize CLAUDE.md project memory files against Claude Code best practices.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `agentic-memory-doctor` | Audit, optimize, or diagnose a CLAUDE.md or project memory file — also activates when Claude appears to be ignoring project instructions |
| `path-rules-advisor` | Create path-specific rules, add rules for file types or directories, or organize Claude rules in `.claude/rules/` |

```bash
claude --plugin-dir ./kit/plugins/memory-tools
# "Audit my CLAUDE.md file"
# "Claude keeps ignoring my instructions — what's wrong?"
# "Create path-specific rules for my src/ directory"
```

[View Documentation](./kit/plugins/memory-tools/README.md)

---

#### `social-media-tools` v2.5.1

Discover shareable code from git history or codebase path, scrub for secrets, draft objective-driven platform-aware copy, and generate styled dark-mode social cards (1024px wide) for LinkedIn, Twitter/X, Bluesky, and Substack. Generate a `SOCIAL.md` project config for default platform, tone, and content preferences.

**Commands:**

| Command | Description |
|---------|-------------|
| `/social-media-tools:digest` | Scan recent git history or a codebase path for shareable code, scrub for secrets, and draft code-share prompts |

**Skills:**

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `social-share` | Share what you're working on or post code, a blog, video, or project update |
| `share-github` | Share a code snippet from a GitHub repository |
| `share-session` | Share your session, session recap, what you worked on today, or a session summary |
| `security-scrub` | Check for secrets or review a diff for leaks |
| `share-selection` | Share, post, or tweet selected, highlighted, or pasted code |
| `media-library` | Browse the media library or find a prior post |
| `share-scan` | Find commits worth sharing or create a digest |
| `share-blog` | Share a blog post or article on social media |
| `share-code` | Post or share a code change |
| `share-video` | Share or promote a video on social media |
| `share-project` | Announce features, bugs, changes, or releases on social media — manual invoke only |
| `share-init` | Set up social sharing preferences and generate a `SOCIAL.md` project config |

```bash
claude --plugin-dir ./kit/plugins/social-media-tools
# "Create a social card for this feature"
# "Draft a LinkedIn post about my latest commit"
# /social-media-tools:digest
```

[View Documentation](./kit/plugins/social-media-tools/README.md)

---

#### `issue-agent` v0.2.2

Create GitHub and GitLab issues from any context — selection, session, bug, or feature — with host auto-detection, a confirmation gate before writing, and automatic browser open on creation.

**Skills** (activate explicitly):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `create-issue` | File, open, or create an issue or ticket — manual invoke only |

```bash
claude --plugin-dir ./kit/plugins/issue-agent
# /issue-agent:create-issue bug "Login button throws 500 on mobile"
# /issue-agent:create-issue feature "Add dark mode toggle to settings page"
# /issue-agent:create-issue session
```

[View Documentation](./kit/plugins/issue-agent/README.md)

---

## Plugin Reference Table

| Plugin | Version | Category | Components |
|--------|---------|----------|------------|
| [code-review](./kit/plugins/code-review/README.md) | 3.3.1 | development | 1 command, 1 skill, 1 agent |
| [code-testing-agent](./kit/plugins/code-testing-agent/README.md) | 3.4.1 | testing | 5 skills |
| [plan-interview](./kit/plugins/plan-interview/README.md) | 2.2.4 | development | 10 commands, 6 skills, 1 agent, 1 hook |
| [product-plans](./kit/plugins/product-plans/README.md) | 3.4.5 | productivity | 1 command, 1 skill, 7 agents |
| [plan-agent](./kit/plugins/plan-agent/README.md) | 1.0.0 | productivity | 4 skills, 2 hooks |
| [git-agent](./kit/plugins/git-agent/README.md) | 3.10.3 | development | 3 commands, 5 skills, 3 agents |
| [settings-sync](./kit/plugins/settings-sync/README.md) | 1.0.1 | productivity | 2 skills |
| [wcag-compliance-reviewer](./kit/plugins/wcag-compliance-reviewer/README.md) | 1.2.2 | security | 1 skill |
| [skill-reviewer](./kit/plugins/skill-reviewer/README.md) | 2.2.4 | development | 1 command, 4 skills, 1 hook |
| [memory-tools](./kit/plugins/memory-tools/README.md) | 3.1.2 | development | 2 skills |
| [social-media-tools](./kit/plugins/social-media-tools/README.md) | 2.5.1 | productivity | 1 command, 12 skills |
| [issue-agent](./kit/plugins/issue-agent/README.md) | 0.2.2 | development | 1 skill |

---

## Removed Plugins

The following plugins have been removed from the `agentics-kit` marketplace as of v4.0.0. They **will not appear** when browsing or installing from the marketplace — `/plugin install` will not find them.

Their source directories are retained in the repository as reference implementations. You can still load any of them locally with `--plugin-dir`:

```bash
git clone https://github.com/shawn-sandy/agentics.git
cd agentics
claude --plugin-dir ./kit/plugins/<plugin-name>
```

| Plugin | Last Version | Removed | Reason | Replacement |
|--------|-------------|---------|--------|-------------|
| [`agent-creator`](./kit/plugins/agent-creator) | 1.1.2 | 2026-05-29 | Redundant with `agentic-plugin-dev` | Use `agentic-plugin-dev` (also archived; see below) |
| [`agent-reviewer`](./kit/plugins/agent-reviewer) | 1.0.2 | 2026-05-29 | Overlaps with `skill-reviewer` | `/plugin install skill-reviewer@agentics-kit` |
| [`marketplace-builder`](./kit/plugins/marketplace-builder) | 1.1.2 | 2026-05-29 | Redundant with `agentic-plugin-dev` | Use `agentic-plugin-dev` (also archived; see below) |
| [`react-perf-analyzer`](./kit/plugins/react-perf-analyzer) | 1.3.1 | 2026-05-29 | Too specialized for React-only projects | `/plugin install code-review@agentics-kit` |
| [`agentic-plugin-dev`](./kit/plugins/agentic-plugin-dev) | 1.2.2 | 2026-05-29 | Functionality consolidated into existing skills | `/plugin install skill-reviewer@agentics-kit` |
| [`code-simplifier`](./kit/plugins/code-simplifier) | 1.0.2 | 2026-05-29 | Structural analysis covered by `code-review` | `/plugin install code-review@agentics-kit` |

**To load a removed plugin locally:**

```bash
# Example — load agent-creator for local use
claude --plugin-dir ./kit/plugins/agent-creator

# Load multiple, mixing active marketplace plugins with archived ones
claude --plugin-dir ./kit/plugins/code-review \
       --plugin-dir ./kit/plugins/agent-creator
```

> Re-registering any of these plugins in `marketplace.json` requires explicit confirmation — see the [Removed Plugins registry](./.claude/rules/marketplace.md) for the removal rationale before proceeding.

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

# Run the docs/pages smoke tests
bash tests/pages/test-docs-hub.sh
bash tests/pages/test-root-redirect.sh

# Check fixture validity
ls tests/fixtures/valid-plugin/
```

### Browsing Docs Online

The docs landing hub is deployed to GitHub Pages at [shawn-sandy.github.io/agentics](https://shawn-sandy.github.io/agentics/) and links to the Plans gallery and Social Media card gallery.

### Browsing Docs Locally

Two ways to serve the HTML galleries (`docs/plans/` and `docs/media/social/`) locally. The root `docs/index.html` is a landing hub with cards linking to each gallery:

**Script — auto-selects a free port:**

```bash
bash scripts/serve-docs.sh
# Plans gallery:  http://localhost:<port>/plans/
# Media library:  http://localhost:<port>/media/social/
```

Pass an explicit port as the first argument to pin it:

```bash
bash scripts/serve-docs.sh 8900
```

**Launch configs — fixed ports (`.claude/launch.json`):**

| Config | URL | Directory |
|--------|-----|-----------|
| `plans-gallery` | http://localhost:8901 | `docs/plans/` |
| `media-library` | http://localhost:8902 | `docs/media/social/` |
| `docs-all` | http://localhost:8900 | `docs/` (landing hub at root) |

---

## Distribution

Plugin releases are published daily to [shawn-sandy/agentics-kit](https://github.com/shawn-sandy/agentics-kit) — a clean, plugin-only distribution repository containing only the installable plugin files with no development scaffolding, test fixtures, or internal tooling.

**Install from the distribution repo:**

```
/plugin marketplace add shawn-sandy/agentics-kit
```

**Repository roles:**

| Repo | Purpose |
|------|---------|
| `shawn-sandy/agentics` | Development workspace — full source, tests, plans, CI, and authoring tooling |
| `shawn-sandy/agentics-kit` | Clean distribution — plugin files only, built and published by the daily publish workflow |

**Publish workflow:** [publish-dist.yml](https://github.com/shawn-sandy/agentics/actions/workflows/publish-dist.yml) — runs daily and pushes the current `kit/plugins/` contents to `shawn-sandy/agentics-kit`.

**Trigger a manual publish:**

```bash
gh workflow run publish-dist.yml --repo shawn-sandy/agentics
```

---

## CI/CD

GitHub Actions workflows:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `claude.yml` | `@claude` mention in issues/PRs | Respond to questions and implement requested changes |
| `claude-code-review.yml` | PR opened / synchronized / reopened | Automated code review as PR comments |
| `deploy-pages.yml` | Push to `main` (docs changes) | Deploy `docs/` to GitHub Pages |
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
