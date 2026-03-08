# Plan: Create `agent-creator` Plugin

## Context

The codebase has plugins for skill authoring (`skill-reviewer`) but nothing for agent authoring. Claude Code sub-agents (`agents/*.md` files) are a distinct component type with their own frontmatter schema, tool lists, and configuration. This plugin fills the gap by providing a guided workflow to scaffold agent-based plugins, mirroring how `planning-skills` scaffolds new skills.

Reference: https://code.claude.com/docs/en/sub-agents

## Plugin: `agent-creator` v1.0.0

New plugin at `plugins/agent-creator/` with one skill: `generating-agents`.

## Directory Structure

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

## Implementation Steps

### 1. Create `plugin.json`

Path: `plugins/agent-creator/.claude-plugin/plugin.json`

```json
{
  "name": "agent-creator",
  "version": "1.0.0",
  "description": "Scaffold Claude Code agent-based plugins with guided workflows",
  "author": { "name": "Agentics Project" },
  "license": "MIT",
  "keywords": ["agents", "scaffolding", "plugin-authoring", "code-generation"],
  "homepage": "https://github.com/shawn-sandy/agentics/tree/main/plugins/agent-creator",
  "repository": "https://github.com/shawn-sandy/agentics"
}
```

### 2. Create `SKILL.md`

Path: `plugins/agent-creator/skills/generating-agents/SKILL.md`

- **Frontmatter:** `name: generating-agents`, description triggers on "create an agent", "generate an agent plugin", "scaffold an agent", "add an agent to my plugin", "build a new agent"
- **Pattern:** Sequential/Pipeline (same as `planning-skills`)
- **Steps:**
  - Step 0: Create progress todos
  - Step 1: Determine scope (new plugin vs. add to existing)
  - Step 2: Gather agent requirements (name, purpose, tools, model, advanced features)
  - Step 3: Plan plugin structure (directory tree)
  - Step 4: Draft agent frontmatter (progressive disclosure -- required fields first, advanced optional)
  - Step 5: Draft agent system prompt (role, behavior, workflow, output format, scope boundaries)
  - Step 6: Generate all files (plugin.json, agent .md, README, CHANGELOG)
  - Step 7: Register in marketplace (optional -- update `.claude-plugin/marketplace.json`)

### 3. Create `references/agent-schema.md`

Path: `plugins/agent-creator/skills/generating-agents/references/agent-schema.md`

Documents the complete agent frontmatter schema:
- Required fields: `name`, `description`
- Optional fields: `tools`, `disallowedTools`, `model`, `permissionMode`, `maxTurns`, `skills`, `mcpServers`, `hooks`, `memory`, `background`, `isolation`
- Available tools list (Read, Write, Edit, Bash, Glob, Grep, Agent, NotebookEdit, WebFetch, WebSearch, TodoWrite, AskUserQuestion)
- Model selection guide (sonnet/opus/haiku/inherit)
- Permission modes table
- Two concrete examples (minimal agent + advanced agent with memory/isolation)

### 4. Create `README.md`

Path: `plugins/agent-creator/README.md`

Sections: Overview, Features, Installation, Usage (trigger phrases), Plugin Structure, Components.

### 5. Create `CHANGELOG.md`

Path: `plugins/agent-creator/CHANGELOG.md`

Initial v1.0.0 entry documenting the `generating-agents` skill.

### 6. Update `marketplace.json`

Path: `.claude-plugin/marketplace.json`

Add entry:
```json
{
  "name": "agent-creator",
  "source": "./plugins/agent-creator",
  "version": "1.0.0",
  "description": "Scaffold Claude Code agent-based plugins with guided workflows",
  "category": "development",
  "tags": ["agents", "scaffolding", "plugin-authoring", "code-generation"]
}
```

### 7. Verify version sync

Confirm `plugin.json` version matches `marketplace.json` entry (both `1.0.0`).

## Key Design Decisions

- **Skill name `generating-agents`**: Gerund form per repo convention (`reviewing-skills`, `planning-skills`, `running-tests`)
- **Progressive disclosure in Step 4**: Start with required fields + tools/model, then offer advanced config (memory, hooks, permissions, isolation)
- **Reference file for schema**: Offloads detailed field docs from SKILL.md, keeping the main workflow focused
- **Step 7 is optional**: Not all users will want marketplace registration

## Critical Files

| File | Role |
|------|------|
| `plugins/skill-reviewer/skills/planning-skills/SKILL.md` | Primary pattern to follow |
| `.claude-plugin/marketplace.json` | Must add new plugin entry |
| `plugins/git-agent/.claude-plugin/plugin.json` | Template for plugin.json structure |

## Verification

1. Load plugin: `claude --plugin-dir plugins/agent-creator`
2. Test trigger: "Create a new agent plugin" -- should activate `generating-agents`
3. Test trigger: "Help me scaffold an agent" -- should activate
4. Verify marketplace: `grep -r '"version"' plugins/agent-creator/.claude-plugin/ .claude-plugin/marketplace.json`
5. Walk through the full workflow to generate a test agent plugin
