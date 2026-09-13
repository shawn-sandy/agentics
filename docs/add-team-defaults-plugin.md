# Add team-defaults plugin

> Created a `team-defaults` plugin to distribute shareable agents and global rules through the marketplace, with a `sync-rules` skill that installs rules into `~/.claude/rules/` with per-file confirmation.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/team-defaults/` with two bundled agents (`ts-commenter`, `css-generator`), four global rules plus `reference/SKELETON.md`, and a `sync-rules` skill with `allowed-tools`, plugin manifest, README, and CHANGELOG (the project-specific `ticket-creator.md` agent was excluded as not team-wide).
- Rewrote the hook reference in the bundled `plan-mode.md` to remove the machine-local `~/.claude/hooks/validate-plan-filename.py` path, since teammates installing the plugin would not have that path.
- Registered `team-defaults` at v0.1.0 in `.claude-plugin/marketplace.json` under the `productivity` category with a relative `git-subdir` source and no `version` key in `plugin.json`.
- Updated `tests/publish/smoke-clean-dist.sh` with the new plugin name and the CLAUDE.md plugin table.

**Note:** The `kit/plugins/team-defaults/` directory no longer exists — the plugin was retired in commit `9d6f4b3` (2026-08-23) as unused, with a marketplace entry at 0.2.3 retained in `.claude-plugin/marketplace.json`. Rule distribution is now covered by the `settings-sync` plugin. Source is recoverable from git history.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/team-defaults/` | Plugin directory: agents, rules, skill, manifest, README, CHANGELOG | Missing (retired 2026-08-23) |
| `tests/publish/smoke-clean-dist.sh` | Smoke test updated with new plugin | Modified |
| `.claude-plugin/marketplace.json` | team-defaults v0.1.0 registration | Modified |

## How it works

The plugin's premise was that a user's `~/.claude/` folder holds agents and global rules that the whole team should share, but hand-copying dotfiles does not version or update. The marketplace is already the distribution channel for this repo's tooling, so a plugin is the natural fit.

The `sync-rules` skill drove the installation experience: it listed each bundled rule and asked for per-file confirmation before writing to `~/.claude/rules/`. This made the install non-destructive — a teammate could pick only the rules they wanted and skip any that conflicted with their existing setup.

The hook reference in the bundled `plan-mode.md` required rewriting before distribution. The original referenced `~/.claude/hooks/validate-plan-filename.py`, which only exists on machines where `plan-agent` installed it. Distributing that path to teammates would cause the rule to reference a non-existent hook, so the bundled copy replaced the reference with a note pointing to the `plan-agent` plugin.

The plugin was registered at v0.1.0 under the `productivity` category. The `plugin.json` intentionally carried no `version` key — for relative-path plugins in this repo, the version lives only in `marketplace.json`, and a `version` key in `plugin.json` would silently override it.

The plugin was retired at v0.2.3 (commit `9d6f4b3`, 2026-08-23) after it was never invoked in practice. Rule distribution has been taken over by the `settings-sync` plugin.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `9d6f4b3` | 2026-08-23 | refactor: retire the unused team-defaults plugin (0.2.3) (#599) |
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
