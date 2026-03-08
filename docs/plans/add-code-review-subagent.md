# Plan: Add code-review-agent Subagent

## Context

The code-review plugin (v2.1.0) has a monolithic skill (`skills/code-review-agent/SKILL.md`, ~320 lines) that contains the full review checklist, format template, file resolution logic, and examples. Claude Code now supports plugin subagents as a distinct component type — markdown files in `agents/` with their own context window, tool restrictions, and system prompt. Extracting the review logic into a subagent improves context isolation and aligns with the official plugin architecture.

## Design Decision

**The agent owns the entire review process end-to-end** (including file resolution). The skill becomes a thin delegation wrapper.

Rationale:
- Agents run in their own context window — splitting file resolution (skill) from review (agent) creates an unnecessary hand-off seam
- Official docs show agents as self-contained specialists
- The skill's `description` remains the activation mechanism; the body becomes a delegation instruction

## Steps

### 1. Create `plugins/code-review/agents/code-review-agent.md`

New file — the subagent definition.

**Frontmatter:**
```yaml
name: code-review-agent
description: Expert code review specialist. Systematically reviews code for quality, bugs, security vulnerabilities, best practices, complexity, breaking changes, and potential regressions. Use when reviewing code or analyzing code quality.
tools: Read, Grep, Glob, Bash
model: inherit
```

**Body:** Transfer from current SKILL.md:
- Opening paragraph
- Step 0: Resolve Target Files (full section)
- Review Checklist (all 6 subsections)
- Review Format (full template)
- Example Review
- Tips for Effective Reviews
- Scope

Remove the Table of Contents (unnecessary for an agent system prompt).

### 2. Simplify `plugins/code-review/skills/code-review-agent/SKILL.md`

Replace the 320-line file with a thin delegation wrapper (~8 lines):
- Keep the `description` frontmatter exactly as-is (controls activation)
- Body: instruct Claude to delegate to the `code-review-agent` subagent, passing the user's full message

### 3. Bump version in `plugins/code-review/.claude-plugin/plugin.json`

`"version": "2.1.0"` → `"version": "2.2.0"`

### 4. Bump version in `.claude-plugin/marketplace.json`

`code-review` entry version `"2.1.0"` → `"2.2.0"`

### 5. Update `plugins/code-review/CHANGELOG.md`

Add `[2.2.0]` entry documenting the new subagent and skill simplification.

### 6. Update `plugins/code-review/README.md`

Fix stale content:
- "four dimensions" → "six dimensions" (add Code Complexity + Breaking Changes & Regressions)
- Add "Breaking Changes & Regressions" to review output format list
- Add Agents section documenting `code-review-agent`
- Update Plugin Structure to show `agents/` directory

## Files to Modify

| File | Action |
|------|--------|
| `plugins/code-review/agents/code-review-agent.md` | **CREATE** — subagent with full review system prompt (~300 lines) |
| `plugins/code-review/skills/code-review-agent/SKILL.md` | **REPLACE** — thin delegation wrapper (~8 lines) |
| `plugins/code-review/.claude-plugin/plugin.json` | **EDIT** — version 2.1.0 → 2.2.0 |
| `.claude-plugin/marketplace.json` | **EDIT** — code-review version 2.1.0 → 2.2.0 |
| `plugins/code-review/CHANGELOG.md` | **EDIT** — add 2.2.0 entry |
| `plugins/code-review/README.md` | **EDIT** — add agents, fix stale checklist count and output format |

## Verification

1. `grep -r '"version"' plugins/code-review/.claude-plugin/ .claude-plugin/marketplace.json` — confirm both show 2.2.0
2. Verify `agents/code-review-agent.md` has valid YAML frontmatter with `name` and `description`
3. Verify skill SKILL.md references the agent correctly
4. Load plugin locally: `claude --plugin-dir ./plugins/code-review` and trigger with "review this code"

## Unresolved Questions

1. Should `maxTurns` be set on the agent to prevent runaway reviews on very large codebases? (Suggest 15 as a reasonable default, or omit to inherit default behavior.)
2. Should `permissionMode` be set (e.g., `plan` for read-only)? The `tools` list already restricts capabilities.

## Interview Summary

### Key Decisions Confirmed
- **Agent re-reads files independently** — the skill delegates without pre-reading, keeping the wrapper simple
- **Full example kept** in the agent system prompt — acceptable token cost for output quality
- **Agent will be renamed** to `code-reviewer` (not `code-review-agent`) to avoid name collision with the skill and match official docs convention

### Open Risks & Concerns
- **Double activation**: Both skill and agent describe "review code." The agent's `description` must be phrased as an internal delegation target, not a user-facing trigger, to prevent Claude from bypassing the skill
- **Bash scope**: Agent gets unrestricted Bash access; acceptable for now but worth noting
- **No explicit rollback path**: Original SKILL.md content is deleted; rollback depends on git history

### Recommended Next Steps
1. **Agent name**: Use `code-reviewer` — update Step 1 file path to `plugins/code-review/agents/code-reviewer.md`
2. **Rewrite the agent description** to be delegation-oriented (e.g., "Performs structured code review when delegated. Do not invoke directly — activated through the code-review-agent skill.")
3. **Skill delegation instruction** must use qualified name `code-review:code-reviewer` (plugin-name:agent-name)
4. **Verify qualified name resolution** during manual testing (Step 4 of Verification)

### Simplification Opportunities
None — the plan already simplifies the existing architecture.
