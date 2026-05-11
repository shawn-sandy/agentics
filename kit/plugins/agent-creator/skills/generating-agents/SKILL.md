---
name: generating-agents
description: "Use when the user asks to create, scaffold, or generate an agent or sub-agent in a plugin. Scaffolds frontmatter, tool selection, system prompt, and files."
allowed-tools: AskUserQuestion, Edit, Glob, Read, Write
---

## Overview

Walks users through a structured workflow to scaffold a complete Claude Code agent — either as a new plugin or added to an existing one. Produces ready-to-use agent `.md` files with frontmatter and system prompt.

Follow these steps exactly.

## When not to use

Does not review existing agents — use agent-reviewer for that.

## Table of Contents

- [Step 1: Determine Scope](#step-1-determine-scope)
- [Step 2: Gather Agent Requirements](#step-2-gather-agent-requirements)
- [Step 3: Draft Agent Frontmatter](#step-3-draft-agent-frontmatter)
- [Step 4: Generate Agent and Plugin Files](#step-4-generate-agent-and-plugin-files)
- [Step 5: Validate Generated Files](#step-5-validate-generated-files)
- [Step 6: Register in Marketplace](#step-6-register-in-marketplace)

---

## Step 1: Determine Scope

Ask the user whether they want to create a new plugin with an agent or add an agent to an existing plugin. Use `AskUserQuestion` with these options:

1. **New plugin** — Scaffold a complete plugin directory with the agent
2. **Add to existing plugin** — Add an agent to a plugin that already exists

### New Plugin Path

If the user selects "new plugin", confirm the target directory:

> "I'll create the plugin at `plugins/[plugin-name]/`. Should I proceed?"

If no `.claude-plugin/` directory would exist at the target, inform the user that one will be created and ask for confirmation before proceeding.

### Add to Existing Plugin Path

If the user selects "add to existing", ask which plugin to target. Then:

1. Use `Glob` to check for an existing `agents/` directory in the target plugin
2. If `agents/` exists, use `Glob` to list existing agent files (`agents/*.md`)
3. Present the list to the user: "This plugin already has these agents: [list]. I'll add the new agent alongside them."
4. **Conflict detection:** After gathering the agent name in Step 2, check if an agent file with the same name already exists. If it does, warn the user and ask whether to overwrite or choose a different name.

---

## Step 2: Gather Agent Requirements

Ask the user up to 4 questions using `AskUserQuestion` to understand what agent they want to build. Tailor questions to what the user has already provided — skip questions they have already answered.

**Questions to consider (pick the most relevant):**

1. **What does the agent do?** — "What task or workflow should this agent handle autonomously?"
2. **What triggers it?** — "When should this agent be invoked? What would a user say?" (helps draft the description)
3. **What tools does it need?** — Present the curated presets from `references/agent-schema.md`:
   - **Read-Only** — Read, Glob, Grep, WebFetch, WebSearch (for reviewers, explorers, auditors)
   - **Code Editor** — Read, Write, Edit, Glob, Grep, NotebookEdit (for formatters, refactoring)
   - **Full Access** — All tools (for build agents, test runners, deployment)
   - **Custom** — User specifies individual tools
4. **What is the expected output?** — "What does the user receive when the agent finishes? (report, modified files, summary, generated code)"

After gathering answers, summarize:

```
**Agent concept:**
- Purpose: [what it does]
- Trigger: [when it's invoked]
- Tool preset: [preset name] + [any customizations]
- Output: [what the user gets]
```

---

## Step 3: Draft Agent Frontmatter

Generate the agent frontmatter using the requirements from Step 2 and the schema in `references/agent-schema.md`.

**Required fields first (always generate):**

```yaml
---
name: [agent-name]
description: [agent-description with trigger phrases]
---
```

**Name rules:**
- Lowercase letters, numbers, hyphens only
- ≤64 characters
- Must not contain `anthropic` or `claude` as substring
- Use kebab-case matching the intended file name

**Description rules:**
- ≤1,024 characters
- Third person (no "I", "you", "we", "your")
- Must contain trigger phrases ("Use when...")
- Include scope exclusion ("Does NOT...")

**Then offer optional fields via progressive disclosure:**

After presenting the required fields, ask the user if they want to configure advanced options using `AskUserQuestion` with `multiSelect: true`:

- **Model** — Choose sonnet/opus/haiku/inherit (default: inherit)
- **Max turns** — Limit conversation turns (default: 25)
- **Permission mode** — default/acceptEdits/bypassPermissions/planMode/inherit
- **Isolation** — Run in a git worktree for safety
- **Background** — Run as a background agent

Only add fields the user explicitly selects. Present the complete frontmatter for confirmation before proceeding.

---

## Step 4: Generate Agent and Plugin Files

After the user confirms the frontmatter, generate all files. This step combines system prompt drafting with file generation — the prompt is written directly into the agent file.

### System Prompt Structure

Generate a structured system prompt for the agent body using this template:

```markdown
## Role

[1-2 sentences defining who the agent is and what it specializes in]

## Behavior

- [Bullet points describing how the agent should act]
- [Include tone, verbosity, and interaction style]

## Workflow

1. [Numbered steps the agent follows]
2. [Each step should be a concrete action]
3. [Include tool usage where relevant]

## Output Format

[Describe what the agent produces — report format, file structure, summary style]

## Scope Boundaries

- **In scope:** [what the agent handles]
- **Out of scope:** [what the agent does NOT handle — redirect to other tools/agents]
```

Fill in the template based on the requirements gathered in Step 2. Each section should be specific to the agent being created, not generic.

### File Generation Order

**For new plugins:**

1. Create `.claude-plugin/plugin.json` with plugin metadata
2. Create `agents/[agent-name].md` with frontmatter + system prompt
3. Create `CHANGELOG.md` with initial v1.0.0 entry

**For adding to existing plugins:**

1. Create `agents/` directory if it doesn't exist
2. Create `agents/[agent-name].md` with frontmatter + system prompt
3. Update `CHANGELOG.md` with the new agent entry (create if missing)

**Before writing files, confirm:**

> "I'll generate the following files at `[path]`:
> - `[list of files]`
>
> Should I proceed?"

---

## Step 5: Validate Generated Files

After generating files, run these validation checks:

### Frontmatter Validation

1. **Name check:** Verify the agent name is lowercase, hyphenated, ≤64 chars, and doesn't contain `anthropic` or `claude`
2. **Description check:** Verify the description is ≤1,024 chars and contains trigger phrases
3. **Tools check:** If `tools` is set, verify every entry is from the allowed tools list (see `references/agent-schema.md` Full Access preset)
4. **Mutual exclusion:** Verify that `tools` and `disallowedTools` are not both set
5. **Model check:** If `model` is set, verify it's one of: `sonnet`, `opus`, `haiku`, `inherit`
6. **Permission check:** If `permissionMode` is set, verify it's one of: `default`, `acceptEdits`, `bypassPermissions`, `planMode`, `inherit`

### Structure Validation

1. **YAML validity:** Read the generated agent file and verify the frontmatter parses correctly
2. **Plugin.json check:** Verify `.claude-plugin/plugin.json` exists and contains required fields (`name`, `version`, `description`)
3. **Body check:** Verify the agent body contains at least a Role and Workflow section

### Report Results

Present a validation summary:

```
## Validation Results

- [PASS/FAIL] Agent name: [name]
- [PASS/FAIL] Description length: [length]/1024
- [PASS/FAIL] Tools: [list or "default (all)"]
- [PASS/FAIL] YAML frontmatter: valid/invalid
- [PASS/FAIL] Plugin.json: present/missing
- [PASS/FAIL] Agent body: [sections found]
```

If any checks fail, fix the issues automatically and re-validate.

---

## Step 6: Register in Marketplace

This step is **conditional** — only offer it when a `marketplace.json` file exists.

1. Use `Glob` to check for `.claude-plugin/marketplace.json` in the project root
2. If it does not exist, skip this step and inform the user: "No marketplace.json found — skipping marketplace registration. You can add one later."
3. If it exists, ask the user: "Would you like to register this agent plugin in the marketplace?"

If the user confirms:

1. Read the existing `marketplace.json`
2. Add a new entry to the `plugins` array:
   ```json
   {
     "name": "[plugin-name]",
     "source": "./plugins/[plugin-name]",
     "version": "1.0.0",
     "description": "[plugin description from plugin.json]",
     "category": "development",
     "tags": ["agents", "relevant-tags"]
   }
   ```
3. **Version sync:** Ensure the `version` in the marketplace entry matches the `version` in `plugin.json` exactly
4. Write the updated `marketplace.json`

After all steps complete, present a final summary:

```
## Agent Created

**Location:** `[path]/agents/[agent-name].md`
**Plugin:** `[plugin-name]` v[version]
**Tools:** [preset name] ([tool count] tools)
**Model:** [model or "inherit"]

**Files created/modified:**
- [list of files with line counts]

**Next steps:**
1. Load the plugin: `claude --plugin-dir [plugin-path]`
2. Test by asking Claude something that matches the trigger description
3. Review and refine the system prompt as needed
```
