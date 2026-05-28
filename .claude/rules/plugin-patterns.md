---
paths:
  - "kit/plugins/**"
---

# Plugin Component Patterns

## Command Pattern (Explicit Invocation)

Commands use YAML frontmatter + markdown body:

```markdown
---
description: Brief one-sentence description for command list
---

# Command Title

Detailed instructions for Claude.

Access user input via $ARGUMENTS.
Access current directory via $PWD.
```

- Invoke via: `/plugin-name:command-name [arguments]`
- File location: `commands/command-name.md`

## Skill Pattern (Automatic Activation)

Skills use YAML frontmatter with activation criteria:

```markdown
---
name: skill-name
description: "Reviews code for bugs, security issues, and quality. Use when the user asks to review code or check for bugs."
allowed-tools: Bash, Read, Write, Edit
---

# Skill Instructions

The description field determines WHEN the skill activates and describes WHAT it does.
The body determines HOW Claude does it when activated.
```

- File location: `skills/skill-name/SKILL.md`
- Activation: automatic when user intent matches `description`

### Declaring `allowed-tools`

Declare every tool the skill actually uses in a comma-separated `allowed-tools:` line so the user isn't prompted for permission mid-run. Common entries: `Bash`, `Read`, `Write`, `Edit`, `Glob`, `Grep`, `TodoWrite`, `WebFetch`, `WebSearch`, `AskUserQuestion`, `NotebookEdit`, `Task`.

When the skill only shells out to one CLI family, prefer the restricted form (see `kit/plugins/git-agent/skills/commit-agent/SKILL.md`):

```yaml
allowed-tools: Bash(git *)
```

Use the `auditing-allowed-tools` skill (in the `skill-reviewer` plugin) to recommend or patch a SKILL.md's `allowed-tools` automatically, or to cross-reference a skill against a real session JSONL transcript.

#### Deferred tools

Some harness tools (including `ExitPlanMode`) are **deferred** — their schemas are not loaded at session start. Any skill that calls a deferred tool must:

- List both `ToolSearch` **and** the deferred tool in `allowed-tools`
- Include a note in the step body: "use `ToolSearch` with `select:<ToolName>` first, then call `<ToolName>`"

Skipping `ToolSearch` causes a permission prompt mid-skill, breaking the flow.

## Progressive Disclosure in Skills

Structure skills in layers to avoid overwhelming context:

1. **Description** — Simple, clear activation criteria (frontmatter)
2. **Summary** — Brief overview of what the skill does
3. **Detailed Instructions** — Step-by-step process with edge cases
4. **Examples** — Concrete demonstrations

## Plugin README Structure

Each plugin must have a `README.md` with:
1. **Overview** — What the plugin does
2. **Features** — List of commands/skills with invocation syntax
3. **Installation** — How to load the plugin
4. **Usage** — Example invocations
5. **Plugin Structure** — Directory tree
6. **Components** — Detailed component documentation

## Documentation Principles

- **README First** — Write the plugin README before implementing complex features
- **Command Descriptions** — Keep frontmatter descriptions to one sentence
- **Skill Description Format** — Three-part format: `[Short description (≤80 chars).] [Capability statement.] Use when the user asks to [trigger].` Short description is always Sentence 1 and survives even at ~100 skills installed (8,000 ÷ 100 = 80 chars/skill). Source both sentences from the skill body's `## Overview` section. Total budget: ≤200 chars.
- **Examples Matter** — Include concrete usage examples in every component
- **Progressive Disclosure** — Start simple, add detail progressively in skills

## Common Pitfalls

### Plugin Manifest Errors

- Missing required field `name` in `plugin.json`
- Invalid semantic version format (must be `X.Y.Z`, not `v1.0` or `1.0`)
- Setting `version` in both `plugin.json` and `marketplace.json` — for relative-path plugins, set it only in `marketplace.json`

### Component Structure Errors

- Missing YAML frontmatter in command or skill files
- Commands without a `description` field in frontmatter
- Skills without both `name` and `description` fields
- Non-markdown files using `.md` extension

### Markdown Formatting

- Commands use backticks: `/plugin:command`
- File paths use backticks: `path/to/file`
- Directory trees use code blocks with no language specifier
- Keep lists simple (no excessive nesting)
