# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

**Marketplace system for Claude Code plugins.** Plugin sources live in `kit/plugins/`; the marketplace infrastructure around them handles discovery, distribution, and installation.

## Tech Stack

- **Plugin manifest:** `kit/plugins/<name>/.claude-plugin/plugin.json`, requires `name`
- **Marketplace manifest:** `.claude-plugin/marketplace.json` — plugin registry with relative `source` paths
- **Minimum Claude Code Version:** 1.0.33 or later

## Repository Structure

```plaintext
.claude-plugin/       → marketplace.json — must be at repo root
kit/plugins/          → Plugin source code (what users install)
.claude/rules/        → Detailed authoring patterns (scoped rules)
scripts/              → Build + git merge-driver helpers
tests/                → fixtures, pages, plugins, publish, demo
docs/                 → GitHub Pages site root (plans, prompts, guides, media)
docs/plans/archive/   → Archived plans — IGNORE in all searches and exploration
dist/                 → Local build output, gitignored (node scripts/build-dist.mjs)
```

> **Search exclusion:** Never include `docs/plans/archive/` in file searches, glob patterns, or exploratory reads. Treat it as off-limits unless the user explicitly targets it by path.

Plugins are **referenced** by marketplaces, not embedded.

## Common Commands

```bash
# Load a plugin for local testing
claude --plugin-dir ./kit/plugins/<name>

# Register marketplace and install a plugin
/plugin marketplace add shawn-sandy/agentics
/plugin install <plugin-name>@agentics-kit

# Trigger a manual publish to the distribution repo
gh workflow run publish-dist.yml --repo shawn-sandy/agentics
```

> Machine-specific paths belong in `CLAUDE.local.md`, not here.

## Reference Implementations

13 plugins in the marketplace (`agentics-kit` v4.0.0):

| Plugin | Type | Purpose |
|--------|------|---------|
| `artifact-tools` | Skills + Commands | Publish diffs, sessions, plans, and prompts as claude.ai artifact pages |
| `code-review` | Skills + Agents + Commands | Multi-dimensional review; `fix-branch` applies fixes across the whole branch |
| `code-testing-agent` | Skills + Agents | Test suggestion and review, plus manual-only tdd-fix and tdd-loop |
| `content-tools` | Skills | Convert an HTML artifact or Markdown file into a draft site post |
| `git-agent` | Skills + Agents + Hooks + Commands | Branch, commit, PR, merge, ship, and issue workflows, with background variants |
| `memory-tools` | Skills | Audit CLAUDE.md and project memory against context-engineering practice |
| `plan-agent` | Skills + Agents + Hooks + Commands | Author, review, implement, and maintain implementation plans end to end |
| `product-plans` | Skills + Agents + Commands | Six-role cross-functional review panel for product plans and PRDs |
| `settings-sync` | Skills | Back up and restore Claude Code settings to a git repo |
| `skill-reviewer` | Skills | Audit, score, and optimize SKILL.md files and their frontmatter |
| `social-media-tools` | Skills + Commands | Turn work into scrubbed social cards, guides, and session exports |
| `team-defaults` | Skills + Agents | Shared team rules plus documentation and design-token agents |
| `wcag-compliance-reviewer` | Skills | Review code for WCAG 2.2 AA accessibility compliance |

Detail on demand: README.md's generated Plugin Reference Table, then `kit/plugins/<name>/README.md`.

- **Marketplace config:** `.claude-plugin/marketplace.json`
- **Test fixture:** `tests/fixtures/valid-plugin/` — validation reference

## Modular Rules

Detailed patterns in `.claude/rules/`:

- `plugin-patterns.md` — command/skill patterns, progressive disclosure, pitfalls (scoped to `kit/plugins/**`)
- `skill-authoring.md` — verify `SKILL.md` changes against Anthropic's effective-skills checklist (scoped to `kit/plugins/**/skills/**`)
- `marketplace.md` — categories, tagging, versioning, registration
- `testing.md` — test fixture guidelines (scoped to `tests/**`)
- `plan-hygiene.md` — pre-commit plan file rename checks (scoped to `**/plans/**`)

## Git & Branches

- **Always create a new branch off `main` for each feature or fix.** Never commit new work directly to a long-lived shared branch (e.g. a branch from a previous session). Suggested naming: `verb-target-YYYY-MM-DD` (e.g. `add-implement-prompt-2026-06-01`).
- Run `git fetch origin && git checkout -b <branch-name> origin/main` at the start of each new task.

## Conventions

- Plugin Homepage URLs must point to the plugin's directory, not the repository root: `https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/{plugin-name}`
- Always include the plan file in commits for plugin changes, even minor ones.
- `.claude/settings.json` auto-validates `marketplace.json` JSON syntax after every Write/Edit — fix any errors before committing.
- **Bump `version` manually in `marketplace.json`** when you change a plugin; it must exceed `main`'s value. Semver: `fix` = patch, `feat` = minor, breaking = major. See `.claude/rules/marketplace.md`.
- For relative-path plugins, set `version` only in `marketplace.json` — never add a `version` field to `plugin.json` (it silently overrides the marketplace value).
- Component types: **Commands** (`/plugin:name`), **Skills** (auto-activated), **Agents** (subprocesses), **Hooks** (event-driven).
- Skill `SKILL.md` can use `allowed-tools` frontmatter to restrict tool access if necessary
- Two git merge drivers auto-resolve conflicts: `marketplace.json` keeps the higher semver, and the plans/artifacts gallery indexes union their cards. Run `scripts/setup-merge-driver.sh` once per clone; never hand-edit conflict markers in an `index.html`.

## Official Documentation

- **Main Docs:** <https://code.claude.com/docs/en>
- **Plugin Creation:** <https://code.claude.com/docs/en/plugins>
- **Plugin Reference:** <https://code.claude.com/docs/en/plugins-reference>
- **Plugin Marketplaces:** <https://code.claude.com/docs/en/plugin-marketplaces>
