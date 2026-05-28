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
tests/fixtures/       → Test data for validation logic
.claude/rules/        → Detailed authoring patterns (scoped rules)
docs/plans/           → Plan files (commit with plugin changes)
```

Plugins are **referenced** by marketplaces, not embedded. `marketplace.json` uses relative `source` paths.

## Common Commands

```bash
# Load a plugin for local testing
claude --plugin-dir ./kit/plugins/<name>

# Register marketplace and install a plugin
/plugin marketplace add shawn-sandy/agentics
/plugin install <plugin-name>@agentics-kit
```

> Machine-specific paths belong in `CLAUDE.local.md`, not here.

## Reference Implementations

17 plugins in the marketplace (`agentics-kit` v3.8.0):

| Plugin | Type | Notes |
|--------|------|-------|
| `memory-tools` | Skills | Auto-activated CLAUDE.md / project memory auditing; enforces optimization principle (keep only rules that change Claude's behavior) |
| `code-review` | Skills + Agents + Commands | Auto-activated code review; `/code-review:fix-branch` autonomously reviews and applies fixes across the whole branch |
| `plan-interview` | Commands + Skills | Stress-test plans with deep-grill interview; auto-routes product plans to panel review (Step 1.5 router); `--quick` flag bypasses routing |
| `skill-reviewer` | Skills | Audit and optimize skill files — enforces two-sentence description format (capability + trigger phrase, ≤160 chars) |
| `code-testing-agent` | Skills + Agents | Test suggestion, review, tdd-fix (bug), tdd-loop (feature); tdd-fix and tdd-loop are manual-invoke only (`disable-model-invocation`) |
| `git-agent` | Skills + Agents + Commands | Branch creation, commit, PR, and ship workflows; background commands: `commit-bg`, `pr-bg`, `ship-bg`; `ship-autonomous` for supervised full pipeline |
| `agent-creator` | Agents | Plugin scaffolding agent |
| `agentic-plugin-dev` | Skills + Commands | Plugin development toolkit |
| `code-simplifier` | Skills | Structural quality and simplification analysis |
| `marketplace-builder` | Skills | Marketplace scaffolding |
| `wcag-compliance-reviewer` | Skills | WCAG accessibility review |
| `react-perf-analyzer` | Skills | React performance analysis; manual-invoke only (`disable-model-invocation`) |
| `agent-reviewer` | Skills | Subagent definition file auditing |
| `product-plans` | Skills + Agents + Commands | Cross-functional review panel (PM, Dev, UX, Frontend, A11y, Security); background-mode panel via `/product-plans:product-plans-bg`; codebase-only research (no WebFetch/WebSearch) |
| `settings-sync` | Skills | Back up and restore Claude Code settings to a git repo; routine-compatible |
| `code-share` | Skills + Commands + Agents | Discover shareable code from git history or codebase path, scrub for secrets, generate social cards for LinkedIn/Twitter/Bluesky; `/code-share:digest` and `/code-share:digest-bg` for interactive and background digest scanning |
| `plan-agent` | Skills + Hooks | Explicit `/plan-agent:planning <objective>` skill (manual-invoke, `disable-model-invocation`) runs §0–§7 plan workflow; automatic `verb-target` filename hook on `Write`/`Edit`; optional pairing with `plan-interview:plan-status` |

- **Marketplace config:** `.claude-plugin/marketplace.json`
- **Test fixture:** `tests/fixtures/valid-plugin/` — validation reference

## Modular Rules

Detailed patterns in `.claude/rules/`:

- `plugin-patterns.md` — command/skill patterns, progressive disclosure, pitfalls (scoped to `kit/plugins/**`)
- `marketplace.md` — categories, tagging, versioning, registration
- `testing.md` — test fixture guidelines (scoped to `tests/**`)
- `plan-hygiene.md` — pre-commit plan file rename checks (scoped to `**/plans/**`)

## Conventions

- Plugin Homepage URLs must point to the plugin's directory, not the repository root: `https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/{plugin-name}`
- Always include the plan file in commits for plugin changes, even minor ones.
- `.claude/settings.json` auto-validates `marketplace.json` JSON syntax after every Write/Edit — fix any errors before committing.
- For relative-path plugins, set `version` only in `marketplace.json`, not in `plugin.json`.
- Component types: **Commands** (`/plugin:name`), **Skills** (auto-activated), **Agents** (subprocesses), **Hooks** (event-driven).
- Skill `SKILL.md` can use `allowed-tools` frontmatter to restrict tool access if necessary

## Official Documentation

- **Main Docs:** <https://code.claude.com/docs/en>
- **Plugin Creation:** <https://code.claude.com/docs/en/plugins>
- **Plugin Reference:** <https://code.claude.com/docs/en/plugins-reference>
- **Plugin Marketplaces:** <https://code.claude.com/docs/en/plugin-marketplaces>
