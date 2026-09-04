# agentics

[![Publish dist](https://github.com/shawn-sandy/agentics/actions/workflows/publish-dist.yml/badge.svg)](https://github.com/shawn-sandy/agentics/actions/workflows/publish-dist.yml)

A **marketplace system for Claude Code plugins** — enabling discovery, distribution, and installation of AI-powered plugins that extend Claude's capabilities across code review, planning, testing, git workflows, accessibility, and more.

**Marketplace:** `agentics-kit` v4.0.0 · **11 plugins** · Requires Claude Code 1.0.33+ · [View all plugins](#plugin-reference-table) · [Browse docs](https://shawn-sandy.github.io/agentics/)

> **Breaking change — v4.0.0:** Six plugins have been removed from the marketplace: `agent-creator`, `agent-reviewer`, `agentic-plugin-dev`, `code-simplifier`, `marketplace-builder`, and `react-perf-analyzer`. Their source directories have been removed from the repository and are recoverable from git history at the commit preceding their deletion. See [CHANGELOG.md](./CHANGELOG.md) for details.

> **Built for Claude, with Claude Code:** These plugins depend on the underlying Claude Code runtime, its agents, and its API — they are not standalone tools and will not work outside the Claude Code environment.

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
- [How-To Guides](#how-to-guides)
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
- [Distribution](#distribution)
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
| **Active Plugins** | 11 marketplace plugins in `kit/plugins/` — installable via `/plugin install`, covering code review, planning, testing, git workflows, accessibility, and more |
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
│   └── plugins/                  # 11 plugins in marketplace
│       ├── artifact-tools/
│       ├── code-review/
│       ├── code-testing-agent/
│       ├── content-tools/
│       ├── git-agent/
│       ├── memory-tools/
│       ├── plan-agent/
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
/plugin install plan-agent@agentics-kit
/plugin install memory-tools@agentics-kit
/plugin install git-agent@agentics-kit
/plugin install skill-reviewer@agentics-kit
/plugin install code-testing-agent@agentics-kit
/plugin install wcag-compliance-reviewer@agentics-kit
/plugin install settings-sync@agentics-kit
/plugin install social-media-tools@agentics-kit
/plugin install artifact-tools@agentics-kit
/plugin install content-tools@agentics-kit
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
    "wcag-compliance-reviewer@agentics-kit": true,
    "skill-reviewer@agentics-kit": true,
    "code-testing-agent@agentics-kit": true,
    "git-agent@agentics-kit": true,
    "settings-sync@agentics-kit": true,
    "social-media-tools@agentics-kit": true,
    "plan-agent@agentics-kit": true,
    "artifact-tools@agentics-kit": true,
    "content-tools@agentics-kit": true
  }
}
```

> This config lives in `settings.json`, **not** `CLAUDE.md`. `enabledPlugins` is an object (`"name@agentics-kit": true`), not an array. Merge these keys into any existing settings rather than overwriting the file.

> **Heads-up on first run and web sessions:** the marketplace add is gated by a one-time trust/consent prompt. In a non-interactive context (such as a fresh Claude Code on the web session that can't answer prompts or run `/plugin`), the kit may not load until that prompt is accepted. If a session doesn't pick up the plugins, accept the trust prompt or run `/plugin marketplace add shawn-sandy/agentics` once.

See the full team setup guide — including scope choices and caveats — in [docs/plugin-auto-load-setup.md](https://github.com/shawn-sandy/agentics/blob/main/docs/plugin-auto-load-setup.md).

### Load Locally for Testing

Clone the repo and load any plugin directly with `--plugin-dir`:

```bash
git clone https://github.com/shawn-sandy/agentics.git
cd agentics

# Load a single plugin (starts an interactive Claude session)
claude --plugin-dir ./kit/plugins/code-review

# Load multiple plugins simultaneously
claude --plugin-dir ./kit/plugins/code-review \
       --plugin-dir ./kit/plugins/plan-agent \
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
| **Commands** | Explicit: `/plugin:name` | `/plan-agent:deep-grill plan.md` | User controls exactly when it runs |
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
       --plugin-dir ./kit/plugins/plan-agent

# All skills and commands from all three plugins are available
```

Use `/help` inside any Claude session to list all active commands.

---

## Plugins

### Code Quality

---

#### `code-review`

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
| `agent-code-reviewer` | Internal background code review agent for delegation from other agents or automated workflows — capped at 30 turns; a partial or empty result is no report, and the caller falls back to its own inline review |

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

#### `code-testing-agent`

Analyze code and suggest specific, purpose-driven tests tied to actual behavior and intent — not arbitrary coverage.

**Skills:**

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `code-testing-agent` | Suggest tests, identify what to test, or find untested behavior |
| `reviewing-tests` | Review tests, audit test quality, or improve a test suite |
| `running-tests` | Run tests, check if tests pass, or verify changes |
| `tdd-fix` | TDD-fix a bug or run a red-green cycle — manual invoke only |
| `tdd-loop` | TDD a new feature or write tests first — manual invoke only |
| `verified-change` | Prove a change is merge-ready locally, or run the merge gate |

```bash
claude --plugin-dir ./kit/plugins/code-testing-agent
# "What tests should I write for this function?"
# "Review my test suite for gaps"
# "TDD fix this bug — write a failing test then make it green"
# "Prove this change is merge-ready before I open a PR"
```

[View Documentation](./kit/plugins/code-testing-agent/README.md)

---

### Planning

---

#### `plan-agent`

Plan creation and review on demand or via ambient activation. Run `/plan-agent:implementation-plan <objective>` for the full Steps 0–8 planning workflow with a built-in structured interview; it authors the plan and stops, never writing source files. Implement a plan that already exists with `/plan-agent:build [<plan>]`, which walks the steps, ticks the spec, re-renders, and owns all three completion gates — acceptance criteria, end-to-end verification, and completion checklist. Turn a vague idea into a decision-complete proposal — saved as a copy-pasteable prompt under `docs/prompts/` — with `/plan-agent:build-proposal`, run a ten-reviewer Workflow with `/plan-agent:review-plan`, finalize and mark plans completed with `/plan-agent:finalize-plan`, generate Anthropic-best-practice AI prompts with `/plan-agent:prompt`, scaffold GitHub Pages publishing with `/plan-agent:setup-sites`, turn a completed plan or one-line idea into a runnable, framework-free static-HTML prototype with `/plan-agent:prototype`, publish a multi-artboard design canvas for a plan with `/plan-agent:design`, or bundle a plan and its related HTML into one tabbed hub artifact with `/plan-agent:publish-hub`. Accepts GitHub/GitLab issue URLs and `#n` references to auto-seed plans. Generates self-contained interactive HTML plans with copy-paste implement prompts and optional workflow prompts for complex plans, and publishes them to a claude.ai artifact by default — the repo keeps the `.md` spec, and `--file` also commits the rendered HTML beside it. PostToolUse hooks auto-regenerate the plans, prototypes, and designs gallery indexes and flag prototype/design drift; a filename hook enforces verb-target kebab-case.

**Commands:**

| Command | Description |
|---------|-------------|
| `/plan-agent:fix <objective>` | Author and implement a fix plan — the `/plan-agent:build` chain, typed as a fix |
| `/plan-agent:refactor <objective>` | Author and implement a refactor plan — the `/plan-agent:build` chain, typed as a refactor |
| `/plan-agent:review-plan-bg <path>` | Run the ten-reviewer plan-review Workflow in the background — validates the path, spawns `agent-review-plan`, and returns an ack immediately |
| `/plan-agent:deep-grill [plan-file-path]` | Walk each decision branch in a plan with focused questions and codebase exploration |
| `/plan-agent:plan-status [plan-file-path] [--all]` | Check and update a plan's lifecycle status (todo, in-progress, completed) and type, one file or in bulk |
| `/plan-agent:documenting-plans [plan-file-path]` | Generate developer-friendly documentation at `docs/<slug>.md` from a completed plan |
| `/plan-agent:markdown-to-html [file-path] [--theme=…] [--mode=…]` | Convert a markdown file or plan to a rich, self-contained HTML document |
| `/plan-agent:prompt [intent] [--out <path>] [--answers-gathered]` | Build a structured AI prompt and save it to the prompts directory |
| `/plan-agent:plan-maintenance [--archive] [--index] [--variants] [--all]` | Archive completed plans as HTML, generate a README index, and review variant/duplicate files |

**Skills:**

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `implementation-plan` | Create a plan via `/plan-agent:implementation-plan <objective>` — also auto-activates on plan-document intent |
| `build` | Implement a plan that already exists via `/plan-agent:build [<plan>]` — walks its steps, ticks the spec, re-renders, and runs the acceptance-criteria, end-to-end-verification, and completion-checklist gates; also auto-activates on "implement the plan at …" intent |
| `build-feature` | Turn a feature idea into a team feature doc that splits into sized, dependency-ordered sub-features, each of which becomes its own plan |
| `build-fleet` | Ship a backlog of plans in parallel — one isolated worktree agent per plan, each building its plan, opening a PR, and watching CI |
| `build-proposal` | Turn a vague idea into a decision-complete proposal, saved as a copy-pasteable prompt (`docs/prompts/proposal-<slug>.md`) authored by delegating to `prompt` — researches web + codebase, separates facts from decisions, then hands off to `implementation-plan`; also writes the deprecated `docs/proposals/<slug>.md` copy through 6.0.x; auto-activates on idea / "should-we" / compare-and-align intent |
| `review-plan` | Run a ten-reviewer Workflow (architecture, completeness, testability, risk, conventions, product, security, + UI-conditional UX, accessibility, and frontend) to review a plan, adversarially verify the high-severity findings (`--deep` verifies all of them), and apply what survives in place — no experimental flag, and it finds artifact-published `.md` specs as well as local HTML, republishing to the plan's own `artifact-url:` |
| `finalize-plan` | Review a plan for completion evidence with per-criterion verification and mark it completed, reconciling the spec against the commits that touched it so work that shipped unplanned or was built differently is written back into `## Steps` and `## Decisions` — manual invoke only |
| `prompt` | Generate a copy-pasteable AI prompt grounded in Anthropic best practices (role, XML structure, CoT, examples) across five types (`system`, `task`, `creative`, `analytical`, `proposal`) — command only, with a `commands/prompt.md` wrapper so other skills can reach it |
| `setup-sites` | Scaffold the GitHub Pages deploy pipeline (workflow, `.nojekyll`, landing hub, preview script) into any repo so `docs/` HTML publishes to a public URL — command (`/plan-agent:setup-sites`) or auto-activates on "set up / publish GitHub Pages" intent |
| `prototype` | Turn a completed HTML plan or a one-line idea into a runnable, framework-free static-HTML prototype under `docs/prototypes/` (inline JSON seed + per-prototype `localStorage`, escaped output, a11y baked in) — command (`/plan-agent:prototype <plan.html \| plan.md \| idea>`) or auto-activates on "prototype this plan / idea" intent |
| `design` | Turn a plan, one-line idea, image, or Figma URL into a multi-artboard design canvas published as an Artifact — artboards land under `docs/designs/<plan-slug>/` and the canvas URL is written back as `design:` so the plan header gains a **View design** link and `build` reads the artboards as the visual spec — command (`/plan-agent:design <plan.html \| plan.md \| idea \| image \| figma-url>`) or auto-activates on "design this plan" intent |
| `publish-hub` | Bundle a plan and its related HTML — the `prototype:` file, `--extra` pages, `design:` as an external-link tab — into one tabbed hub artifact at a stable `hub-artifact-url:`, leaving the plan's own `artifact-url:` untouched — command (`/plan-agent:publish-hub <plan.md> [--extra <path>]...`) or auto-activates on "publish / share a plan hub" intent |
| `plans-library` | Browse plans, view plan history, or open the plans index |
| `plans-open` | Reopen the plans gallery without rebuilding |
| `deep-grill` | Deep-grill or stress-test a plan decision by decision — manual invoke only |
| `documenting-plans` | Document a completed plan into `docs/<slug>.md` — manual invoke only |
| `markdown-to-html` | Convert a markdown file or plan to HTML |
| `plan-status` | Check or update a plan's lifecycle status, one file or a whole directory |

**Agents:**

| Agent | Purpose |
|-------|---------|
| `agent-review-plan` | Background plan-review agent — invokes the `review-plan` skill with `--background` and reports the updated path on completion |
| `plan-reviewer-architecture` · `-completeness` · `-testability` · `-risk` · `-conventions` · `-product` · `-security` | Seven core reviewer lenses, always run by the review Workflow |
| `plan-reviewer-ux` · `-accessibility` · `-frontend` | Three UI-conditional reviewer teammates, spawned when UI signals are detected |
| `plan-documenter` | Batch documentation agent — scans the plans directory for completed plans with no `docs/` counterpart and runs `documenting-plans` on each |

> The `review-plan` Workflow requires the `Workflow` tool — no feature flag, and no minimum version to set.

**Hooks:**

| Hook | Trigger | Purpose |
|------|---------|---------|
| `validate-plan-filename` | `PostToolUse` (Write/Edit) | Enforces verb-target kebab-case filenames on plan files |
| `rebuild-plans-index` | `PostToolUse` (Write/Edit/MultiEdit) | Auto-regenerates the plans gallery index when plans change |
| `build-prototypes-index` | `PostToolUse` (Write/Edit/MultiEdit) | Auto-regenerates the prototypes gallery index when `docs/prototypes/` changes |
| `render-plan-html` | `PostToolUse` (Write/Edit/MultiEdit) | Re-renders a plan's HTML after its source changes |
| `check-prototype-drift` | `PostToolUse` (Write/Edit/MultiEdit) | Warns when a prototype has drifted from the plan it was generated from |
| `build-designs-index` | `PostToolUse` (Write/Edit/MultiEdit) | Auto-regenerates the designs gallery index when `docs/designs/` changes |
| `check-design-drift` | `PostToolUse` (Write/Edit/MultiEdit) | Reports a user-facing plan step that no artboard covers |
| Stress-test nudge | `PostToolUse` (ExitPlanMode) | Suggests running the Step 5b interview or the `review-plan` team before implementing |

> All seven Write/Edit hooks are registered through a single `hooks/dispatch.py` entry rather than seven matchers, which is why the reference table counts two registrations. `dispatch.py` path-gates once and fans out only for writes under the plans, prototypes, or designs trees.

```bash
claude --plugin-dir ./kit/plugins/plan-agent
# /plan-agent:implementation-plan "Add dark mode support to the settings page"
# /plan-agent:implementation-plan https://github.com/org/repo/issues/42
# /plan-agent:review-plan docs/plans/add-dark-mode-toggle.html
# /plan-agent:review-plan-bg docs/plans/add-dark-mode-toggle.html
# /plan-agent:finalize-plan add-dark-mode-toggle.html
# /plan-agent:design docs/plans/add-dark-mode-toggle.html
# /plan-agent:publish-hub docs/plans/add-dark-mode-toggle.md
# /plan-agent:prompt
# "Browse my plans"
```

[View Documentation](./kit/plugins/plan-agent/README.md)

---

### Git & Workflow

---

#### `git-agent`

Automated git workflow — create branches, commit with conventional messages, create PRs, and merge them once they are green. Auto-links plan issue references in PR descriptions. By default, every PR-opening flow (`pr-agent`, `ship`, and their background agents) runs an adversarial review of `git diff <base>...HEAD` against an eleven-point checklist before the PR is created; `ship --no-review` skips this review. A reviewer subagent that returns no report (partial, empty, or missing its `### Summary` heading) is not re-dispatched — the checklist runs inline and the PR body says so.

**Commands:**

| Command | Description |
|---------|-------------|
| `/git-agent:commit-bg` | Fire off the agent-commit subagent in the background to stage and commit the working tree, then return control immediately |
| `/git-agent:pr-bg` | Fire off the agent-pr subagent in the background to push the current branch and open a GitHub PR, then return control immediately |
| `/git-agent:ship-bg` | Fire off the agent-ship subagent in the background to commit, push, and open a PR/MR end-to-end, then return control immediately |
| `/git-agent:ship-ci-bg` | Watch CI on an already-open PR in the background, apply at most one deterministic autofix per failure class (which it commits and pushes), and report — without blocking the session |
| `/git-agent:merge-bg` | Squash-merge one fully green PR in the background — dispatching the command *is* the approval; anything ambiguous comes back as a report instead of a merge |

**Skills:**

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `branch-agent` | Create or start a new branch — manual invoke only |
| `commit-agent` | Commit or save work to git — manual invoke only |
| `create-issue` | File, open, or create a GitHub or GitLab issue from any context — detects the host from the git remote and confirms before creating |
| `pr-agent` | Create a PR or open a pull request — manual invoke only |
| `merge` | Merge a PR — checks `MERGEABLE`, green checks, and the lint gate, then merges only with explicit approval; never passes `--delete-branch`. Classifies checks against the head commit's runs, so an undispatched run reads as a block rather than a pass and a started run with unreadable logs reads as a real failure. Typing `merge?` routes here deterministically |
| `post-merge-cleanup` | Clear away a merged branch and its worktree — detects squash-merges, inspects the worktree for uncommitted work first, and asks before every destructive step |
| `ship` | Ship changes or commit and create a PR — manual invoke only |
| `ship-autonomous` | Autonomously ship or watch CI — runs the full ship pipeline with CI polling and bounded autofix; a Step 0 context guard offers to clear or background the run first when the session is already long, since every PR event resends the transcript |

**Agents:**

| Agent | Purpose |
|-------|---------|
| `agent-commit` | Background git commit agent — stages all working-tree changes and creates a conventional commit message without user interaction |
| `agent-pr` | Background pull-request creation agent — pushes the current branch if needed and opens a GitHub pull request with an auto-generated summary |
| `agent-ship` | Background end-to-end ship agent — stages, commits, pushes, and opens a pull/merge request in one autonomous flow |
| `agent-ship-ci` | Background CI watcher — polls checks on an open PR until they settle, applies deterministic autofixes as their own commits (refusing to run on a dirty tree), and reports pass/fail |
| `agent-merge` | Background merge agent — squash-merges a single green PR, or returns a report when readiness is ambiguous |

**Hooks:**

| Hook | Trigger | Purpose |
|------|---------|---------|
| `merge-shorthand` | `UserPromptSubmit` | Routes a bare `merge?` prompt to the `merge` skill instead of leaving it to intent matching |
| `lint-before-commit` | `PreToolUse` (Bash) | Runs the repo's lint gate before a `git commit` lands, so a failing lint blocks the commit rather than CI |
| `scope-guard` | `PreToolUse` (Bash) | Blocks git commands that would reach outside the branch's intended scope |

```bash
claude --plugin-dir ./kit/plugins/git-agent
# "Commit my changes"
# "Create a branch for this feature"
# "Ship it"
# merge?
# /git-agent:ship-bg
# /git-agent:merge-bg
```

[View Documentation](./kit/plugins/git-agent/README.md)

---

#### `settings-sync`

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

#### `wcag-compliance-reviewer`

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

### Plugin Development

---

#### `skill-reviewer`

Review, plan, and optimize Claude Code skills — audit SKILL.md files across five quality dimensions, scaffold new skills, and get `allowed-tools` frontmatter recommended or patched.

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

**Hooks:**

| Hook | Trigger | Purpose |
|------|---------|---------|
| Description budget check | `PostToolUse` (Write/Edit/MultiEdit) | Measures the `description` frontmatter whenever a `SKILL.md` is written and warns past the 200-char budget; skips files whose description is unchanged |

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

#### `memory-tools`

Audit and reshape Claude Code project memory — CLAUDE.md files, path-scoped rule files in `.claude/rules/`, and usage-insights follow-through.

**Skills** (activate automatically):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `agentic-memory-management` | Audit, optimize, or diagnose a CLAUDE.md or project memory file — also activates when Claude appears to be ignoring project instructions |
| `path-rules-advisor` | Create path-specific rules, add rules for file types or directories, or organize Claude rules in `.claude/rules/` |
| `implementing-insights` | Implement the findings from a usage-insights report — triages every recommendation against existing config, discovers target repos from `~/.claude/projects/`, and implements only the genuinely open items, one PR per repo change |

```bash
claude --plugin-dir ./kit/plugins/memory-tools
# "Audit my CLAUDE.md file"
# "Claude keeps ignoring my instructions — what's wrong?"
# "Create path-specific rules for my src/ directory"
# "Implement the findings from this insights report"
```

[View Documentation](./kit/plugins/memory-tools/README.md)

---

#### `social-media-tools`

Discover teachable code, blog posts, videos, GitHub snippets, and selected/pasted code from git history or a codebase path, scrub for secrets, draft instructional platform-aware copy with concrete takeaways, and generate styled dark-mode social cards (1024px wide) for LinkedIn, Twitter/X, Bluesky, and Substack. Generate a `SOCIAL.md` project config for default platform, tone, and content preferences.

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
| `share-react` | Share a React component as a social card with a static rendered preview, code, and a typed props table |
| `share-explanation` | Explain how a project file, component, or concept works — "how does X work" or "explain X" |
| `write-guide` | Write a long-form internal developer guide (rule, tool, system, concept, or change) to `docs/` |
| `share-video` | Share or promote a video on social media |
| `share-project` | Announce features, bugs, changes, or releases on social media — manual invoke only |
| `share-init` | Set up social sharing preferences and generate a `SOCIAL.md` project config |
| `save-artifact` | Save an HTML artifact page into the local `.claude/artifacts` inbox under a dated name, then publish it |
| `export-session` | Export a session JSONL transcript to Markdown under `{plansDirectory}/sessions/` for reference and reuse |

```bash
claude --plugin-dir ./kit/plugins/social-media-tools
# "Create a social card for this feature"
# "Draft a LinkedIn post about my latest commit"
# /social-media-tools:digest
```

[View Documentation](./kit/plugins/social-media-tools/README.md)

---

#### `artifact-tools`

Publish work as live claude.ai artifacts. Every skill runs a blocking `security-scrub` gate before publishing and falls back to local HTML when publishing is unavailable.

**Commands:**

| Command | Description |
|---------|-------------|
| `/artifact-tools:eng-recap` | Publish an engineering recap of this session or a pull request — architecture, code paths, tradeoffs, learnings, tests, and review follow-ups, written for the engineer who touches this code next |
| `/artifact-tools:team-recap` | Publish a detailed, visual recap for the whole team — diagrams, before/after, decisions, and open items, readable by engineers and non-engineers alike |
| `/artifact-tools:product-doc` | Publish a recap for the product team and stakeholders — features, fixes, decisions, and plan details |

**Skills:**

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `diff-artifact` | Publish or share a diff — builds an annotated walkthrough (branch, commit range, or PR) with a sticky file sidebar, per-hunk reviewer notes, and severity labels |
| `plan-artifact` | Publish or share a plan — republishes to the same URL across sessions via `artifact-url:` frontmatter so viewers watch steps check off live |
| `prompt-artifact` | Publish or share a prompt saved by `plan-agent:prompt` — one prompt, or the whole filterable library with `--library` |
| `session-artifact` | Share a session recap — extracts transcript turns into Summary, Decisions, Learnings, and Files touched |
| `teach-artifact` | Publish an explainer — teaches how the system behind a session or a pull request actually works, rather than recapping what changed |

```bash
claude --plugin-dir ./kit/plugins/artifact-tools
# "Publish this diff as an artifact"
# "Share a recap of this session"
```

[View Documentation](./kit/plugins/artifact-tools/README.md)

---

#### `content-tools`

Turn work products into publishable site content. Every site-specific value comes from a project-root `CONTENT.md`, and a blocking `security-scrub` gate runs before any write.

**Skills:**

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `artifact-to-post` | Turn a local HTML artifact, pasted HTML, or a Markdown file into a **draft** post for a static site (Astro first) — each block takes the highest rung of the fidelity ladder that holds, and an MDX-safety pass runs after the prose rewrite. claude.ai artifact URLs are refused with a pointer to `social-media-tools:save-artifact` |

```bash
claude --plugin-dir ./kit/plugins/content-tools
# "Turn this artifact into a blog post draft"
```

[View Documentation](./kit/plugins/content-tools/README.md)

---

## How-To Guides

One brief "How do I" entry per skill: the slash command to type, the plain-English phrasing that triggers it, what it actually does, and the gotcha worth knowing. Skills marked command-only cannot be triggered by natural language. The folder carries its own index at [docs/guides/how-to/README.md](./docs/guides/how-to/README.md).

| Plugin | Guide | Skills |
|--------|-------|--------|
| artifact-tools | [How do I... artifact-tools](./docs/guides/how-to/artifact-tools.md) | 5 |
| code-review | [How do I... code-review](./docs/guides/how-to/code-review.md) | 1 |
| code-testing-agent | [How do I... code-testing-agent](./docs/guides/how-to/code-testing-agent.md) | 6 |
| content-tools | [How do I... content-tools](./docs/guides/how-to/content-tools.md) | 1 |
| git-agent | [How do I... git-agent](./docs/guides/how-to/git-agent.md) | 8 |
| memory-tools | [How do I... memory-tools](./docs/guides/how-to/memory-tools.md) | 3 |
| plan-agent | [How do I... plan-agent](./docs/guides/how-to/plan-agent.md) | 18 |
| settings-sync | [How do I... settings-sync](./docs/guides/how-to/settings-sync.md) | 2 |
| skill-reviewer | [How do I... skill-reviewer](./docs/guides/how-to/skill-reviewer.md) | 4 |
| social-media-tools | [How do I... social-media-tools](./docs/guides/how-to/social-media-tools.md) | 17 |
| wcag-compliance-reviewer | [How do I... wcag-compliance-reviewer](./docs/guides/how-to/wcag-compliance-reviewer.md) | 1 |

Total: 66 skills across 11 plugins.

---

## Plugin Reference Table

> Versions live here only — the per-plugin sections above deliberately omit them so there is one place to update.

| Plugin | Version | Category | Components |
|--------|---------|----------|------------|
| [memory-tools](./kit/plugins/memory-tools/README.md) | 4.3.1 | development | 3 skills |
| [code-review](./kit/plugins/code-review/README.md) | 3.3.6 | development | 1 command, 1 skill, 1 agent |
| [wcag-compliance-reviewer](./kit/plugins/wcag-compliance-reviewer/README.md) | 1.5.2 | security | 1 skill |
| [skill-reviewer](./kit/plugins/skill-reviewer/README.md) | 2.5.2 | development | 1 command, 4 skills, 1 hook |
| [code-testing-agent](./kit/plugins/code-testing-agent/README.md) | 3.6.0 | testing | 6 skills |
| [git-agent](./kit/plugins/git-agent/README.md) | 4.20.2 | development | 5 commands, 8 skills, 5 agents, 3 hooks |
| [settings-sync](./kit/plugins/settings-sync/README.md) | 1.3.0 | productivity | 2 skills |
| [social-media-tools](./kit/plugins/social-media-tools/README.md) | 2.23.4 | productivity | 1 command, 17 skills |
| [plan-agent](./kit/plugins/plan-agent/README.md) | 9.13.2 | productivity | 9 commands, 18 skills, 12 agents, 2 hooks |
| [artifact-tools](./kit/plugins/artifact-tools/README.md) | 1.12.0 | development | 3 commands, 5 skills |
| [content-tools](./kit/plugins/content-tools/README.md) | 1.1.1 | documentation | 1 skill |

---

## Removed Plugins

The following plugins have been removed from the `agentics-kit` marketplace — six at v4.0.0, one absorbed into `git-agent`, two folded into `plan-agent`, and one retired as unused since. They **will not appear** when browsing or installing from the marketplace — `/plugin install` will not find them.

Their source directories have been removed from the repository. De-registering a plugin stops distribution but not loading — a directory left under `kit/plugins/` still loads via `--plugin-dir`, collides by name with a live plugin, and consumes skill-description budget in every session. Git history is the reference, so the source is recoverable:

```bash
git clone https://github.com/shawn-sandy/agentics.git
cd agentics
git log --diff-filter=D --oneline -- kit/plugins/<plugin-name>
git checkout <commit>^ -- kit/plugins/<plugin-name>
```

| Plugin | Last Version | Removed | Reason | Replacement |
|--------|-------------|---------|--------|-------------|
| `team-defaults` | 0.2.3 | 2026-08-23 | Retired as unused — never invoked in any session; its bundled rule copies had drifted from `~/.claude/rules/`, and `settings-sync` already backs up `~/.claude/rules/` and `CLAUDE.md` | `/plugin install settings-sync@agentics-kit` then `/settings-sync:settings-backup` |
| `product-plans` | 3.4.13 | 2026-08-02 | Folded into `plan-agent` 8.2.0 — its PM, security, and frontend lenses now ship as `plan-reviewer-product`, `-security`, and `-frontend` inside `review-plan` | `/plugin install plan-agent@agentics-kit` then `/plan-agent:review-plan` |
| `plan-interview` | 3.0.0 | 2026-07-17 | Merged into `plan-agent` 4.0.0 — `documenting-plans`, `markdown-to-html`, `plan-status`, `plan-maintenance`, `deep-grill`, and the ExitPlanMode nudge all carried over | `/plugin install plan-agent@agentics-kit` |
| `issue-agent` | 0.2.4 | 2026-06-16 | Absorbed into `git-agent` v3.11.0 to reduce plugin count | `/plugin install git-agent@agentics-kit` then `/git-agent:create-issue` |
| `agent-creator` | 1.1.2 | 2026-05-29 | Redundant with `agentic-plugin-dev` | No replacement — removed from the marketplace |
| `agent-reviewer` | 1.0.2 | 2026-05-29 | Overlaps with `skill-reviewer` | `/plugin install skill-reviewer@agentics-kit` |
| `marketplace-builder` | 1.1.2 | 2026-05-29 | Redundant with `agentic-plugin-dev` | No replacement — removed from the marketplace |
| `react-perf-analyzer` | 1.3.1 | 2026-05-29 | Too specialized for React-only projects | `/plugin install code-review@agentics-kit` |
| `agentic-plugin-dev` | 1.2.2 | 2026-05-29 | Functionality consolidated into existing skills | `/plugin install skill-reviewer@agentics-kit` |
| `code-simplifier` | 1.0.2 | 2026-05-29 | Structural analysis covered by `code-review` | `/plugin install code-review@agentics-kit` |

**To recover a removed plugin's source:**

Their directories are no longer in the working tree. Restore one from git history if you need it for reference:

```bash
# Find the commit that deleted it, then restore that path from its parent
git log --diff-filter=D --oneline -- kit/plugins/agent-creator
git checkout <commit>^ -- kit/plugins/agent-creator
```

> Re-registering any of these plugins in `marketplace.json` requires explicit confirmation — see the [Removed Plugins registry](https://github.com/shawn-sandy/agentics/blob/main/.claude/rules/marketplace.md) for the removal rationale before proceeding.

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
| `marketplace.md` | `kit/plugins/**`, `.claude-plugin/**` | Categories, tagging, versioning, registration |
| `testing.md` | `tests/**` | Test fixture guidelines |
| `plan-hygiene.md` | `**/plans/**` | Pre-commit plan file rename checks |
| `skill-authoring.md` | `kit/plugins/**/skills/**` | Skill description format, `allowed-tools`, trigger phrases |
| `removed-plugins.md` | always (unscoped) | Registry of de-registered plugins; gates re-adding one behind explicit confirmation |

### Project Hooks (Auto-Active)

Two hooks run at `SessionStart`:

1. **Merge-driver registration** — runs `scripts/setup-merge-driver.sh` so `marketplace.json` and gallery `index.html` conflicts auto-resolve
2. **Base-branch refresh** — pulls or fetches the default branch so the session starts from current `origin`

Three more run after every file Write/Edit:

1. **JSON validation** — validates `marketplace.json` syntax
2. **Uncommitted plan warning** — alerts if plan files are unstaged alongside plugin changes
3. **Version guard** — when `marketplace.json` is dirty, runs `scripts/check-plugin-versions.mjs` to confirm every touched plugin's version exceeds `origin/main`

The version guard compares **committed** state (`origin/main...HEAD`), so it
catches an un-bumped commit on the next Write/Edit after you commit, not at the
moment you edit. It does not fetch, so it is only as current as your last
`git fetch`. Before pushing, run it directly against a fresh base:

```bash
git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs
```

### Running Tests

`tests/run-all.sh` is the single entry point — it discovers every
`tests/**/test-*.sh`, `tests/**/test-*.mjs`, and `tests/**/*.test.mjs` file
automatically, so a new test needs no wiring. A short skip list at the top of the
script names the four suites that need a CLI, a deployment, or a built `dist/`,
each with its reason.

```bash
# Run everything
bash tests/run-all.sh
```

Individual suites still run on their own:

```bash
bash tests/demo/run.sh                    # demo suite
bash tests/pages/test-docs-hub.sh         # docs hub smoke test
bash tests/plugins/test-agent-frontmatter.sh
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

**Launch configs — auto-assigned ports (`.claude/launch.json`):**

Each config uses `autoPort: true`, so the preview harness binds a free port at start time (reported when the server launches) — no fixed port to collide with another running server.

| Config | Directory |
|--------|-----------|
| `plans-gallery` | `docs/plans/` |
| `media-library` | `docs/media/social/` |
| `docs-all` | `docs/` (landing hub at root) |

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
| `update-docs.yml` | Every Sunday at 00:00 UTC, or manual dispatch | Run the `docs-sync` skill and open a PR bringing the README, how-to guides, and changelog up to date with the releases since the last sync |
| `check-plugin-versions.yml` | Pull request | Fail the PR if a touched plugin's `marketplace.json` version does not exceed the base branch, and run the test suite |
| `publish-dist.yml` | Daily + manual dispatch | Build `dist/` and push it to the `shawn-sandy/agentics-kit` distribution repo |
| `regen-plans.yml` | Push to `main` (plan changes) | Re-render plan HTML and rebuild the plans gallery index |

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
