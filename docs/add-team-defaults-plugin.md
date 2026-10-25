# Add team-defaults plugin

> Creates `kit/plugins/team-defaults/` carrying shareable agents (`ts-commenter`, `css-generator`) and global rules (plan-mode, component-driven-ui, typescript-jsdoc, review-bot-loops, plan skeleton), with a `sync-rules` skill that installs rules into `~/.claude/rules/` with per-file confirmation.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-team-defaults-plugin](plans/add-team-defaults-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/team-defaults/` plugin registered in marketplace at v0.1.0
- Bundled agents: `ts-commenter`, `css-generator`
- Bundled global rules: `plan-mode.md`, `component-driven-ui.md`, `typescript-jsdoc.md`, `review-bot-loops.md`, and plan skeleton rule
- Created `sync-rules` skill that reads each bundled rule, compares against the installed copy in `~/.claude/rules/`, and installs with per-file `AskUserQuestion` confirmation
- Note: subsequently retired (see removed-plugins.md — plugin drifted from maintainer's rules and was never invoked)

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/team-defaults/` | Plugin directory | Created |
| `kit/plugins/team-defaults/plugin.json` | Plugin manifest | Created |
| `kit/plugins/team-defaults/skills/sync-rules/SKILL.md` | Skill — rule installation | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — team-defaults v0.1.0 | Modified |

## How it works

`team-defaults` packages a set of team-wide Claude Code rules and agents into an installable plugin. Teams with a shared coding style — TypeScript JSDoc patterns, component-driven UI conventions, PR review bot behavior — can install the plugin once and get consistent rule activation across all their machines.

The `sync-rules` skill reads each bundled rule file and compares it against the currently installed copy in `~/.claude/rules/`. For each file, it shows the diff and presents an `AskUserQuestion` confirmation before copying. Files already identical are skipped. The per-file confirmation prevents the skill from silently overwriting customized rule copies.

The plugin was later retired because the bundled rule copies drifted behind the maintainer's own `~/.claude/rules/` files, and the skill was never actually invoked. Rule distribution is covered by `settings-sync`. See `removed-plugins.md` for the full retirement context.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin](plans/add-team-defaults-plugin.md)
