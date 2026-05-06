# Agent Definition Best Practices

Reference criteria for the `reviewing-agents` audit. Each section maps to a
scoring dimension. Based on official documentation at
https://code.claude.com/docs/en/sub-agents.

> **Compatibility note:** The `agent-creator` plugin's `references/agent-schema.md`
> may lag behind the official docs. If you scaffolded your agent with
> `agent-creator`, verify field names and valid values against this reference,
> which tracks the canonical documentation.

---

## Table of Contents

- [1. Frontmatter Compliance Rules](#1-frontmatter-compliance-rules)
- [2. Tool Configuration Rules](#2-tool-configuration-rules)
- [3. Description Quality Rules](#3-description-quality-rules)
- [4. System Prompt Quality Rules](#4-system-prompt-quality-rules)
- [5. Security and Isolation Rules](#5-security-and-isolation-rules)
- [6. Anti-Patterns](#6-anti-patterns)
- [7. Golden Template](#7-golden-template)

---

## 1. Frontmatter Compliance Rules

### Required Fields

#### name

- Format: lowercase letters and hyphens only
- Max length: 64 characters
- Must not contain `anthropic` or `claude` as a substring
- Must not contain XML tags
- Must be unique within its scope (project, user, plugin)

#### description

- Max length: 1024 characters
- Written in third person (no I, you, we, your)
- Must not contain XML tags or literal newlines
- Must include "Use when..." trigger phrase for delegation context

### Optional Fields -- Valid Values

#### tools

- Type: comma-separated string or YAML array
- When omitted: inherits all tools from the parent conversation
- Valid tool names: Read, Write, Edit, Bash, Glob, Grep, Agent, NotebookEdit,
  WebFetch, WebSearch, TodoWrite, AskUserQuestion, Skill
- Supports filtered forms: `Bash(git *)` restricts Bash to git commands
- Supports agent-type restrictions: `Agent(worker, researcher)` limits which
  subagents can be spawned (only applies when agent runs as main session via
  `--agent`; has NO effect in subagent definitions)

#### disallowedTools

- Type: comma-separated string or YAML array
- Removes tools from the inherited or specified set
- If both `tools` and `disallowedTools` are set: `disallowedTools` is applied
  first, then `tools` resolves against the remaining pool
- Common read-only pattern: `Write, Edit, NotebookEdit`

#### model

- Valid values: `sonnet`, `opus`, `haiku`, full model ID (e.g.,
  `claude-opus-4-7`, `claude-sonnet-4-6`), or `inherit`
- Default: `inherit` (uses the same model as the main conversation)
- Resolution order: `CLAUDE_CODE_SUBAGENT_MODEL` env var > per-invocation
  model > frontmatter model > main conversation model

**Selection guidance:**

| Model | Best for |
|-------|----------|
| `haiku` | Fast, high-volume, simple tasks (exploration, search) |
| `sonnet` | Most agents -- balanced capability and speed |
| `opus` | Complex reasoning, nuanced analysis |
| `inherit` | Default -- follows the main conversation's model |

#### permissionMode

- Valid values: `default`, `acceptEdits`, `auto`, `dontAsk`,
  `bypassPermissions`, `plan`
- **IGNORED for plugin subagents** (agents in a plugin's `agents/` directory)
- `bypassPermissions` skips all permission prompts -- flag this always
- If parent uses `bypassPermissions` or `acceptEdits`, parent takes precedence
- If parent uses `auto` mode, subagent inherits auto mode regardless of
  frontmatter setting

#### maxTurns

- Type: number
- Recommended range: 5-50
- Below 5: agent may not complete its task
- Above 50: runaway risk without sufficient guard steps
- Default (unset): system default (25)

#### skills

- Type: YAML array of skill names
- Subagents do NOT inherit skills from the parent conversation
- Must list skills explicitly to preload them
- Format: `skill-name` or `plugin:skill-name`
- Full skill content is injected into context at startup
- Skills with `disable-model-invocation: true` cannot be preloaded

#### mcpServers

- Type: YAML mapping or array
- Entries are either inline server definitions or string references to
  already-configured servers
- **IGNORED for plugin subagents**
- Inline definitions: `stdio`, `http`, `sse`, `ws` types keyed by server name
- Use for scoping MCP tools to specific subagents without polluting the
  main conversation

#### hooks

- Type: YAML mapping of hook events
- Supported events: `PreToolUse`, `PostToolUse`, `Stop`
- **IGNORED for plugin subagents**
- `Stop` hooks in frontmatter are converted to `SubagentStop` at runtime
- Each hook entry has `matcher` (tool name or regex) and `hooks` array with
  `type: command` and `command` string

#### memory

- Valid values: `user`, `project`, `local`
- Scope determines storage location:
  - `user`: `~/.claude/agent-memory/<name>/` -- cross-project
  - `project`: `.claude/agent-memory/<name>/` -- project-specific, shareable
  - `local`: `.claude/agent-memory-local/<name>/` -- project-specific, gitignored
- When set: Read, Write, and Edit tools are automatically enabled
- Body MUST contain instructions for consulting and updating memory

#### background

- Type: boolean
- Default: `false`
- When `true`: agent runs concurrently, non-blocking
- Background agents auto-deny permission prompts not pre-approved
- AskUserQuestion calls fail in background agents
- Body should include explicit STOP instruction

#### effort

- Valid values: `low`, `medium`, `high`, `xhigh`, `max`
- Overrides the session effort level for this subagent
- Available levels depend on the model

#### isolation

- Valid value: `worktree`
- Runs the subagent in a temporary git worktree
- Worktree is automatically cleaned up if no changes are made
- Use for agents that need isolated file modifications

#### color

- Valid values: `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`,
  `cyan`
- Display color in the task list and transcript

#### initialPrompt

- Type: string
- Auto-submitted as the first user turn when the agent runs as the main session
  (via `--agent` or `agent` setting)
- Commands and skills are processed in the prompt
- Prepended to any user-provided prompt

### YAML Parsing Notes

Agent descriptions often use YAML folded or block scalars. Both are valid:

**Folded scalar (`>`)** -- newlines become spaces:
```yaml
description: >
  Internal background code review agent for delegation from other agents
  or automated workflows. Use when delegating a code review.
```

**Block scalar (`|`)** -- newlines preserved:
```yaml
description: |
  Internal background code review agent.
  Use when delegating a code review.
```

**Plain scalar** -- single line:
```yaml
description: Internal code review agent. Use when delegating a code review.
```

When parsing frontmatter, read lines between the first and second `---`
delimiters. If `description:` spans multiple lines (folded YAML), collect
all continuation lines (indented more than the key) until the next top-level
key.

---

## 2. Tool Configuration Rules

### Least Privilege Principle

Grant only the tools the agent actually needs. If the agent only reads and
analyzes code, it should not have Write, Edit, or Bash access.

### Read-Only Agent Pattern

For analysis-only agents:
```yaml
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit, NotebookEdit
```

Optionally add `WebFetch` and `WebSearch` for agents that reference external
documentation.

### Background Agent Safety

When `background: true`:
- Agent runs without interactive permission prompts
- Mutation tools (Write, Edit, Bash) should be restricted via `disallowedTools`
  unless the agent's explicit purpose requires mutations (e.g., commit agents)
- If mutations are intentional, the body must include guard steps and rollback
  guidance

### Agent Tool in Subagents

**Subagents cannot spawn other subagents.** The `Agent` tool listed in a
subagent's `tools` field has no effect. Flag this as a warning -- it indicates
a misunderstanding of the execution model.

The `Agent(worker, researcher)` syntax for restricting spawnable subagent types
only applies when the agent runs as the main session via `--agent`, not when
invoked as a subagent.

### tools + disallowedTools Together

Both fields can be set simultaneously. Resolution order:
1. `disallowedTools` is applied first (removes from inherited set)
2. `tools` is resolved against the remaining pool

This is valid but unusual. Typically one or the other is sufficient. Flag as
INFO when both are present.

### Inheriting All Tools

When `tools` is omitted, the subagent inherits everything from the parent
conversation, including MCP tools. This is appropriate for general-purpose
agents but overly permissive for specialized agents. Flag for review when the
agent's description suggests a narrow focus.

---

## 3. Description Quality Rules

### Delegation Context

The description must explain WHEN to delegate to this agent, not just what it
does. Claude uses the description to decide whether to invoke the subagent.

**Bad (what-only):**
```yaml
description: Reviews code for quality.
```

**Good (when + what):**
```yaml
description: >
  Use when delegating a code review to a sub-agent, when another agent needs
  a second opinion on code quality, or when running a proactive sweep after
  a branch switch, merge, or batch of commits. Not intended for direct
  user-initiated review requests.
```

### Trigger Phrase Requirement

Must contain "Use when..." with specific delegation context. Include phrases
like "Use proactively" if the agent should be invoked automatically.

### Scope Exclusion

Include "Does NOT..." or "Not intended for..." to prevent misactivation:
```yaml
description: >
  ...Not intended for direct user-initiated review requests -- those are
  handled by the code-review-agent skill. Does not cover system architecture
  reviews, testing strategy, or accessibility audits.
```

### Keyword Density

Include >= 3 searchable, domain-specific keywords in the description. These
help Claude match user intent to the right subagent.

### Person and Voice

- Third person only (no I, you, we, your)
- No XML tags
- No literal newlines (use YAML folded scalar `>` for multi-line)

---

## 4. System Prompt Quality Rules

The body of the agent definition file IS the system prompt. Subagents receive
only this prompt (plus basic environment details like working directory), not
the full Claude Code system prompt.

### Required Sections

Every agent should have:

1. **Role** (`## Role`) -- Who the agent is and what it specializes in.
   One paragraph defining expertise and behavioral guidelines.

2. **Workflow** (`## Workflow` or `## Behavior`) -- What the agent does,
   step by step. Use numbered steps for sequential workflows. Include guard
   steps (pre-flight checks) for agents that mutate state.

### Recommended Sections

3. **Output Format** (`## Output Format`) -- What the agent produces. Include
   a template with markdown formatting. Essential for agents that generate
   reports.

4. **Scope Boundaries** (`## Scope Boundaries`) -- What is in scope and out
   of scope. Prevents the agent from drifting into adjacent domains.

5. **Memory** -- If `memory:` is set in frontmatter, include instructions for:
   - Consulting memory at the start of each run
   - Updating memory after completing work
   - Keeping entries concise and focused

### Background Agent Requirements

When `background: true`:
- Include explicit STOP instruction: "STOP immediately after completing..."
- Include "Return results to the parent session" or equivalent
- Define what constitutes task completion
- Include early-exit conditions (e.g., "If no files are found, report back
  and STOP")

### Length Guidelines

- Minimum: 20 lines -- shorter prompts may lack necessary detail
- Maximum: 300 lines -- longer prompts dilute instructions and waste context
- Sweet spot: 60-150 lines for most agents

### Structural Quality

- Imperative voice ("Analyze the code", not "The agent analyzes the code")
- Numbered steps for sequential workflows
- Guard steps for agents that mutate state (check preconditions first)
- No hardcoded absolute paths (use relative paths or environment variables)
- No time-sensitive content ("as of 2024", "currently", "recently added")
- No first/second person addressing the user (the agent is autonomous)

---

## 5. Security and Isolation Rules

### bypassPermissions

ALWAYS flag when present. This mode skips all permission prompts, allowing
unrestricted operations. Only justified for:
- Tightly scoped agents with minimal tools (e.g., only Read and Grep)
- Agents running in isolated worktrees where mutations are sandboxed
- Testing/CI environments where human oversight is not expected

The body must include explicit justification if this mode is used.

### Background + Mutation Tools

Flag when `background: true` AND the agent has unrestricted access to Write,
Edit, or Bash. Background agents auto-deny permission prompts not pre-approved,
meaning mutations could proceed without oversight.

Safe patterns:
- `background: true` + `disallowedTools: Write, Edit, NotebookEdit` (read-only)
- `background: true` + `tools: Bash, Read, Grep, Glob` (explicit allowlist,
  Bash for git commands only)

Unsafe pattern:
- `background: true` + no tool restrictions + body includes Write/Edit
  operations

### Plugin Agent Limitations

When an agent definition lives inside a plugin's `agents/` directory:
- `permissionMode` is **silently ignored**
- `hooks` is **silently ignored**
- `mcpServers` is **silently ignored**

Authors may set these fields thinking they are active, but they have zero
effect. Flag when detected -- unless the agent is in a known marketplace
structure (`kit/plugins/`), in which case suppress the warning (the author
likely controls the plugin and is aware of the limitation).

If ignored fields are critical to the agent's behavior, recommend copying the
agent file to `.claude/agents/` or `~/.claude/agents/` where these fields
are honored.

### Memory Hygiene

When `memory:` is set in frontmatter but the body contains no memory
instructions (no mention of "memory", "consult", "update", "save", or
"remember"), flag as a warning. The memory directory will be created but
never used, and memory-enabling auto-adds Read/Write/Edit tools that may
be unintended.

### maxTurns Bounds

- Below 5: WARNING -- agent may not complete its task
- Above 50: WARNING -- runaway risk without guard steps
- These thresholds are based on existing agent patterns in the marketplace

---

## 6. Anti-Patterns

### Error Level (must fix)

| Anti-Pattern | Detection | Fix |
|-------------|-----------|-----|
| Missing `name` field | Frontmatter parse | Add `name:` with kebab-case identifier |
| Missing `description` field | Frontmatter parse | Add `description:` with "Use when..." trigger |
| `name` not lowercase/hyphens | Regex `^[a-z][a-z0-9-]*$` | Convert to kebab-case |
| `name` contains `anthropic` or `claude` | Substring check | Rename to avoid reserved words |
| `name` exceeds 64 characters | Length check | Shorten the name |
| YAML parse failure | Frontmatter parse | Fix YAML syntax |
| Non-YAML frontmatter | Missing `---` delimiters | Add YAML frontmatter with `---` delimiters |
| Duplicate YAML keys | Scan for repeated keys | Remove duplicates, keep intended value |

### Warning Level (should fix)

| Anti-Pattern | Detection | Fix |
|-------------|-----------|-----|
| `Agent` in `tools` list | Check tools array | Remove -- subagents cannot spawn subagents |
| Plugin agent with `permissionMode` set | Plugin detection + field check | Remove or document the limitation |
| Plugin agent with `hooks` set | Plugin detection + field check | Move agent to `.claude/agents/` if hooks are needed |
| Plugin agent with `mcpServers` set | Plugin detection + field check | Move agent to `.claude/agents/` if MCP is needed |
| `background: true` + unrestricted mutations | Background + tools check | Add `disallowedTools` or restrict `tools` |
| `memory` set without memory instructions | Memory field + body scan | Add consult/update instructions to body |
| `bypassPermissions` without justification | permissionMode check + body scan | Add justification or use a safer mode |
| `maxTurns` outside 5-50 range | Numeric check | Adjust to recommended range |
| Description in first/second person | Person check | Rewrite in third person |
| No "Use when..." trigger phrase | Trigger scan | Add delegation context |
| Empty body (frontmatter only) | Line count check | Add Role and Workflow sections |
| Unrecognized frontmatter field | Field name check | Fix typo or remove unknown field |
| `description` exceeds 1024 characters | Length check | Shorten the description |

### Suggestion Level (consider)

| Anti-Pattern | Detection | Fix |
|-------------|-----------|-----|
| Both `tools` and `disallowedTools` set | Field presence check | Typically one is sufficient |
| Missing scope exclusion in description | "Does NOT" scan | Add what the agent does NOT cover |
| Missing `## Output Format` section | Heading scan | Add output template if agent produces reports |
| Missing `## Scope Boundaries` section | Heading scan | Add in-scope / out-of-scope list |
| Tools omitted (inherits all) | Missing tools field | Consider restricting to needed tools |
| Body > 300 lines | Line count | Consider splitting into references |
| Body < 20 lines | Line count | Consider adding more detail |
| `model` not specified | Field check | Consider setting explicitly for consistent behavior |
| Background agent without STOP instruction | Background + body scan | Add explicit STOP instruction |

---

## 7. Golden Template

For new agent files with no git history, compare against this structural
template. Report missing sections as "template gaps."

### Expected Structure

```markdown
---
name: agent-name
description: >
  [Delegation context with "Use when..." trigger phrase.
  Scope exclusion with "Does NOT..." or "Not intended for..."]
tools: [Appropriate tool list]
model: [sonnet | haiku | opus | inherit]
---

## Role

[1-2 paragraphs defining expertise and behavioral guidelines]

## Workflow

1. [First step with guard/precondition if applicable]
2. [Core analysis or action step]
3. [Output generation step]
4. [Completion and cleanup step]

## Output Format

[Template with markdown formatting showing expected output structure]

## Scope Boundaries

- **In scope:** [What this agent handles]
- **Out of scope:** [What this agent does NOT handle]
```

### Template Gap Detection

| Section | Required | Condition |
|---------|----------|-----------|
| `## Role` | Yes | Always expected |
| `## Workflow` or `## Behavior` | Yes | Always expected |
| `## Output Format` | Conditional | Expected when agent produces structured output |
| `## Scope Boundaries` | Recommended | Always suggested |
| Memory instructions | Conditional | Required when `memory:` is set |
| STOP instruction | Conditional | Required when `background: true` |
