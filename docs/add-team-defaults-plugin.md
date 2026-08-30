# Add team-defaults plugin

> Create a `team-defaults` plugin carrying shareable agents and global rules with a `sync-rules` skill that installs them into `~/.claude/rules/` with per-file confirmation, and register it in the marketplace at v0.1.0.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [add-team-defaults-plugin](plans/add-team-defaults-plugin.md)
**Type:** feature

> **Note:** `team-defaults` was subsequently retired and removed from the marketplace on 2026-08-23. See the removed-plugins registry for the reason (the plugin was never invoked in practice; rule distribution is covered by `settings-sync`; bundled rule copies had drifted from `~/.claude/rules/`). The source is recoverable from git history.

## What shipped

- Created `kit/plugins/team-defaults/` with two shareable agents (`ts-commenter`, `css-generator`), four global rules plus `reference/SKELETON.md`, and a `sync-rules` skill with per-file confirmation.
- Rewrote the bundled `plan-mode.md` to remove machine-local hook paths.
- Registered `team-defaults` in `.claude-plugin/marketplace.json` at v0.1.0 under the `productivity` category.
- Extended `tests/publish/smoke-clean-dist.sh` to include the new plugin and updated the CLAUDE.md plugin table.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/team-defaults/` | Plugin root — agents, rules, sync-rules skill, README, CHANGELOG | Missing (removed post-ship) |
| `.claude-plugin/marketplace.json` | team-defaults registered at 0.1.0 | Modified |
| `tests/publish/smoke-clean-dist.sh` | Plugin list extended to include team-defaults | Modified |
| `CLAUDE.md` | Plugin table row for team-defaults | Modified |

## How it works

The user's `~/.claude/` folder holds agents and global rules the whole team should share. Hand-copying dotfiles provides no versioning or update mechanism; this repo is already a plugin marketplace, so a plugin is the natural distribution channel.

Content selection excluded project-specific material (`ticket-creator.md` belongs to a single project's setup) and vendored skills, keeping only the two agents and four rules that are genuinely team-wide. The bundled `plan-mode.md` was rewritten to remove any reference to `~/.claude/hooks/validate-plan-filename.py`, because teammates installing the plugin would not have that home-directory hook — the hook ships with `plan-agent` instead.

The `sync-rules` skill installs each bundled rule into `~/.claude/rules/` with an AskUserQuestion confirmation per file, making adoption opt-in per rule rather than all-or-nothing. The plugin structure satisfied `.claude-plugin/plugin.json` validation (name only, no version key) and passed `/validate-plugin team-defaults`.

Registering in `marketplace.json` as a relative `git-subdir` source under `kit/plugins/team-defaults` made the plugin discoverable via `/plugin install team-defaults@agentics-kit` and distributable via the `publish-dist.yml` workflow. The smoke test at `tests/publish/smoke-clean-dist.sh` was extended to assert `dist/kit/plugins/team-defaults` is produced.

## How to use it

The plugin source has been removed from the repository. To recover it:

```bash
git log --all --oneline -- kit/plugins/team-defaults/
git show <sha>:kit/plugins/team-defaults/.claude-plugin/plugin.json
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `df49b6d` | 2026-08-12 | feat(settings-sync): restore onto a new machine via clone URL (1.1.0) (#548) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin](plans/add-team-defaults-plugin.md)
