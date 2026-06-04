# Create `agent-creator` Plugin

> New plugin that guides developers through scaffolding Claude Code sub-agent plugins with a 7-step sequential workflow, filling the gap left by `skill-reviewer` which only covers skill authoring.

<!-- generated:start -->

**Status:** Shipped 2026-03-08   **Plan:** [agent-creator-plugin.md](plans/agent-creator-plugin.md)   **Type:** standard

## What shipped

- New `agent-creator` plugin at `kit/plugins/agent-creator/` with a single `generating-agents` skill.
- 7-step guided scaffolding workflow: determine scope (new plugin vs. add to existing), gather requirements, plan structure, draft frontmatter, draft system prompt, generate files, optionally register in marketplace.
- Reference file `references/agent-schema.md` documents the complete agent frontmatter schema (required and optional fields), tool selection guide, model selection (sonnet/opus/haiku/inherit), permission modes, and two concrete examples.
- Curated tool presets (read-only, full-access, code-editor) with customization.
- Conflict detection for "add to existing plugin" workflow.
- Plugin registered in `.claude-plugin/marketplace.json` at `v1.0.0`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/agent-creator/skills/generating-agents/SKILL.md` | Skill instructions — generating-agents | Created |
| `kit/plugins/agent-creator/skills/generating-agents/references/agent-schema.md` | Agent frontmatter schema reference | Created |
| `kit/plugins/agent-creator/.claude-plugin/plugin.json` | Plugin manifest v1.0.0 | Created |
| `kit/plugins/agent-creator/README.md` | Plugin documentation | Created |
| `kit/plugins/agent-creator/CHANGELOG.md` | Version history | Created |
| `.claude-plugin/marketplace.json` | Marketplace registry — new plugin entry | Modified |

## How it works

The skill starts by asking whether the user wants to create a new plugin or add an agent to an existing one. For new plugins it scaffolds the full directory structure; for existing plugins it checks for name conflicts before writing.

Requirements gathering (Step 2) collects the agent name, purpose, tools needed, model preference, and whether advanced features (memory, hooks, permissions, isolation) are needed. Progressive disclosure in Step 4 presents required fields first (`name`, `description`, `tools`, `model`) and defers advanced options to a follow-up prompt.

The system prompt template (Step 5) follows a structured format: Role, Behavior, Workflow, Output Format, and Scope Boundaries. This mirrors the format used by `code-reviewer` and other agents in the repo.

Step 6 generates all files: `plugin.json` (no version field — set in marketplace.json for relative-path plugins), the agent `.md` file, `README.md`, and `CHANGELOG.md`. Each file is shown for confirmation before writing. Step 7 optionally registers the plugin in `marketplace.json` — the step is conditional, only offered if a marketplace.json exists in the project.

The `agent-schema.md` reference covers all 13 optional agent frontmatter fields, documents the 7 valid `permissionMode` values, and includes a minimal example (5 fields) and a full advanced example (memory, isolation, hooks).

## How to use it

**Skill activation** — triggers on "create an agent", "scaffold an agent", "add an agent to my plugin", "build a new agent":

```bash
claude --plugin-dir ./kit/plugins/agent-creator
```

Then say: "Create a new agent plugin called my-analyzer"

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |
| `9924d3f` | 2026-04-09 | refactor(kit/plugins): trim allowed-tools to only tools each skill actually uses |

<!-- generated:end -->

## References

- Plan: [agent-creator-plugin.md](plans/agent-creator-plugin.md)
- Official sub-agent docs: https://code.claude.com/docs/en/sub-agents
