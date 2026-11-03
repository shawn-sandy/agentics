# Add team-defaults plugin

> Creates a `team-defaults` plugin distributing shareable agents and global rules via the marketplace, with a `sync-rules` skill that installs them into `~/.claude/rules/`.

<!-- generated:start -->

**Status:** Shipped 2026-07-13 **Plan:** [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/team-defaults/` with agents (`ts-commenter`, `css-generator`), rules (`plan-mode`, `component-driven-ui`, `typescript-jsdoc`, `review-bot-loops`) and a `reference/SKELETON.md`.
- Rewrote the bundled `plan-mode.md` to remove machine-local hook path references.
- Added `.claude-plugin/plugin.json`, `skills/sync-rules/SKILL.md`, `README.md`, and `CHANGELOG.md`.
- Registered `team-defaults` v0.1.0 in `.claude-plugin/marketplace.json` (category `productivity`).
- Updated `tests/publish/smoke-clean-dist.sh` plugin list and the CLAUDE.md plugin table.

> **Note:** This plugin was subsequently retired in v0.2.3 (2026-08-23) — see [retire-team-defaults commit](https://github.com/shawn-sandy/agentics/commit/9d6f4b3).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/team-defaults/.claude-plugin/plugin.json` | Plugin manifest | Created |
| `kit/plugins/team-defaults/agents/` (2 files) | Shared agents | Created |
| `kit/plugins/team-defaults/rules/` (4 files + skeleton) | Shared rules | Created |
| `kit/plugins/team-defaults/skills/sync-rules/SKILL.md` | Sync skill | Created |
| `kit/plugins/team-defaults/README.md` | Documentation | Created |
| `kit/plugins/team-defaults/CHANGELOG.md` | Version history | Created |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `tests/publish/smoke-clean-dist.sh` | Build test | Modified |

## How it works

The plugin bundles the team-wide assets from `~/.claude/` that are safe to share across machines — the two shared agents and four global rules — into a versioned plugin directory. The `sync-rules` skill installs them into `~/.claude/rules/` with per-file confirmation, so teammates can adopt team defaults with one command.

The `plan-mode.md` rule was edited to remove a `~/.claude/hooks/validate-plan-filename.py` reference that would only exist on the plugin author's machine. The project-specific `ticket-creator.md` agent was excluded.

## How to use it

```
/plugin install team-defaults@agentics-kit
```

Then activate the sync skill to install the shared rules:

```
sync team rules
```

The skill installs each rule with a per-file confirmation so no existing customizations are overwritten without consent.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `9d6f4b3` | 2026-08-23 | refactor: retire the unused team-defaults plugin (0.2.3) (#599) |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
