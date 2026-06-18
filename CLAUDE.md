# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

**Marketplace system for Claude Code plugins.** Contains example plugins and marketplace infrastructure for testing plugin discovery, distribution, and installation.

Two distinct purposes:

1. **Example Plugins** — Reference implementations in `kit/plugins/` demonstrating Claude Code plugin structure
2. **Marketplace Infrastructure** — API and CLI for discovering and serving these plugins

## Tech Stack

- **Formats:** Markdown (commands, skills), JSON (plugin manifests)
- **Plugin manifest:** `kit/plugins/<name>/.claude-plugin/plugin.json` — requires `name`; `version` is managed in `marketplace.json` for relative-path plugins
- **Marketplace manifest:** `.claude-plugin/marketplace.json` — plugin registry with relative `source` paths
- **Minimum Claude Code Version:** 1.0.33 or later

## Repository Structure

```plaintext
.claude-plugin/       → Marketplace metadata (marketplace.json) — must be at repo root
kit/plugins/          → Plugin source code (what users install)
.claude/rules/        → Detailed authoring patterns (scoped rules)
scripts/              → Build + git merge-driver helpers (build-dist, merge-marketplace, merge-plans-index)
examples/             → Standalone demo scripts (e.g. demo-tdd-loop.sh)
tests/fixtures/       → Test data for validation logic
tests/pages/          → Smoke tests for docs landing hub and GitHub Pages
tests/plugins/        → Plugin behavior smoke tests
tests/publish/        → Dist build + publish-pipeline tests
tests/demo/           → Sample project used by test-driven demos
docs/                 → GitHub Pages site root (deployed via deploy-pages.yml)
docs/index.html       → Landing hub — links to Plans gallery and Media library
docs/guides/          → Reference guides (auto-load setup, etc.)
docs/media/social/    → Generated social cards gallery (Media library)
docs/prompts/         → Saved refined prompts (from plan-agent:refine-prompt)
docs/plans/           → Plan files (commit with plugin changes)
docs/plans/archive/   → Archived completed plans — IGNORE in all searches and exploration
dist/                 → Local build output, gitignored; populated by node scripts/build-dist.mjs
```

> **Search exclusion:** Never include `docs/plans/archive/` in file searches, glob patterns, or exploratory reads. Treat it as off-limits unless the user explicitly targets it by path.

Plugins are **referenced** by marketplaces, not embedded. `marketplace.json` uses relative `source` paths.

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

11 plugins in the marketplace (`agentics-kit` v4.0.0):

| Plugin | Type | Notes |
|--------|------|-------|
| `memory-tools` | Skills | Auto-activated CLAUDE.md / project memory auditing; enforces optimization principle (keep only rules that change Claude's behavior) |
| `code-review` | Skills + Agents + Commands | Auto-activated code review; `/code-review:fix-branch` autonomously reviews and applies fixes across the whole branch |
| `plan-interview` | Commands + Skills | Stress-test plans with deep-grill interview; auto-routes product plans to panel review (Step 1.5 router); `--quick` flag bypasses routing |
| `skill-reviewer` | Skills | Audit and optimize skill files — enforces three-part description format (short label + capability + trigger phrase, ≤200 chars) |
| `code-testing-agent` | Skills + Agents | Test suggestion, review, tdd-fix (bug), tdd-loop (feature); tdd-fix and tdd-loop are manual-invoke only (`disable-model-invocation`) |
| `git-agent` | Skills + Agents + Commands | Branch creation, commit, PR, and ship workflows; background commands: `commit-bg`, `pr-bg`, `ship-bg`; `ship-autonomous` for supervised full pipeline; `create-issue` skill files GitHub/GitLab issues from any context (selection, session, bug, feature) with host auto-detection and confirmation gate |
| `wcag-compliance-reviewer` | Skills | WCAG accessibility review |
| `product-plans` | Skills + Agents + Commands | Cross-functional review panel (PM, Dev, UX, Frontend, A11y, Security); background-mode panel via `/product-plans:product-plans-bg`; codebase-only research (no WebFetch/WebSearch) |
| `settings-sync` | Skills | Back up and restore Claude Code settings to a git repo; routine-compatible |
| `social-media-tools` | Skills + Commands | Discover teachable content (git history, codebase path, blog posts, videos, GitHub snippets, selected code), scrub for secrets, generate dark-mode social cards for LinkedIn/Twitter/Bluesky/Substack with contextual follow CTAs; `social-share` router skill classifies any share request and runs the right workflow directly; `share-init` generates a `SOCIAL.md` project config for default platform, tone, and content preferences; `share-react` shares a React component with a static rendered preview and a typed props table on one card; `write-guide` writes a long-form internal developer explainer guide (system, rule, or concept) to `docs/` following a fixed 12-section skeleton; `/social-media-tools:digest` for interactive digest scanning |
| `plan-agent` | Skills + Agents + Hooks + Commands | `/plan-agent:implementation-plan <objective>` runs Steps 0–8 plan workflow with built-in interview; `/plan-agent:review-plan` spawns a seven-reviewer Agent Team; `/plan-agent:review-plan-bg <path>` runs the review team in the background; `/plan-agent:finalize-plan` reviews and marks plans completed with per-criterion verification; `/plan-agent:build-proposal <idea>` turns a vague idea into a decision-complete `docs/proposals/<slug>.md` via an 8-step research→decide loop + Tier 0/1/2 right-sizing gate, then hands off to implementation-plan; `/plan-agent:refine-prompt` generates AI prompts from Anthropic best practices (command-only); accepts issue URLs/`#n` to seed plans and `.md` plan paths for conversion to HTML; `plans-library` builds filterable gallery; `plans-open` reopens gallery; automatic filename hook + gallery index auto-rebuild hook |

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
- **Bump `version` manually in `marketplace.json`** when you change a plugin — the new value must be higher than the value on `main`. Follow semver: `fix` = patch, `feat` = minor, breaking change = major. See `.claude/rules/marketplace.md`.
- For relative-path plugins, set `version` only in `marketplace.json` — never add a `version` field to `plugin.json` (it silently overrides the marketplace value).
- Component types: **Commands** (`/plugin:name`), **Skills** (auto-activated), **Agents** (subprocesses), **Hooks** (event-driven).
- Skill `SKILL.md` can use `allowed-tools` frontmatter to restrict tool access if necessary
- Two git merge drivers (registered in `.gitattributes`) auto-resolve conflicts: `merge-marketplace.mjs` keeps the higher semver in `marketplace.json`; `merge-plans-index.mjs` unions plan cards in `docs/plans/index.html`. Run `scripts/setup-merge-driver.sh` once per clone to enable them.

## Official Documentation

- **Main Docs:** <https://code.claude.com/docs/en>
- **Plugin Creation:** <https://code.claude.com/docs/en/plugins>
- **Plugin Reference:** <https://code.claude.com/docs/en/plugins-reference>
- **Plugin Marketplaces:** <https://code.claude.com/docs/en/plugin-marketplaces>
