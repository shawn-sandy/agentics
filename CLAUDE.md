# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **marketplace system for Claude Code plugins**. The repository contains example plugins and marketplace infrastructure for testing plugin discovery, distribution, and installation.

**Critical Understanding:** This project has two distinct purposes:
1. **Example Plugins** - Reference implementations in `plugins/` that demonstrate Claude Code plugin structure
2. **Marketplace Infrastructure** - (Planned) API and CLI for discovering and serving these plugins

Currently, the repository focuses on plugin examples. The marketplace API implementation is in progress.

## Repository Architecture

### Three-Layer Structure

```
plugins/              → Plugin source code (what users install)
.claude-plugin/       → Marketplace metadata (how plugins are discovered)
tests/fixtures/       → Test data for validation logic
```

**Key Insight:** Plugins are **referenced** by marketplaces, not embedded in them. The `marketplace.json` file contains metadata that points to plugin directories via relative paths (`source: "./plugins/hello-world"`). This allows:
- Same plugin to be in multiple marketplaces with different metadata
- Plugin versioning independent of marketplace versioning
- Local development without duplicating plugin code

### Plugin Structure (Claude Code Standard)

Every plugin follows this structure:
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
- **Commands** - Explicit invocation via `/plugin:command` syntax
- **Skills** - Automatic activation based on user intent (described in frontmatter)
- **Agents** - Long-running autonomous subprocesses
- **Hooks** - Event handlers (PreToolUse, PostToolUse, etc.)

### Marketplace Manifest Structure

The `.claude-plugin/marketplace.json` at the project root defines:
- Marketplace identity (name, version, owner)
- Plugin registry (array of plugin entries with source paths)
- Plugin metadata (categories, tags, component lists)

**Discovery Flow:**
1. API reads `marketplace.json`
2. For each plugin entry, follows `source` path
3. Parses plugin's `plugin.json` manifest
4. Scans component directories (`commands/`, `skills/`, etc.)
5. Indexes metadata for search/retrieval

## Local Development Path

The canonical path to this repository on the development machine is:

```
~/devbox/agentics
```

### Testing Plugins from Any Project Folder

Use the absolute path to load plugins from any working directory:

```bash
# Load a single plugin from anywhere
claude --plugin-dir ~/devbox/agentics/plugins/hello-world

# Load dev-tools (includes format, plan-interview commands + code-review, claude-md-optimizer, plan-interview skills)
claude --plugin-dir ~/devbox/agentics/plugins/dev-tools

# Load multiple plugins simultaneously
claude --plugin-dir ~/devbox/agentics/plugins/hello-world --plugin-dir ~/devbox/agentics/plugins/dev-tools
```

### Register the Marketplace (Persistent)

Register once so plugins are available without specifying paths each time:

```bash
/plugin marketplace add ~/devbox/agentics
/plugin install dev-tools@agentics-kit
```

### Testing from the Repository Root

If you are already in the agentics directory, relative paths also work:

```bash
cd ~/devbox/agentics

# Load a single plugin (starts interactive Claude session)
claude --plugin-dir ./plugins/hello-world

# Once Claude responds in the interactive session, type your commands:
# /hello-world:greet Alice

# Alternative: Provide prompt directly
claude --plugin-dir ./plugins/hello-world "Run /hello-world:greet Alice"

# Load multiple plugins simultaneously (starts interactive session)
claude --plugin-dir ./plugins/hello-world --plugin-dir ./plugins/dev-tools

# Once in the session, use commands from either plugin:
# /hello-world:greet
# /dev-tools:format src/index.ts
# /dev-tools:plan-interview path/to/plan.md
```

**Note:** The `--plugin-dir` flag either starts an interactive Claude Code session where you can type commands, or you can provide a prompt as a command-line argument for direct execution.

### Creating New Example Plugins

Follow the Plugin Structure and Plugin Component Patterns sections below. Then register the plugin in `.claude-plugin/marketplace.json`.

### Registering Plugins in Test Marketplace

After creating a plugin, register it in `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "version": "1.0.0",
      "description": "Brief description",
      "source": "./plugins/my-plugin",
      "category": "development",
      "tags": ["relevant", "tags"]
    }
  ]
}
```

**Version Synchronization:** The plugin's `version` in marketplace.json must match the `version` in the plugin's plugin.json.

## Plugin Component Patterns

### Command Pattern (Explicit Invocation)

Commands use YAML frontmatter + markdown:

```markdown
---
description: Brief description for command list
---

# Command Title

Detailed instructions for Claude.

Access user input via $ARGUMENTS.
Access current directory via $PWD.
```

