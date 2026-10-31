# Add team-defaults plugin

> Create `kit/plugins/team-defaults/` carrying the shareable agents (`ts-commenter`, `css-generator`) and global rules (plan-mode, component-driven-ui, typescr...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
**Type:** feature

## What shipped

- Copy agents and rules from `~/.claude/` into `kit/plugins/team-defaults/`, excluding project-specific content (`ticket-creator.md` is astro-basics-only) and vendored skills. —
- Rewrite the hook reference in the bundled `plan-mode.md` (the `validate-plan-filename` hook ships with `plan-agent`, not at a home path). —
- Write `.claude-plugin/plugin.json` (name only, no version), `skills/sync-rules/SKILL.md` with `allowed-tools`, `README.md`, `CHANGELOG.md`. —
- Register `team-defaults` v0.1.0 in `.claude-plugin/marketplace.json` (category `productivity`). —
- Update `tests/publish/smoke-clean-dist.sh` plugin list and the CLAUDE.md plugin table. —

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/team-defaults/` | plugin directory (agents, rules) | Created |
| `kit/plugins/team-defaults/skills/sync-rules/SKILL.md` | Skill instructions | Created |
| `kit/plugins/team-defaults/README.md` | Plugin documentation | Created |
| `kit/plugins/team-defaults/CHANGELOG.md` | Changelog | Created |
| `kit/plugins/team-defaults/.claude-plugin/plugin.json` | Plugin metadata | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `CLAUDE.md` | Plugin table | Modified |
| `tests/publish/smoke-clean-dist.sh` | Test suite | Modified |

## How it works

Create `kit/plugins/team-defaults/` carrying the shareable agents (`ts-commenter`, `css-generator`) and global rules (plan-mode, component-driven-ui, typescript-jsdoc, review-bot-loops + plan skeleton), with a `sync-rules` skill that installs the rules into `~/.claude/rules/` with per-file confirmation, and register it in the marketplace at v0.1.0.

The user's `~/.claude/` folder holds agents and global rules the whole team should share. Hand-copying dotfiles doesn't version or update; this repo is already a plugin marketplace, so a plugin is the natural distribution channel.

The implementation proceeded through the following steps: Copy agents and rules from `~/.claude/` into `kit/plugins/team-defaults/`, excluding project-specific content (`ticket-creator.md` is astro-basics-only) and vendored skills. —; Rewrite the hook reference in the bundled `plan-mode.md` (the `validate-plan-filename` hook ships with `plan-agent`, not at a home path). —; Write `.claude-plugin/plugin.json` (name only, no version), `skills/sync-rules/SKILL.md` with `allowed-tools`, `README.md`, `CHANGELOG.md`. —; Register `team-defaults` v0.1.0 in `.claude-plugin/marketplace.json` (category `productivity`). —; Update `tests/publish/smoke-clean-dist.sh` plugin list and the CLAUDE.md plugin table. —.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
