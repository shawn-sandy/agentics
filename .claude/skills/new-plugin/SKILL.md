---
name: new-plugin
description: Use when the user asks to create a new plugin, scaffold a plugin directory, or add a new plugin to the agentics marketplace. Invoked with /new-plugin <name>.
allowed-tools: Write, Read, Bash, Glob
---

# New Plugin Scaffolding

Scaffold a complete, standards-compliant plugin directory for the agentics marketplace.

## Steps

**1. Determine plugin name** from `$ARGUMENTS`. If none provided, ask the user. Use kebab-case (e.g., `my-plugin`).

**2. Check for conflicts** — verify `plugins/<name>/` does not already exist.

**3. Create this directory structure:**

```
plugins/<name>/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── CHANGELOG.md
└── skills/
    └── <name>/
        └── SKILL.md
```

**4. Create `.claude-plugin/plugin.json`** — NO `version` field (version lives only in `marketplace.json`):

```json
{
  "name": "<name>",
  "description": "<one-line description of what the plugin does>",
  "author": { "name": "Agentics Project" },
  "license": "MIT",
  "keywords": [],
  "homepage": "https://github.com/shawn-sandy/agentics/tree/main/plugins/<name>",
  "repository": "https://github.com/shawn-sandy/agentics"
}
```

**5. Create `skills/<name>/SKILL.md`** with required frontmatter:

```markdown
---
name: <name>
description: Use when the user asks to... [activation criteria written as user intent]
allowed-tools: Read, Grep
---

# <Name> Skill

## Overview

[Describe what this skill does and when it's useful]

## Steps

1. [Step 1]
2. [Step 2]
```

**6. Create `README.md`** — skeleton only, user will fill in details:

```markdown
# <Name> Plugin

<One-line description>

## Skills

- `/<name>` — [what it does]

## Usage

[Usage examples]
```

**7. Create `CHANGELOG.md`** with initial entry using today's date:

```markdown
# Changelog

## [1.0.0] - YYYY-MM-DD

### Added
- Initial release
```

**8. After scaffolding, remind the user:**

- Add an entry to `.claude-plugin/marketplace.json` — version goes here, not in `plugin.json`:
  ```json
  {
    "name": "<name>",
    "source": "./plugins/<name>",
    "version": "1.0.0",
    "description": "<description>",
    "category": "development",
    "tags": []
  }
  ```
- Fill in `keywords`, `description`, `category`, and `tags`
- Run `/validate-plugin <name>` to verify the structure passes all checks
- Homepage URL must point to `/plugins/<name>`, never the repo root

## Critical Conventions

- **No `version` in `plugin.json`** — version belongs only in `marketplace.json` for relative-path plugins; if both declare it, `plugin.json` silently wins, creating a maintenance hazard
- **`allowed-tools` is required** in every `SKILL.md` — restrict to only the tools the skill actually needs
- **Skill descriptions are activation criteria** — write them as "Use when the user asks to..." so Claude knows when to auto-activate
- **Homepage URL format:** `https://github.com/shawn-sandy/agentics/tree/main/plugins/<name>`
