# Marketplace Scaffolding Templates

Templates used by the `building-marketplaces` skill when generating files. Derive values from scan data where possible — do not use placeholders when actual data is available.

---

## marketplace.json

Per official schema: https://code.claude.com/docs/en/plugin-marketplaces

**Required fields:** `name`, `owner`, `plugins`
**Optional fields:** `metadata.description`, `metadata.version`, `metadata.pluginRoot`

```json
{
  "name": "<repo-name-kebab-case>",
  "owner": {
    "name": "<from git config user.name or package manifest author>",
    "email": "<from git config user.email — optional>"
  },
  "metadata": {
    "description": "<derived from README first paragraph or package manifest description>"
  },
  "plugins": []
}
```

**Deriving values:**
- `name` — convert repo directory name to kebab-case. If the directory name is generic (e.g., `src`, `app`), use the git remote repo name or package manifest name instead.
- `owner.name` — try in order: package manifest `author.name`, git config `user.name`, prompt user
- `metadata.description` — try in order: package manifest `description`, first non-heading paragraph from README.md, prompt user

**Reserved marketplace names** (Claude Code blocks these):
`claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`

Names that impersonate official marketplaces (e.g., `official-claude-plugins`, `anthropic-tools-v2`) are also blocked.

---

## Plugin Entry

Required fields: `name`, `source`. All other fields are optional.

```json
{
  "name": "<plugin-name-kebab-case>",
  "source": "./plugins/<plugin-name>",
  "description": "<brief description of what the plugin does>",
  "version": "<semver — only set here for relative-path plugins>",
  "category": "<category>",
  "tags": ["<searchable>", "<terms>"]
}
```

**Standard categories:**
- `development` — developer tools and utilities
- `productivity` — workflow and efficiency tools
- `learning` — educational and tutorial plugins
- `testing` — testing and QA tools
- `documentation` — documentation generators
- `security` — security analysis and auditing

**Version placement rule:** Do not set version in both `plugin.json` and `marketplace.json` for the same plugin. For relative-path plugins, set version in the marketplace entry only. For external sources (github, npm, etc.), set version in `plugin.json` only.

### Plugin Source Types

When scaffolding, default to relative path. Mention alternatives if the user's plugins are in separate repositories.

| Source | Format | When to use |
|--------|--------|-------------|
| Relative path | `"./plugins/name"` | Plugin in same repo as marketplace (default) |
| GitHub | `{"source": "github", "repo": "owner/repo"}` | Plugin in a separate GitHub repo |
| Git URL | `{"source": "url", "url": "https://host.com/repo.git"}` | Plugin on GitLab, Bitbucket, or self-hosted git |
| Git subdirectory | `{"source": "git-subdir", "url": "...", "path": "tools/plugin"}` | Plugin inside a monorepo subdirectory |
| npm | `{"source": "npm", "package": "@org/plugin"}` | Plugin published to npm registry |
| pip | `{"source": "pip", "package": "plugin-name"}` | Plugin published to PyPI |

All non-relative sources support optional `ref` (branch/tag) and `sha` (exact commit) for pinning.

---

## plugin.json

Required fields: `name`, `description`, `version`.

```json
{
  "name": "<plugin-name>",
  "description": "<what this plugin does>",
  "version": "<semver — only set here for external-source plugins>",
  "author": { "name": "<author name>" },
  "license": "MIT",
  "keywords": ["<searchable>", "<terms>"],
  "homepage": "<url to plugin directory in repo>",
  "repository": "<repo url>"
}
```

**Homepage convention:** Point to the plugin's specific directory, not the repo root.
Example: `https://github.com/owner/repo/tree/main/plugins/my-plugin`

---

## Plugin Directory Structure

```
plugins/<plugin-name>/
  .claude-plugin/
    plugin.json              # Plugin manifest (required)
  skills/
    <skill-name>/
      SKILL.md               # Skill definition (required for skills)
      references/             # Progressive disclosure files (optional)
  commands/                   # Command files (optional)
    <command-name>.md
  README.md                  # Plugin documentation
  CHANGELOG.md               # Version history
```

**Naming rules:**
- Plugin directory: kebab-case
- Skill directory: kebab-case, gerund form preferred (e.g., `building-marketplaces`)
- SKILL.md: exact casing, uppercase
- References: one level deep only (no `references/sub/file.md`)

---

## SKILL.md Stub

```markdown
---
name: <skill-name-kebab-case>
description: <Describe what this skill does in third person. Include "Use when..." trigger phrases listing specific user intents. State what this skill does NOT cover.>
---

## Overview

<Brief description of what this skill does and who it's for.>

## Steps

1. **Step 1** — <description>
2. **Step 2** — <description>
3. **Step 3** — <description>
```

**SKILL.md frontmatter rules:**
- `name`: kebab-case, lowercase + numbers + hyphens only, max 64 chars, must not contain `anthropic` or `claude`
- `description`: max 1024 chars, third person (no "I", "you", "we"), must include "Use when..." trigger phrase

---

## CLAUDE.md Stub

Generate a minimal stub with section headings and TODO placeholders. Do not fill in content — defer to `claude-md-optimizer` for quality optimization.

```markdown
# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

<!-- TODO: Describe the project's purpose and scope -->

## Tech Stack

<!-- TODO: List languages, frameworks, and key dependencies -->

## Repository Structure

<!-- TODO: Document key directories and their purposes -->

## Common Commands

<!-- TODO: List build, test, lint, and dev server commands -->

## Conventions

<!-- TODO: Document naming patterns, code style, and project-specific rules -->
```

---

## Starter .claude/rules/ Files

### plugin-patterns.md

```markdown
# Plugin Authoring Conventions

## Plugin Structure

- Each plugin lives in `plugins/<name>/` with its own `.claude-plugin/plugin.json`
- Skills go in `skills/<skill-name>/SKILL.md` (SKILL.md must be uppercase)
- Commands go in `commands/<command-name>.md`
- Skill folders use kebab-case naming; gerund form preferred for skill names

## SKILL.md Rules

- YAML frontmatter with `name` and `description` is required
- `name` must be kebab-case, max 64 characters
- `description` must be third person, max 1024 characters, include "Use when..." triggers
- Body should be under 500 lines; offload detail to `references/` files
- Reference files must be one level deep (no subdirectories)

## Plugins Are Copied

Plugins are copied to a cache directory when installed. Do not reference files outside the plugin directory with `../` paths. Use symlinks if sharing files across plugins.
```

### marketplace.md

```markdown
# Marketplace Configuration

## Version Synchronization

- For relative-path plugins: set version in the marketplace entry only
- For external-source plugins: set version in plugin.json only
- Never set version in both places — plugin.json always wins silently

## Plugin Entries

Required fields per plugin: `name` (kebab-case), `source`
Recommended fields: `description`, `version`, `category`, `tags`

## Validation

Run `claude plugin validate .` or `/plugin validate .` to check:
- JSON syntax validity
- Required fields present
- No duplicate plugin names
- No path traversal in source paths
```

---

## Team Distribution (optional)

`.claude/settings.json` for auto-prompting team members to install the marketplace:

```json
{
  "extraKnownMarketplaces": {
    "<marketplace-name>": {
      "source": {
        "source": "github",
        "repo": "<owner>/<repo>"
      }
    }
  }
}
```

This can also specify default-enabled plugins:

```json
{
  "enabledPlugins": {
    "<plugin-name>@<marketplace-name>": true
  }
}
```
