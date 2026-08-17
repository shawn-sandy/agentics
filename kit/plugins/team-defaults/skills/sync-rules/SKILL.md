---
name: sync-rules
description: "Installs the team's shared rule files into ~/.claude/rules/. Copies the bundled plan-mode, UI, JSDoc, and review rules with per-file confirmation. Use when asked to sync team rules."
allowed-tools: Bash, Read, AskUserQuestion
---

# Sync Team Rules

Copy the rule files bundled with this plugin into the user's global rules directory so every project on their machine picks them up.

## Source and destination

- Source: the `rules/` directory bundled beside this SKILL.md (`skills/sync-rules/rules/` inside the plugin's install directory, the one Claude Code exposes as `${CLAUDE_PLUGIN_ROOT}`)
- **Resolve the plugin root first.** Before composing any `cp` or `diff` command, resolve the plugin root to the absolute directory containing this SKILL.md and write that literal path into the command — a literal `${CLAUDE_PLUGIN_ROOT}` in a Bash call is refused ("Contains expansion") and never runs.
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
4. **Copy** the approved files.
5. **Verify the copy.** Re-run `diff -q` source-vs-destination for every file just copied and report each one as identical. Any difference or missing destination file is a failure — name the file, report it loudly, and stop; never report the sync as successful past a mismatch.
6. **List** exactly what was written and verified.
7. Never touch any file in `~/.claude/rules/` that this plugin does not ship — the destination may contain the user's own rules.

## Notes

- `plan-mode.md` references a `validate-plan-filename` hook; that hook ships with the `plan-agent` plugin, not this one. Mention it if the user doesn't have `plan-agent` installed.
- Rules are plain Markdown — no restart needed; they load on the next session.
