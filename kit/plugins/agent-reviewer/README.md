# agent-reviewer

Review and audit Claude Code subagent definition files (`agents/*.md`) against official best practices from [code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents).

## Features

- **5-dimension scored audit** -- frontmatter compliance, tool configuration, description quality, system prompt quality, security & isolation
- **Graded reports** -- Excellent (9-10), Good (6-8), Needs Work (3-5), Rewrite (0-2)
- **Fix generation** -- presents unified diff with frontmatter auto-corrections and inline body suggestions
- **Plugin agent detection** -- flags silently-ignored fields (`permissionMode`, `hooks`, `mcpServers`)
- **Background agent safety** -- checks for unrestricted mutation tools
- **Golden template comparison** -- structural validation for new agent files with no git history
- **Regression risk check** -- git-based comparison against last committed version
- **Edge case handling** -- empty body, non-YAML frontmatter, mixed tools+disallowedTools, duplicate YAML keys

## Installation

### Via Marketplace (recommended)

```bash
/plugin install agent-reviewer@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ~/devbox/agentics/kit/plugins/agent-reviewer
```

## Usage

This plugin is skills-only — there are no slash commands. The skill activates automatically when your request matches its trigger description.

### Skills

#### reviewing-agents (auto-activated)

Audits Claude Code agent files across 5 quality dimensions. Produces a scored report and optionally generates a fix.

Activates automatically when you ask to review, audit, or score an agent definition file. Example trigger phrases:

```
Review my agent definition at agents/agent-code-reviewer.md
Audit this agent file
Score my agent definition
Does this agent follow best practices?
Check agent quality for agents/agent-commit.md
```

### Example output

```
## Agent Audit Report: `agent-code-reviewer`

| # | Dimension              | Score | Notes                |
|---|------------------------|-------|----------------------|
| 1 | Frontmatter Compliance | 2     | Clean                |
| 2 | Tool Configuration     | 2     | Clean                |
| 3 | Description Quality    | 2     | Clean                |
| 4 | System Prompt Quality  | 2     | Clean                |
| 5 | Security & Isolation   | 2     | Clean                |

**Total: 10/10 -- Grade: Excellent**
```

### Using live guidelines

By default, the audit uses a static reference file. To fetch the latest guidelines from the official docs:

```
Review my agent using the latest official docs
Audit this agent -- check official docs
```

## Plugin Structure

```
agent-reviewer/
  .claude-plugin/
    plugin.json
  skills/
    reviewing-agents/
      SKILL.md
      references/
        best-practices.md
        audit-steps.md
  CHANGELOG.md
  README.md
```

## Components

### Skills

#### reviewing-agents

Structured audit of subagent definition files. Produces a scored report across 5 quality dimensions and optionally generates a corrected version.

**Activation:** Auto-activated — no slash command needed. The skill activates when user intent matches trigger phrases.

**Trigger phrases:** "review my agent", "audit this agent", "check agent quality", "score my agent definition"

**Scope:** Agent definition files (`agents/*.md`) only. Does NOT review SKILL.md files (use `skill-reviewer`), CLAUDE.md files, or general markdown. Does NOT create or scaffold agents (use `agent-creator`).

### References

#### best-practices.md

Comprehensive normative rules organized by audit dimension. Covers all 16 optional frontmatter fields with valid values, tool configuration patterns, description quality criteria, system prompt structure requirements, security rules, anti-pattern tables, and the golden template for new agents.

Source of truth: [code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents)

#### audit-steps.md

Procedural workflow for Steps 3-7: scoring rubric per dimension, report template, diff-based fix generation, fix application options, and write-to-disk confirmation.

## Scoring Dimensions

| # | Dimension | Points | Key Checks |
|---|-----------|--------|------------|
| 1 | Frontmatter Compliance | 0-2 | Required fields, valid values, naming conventions, YAML syntax |
| 2 | Tool Configuration | 0-2 | Least privilege, Agent tool caveat, background safety |
| 3 | Description Quality | 0-2 | Delegation context, trigger phrases, scope exclusion, keywords |
| 4 | System Prompt Quality | 0-2 | Role + Workflow sections, STOP instruction, memory pairing |
| 5 | Security & Isolation | 0-2 | bypassPermissions, plugin ignored fields, mutation restrictions |

## Grade Thresholds

| Score | Grade | Meaning |
|-------|-------|---------|
| 9-10 | Excellent | Production-ready, follows all best practices |
| 6-8 | Good | Functional with minor improvements possible |
| 3-5 | Needs Work | Significant issues that should be addressed |
| 0-2 | Rewrite | Fundamental problems -- start from the golden template |
