---
name: plugin-creator
description: "Scaffolds a complete Claude Code plugin from scratch. Generates manifest, commands, skills, and agents for selected component types. Use when the user asks to create or scaffold a new plugin."
allowed-tools: AskUserQuestion, ExitPlanMode, Glob, Read, ToolSearch, Write
---

## Overview

Walks users through a structured workflow to scaffold a complete Claude Code plugin — producing a ready-to-use plugin directory with manifest, components, and changelog.

Follow these steps exactly.

## When not to use

Does not scaffold individual skills (use skill-reviewer:planning-skills), individual agents (use agent-creator), or marketplace infrastructure (use marketplace-builder).

## Table of Contents

- [Step 0: Exit Plan Mode](#step-0-exit-plan-mode)
- [Step 1: Disambiguation](#step-1-disambiguation)
- [Step 2: Gather Plugin Requirements](#step-2-gather-plugin-requirements)
- [Step 3: Gather Component Details](#step-3-gather-component-details)
- [Step 4: Generate Plugin Manifest](#step-4-generate-plugin-manifest)
- [Step 5: Generate Plugin Files](#step-5-generate-plugin-files)
- [Step 6: Register in Marketplace](#step-6-register-in-marketplace)

---

## Step 0: Exit Plan Mode

Call `ExitPlanMode` immediately and silently — always, unconditionally, before
any other action. Do not prompt the user. Plugin scaffolding writes
files and directories, which requires exiting plan mode.

`ExitPlanMode` is a deferred tool whose schema must be loaded before it can be
called. Use `ToolSearch` with `select:ExitPlanMode` first, then call
`ExitPlanMode`. Both steps happen silently with no user-visible output.

**Error handling:** If `ExitPlanMode` returns the exact error `"You are not in plan mode"`, treat that as **success** — plan mode was already off. Do not abort or surface the error to the user; continue to the next step.

---

## Step 1: Disambiguation

Before proceeding, check if the user's intent is ambiguous. If the request could mean something other than creating a full plugin, clarify:

- **"scaffold a skill"** or **"create a skill"** — Ask: "Do you want to create a full plugin with a skill, or just add a skill to an existing plugin? For adding a single skill, try `skill-reviewer:planning-skills`."
- **"create an agent"** or **"scaffold an agent"** — Ask: "Do you want a full plugin containing an agent, or just add an agent to an existing plugin? For adding a single agent, try `agent-creator`."
- **"set up a marketplace"** — Redirect: "For marketplace infrastructure, use `marketplace-builder` instead."

If the user clearly wants a full plugin, proceed to Step 2.

---

## Step 2: Gather Plugin Requirements

Ask the user up to 4 questions using `AskUserQuestion` to understand the plugin they want. Skip questions already answered.

**Questions to consider (pick the most relevant):**

1. **Plugin name** — "What should the plugin be called?" Validate: lowercase, hyphens only, no `anthropic` or `claude` substrings.
2. **Purpose** — "What does this plugin do? One sentence."
3. **Components** — "Which components does this plugin need?" Present options:
   - **Commands** — Explicit invocation via `/plugin:command`
   - **Skills** — Auto-activated by user intent
   - **Agents** — Autonomous sub-processes
   - **Hooks** — Event-driven triggers (pre/post tool execution)
   - **MCP servers** — External tool integrations
4. **Target directory** — Default to `plugins/[name]/`. Confirm with user.

After gathering answers, summarize:

```
**Plugin concept:**
- Name: [name]
- Purpose: [description]
- Components: [list]
- Location: plugins/[name]/
```

---

## Step 3: Gather Component Details

For each component type selected in Step 2, gather specifics:

### Commands

For each command:
- Name (kebab-case)
- One-sentence description (for frontmatter)
- Whether it accepts `$ARGUMENTS`

### Skills

For each skill:
- Name (kebab-case)
- Description with trigger phrases ("Use when...")
- Design pattern: sequential, adaptive, or orchestrator
- Whether it needs reference files

### Agents

For each agent:
- Name (kebab-case)
- Description with trigger phrases
- Tool preset: Read-Only, Code Editor, Full Access, or Custom
- Model preference: sonnet/opus/haiku/inherit

### Hooks

For each hook:
- Event trigger (e.g., PreToolUse, PostToolUse)
- Matcher pattern
- Shell command to execute

### MCP Servers

For each server:
- Server name
- Command and args to launch it
- Environment variables needed

Present the complete component plan for confirmation before proceeding.

---

## Step 4: Generate Plugin Manifest

Generate `plugin.json` using the schema from `references/plugin-json-schema.md`.

**Rules:**
- `name` is required
- Do NOT include `version` (relative-path convention — version lives in `marketplace.json` only)
- Include `description`, `author`, `license`, `keywords`, `homepage`, `repository`
- Homepage format: `https://github.com/[owner]/[repo]/tree/main/plugins/[name]`

Present the manifest for confirmation:

> "Here's the plugin manifest. Should I proceed?"

```json
{
  "name": "[name]",
  "description": "[description]",
  ...
}
```

---

## Step 5: Generate Plugin Files

After the user confirms, show the full file list before writing:

> "I'll generate the following files at `plugins/[name]/`:
> - `.claude-plugin/plugin.json`
> - [list all component files]
> - `CHANGELOG.md`
>
> Should I proceed?"

### File Generation Order

Write files sequentially using templates from `references/component-templates.md`:

1. `.claude-plugin/plugin.json` — Plugin manifest (from Step 4)
2. Component files in order: commands, skills, agents, hooks, MCP servers
3. `CHANGELOG.md` — Initial entry using [Keep a Changelog](https://keepachangelog.com/) format

**For each component type:**

- **Commands:** `commands/[name].md` with YAML frontmatter + markdown body
- **Skills:** `skills/[name]/SKILL.md` with YAML frontmatter + structured body. Create `references/` subdirectory if the skill needs reference files
- **Agents:** `agents/[name].md` with YAML frontmatter + system prompt body
- **Hooks:** `hooks.json` at plugin root
- **MCP servers:** `.mcp.json` at plugin root

**Error handling:** If any file write fails, report which files succeeded and which failed. Do not stop on first failure.

**Undo guidance:** After all files are written, inform the user: "To undo, remove the `plugins/[name]/` directory or run `git checkout` to revert."

---

## Step 6: Register in Marketplace

This step is **conditional** — only offer when a `marketplace.json` file exists.

1. Use `Glob` to check for `.claude-plugin/marketplace.json` in the project root
2. If not found, skip: "No marketplace.json found — skipping marketplace registration. You can register later with `plugin-manager`."
3. If found, read it and ask: "Would you like to register this plugin in the marketplace?"

If the user confirms:

1. Read the existing `marketplace.json`
2. **Check for duplicate names** — if a plugin with the same name exists, warn and ask whether to overwrite or choose a different name
3. **Confirm marketplace identity** — "This marketplace is `[name]` v[version]. Register here?"
4. Add entry to the `plugins` array:
   ```json
   {
     "name": "[plugin-name]",
     "source": "./plugins/[plugin-name]",
     "version": "1.0.0",
     "description": "[from plugin.json]",
     "category": "[ask user or infer]",
     "tags": ["relevant", "tags"]
   }
   ```
5. Write the updated `marketplace.json`

### Final Summary

After all steps, present:

```
## Plugin Created

**Location:** plugins/[name]/
**Components:** [count] commands, [count] skills, [count] agents
**Marketplace:** [registered/not registered]

**Files created:**
- [list with line counts]

**Next steps:**
1. Load the plugin: `claude --plugin-dir ./plugins/[name]`
2. Test each component
3. Refine descriptions and instructions as needed
```
