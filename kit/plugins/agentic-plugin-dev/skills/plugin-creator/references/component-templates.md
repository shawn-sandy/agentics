# Component Templates

Starter templates for each Claude Code plugin component type.

## Command Template

**File:** `commands/[name].md`

```markdown
---
description: Brief one-sentence description for the command list
---

# [Command Name]

[Detailed instructions for Claude when this command is invoked.]

## Arguments

Access user input via `$ARGUMENTS`.
Access current directory via `$PWD`.

## Workflow

1. [Step 1]
2. [Step 2]
3. [Step 3]
```

## Skill Template

**File:** `skills/[name]/SKILL.md`

```markdown
---
name: [skill-name]
description: [Third-person description]. Use when the user asks to [trigger phrases]. Does NOT [scope exclusion].
---

## Overview

[1-2 sentences describing what the skill does.]

[Freedom level instruction, e.g., "Follow these steps exactly." or "Follow these steps, adapt as needed."]

## Step 1: [First Step]

[Instructions]

## Step 2: [Second Step]

[Instructions]
```

**Rules:**
- `name`: lowercase, hyphens, ≤64 chars, no `anthropic`/`claude`
- `description`: ≤1,024 chars, third person, includes "Use when..." triggers and "Does NOT..." scope exclusion
- Reference files go in `skills/[name]/references/`

## Agent Template

**File:** `agents/[name].md`

```markdown
---
name: [agent-name]
description: [Third-person description]. Use when the user asks to [trigger phrases]. Does NOT [scope exclusion].
---

## Role

[1-2 sentences defining who the agent is and what it specializes in]

## Behavior

- [How the agent should act]
- [Tone, verbosity, interaction style]

## Workflow

1. [Concrete action with tool usage]
2. [Next action]
3. [Final action]

## Output Format

[What the agent produces — report format, file structure, summary style]

## Scope Boundaries

- **In scope:** [what the agent handles]
- **Out of scope:** [what the agent does NOT handle]
```

**Optional frontmatter fields:** `tools`, `disallowedTools`, `model`, `maxTurns`, `permissionMode`, `isolation`, `background`

## Hooks Template

**File:** `hooks.json` (plugin root)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "[tool-name-pattern]",
        "hooks": [
          {
            "type": "command",
            "command": "[shell command]"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "[tool-name-pattern]",
        "hooks": [
          {
            "type": "command",
            "command": "[shell command]"
          }
        ]
      }
    ]
  }
}
```

**Available events:** `PreToolUse`, `PostToolUse`, `Notification`, `Stop`, `SubAgentStop`

## MCP Server Template

**File:** `.mcp.json` (plugin root)

```json
{
  "mcpServers": {
    "[server-name]": {
      "command": "[executable]",
      "args": ["[arg1]", "[arg2]"],
      "env": {
        "[VAR_NAME]": "[value]"
      }
    }
  }
}
```

## CHANGELOG Template

**File:** `CHANGELOG.md` (plugin root)

Uses [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
# Changelog

All notable changes to this plugin will be documented in this file.

## [1.0.0] - YYYY-MM-DD

### Added

- Initial release
- [Component type]: [name] — [brief description]
```
