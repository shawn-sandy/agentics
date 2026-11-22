# Add team-defaults plugin

> The user's `~/.claude/` folder holds agents and global rules the whole team should share, but hand-copying dotfiles does not version or update them. This packages the shareable agents and rules as a marketplace plugin with a `sync-rules` skill for installation.

<!-- generated:start -->

**Status:** Shipped 2026-07-13 **Plan:** [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/team-defaults/` with two agents (`ts-commenter`, `css-generator`), four rules (`plan-mode`, `component-driven-ui`, `typescript-jsdoc`, `review-bot-loops`) plus `reference/SKELETON.md`.
- Added `skills/sync-rules/SKILL.md` that installs the rules into `~/.claude/rules/` with per-file confirmation.
- Rewrote the hook reference in the bundled `plan-mode.md` — removed the machine-local `~/.claude/hooks/validate-plan-filename.py` path; teammates installing the plugin do not have that file.
- Added `plugin.json` (name only, no version), `README.md`, `CHANGELOG.md`.
- Registered `team-defaults` v0.1.0 in `.claude-plugin/marketplace.json` (category `productivity`).
- Updated `tests/publish/smoke-clean-dist.sh` plugin list and the `CLAUDE.md` plugin table.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/team-defaults/` | Full plugin directory | Created |
| `kit/plugins/team-defaults/agents/ts-commenter.md` | TypeScript commenter agent | Created |
| `kit/plugins/team-defaults/agents/css-generator.md` | CSS generator agent | Created |
| `kit/plugins/team-defaults/rules/plan-mode.md` | Plan-mode rule | Created |
| `kit/plugins/team-defaults/rules/component-driven-ui.md` | Component-driven UI rule | Created |
| `kit/plugins/team-defaults/rules/typescript-jsdoc.md` | TypeScript JSDoc rule | Created |
| `kit/plugins/team-defaults/rules/review-bot-loops.md` | Review-bot loops rule | Created |
| `kit/plugins/team-defaults/rules/reference/SKELETON.md` | Plan skeleton reference | Created |
| `kit/plugins/team-defaults/skills/sync-rules/SKILL.md` | Rule installation skill | Created |
| `kit/plugins/team-defaults/plugin.json` | Plugin manifest | Created |
| `kit/plugins/team-defaults/README.md` | Plugin documentation | Created |
| `kit/plugins/team-defaults/CHANGELOG.md` | Version history | Created |
| `.claude-plugin/marketplace.json` | team-defaults v0.1.0 | Modified |
| `tests/publish/smoke-clean-dist.sh` | Plugin list updated | Modified |
| `CLAUDE.md` | Plugin table | Modified |

## How it works

The plugin packages shareable team defaults as a distributable marketplace entry. `plugin.json` carries the name only (no `version` key — the version lives exclusively in `marketplace.json` per repo convention). The bundled `plan-mode.md` rule references only the `plan-agent` plugin's shipped hook, not a machine-local path.

`sync-rules` walks the bundled rules directory and offers each rule file for installation to `~/.claude/rules/` with a per-file confirmation, so a teammate can pick which defaults they want without accepting the full set.

## How to use it

```
/plugin marketplace add shawn-sandy/agentics
/plugin install team-defaults@agentics-kit
```

Then run `/team-defaults:sync-rules` to install the shared rules into `~/.claude/rules/` with per-file confirmation.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-07-13 | feat: add team-defaults plugin (0.1.0) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
