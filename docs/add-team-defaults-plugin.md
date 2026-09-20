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
| `ticket-creator.md` | Documentation | Modified |
| `reference/SKELETON.md` | Documentation | Modified |
| `plan-mode.md` | Documentation | Modified |
| `skills/sync-rules/SKILL.md` | Skill instructions | Modified |
| `README.md` | Plugin documentation | Modified |
| `CHANGELOG.md` | Changelog | Modified |
| `tests/publish/smoke-clean-dist.sh` | Test suite | Modified |

## How it works

Create `kit/plugins/team-defaults/` carrying the shareable agents (`ts-commenter`, `css-generator`) and global rules (plan-mode, component-driven-ui, typescript-jsdoc, review-bot-loops + plan skeleton), with a `sync-rules` skill that installs the rules into `~/.claude/rules/` with per-file confirmation, and register it in the marketplace at v0.1.0.

The user's `~/.claude/` folder holds agents and global rules the whole team should share. Hand-copying dotfiles doesn't version or update; this repo is already a plugin marketplace, so a plugin is the natural distribution channel.

The implementation proceeded through the following steps: Copy agents and rules from `~/.claude/` into `kit/plugins/team-defaults/`, excluding project-specific content (`ticket-creator.md` is astro-basics-only) and vendored skills. — *Why:* only genuinely team-wide defaults belong in the plugin. *Verify:* `agents/` has 2 files, `rules/` has 4 + `reference/SKELETON.md`.; Rewrite the hook reference in the bundled `plan-mode.md` (the `validate-plan-filename` hook ships with `plan-agent`, not at a home path). — *Why:* teammates won't have `~/.claude/hooks/validate-plan-filename.py`. *Verify:* no `~/.claude/hooks/` path remains in the bundled copy.; Write `.claude-plugin/plugin.json` (name only, no version), `skills/sync-rules/SKILL.md` with `allowed-tools`, `README.md`, `CHANGELOG.md`. — *Why:* required plugin structure per repo conventions. *Verify:* `/validate-plugin team-defaults` passes.; Register `team-defaults` v0.1.0 in `.claude-plugin/marketplace.json` (category `productivity`). — *Why:* plugins are discovered via the marketplace manifest. *Verify:* JSON validates; entry present.; Update `tests/publish/smoke-clean-dist.sh` plugin list and the CLAUDE.md plugin table. — *Why:* both hardcode the plugin roster. *Verify:* `node scripts/build-dist.mjs && bash tests/publish/smoke-clean-dist.sh` prints PASS..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
