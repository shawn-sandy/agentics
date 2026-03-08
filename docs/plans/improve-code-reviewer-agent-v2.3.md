# Plan: Improve code-reviewer agent (v2.2.0 -> v2.3.0)

## Context

The `code-reviewer` sub-agent was compared against the [official sub-agents docs](https://code.claude.com/docs/en/sub-agents). Several frontmatter fields and prompt improvements are missing. These changes improve safety, enable persistent learning, and align with documented best practices.

## Changes

### 1. Frontmatter: Remove unnecessary tools
- **Remove** `WebFetch` and `WebSearch` from `tools`
- A code reviewer has no need to fetch URLs or search the web
- Docs: "Limit tool access: grant only necessary permissions for security and focus"

### 2. Frontmatter: Add `permissionMode: plan`
- Enforces read-only behavior at the framework level
- Docs define `plan` as "read-only exploration" — matches reviewer intent exactly

### 3. Frontmatter: Add `disallowedTools`
- Explicitly block `Write`, `Edit`, `NotebookEdit` as defense-in-depth
- Prevents accidental modification even if tools are inherited

### 4. Frontmatter: Add `memory: project`
- Enables persistent learning of project-specific patterns across sessions
- Memory stored at `.claude/agent-memory/code-reviewer/`
- Add memory instructions to the prompt body

### 5. Frontmatter: Add `background: true`
- Code reviews are non-blocking — let the parent continue working
- User still gets results when the agent completes

### 6. Frontmatter: Switch tools format to comma-separated
- From YAML list to: `tools: Read, Glob, Grep, Bash`
- Matches docs convention

### 7. Description: Add proactive delegation language
- Append: "Use proactively after code changes, branch switches, or before merging to catch issues early."
- Docs recommend this to encourage automatic delegation

### 8. Prompt body: Fix workflow step 1 error
- Line 39 says "via Grep/Glob" — `git status` is a shell command, should say "via Bash"

### 9. Prompt body: Add memory instructions section
- After Scope Boundaries, add guidance for reading/writing memory
- Consult memory at review start, update after discovering new patterns

### 10. Version bump and docs
- Bump `plugin.json` and `marketplace.json` from `2.2.0` to `2.3.0`
- Update `CHANGELOG.md` with all changes
- Update `README.md` to mention memory and background capabilities

## Resulting frontmatter

```yaml
---
name: code-reviewer
description: >
  Reviews code for bugs, logic errors, security vulnerabilities, code quality
  issues, and adherence to project conventions, using confidence-based filtering
  to report only high-priority issues that truly matter. Use when the user asks
  to review code, check files for problems, find bugs or security issues, detect
  breaking changes, or evaluate code quality. Also triggers for informal requests
  like "take a look at this" or "anything wrong with this code." Use proactively
  after code changes, branch switches, or before merging to catch issues early.
  Does not cover system architecture reviews, testing strategy, or accessibility
  audits.
tools: Read, Glob, Grep, Bash
disallowedTools: Write, Edit, NotebookEdit
model: sonnet
permissionMode: plan
maxTurns: 10
memory: project
background: true
---
```

## Files to modify

| File | Change |
|------|--------|
| `plugins/code-review/agents/code-reviewer.md` | Frontmatter + prompt body |
| `plugins/code-review/.claude-plugin/plugin.json` | Version 2.2.0 -> 2.3.0 |
| `.claude-plugin/marketplace.json` | Version 2.2.0 -> 2.3.0 (line 56) |
| `plugins/code-review/CHANGELOG.md` | New 2.3.0 entry |
| `plugins/code-review/README.md` | Document new capabilities |

## Verification

1. Grep both version files to confirm sync: `grep -r '"version"' plugins/code-review/.claude-plugin/ .claude-plugin/marketplace.json`
2. Load plugin locally: `claude --plugin-dir ./plugins/code-review`
3. Test agent invocation: "Use the code-reviewer agent to review recent changes"
4. Verify background execution and memory directory creation

## Unresolved questions

1. Should `maxTurns` increase from 10 to account for memory read/write turns? (Likely fine at 10 — memory ops are lightweight)
2. Is `background: true` always desired, or should users see streaming review output? (Can be removed if real-time feedback preferred)