**Invocation:** `/plugin-name:command-name [arguments]`

### Skill Pattern (Automatic Activation)

Skills use YAML frontmatter with activation criteria:

```markdown
---
name: skill-name
description: Use when the user asks to review code, check for bugs, or analyze quality.
---

# Skill Instructions

Detailed, progressive instructions for Claude.

The description field determines WHEN the skill activates.
The body determines WHAT Claude does when activated.
```

**Activation:** Claude automatically invokes skills when user intent matches the description.

### Progressive Disclosure in Skills

Skills should use progressive disclosure to avoid overwhelming context:

1. **Description** - Simple, clear activation criteria
2. **Summary** - Brief overview of what the skill does
3. **Detailed Instructions** - Step-by-step process with edge cases
4. **Examples** - Concrete demonstrations

See `plugins/dev-tools/skills/code-review/SKILL.md` for a reference implementation.

## Metadata Conventions

### Categories

Standard categories for organizing plugins:
- `development` - Developer tools and utilities
- `productivity` - Workflow and efficiency tools
- `learning` - Educational and tutorial plugins
- `testing` - Testing and QA tools
- `documentation` - Documentation generators
- `security` - Security analysis and auditing

### Tagging Strategy

Tags should be:
- Specific and descriptive
- Searchable terms users would use
- Related to plugin functionality or use case
- Examples: `["formatting", "code-quality", "prettier", "eslint"]`

### Versioning

Use semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR** - Breaking changes to plugin structure or behavior
- **MINOR** - New features, backward compatible
- **PATCH** - Bug fixes, backward compatible

## Test Fixtures

The `tests/fixtures/` directory contains minimal plugins for automated testing:

- `valid-plugin/` - Passes all validation checks (used for success path tests)
- `invalid-plugin/` - Missing required fields (used for error handling tests)

**When to add fixtures:**
- Testing new validation rules
- Reproducing specific error conditions
- Testing edge cases in plugin parsing

Keep fixtures minimal—include only what's necessary for the specific test scenario.

## File Organization Rules

### Plugin README Structure

Each plugin should have a README.md with:
1. **Overview** - What the plugin does
2. **Features** - List of commands/skills
3. **Installation** - How to load the plugin
4. **Usage** - Example invocations
5. **Plugin Structure** - Directory tree
6. **Components** - Detailed component documentation

See `plugins/hello-world/README.md` for minimal example.
See `plugins/dev-tools/README.md` for multi-component example.

### Markdown Formatting

- Commands use backticks: `/plugin:command`
- File paths use backticks: `path/to/file`
- Directory trees use code blocks with no language specifier
- Keep lists simple (no excessive nesting)

## Common Pitfalls

### Plugin Manifest Errors

- ❌ Forgetting required fields (name, version, description)
- ❌ Using invalid semantic version format (must be X.Y.Z)
- ❌ Mismatched versions between plugin.json and marketplace.json

### Component Structure Errors

- ❌ Missing YAML frontmatter in command/skill files
- ❌ Commands without description field
- ❌ Skills without name and description fields
- ❌ Using `.md` extension for anything except markdown files

### Marketplace Configuration Errors

- ❌ Invalid source paths (must be relative or absolute, must exist)
- ❌ Duplicate plugin names in same marketplace
- ❌ Missing marketplace.json in `.claude-plugin/` directory

## Documentation Principles

When creating or modifying plugins:

1. **README First** - Write plugin README before implementing complex features
2. **Command Descriptions** - Keep frontmatter descriptions concise (one sentence)
3. **Skill Activation** - Make skill descriptions clear about WHEN to activate
4. **Examples Matter** - Include concrete usage examples in documentation
5. **Progressive Disclosure** - Start simple, add detail progressively in skills

## Reference Implementations

- **Minimal Plugin:** `plugins/hello-world/` - Single command, basic structure
- **Multi-Component:** `plugins/dev-tools/` - Command + skill working together
- **Marketplace Config:** `.claude-plugin/marketplace.json` - Plugin registry
- **Valid Test Fixture:** `tests/fixtures/valid-plugin/` - Validation reference

## Official Documentation Resources

Always refer to the official Claude Code documentation for the latest information:

- **Main Documentation:** https://code.claude.com/docs/en
- **Plugin Creation:** https://code.claude.com/docs/en/plugins
- **Plugin Reference:** https://code.claude.com/docs/en/plugins-reference
- **Plugin Marketplaces:** https://code.claude.com/docs/en/plugin-marketplaces
- **Discover Plugins:** https://code.claude.com/docs/en/discover-plugins

**Minimum Claude Code Version Required:** 1.0.33 or later (for plugin support)
