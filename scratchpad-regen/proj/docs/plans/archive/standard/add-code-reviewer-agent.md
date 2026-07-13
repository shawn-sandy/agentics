---
status: completed
type: standard
created: 2026-03-08
---

# Plan: Add Code Reviewer Agent to code-review Plugin

## Context

The `code-review` plugin (v2.1.1) currently has a skill (`code-review-agent`) but no agents. The `agents/` directory exists but is empty. Adding a dedicated code-reviewer agent enables the plugin to be invoked as a sub-agent from other contexts, with confidence-based filtering to surface only high-priority findings.

## Files to Create/Modify

1. **Create** `plugins/code-review/agents/code-reviewer.md` -- Agent file with frontmatter + system prompt
2. **Update** `plugins/code-review/CHANGELOG.md` -- Add entry for the new agent
3. **Update** `plugins/code-review/.claude-plugin/plugin.json` -- Bump version to 2.2.0 (minor: new agent added)
4. **Update** `.claude-plugin/marketplace.json` -- Sync version to 2.2.0

## Agent Frontmatter

```yaml
---
name: code-reviewer
description: >
  Reviews code for bugs, logic errors, security vulnerabilities, code quality
  issues, and adherence to project conventions, using confidence-based filtering
  to report only high-priority issues that truly matter. Use when the user asks
  to review code, check files for problems, find bugs or security issues, detect
  breaking changes, or evaluate code quality. Also triggers for informal requests
  like "take a look at this" or "anything wrong with this code." Does not cover
  system architecture reviews, testing strategy, or accessibility audits.
tools:
  - Read
  - Glob
  - Grep
  - WebFetch
  - WebSearch
model: sonnet
maxTurns: 10
---
```

## Agent Body (System Prompt)

Structured with these sections:
- **Role** -- Code review specialist with confidence-based filtering
- **Behavior** -- Guidelines for tone, severity ranking, actionability
- **Workflow** -- 4-step process: resolve files, analyze, filter by confidence, format report
- **Output Format** -- Structured report matching the existing skill format (Summary, Complexity Rating, Breaking Changes, Critical Issues, Improvements, Positive Observations)
- **Scope Boundaries** -- In scope vs. out of scope

The agent body will reuse the review checklist structure from the existing skill (`skills/code-review-agent/SKILL.md`) but adapted for agent context with confidence thresholds.

## Version Bump

- Current: `2.1.1`
- New: `2.2.0` (minor bump -- new agent feature, backward compatible)
- Both `plugin.json` and `marketplace.json` must be updated to `2.2.0`

## Verification

1. Validate frontmatter: name is lowercase/hyphenated, description <1024 chars, tools from allowed list, model is valid
2. Confirm `plugin.json` has required fields and version matches `marketplace.json`
3. Agent body contains Role, Behavior, Workflow, Output Format, and Scope sections
4. Test by loading: `claude --plugin-dir ~/devbox/agentics/plugins/code-review`
