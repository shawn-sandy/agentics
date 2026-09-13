# Add team-defaults plugin

> Created `kit/plugins/team-defaults/` carrying shareable agents and global rules with a `sync-rules` skill for installation. The plugin shipped at v0.1.0 but was retired as unused on 2026-08-23 — rule distribution is now covered by `settings-sync`.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/team-defaults/` with two agents (`ts-commenter`, `css-generator`) and four rules plus `reference/SKELETON.md` sourced from `~/.claude/`, excluding project-specific content (`ticket-creator.md`).
- Rewrote the hook reference in the bundled `plan-mode.md` to remove the machine-local `~/.claude/hooks/validate-plan-filename.py` path (that hook ships with `plan-agent`).
- Wrote `.claude-plugin/plugin.json` (name only, no version), `skills/sync-rules/SKILL.md` with `allowed-tools`, `README.md`, and `CHANGELOG.md`.
- Registered `team-defaults` v0.1.0 in `.claude-plugin/marketplace.json` under `productivity`.
- Extended `tests/publish/smoke-clean-dist.sh` plugin list and the `CLAUDE.md` plugin table.

**Retired 2026-08-23:** The plugin was removed from the marketplace and its source deleted. It was never invoked in production; rule distribution is covered by `settings-sync`. The source is recoverable from git history.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/team-defaults/` | Plugin directory (agents, rules, skill, README, CHANGELOG) | Created (deleted 2026-08-23) |
| `.claude-plugin/marketplace.json` | team-defaults v0.1.0 registration | Modified (entry later removed) |
| `tests/publish/smoke-clean-dist.sh` | Plugin list extended | Modified |
| `CLAUDE.md` | Plugin table updated | Modified |

## How it works

The plugin's premise was that `~/.claude/` holds agents and global rules the whole team should share, and that hand-copying dotfiles doesn't version or update. The repo already distributes plugins, so a plugin was the natural distribution channel.

The `sync-rules` skill installed the bundled rules into `~/.claude/rules/` with per-file confirmation, guarding against silent overwrites. Project-specific content was excluded at authoring time: `ticket-creator.md` was identified as Astro-specific and omitted. The bundled `plan-mode.md` was edited to replace the machine-local hook reference with a note that the hook ships with `plan-agent`, since teammates would not have the path.

The plugin was retired before it saw real use. Measurement showed it was never invoked, and `settings-sync` (which landed shortly after) covers the same rule-distribution need with a more complete implementation. The bundled rule copies had also drifted from `~/.claude/rules/` by the time of retirement.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
