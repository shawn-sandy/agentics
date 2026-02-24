# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Marketplace system for Claude Code plugins.** Contains example plugins and marketplace infrastructure for testing plugin discovery, distribution, and installation.

Two distinct purposes:

1. **Example Plugins** — Reference implementations in `plugins/` demonstrating Claude Code plugin structure
2. **Marketplace Infrastructure** — (Planned) API and CLI for discovering and serving these plugins

## Tech Stack

- **Formats:** Markdown (commands, skills), JSON (plugin manifests)
- **Plugin manifest:** `.claude-plugin/plugin.json` — requires `name`, `version`, `description`
- **Marketplace manifest:** `.claude-plugin/marketplace.json` — plugin registry with relative `source` paths
- **Minimum Claude Code Version:** 1.0.33 or later

## Repository Structure

```plaintext
plugins/              → Plugin source code (what users install)
.claude-plugin/       → Marketplace metadata (marketplace.json)
tests/fixtures/       → Test data for validation logic
.claude/rules/        → Detailed authoring patterns (scoped rules)
```

**Key principle:** Plugins are **referenced** by marketplaces, not embedded. `marketplace.json` uses relative `source` paths, allowing the same plugin to appear in multiple marketplaces.

## Common Commands

```bash
# Load a plugin for local testing
claude --plugin-dir ~/devbox/agentics/plugins/<name>

# Register marketplace and install a plugin
/plugin marketplace add ~/devbox/agentics
/plugin install <plugin-name>@agentics-kit
```

> Machine-specific paths (e.g. absolute local paths) belong in `.claude.md.local`, not here.

## Reference Implementations

- **Minimal:** `plugins/hello-world/` — single command, basic structure
- **Commands only:** `plugins/dev-tools/` — formatting commands
- **Skills only:** `plugins/claude-md-optimizer/` — auto-activated CLAUDE.md auditing
- **Skills only:** `plugins/code-review/` — auto-activated code review
- **Mixed:** `plugins/plan-interview/` — commands + skills
- **Marketplace config:** `.claude-plugin/marketplace.json` — registry (agentics-kit v2.0.0)
- **Test fixture:** `tests/fixtures/valid-plugin/` — validation reference

## Modular Rules

Detailed patterns in `.claude/rules/`:

- `plugin-patterns.md` — command/skill patterns, progressive disclosure, pitfalls (scoped to `plugins/**`)
- `marketplace.md` — categories, tagging, versioning, registration
- `testing.md` — test fixture guidelines (scoped to `tests/**`)

## Conventions

- Plugin homepages must link to the plugin's own GitHub source directory, not the repo root.
- Always include the plan file in commits for plugin changes, even minor ones.
- `version` in `marketplace.json` must exactly match `version` in the plugin's `plugin.json`.
- Component types: **Commands** (invoked via `/plugin:name`), **Skills** (auto-activated by intent), **Agents** (subprocesses), **Hooks** (event-driven).

## Official Documentation

- **Main Docs:** <https://code.claude.com/docs/en>
- **Plugin Creation:** <https://code.claude.com/docs/en/plugins>
- **Plugin Reference:** <https://code.claude.com/docs/en/plugins-reference>
- **Plugin Marketplaces:** <https://code.claude.com/docs/en/plugin-marketplaces>
