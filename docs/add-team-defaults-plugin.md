# Add team-defaults plugin

> Create a `team-defaults` plugin carrying shareable agents and global rules, distributed through the plugin marketplace with a `sync-rules` skill that installs rules into `~/.claude/rules/`.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/team-defaults/` with bundled agents (`ts-commenter`, `css-generator`), global rules (`plan-mode.md`, `component-driven-ui`, `typescript-jsdoc`, `review-bot-loops`, plus `reference/SKELETON.md`), and a `sync-rules` skill for one-by-one installation into `~/.claude/rules/`.
- Rewrote the hook reference in the bundled `plan-mode.md` so it no longer references a machine-local `~/.claude/hooks/validate-plan-filename.py` path.
- Registered `team-defaults` at v0.1.0 in `.claude-plugin/marketplace.json` under the `productivity` category.
- Extended `tests/publish/smoke-clean-dist.sh` plugin list and updated the CLAUDE.md plugin table.

Note: the `team-defaults` plugin source was subsequently removed from the repository (retired as unused per the removed-plugins registry; recoverable from git history). The source directory no longer exists on `main`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/team-defaults/` | Plugin source directory | Missing (deleted post-ship) |
| `.claude-plugin/marketplace.json` | team-defaults v0.1.0 entry | Modified |
| `tests/publish/smoke-clean-dist.sh` | Extended plugin list | Modified |
| `CLAUDE.md` | Plugin table updated | Modified |

## How it works

The plugin bundled two categories of shareable content: agents (reusable role definitions) and global rules (authoring conventions). Rather than hand-copying dotfiles, users install the plugin from the marketplace and run `sync-rules` to install each rule file into `~/.claude/rules/` with per-file confirmation. The `plan-mode.md` rule was adapted to remove the home-directory hook path so it works on any machine.

The `sync-rules` skill used a per-file prompt so users could decline individual rules that didn't fit their workflow — a single `rsync` would have installed everything without review.

The plugin was marked as requiring no version key in `plugin.json` (only in `marketplace.json`), consistent with the repo's relative-path plugin convention.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
