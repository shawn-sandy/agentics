# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

**Marketplace system for Claude Code plugins.** Contains example plugins and marketplace infrastructure for testing plugin discovery, distribution, and installation.

Two distinct purposes:

1. **Example Plugins** — Reference implementations in `plugins/` demonstrating Claude Code plugin structure
2. **Marketplace Infrastructure** — (Planned) API and CLI for discovering and serving these plugins

## Tech Stack

- **Formats:** Markdown (commands, skills), JSON (plugin manifests)
- **Plugin manifest:** `.claude-plugin/plugin.json` — requires `name`; `version` is managed in `marketplace.json` for relative-path plugins
- **Marketplace manifest:** `.claude-plugin/marketplace.json` — plugin registry with relative `source` paths
- **Minimum Claude Code Version:** 1.0.33 or later

## Repository Structure

```plaintext
plugins/              → Plugin source code (what users install)
.claude-plugin/       → Marketplace metadata (marketplace.json)
tests/fixtures/       → Test data for validation logic
.claude/rules/        → Detailed authoring patterns (scoped rules)
docs/plans/           → Plan files (commit with plugin changes)
```

Plugins are **referenced** by marketplaces, not embedded. `marketplace.json` uses relative `source` paths.

## Common Commands

```bash
# Load a plugin for local testing
claude --plugin-dir ./plugins/<name>

# Register marketplace and install a plugin
/plugin marketplace add /path/to/agentics
/plugin install <plugin-name>@agentics-kit
```

> Machine-specific paths belong in `CLAUDE.local.md`, not here.

## Reference Implementations

- **Skills only:** `plugins/claude-md-optimizer/` — auto-activated CLAUDE.md auditing
- **Skills only:** `plugins/code-review/` — auto-activated code review
- **Mixed:** `plugins/plan-interview/` — commands + skills
- **Marketplace config:** `.claude-plugin/marketplace.json` — registry (agentics-kit v2.3.0)
- **Test fixture:** `tests/fixtures/valid-plugin/` — validation reference

## Modular Rules

Detailed patterns in `.claude/rules/`:

- `plugin-patterns.md` — command/skill patterns, progressive disclosure, pitfalls (scoped to `plugins/**`)
- `marketplace.md` — categories, tagging, versioning, registration
- `testing.md` — test fixture guidelines (scoped to `tests/**`)
- `plan-hygiene.md` — pre-commit plan file rename checks (scoped to `**/plans/**`)

## Conventions

- Plugin Homepage URLs must point to the plugin's directory, not the repository root: `https://github.com/shawn-sandy/agentics/tree/main/plugins/{plugin-name}`
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
