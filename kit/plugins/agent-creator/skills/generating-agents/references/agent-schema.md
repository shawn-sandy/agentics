# Agent Frontmatter Schema Reference

Official docs: <https://code.claude.com/docs/en/sub-agents>

This reference documents the complete YAML frontmatter schema for Claude Code agent `.md` files. Agents are placed in `agents/` directories within a plugin.

## Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Agent identifier. Lowercase, hyphens, ≤64 chars. Must not contain `anthropic` or `claude`. |
| `description` | string | What the agent does and when to use it. ≤1,024 chars. Include trigger phrases. |

## Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `tools` | string[] | all | Allow-list of tools the agent can use. |
| `disallowedTools` | string[] | none | Deny-list of tools. Use instead of `tools` when you want most tools but need to block a few. |
| `model` | string | inherit | Model to use: `sonnet`, `opus`, `haiku`, or `inherit` (uses parent's model). |
| `permissionMode` | string | inherit | One of: `default`, `acceptEdits`, `bypassPermissions`, `planMode`, `inherit`. |
| `maxTurns` | number | 25 | Maximum conversation turns before the agent stops. |
| `skills` | string[] | none | List of skill names the agent can invoke. |
| `mcpServers` | object | none | MCP server configurations available to the agent. |
| `hooks` | object | none | Event-driven hooks (pre/post tool execution). |
| `memory` | boolean | false | Whether the agent has persistent memory across invocations. |
| `background` | boolean | false | Whether the agent runs in the background. |
| `isolation` | string | none | Set to `"worktree"` to run in an isolated git worktree. |

## Tool Presets

Use these presets as starting points. Customize by adding or removing individual tools.

### Read-Only

For agents that analyze code without modifying it (reviewers, explorers, auditors).

```yaml
tools:
  - Read
  - Glob
  - Grep
  - WebFetch
  - WebSearch
```

### Code Editor

For agents that read and modify files but don't run commands (formatters, refactoring agents).

```yaml
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - NotebookEdit
```

### Full Access

For agents that need complete control (build agents, deployment agents, test runners).

```yaml
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Agent
  - NotebookEdit
  - WebFetch
  - WebSearch
  - TodoWrite
  - AskUserQuestion
```

### Deny-List Alternative

When you want most tools but need to block a few, use `disallowedTools` instead of `tools`:

```yaml
# Allow everything except Bash and Agent (safe for untrusted contexts)
disallowedTools:
  - Bash
  - Agent
```

**Rule of thumb:** Use `tools` (allow-list) when the agent needs ≤6 tools. Use `disallowedTools` (deny-list) when the agent needs most tools but should be blocked from 1-3 specific ones.

## Model Selection Guide

| Model | Best For | Trade-off |
|-------|----------|-----------|
| `sonnet` | Most agents — good balance of speed and capability | Fast, cost-effective |
| `opus` | Complex reasoning, architecture decisions, nuanced analysis | Slower, more capable |
| `haiku` | Simple, high-volume tasks (formatting, classification) | Fastest, least capable |
| `inherit` | Use parent conversation's model | No overhead, follows user's choice |

Default to `inherit` unless the agent's task demands a specific capability level.

## Permission Modes

| Mode | Description |
|------|-------------|
| `default` | Normal permission prompting — user approves each action |
| `acceptEdits` | Auto-approve file edits, prompt for other actions |
| `bypassPermissions` | Skip all permission prompts (use with caution) |
| `planMode` | Read-only mode — agent can explore but not modify |
| `inherit` | Use parent conversation's permission mode |

## Examples

### Minimal Agent

```yaml
---
name: code-explorer
description: Explores and analyzes codebase structure, dependencies, and patterns. Use when the user asks to understand, map, or document how code is organized.
---
```

Body follows with the agent's system prompt instructions.

### Full-Featured Agent

```yaml
---
name: test-runner
description: Runs test suites, reports results, and suggests fixes for failures. Use when the user asks to run tests, check coverage, or debug failing tests.
tools:
  - Read
  - Glob
  - Grep
  - Bash
  - TodoWrite
model: sonnet
maxTurns: 15
isolation: worktree
---
```

### Agent with Deny-List

```yaml
---
name: security-auditor
description: Audits code for security vulnerabilities, dependency risks, and OWASP top 10 issues. Use when the user asks to review security, check for vulnerabilities, or audit dependencies.
disallowedTools:
  - Bash
  - Write
  - Edit
model: opus
permissionMode: planMode
---
```

## Agent File Placement

Agents live in the `agents/` directory of a plugin:

```
plugins/my-plugin/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── my-agent.md
│   └── another-agent.md
├── skills/
│   └── ...
└── CHANGELOG.md
```

Multiple agents can coexist in one plugin. Each `.md` file in `agents/` is a separate agent.

## Validation Checklist

After generating an agent, verify:

- [ ] `name` is lowercase, hyphenated, ≤64 chars, no `anthropic`/`claude` substring
- [ ] `description` is ≤1,024 chars and includes trigger phrases
- [ ] `tools` entries are from the allowed tools list (see Full Access preset)
- [ ] `disallowedTools` and `tools` are not both set (mutually exclusive)
- [ ] `model` is one of: `sonnet`, `opus`, `haiku`, `inherit`, or omitted
- [ ] `permissionMode` is one of: `default`, `acceptEdits`, `bypassPermissions`, `planMode`, `inherit`, or omitted
- [ ] YAML frontmatter is valid (no tabs, proper indentation)
- [ ] Agent body contains clear instructions with role, behavior, and scope
- [ ] `plugin.json` exists in `.claude-plugin/` with matching plugin metadata
