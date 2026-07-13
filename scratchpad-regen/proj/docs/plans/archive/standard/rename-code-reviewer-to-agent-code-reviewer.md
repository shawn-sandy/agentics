---
status: in-progress
created: 2026-03-08
---

# Plan: Rename code-reviewer agent to agent-code-reviewer

## Context

The `code-review` plugin's sub-agent is named `code-reviewer`, which conflicts with the built-in/default `code-reviewer` agent from `feature-dev`. Renaming to `agent-code-reviewer` eliminates the collision while keeping the name descriptive.

Per marketplace versioning rules, renaming an agent is a **MAJOR** bump: `2.3.0` -> `3.0.0`.

## Changes

### 1. Rename agent file
- `plugins/code-review/agents/code-reviewer.md` -> `plugins/code-review/agents/agent-code-reviewer.md`

### 2. Update agent frontmatter
- **File:** `plugins/code-review/agents/agent-code-reviewer.md`
- Change `name: code-reviewer` -> `name: agent-code-reviewer`

### 3. Update README.md
- **File:** `plugins/code-review/README.md`
- Line 28: `code-reviewer` -> `agent-code-reviewer`
- Line 34: memory path `.claude/agent-memory/code-reviewer/` -> `.claude/agent-memory/agent-code-reviewer/`

### 4. Update CHANGELOG.md
- **File:** `plugins/code-review/CHANGELOG.md`
- Add `[3.0.0]` entry at top:
  - BREAKING CHANGE: agent renamed from `code-reviewer` to `agent-code-reviewer` to avoid conflict with built-in code-reviewer agent
  - Agent file renamed: `agents/code-reviewer.md` -> `agents/agent-code-reviewer.md`

### 5. Bump version in plugin.json
- **File:** `plugins/code-review/.claude-plugin/plugin.json`
- `"version": "2.3.0"` -> `"version": "3.0.0"`

### 6. Bump version in marketplace.json
- **File:** `.claude-plugin/marketplace.json`
- `"version": "2.3.0"` -> `"version": "3.0.0"` (for code-review entry)

## Files touched

| File | Action |
|------|--------|
| `plugins/code-review/agents/code-reviewer.md` | Delete (rename) |
| `plugins/code-review/agents/agent-code-reviewer.md` | Create (rename) |
| `plugins/code-review/README.md` | Edit lines 28, 34 |
| `plugins/code-review/CHANGELOG.md` | Add 3.0.0 entry |
| `plugins/code-review/.claude-plugin/plugin.json` | Bump version |
| `.claude-plugin/marketplace.json` | Bump version |

## Verification

1. Confirm both `plugin.json` and `marketplace.json` show version `3.0.0`
2. Confirm no remaining references to `name: code-reviewer` (without `agent-` prefix) in the plugin directory
3. Confirm the old file `agents/code-reviewer.md` no longer exists
4. Run: `grep -r "code-reviewer" plugins/code-review/` -- only hits should be in CHANGELOG historical entries
