---
name: sync-rules
description: Installs the team's shared rule files into ~/.claude/rules/ with per-file confirmation. Copies plan-mode, component-driven-ui, typescript-jsdoc, and review-bot-loops rules plus the plan skeleton. Use when the user asks to sync, install, or update team rules.
allowed-tools: Bash, Read, AskUserQuestion
---

# Sync Team Rules

Copy the rule files bundled with this plugin into the user's global rules directory so every project on their machine picks them up.

## Source and destination

- Source: `${CLAUDE_PLUGIN_ROOT}/skills/sync-rules/rules/`
- Destination: `~/.claude/rules/` (create it if missing, including `reference/`)

Files to sync:

| File | Purpose |
|------|---------|
| `plan-mode.md` | Plan-mode workflow: frontmatter, naming, required structure |
| `reference/SKELETON.md` | Starter skeleton for new plan files |
| `component-driven-ui.md` | Bottom-up component composition rule (scoped to JS-framework files) |
| `typescript-jsdoc.md` | JSDoc documentation rule (scoped to TS/JS files) |
| `review-bot-loops.md` | Guard against automated review-bot iteration loops |

## Workflow

1. **Diff first.** For each source file, check whether the destination file exists:
   - Missing → mark as **new**.
   - Identical (`diff -q`) → mark as **up to date**, skip silently.
   - Different → mark as **conflict**.
2. **Report the sync plan** as a short table (file, status) before writing anything.
3. **Confirm conflicts.** If any file is in conflict, ask the user per file (overwrite / keep local) with `AskUserQuestion` before overwriting. New files need no confirmation.
4. **Copy** the approved files, then list exactly what was written.
5. Never touch any file in `~/.claude/rules/` that this plugin does not ship — the destination may contain the user's own rules.

## Notes

- `plan-mode.md` references a `validate-plan-filename` hook; that hook ships with the `plan-agent` plugin, not this one. Mention it if the user doesn't have `plan-agent` installed.
- Rules are plain Markdown — no restart needed; they load on the next session.
