# agent-creator Plugin

Scaffold Claude Code agent-based plugins with a guided workflow. Instead of manually writing agent frontmatter, choosing tools, and structuring system prompts, describe what you want and the skill walks you through every step — from requirements gathering to marketplace registration.

## Installation

### Via Marketplace (recommended)

```bash
/plugin install agent-creator@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ./kit/plugins/agent-creator
```

## Usage

### Components

| Component | Type | Activation |
|-----------|------|-----------|
| `generating-agents` | Skill | Auto-activated — triggers when user asks to "create an agent", "generate an agent plugin", "scaffold an agent", "add an agent to my plugin", "build a new agent", or "make a sub-agent" |

All skills declare `allowed-tools` explicitly in their frontmatter for consistent, session-independent tool access.

The skill activates automatically when your message matches the trigger phrases. Just describe what you need:

```
Create an agent that reviews pull requests for security issues
Scaffold a new agent plugin for running database migrations
Add an agent to my existing plugin that formats markdown files
Build a sub-agent for analyzing test coverage
Generate an agent that audits accessibility compliance
```

The skill then guides you through an interactive 6-step workflow using structured questions — you don't need to know the agent schema upfront.

## Purpose

Authoring a Claude Code agent involves several interconnected decisions: naming conventions, tool allow-lists, permission modes, model selection, and a well-structured system prompt. Getting any of these wrong causes silent failures or unexpected behavior. This plugin encodes the official agent schema into a step-by-step workflow that produces valid, ready-to-use agent files — either as a new plugin or added to an existing one.

## What the Skill Does

### Step 1: Determine Scope

Asks whether to create a new plugin or add an agent to an existing one. For existing plugins, it detects current agents and checks for naming conflicts.

### Step 2: Gather Requirements

Asks up to 4 targeted questions about the agent's purpose, triggers, tool needs, and expected output. Presents curated tool presets:

| Preset | Tools | Best For |
|--------|-------|----------|
| **Read-Only** | Read, Glob, Grep, WebFetch, WebSearch | Reviewers, explorers, auditors |
| **Code Editor** | Read, Write, Edit, Glob, Grep, NotebookEdit | Formatters, refactoring tools |
| **Full Access** | All tools | Build agents, test runners, deployment |
| **Custom** | User-specified | Specialized use cases |

### Step 3: Draft Frontmatter

Generates the required `name` and `description` fields, then offers optional configuration via progressive disclosure:

- **Model** — sonnet, opus, haiku, or inherit (default)
- **Max turns** — conversation turn limit
- **Permission mode** — default, acceptEdits, bypassPermissions, planMode, inherit
- **Isolation** — git worktree isolation for safety
- **Background** — run as a background agent

Presents the complete frontmatter for confirmation before proceeding.

### Step 4: Generate Files

Creates all plugin files with a structured system prompt containing Role, Behavior, Workflow, Output Format, and Scope Boundaries sections.

**New plugin:** `plugin.json` + `agents/[name].md` + `CHANGELOG.md`

**Existing plugin:** `agents/[name].md` + updated `CHANGELOG.md`

### Step 5: Validate

Runs automated checks on the generated files:

- Name format (lowercase, hyphens, no reserved substrings)
- Description length and trigger phrase presence
- Tool list validity and mutual exclusion rules
- YAML frontmatter syntax
- Plugin.json required fields
- Agent body section completeness

Fixes issues automatically and re-validates.

### Step 6: Marketplace Registration

If a `marketplace.json` exists in the project root, offers to register the new plugin with version synchronization between `plugin.json` and the marketplace entry.

## Plugin Structure

```
plugins/agent-creator/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   └── generating-agents/
│       ├── SKILL.md
│       └── references/
│           └── agent-schema.md
├── README.md
└── CHANGELOG.md
```

## References

The skill includes a complete agent schema reference at `skills/generating-agents/references/agent-schema.md` covering:

- All required and optional frontmatter fields
- Tool presets with exact tool lists
- Model selection guide
- Permission mode descriptions
- File placement conventions
- 12-point validation checklist
