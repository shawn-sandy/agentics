# Add team-defaults plugin

> Create `kit/plugins/team-defaults/` carrying shareable agents and global rules, with a `sync-rules` skill that installs the rules into `~/.claude/rules/`, and register it in the marketplace at v0.1.0.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/team-defaults/` with two agents (`ts-commenter`, `css-generator`), four global rules (`plan-mode.md`, `component-driven-ui.md`, `typescript-jsdoc.md`, `review-bot-loops.md`) plus a plan skeleton reference, a `sync-rules` skill, `README.md`, and `CHANGELOG.md`
- Rewrote the hook reference in the bundled `plan-mode.md` — the original referenced a user-local path (`~/.claude/hooks/validate-plan-filename.py`) that teammates would not have; the bundle points to the hook as it ships with `plan-agent` instead
- Registered `team-defaults` v0.1.0 in `.claude-plugin/marketplace.json` under category `productivity` with a relative `git-subdir` source
- Extended `tests/publish/smoke-clean-dist.sh` to include `team-defaults` in the plugin roster
- Updated `CLAUDE.md`'s plugin table

> **Note:** `team-defaults` was subsequently retired (2026-08-23) as unused — rule distribution is now covered by `settings-sync` and the bundled rule copies had drifted from `~/.claude/rules/`. The plugin source was deleted; it is recoverable from git history.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/team-defaults/` | Plugin directory (agents, rules, skill, README) | Created (later removed) |
| `.claude-plugin/marketplace.json` | team-defaults v0.1.0 entry | Modified |
| `tests/publish/smoke-clean-dist.sh` | Plugin roster extended | Modified |
| `CLAUDE.md` | Plugin table updated | Modified |

## How it works

The plugin bundled a curated subset of the author's `~/.claude/` contents — specifically the agents and rules that are genuinely team-wide defaults, excluding project-specific agents (`ticket-creator.md`) and vendored skills.

The `sync-rules` skill walks the plugin's `rules/` directory, presents each file with a diff against the current `~/.claude/rules/` contents, and copies accepted files with per-file confirmation. This gave teams a versioned, reviewable distribution channel for shared Claude Code rules rather than hand-copying dotfiles.

The hook reference in the bundled `plan-mode.md` was rewritten to remove the machine-local `~/.claude/hooks/validate-plan-filename.py` path — teammates installing the plugin would not have that hook at that path, so the reference would cause confusion. The hook ships with `plan-agent` and the bundle documents where to find it there.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
- Removal record: [.claude/rules/removed-plugins.md](../.claude/rules/removed-plugins.md)
- Successor: [kit/plugins/settings-sync/](../kit/plugins/settings-sync/) — rule distribution is now covered here
