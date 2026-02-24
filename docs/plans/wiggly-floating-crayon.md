# Plan: Update plugin.json homepage URLs

## Context

All 5 production `plugin.json` files currently set `homepage` to the generic Claude docs URL (`https://code.claude.com/docs/en/plugins`). The homepage should point to the plugin's own GitHub source directory so users can browse the plugin code and docs directly.

## Changes

Update `homepage` in each plugin's `.claude-plugin/plugin.json` to the plugin-specific GitHub URL:

| Plugin | File | New homepage |
|---|---|---|
| claude-md-optimizer | `plugins/claude-md-optimizer/.claude-plugin/plugin.json` | `https://github.com/shawn-sandy/agentics/plugins/claude-md-optimizer` |
| code-review | `plugins/code-review/.claude-plugin/plugin.json` | `https://github.com/shawn-sandy/agentics/plugins/code-review` |
| dev-tools | `plugins/dev-tools/.claude-plugin/plugin.json` | `https://github.com/shawn-sandy/agentics/plugins/dev-tools` |
| hello-world | `plugins/hello-world/.claude-plugin/plugin.json` | `https://github.com/shawn-sandy/agentics/plugins/hello-world` |
| plan-interview | `plugins/plan-interview/.claude-plugin/plugin.json` | `https://github.com/shawn-sandy/agentics/plugins/plan-interview` |

## Steps

1. Edit `plugins/claude-md-optimizer/.claude-plugin/plugin.json` — update `homepage`
2. Edit `plugins/code-review/.claude-plugin/plugin.json` — update `homepage`
3. Edit `plugins/dev-tools/.claude-plugin/plugin.json` — update `homepage`
4. Edit `plugins/hello-world/.claude-plugin/plugin.json` — update `homepage`
5. Edit `plugins/plan-interview/.claude-plugin/plugin.json` — update `homepage`

## Out of Scope

- `tests/fixtures/` — minimal test fixtures; no `homepage` field expected there

## Verification

After edits, confirm each file contains the correct plugin-specific URL with `grep -r "homepage" plugins/`.
