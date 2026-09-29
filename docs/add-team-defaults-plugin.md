# Add team-defaults Plugin

> Ship a marketplace plugin distributing shared agents and rules via a `sync-rules` skill, then retire it when `settings-sync` made it redundant.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/team-defaults/` with two bundled agents (`ts-commenter`, `css-generator`) and four global rules (`plan-mode.md`, `component-driven-ui.md`, `typescript-jsdoc.md`, `review-bot-loops.md`) plus `reference/SKELETON.md`
- Wrote the `sync-rules` skill that installs the bundled rules into `~/.claude/rules/` with per-file confirmation
- Registered the plugin in `.claude-plugin/marketplace.json` at `v0.1.0` under the `productivity` category with a `git-subdir` source
- Fixed the hook reference in the bundled `plan-mode.md` so it did not point at a machine-local path (`~/.claude/hooks/validate-plan-filename.py`)
- Added `team-defaults` to `tests/publish/smoke-clean-dist.sh` and the CLAUDE.md plugin table
- Plugin was subsequently retired at `v0.2.3` (commit `9d6f4b3`, 2026-08-23) after session logs showed zero invocations and the bundled rule copies had drifted from `~/.claude/rules/`; `settings-sync` covers the distribution job `sync-rules` existed for

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/team-defaults/.claude-plugin/plugin.json` | Plugin manifest (name only, no version) | Deleted (retired) |
| `kit/plugins/team-defaults/agents/ts-commenter.md` | Bundled TypeScript commenter agent | Deleted (retired) |
| `kit/plugins/team-defaults/agents/css-generator.md` | Bundled CSS generator agent | Deleted (retired) |
| `kit/plugins/team-defaults/skills/sync-rules/SKILL.md` | `sync-rules` skill definition | Deleted (retired) |
| `kit/plugins/team-defaults/skills/sync-rules/rules/plan-mode.md` | Bundled plan-mode rule | Deleted (retired) |
| `kit/plugins/team-defaults/skills/sync-rules/rules/component-driven-ui.md` | Bundled UI rule | Deleted (retired) |
| `kit/plugins/team-defaults/skills/sync-rules/rules/typescript-jsdoc.md` | Bundled JSDoc rule | Deleted (retired) |
| `kit/plugins/team-defaults/skills/sync-rules/rules/review-bot-loops.md` | Bundled review-bot rule | Deleted (retired) |
| `kit/plugins/team-defaults/skills/sync-rules/rules/reference/SKELETON.md` | Plan skeleton reference | Deleted (retired) |
| `kit/plugins/team-defaults/README.md` | Plugin README | Deleted (retired) |
| `kit/plugins/team-defaults/CHANGELOG.md` | Plugin changelog | Deleted (retired) |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `.claude/rules/removed-plugins.md` | Retirement record | Modified |

## How it works

The plan identified a gap in team tooling: `~/.claude/` holds agents and global rules that the whole team should share, but hand-copying dotfiles has no versioning or update story. Because the repo is already a plugin marketplace, a plugin is the natural distribution channel.

The `sync-rules` skill was the primary user-facing component. When invoked, it iterated over the bundled rule files in `skills/sync-rules/rules/` and offered to install each one into `~/.claude/rules/`, asking for per-file confirmation. This gave teammates a single `/team-defaults:sync-rules` command to pull the shared defaults onto any machine.

Two agents were bundled — `ts-commenter` (generates JSDoc comments for TypeScript) and `css-generator` (produces CSS from natural language) — representing genuinely team-wide utilities rather than project-specific automation.

A critical correctness fix was made to the bundled `plan-mode.md`: the original referenced `~/.claude/hooks/validate-plan-filename.py`, a machine-local hook path that only existed on the original developer's machine. The bundled copy was rewritten to reference that the hook ships with `plan-agent`, removing any dependency on a local path.

The plugin was registered in `.claude-plugin/marketplace.json` at `v0.1.0` following the standard `git-subdir` source pattern. No `version` field was added to `plugin.json` itself, following the repo convention where version lives only in the marketplace manifest.

The plugin was retired at `v0.2.3` on 2026-08-23 after session usage logs showed zero invocations of `sync-rules` or either bundled agent. Additionally, three of the four bundled rule files had drifted from their `~/.claude/rules/` originals, making the plugin a second source of truth that nobody was reading. The `settings-sync` plugin already backs up and restores `~/.claude/rules/` and `CLAUDE.md`, covering the distribution job `sync-rules` was designed for.

## How to use it

This plugin has been retired. Use `/settings-sync:settings-backup` and `/settings-sync:settings-restore` to distribute and sync `~/.claude/` rules and settings instead. The plugin source is recoverable from git history at commit `3ee6806` if needed.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `9d6f4b3` | 2026-08-23 | refactor: retire the unused team-defaults plugin (0.2.3) (#599) |
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
- Removed plugins record: [.claude/rules/removed-plugins.md](../.claude/rules/removed-plugins.md)
