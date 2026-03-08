# Plan: Create README for agent-creator Plugin

## Context

The `plugins/agent-creator/` plugin (v1.0.0) is missing a README.md. Per `plugin-patterns.md`, every plugin must have a README with overview, features, installation, usage, structure, and component documentation. This plan covers creating that README.

## Steps

1. **Create `plugins/agent-creator/README.md`** following the established README pattern (see `plugins/code-testing-agent/README.md` as style reference)

## README Sections

1. **Title + overview** - What the plugin does (scaffold Claude Code agents via guided workflow)
2. **Purpose** - Why this plugin exists (agent authoring is complex; this automates frontmatter, tool selection, prompt structure, and marketplace registration)
3. **Components table** - Single skill: `generating-agents` with activation triggers
4. **Usage examples** - Natural-language triggers that activate the skill
5. **What the skill does** - 6-step workflow summary (scope, requirements, frontmatter, generation, validation, marketplace)
6. **Key features** - Tool presets, progressive disclosure, validation, conflict detection
7. **Installation** - Marketplace install + local loading
8. **Plugin structure** - Directory tree
9. **References** - Link to `agent-schema.md`

## Files to Create/Modify

- **Create:** `plugins/agent-creator/README.md`

## Verification

1. Confirm README follows the same structure as other plugin READMEs (code-testing-agent, git-agent)
2. Confirm all factual details match `plugin.json`, `SKILL.md`, and `agent-schema.md`
3. Confirm installation commands use correct plugin name and marketplace name
