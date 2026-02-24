# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **marketplace system for Claude Code plugins**. The repository contains example plugins and marketplace infrastructure for testing plugin discovery, distribution, and installation.

**Two distinct purposes:**
1. **Example Plugins** — Reference implementations in `plugins/` demonstrating Claude Code plugin structure
2. **Marketplace Infrastructure** — (Planned) API and CLI for discovering and serving these plugins

Currently focused on plugin examples. The marketplace API is in progress.

## Repository Architecture

### Three-Layer Structure

```
plugins/              → Plugin source code (what users install)
.claude-plugin/       → Marketplace metadata (how plugins are discovered)
tests/fixtures/       → Test data for validation logic
```

**Key Insight:** Plugins are **referenced** by marketplaces, not embedded in them. The `marketplace.json` file points to plugin directories via relative `source` paths. This allows the same plugin to appear in multiple marketplaces and supports versioning independent of marketplace versioning.

### Plugin Structure (Claude Code Standard)

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json           # Required: name, version, description
├── commands/                 # Optional: Slash commands
│   └── command-name.md       # YAML frontmatter + markdown instructions
├── skills/                   # Optional: Auto-activated capabilities
│   └── skill-name/
│       └── SKILL.md          # YAML frontmatter + markdown instructions
├── agents/                   # Optional: Specialized subagents
└── hooks/                    # Optional: Event-driven automation
```

**Component Types:**
- **Commands** — Explicit invocation via `/plugin:command` syntax
- **Skills** — Automatic activation when user intent matches frontmatter `description`
- **Agents** — Long-running autonomous subprocesses
- **Hooks** — Event handlers (PreToolUse, PostToolUse, etc.)

### Marketplace Manifest Structure

`.claude-plugin/marketplace.json` defines marketplace identity, plugin registry, and metadata.

**Discovery Flow:**
1. API reads `marketplace.json`
2. Follows each `source` path to parse `plugin.json`
3. Scans component directories (`commands/`, `skills/`, etc.)
4. Indexes metadata for search/retrieval

## Local Development

Canonical path: `~/devbox/agentics`

```bash
# Load a single plugin
claude --plugin-dir ~/devbox/agentics/plugins/hello-world

# Load multiple plugins
claude --plugin-dir ~/devbox/agentics/plugins/hello-world --plugin-dir ~/devbox/agentics/plugins/dev-tools

# Load all plugins
claude --plugin-dir ~/devbox/agentics/plugins/hello-world \
  --plugin-dir ~/devbox/agentics/plugins/dev-tools \
  --plugin-dir ~/devbox/agentics/plugins/claude-md-optimizer \
  --plugin-dir ~/devbox/agentics/plugins/code-review \
  --plugin-dir ~/devbox/agentics/plugins/plan-interview

# Register marketplace persistently
/plugin marketplace add ~/devbox/agentics
/plugin install dev-tools@agentics-kit
/plugin install claude-md-optimizer@agentics-kit
/plugin install code-review@agentics-kit
/plugin install plan-interview@agentics-kit
```

## Reference Implementations

- **Minimal Plugin:** `plugins/hello-world/` — Single command, basic structure
- **Commands Only:** `plugins/dev-tools/` — Formatting commands (skills extracted in v2.0)
- **Skills Only:** `plugins/claude-md-optimizer/` — Auto-activated CLAUDE.md auditing skill
- **Skills Only:** `plugins/code-review/` — Auto-activated code review skill
- **Mixed (commands + skills):** `plugins/plan-interview/` — Plan interview command and skill
- **Marketplace Config:** `.claude-plugin/marketplace.json` — Plugin registry (agentics-kit v2.0.0)
- **Valid Test Fixture:** `tests/fixtures/valid-plugin/` — Validation reference

## Modular Rules

Detailed patterns are in `.claude/rules/`:
- `plugin-patterns.md` — Command/skill patterns, progressive disclosure, pitfalls (scoped to `plugins/**`)
- `marketplace.md` — Categories, tagging, versioning, registration
- `testing.md` — Test fixture guidelines (scoped to `tests/**`)

## Official Documentation

- **Main Docs:** https://code.claude.com/docs/en
- **Plugin Creation:** https://code.claude.com/docs/en/plugins
- **Plugin Reference:** https://code.claude.com/docs/en/plugins-reference
- **Plugin Marketplaces:** https://code.claude.com/docs/en/plugin-marketplaces

**Minimum Claude Code Version:** 1.0.33 or later
