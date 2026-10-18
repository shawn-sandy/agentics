# Add team-defaults plugin

> Creates the `team-defaults` plugin to distribute shareable agents and global rules from the user's `~/.claude/` folder across a team through the existing plugin marketplace, with a `sync-rules` skill that installs the rules with per-file confirmation.

<!-- generated:start -->

**Status:** Shipped 2026-07-13  **Plan:** [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/team-defaults/` carrying the `ts-commenter` and `css-generator` agents, four global rules (`plan-mode`, `component-driven-ui`, `typescript-jsdoc`, `review-bot-loops`) plus `reference/SKELETON.md`.
- Rewrote the hook reference in the bundled `plan-mode.md` to remove the machine-local `~/.claude/hooks/` path (the `validate-plan-filename` hook ships with `plan-agent`, not at a home path).
- Added `skills/sync-rules/SKILL.md` with `allowed-tools` and per-file confirmation flow.
- Added `.claude-plugin/plugin.json` (name only, no version), `README.md`, and `CHANGELOG.md`.
- Registered `team-defaults` at `v0.1.0` in `.claude-plugin/marketplace.json` under the `productivity` category.
- Updated `tests/publish/smoke-clean-dist.sh` plugin list and `CLAUDE.md` plugin reference table.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/team-defaults/` | Plugin directory | Created |
| `kit/plugins/team-defaults/.claude-plugin/plugin.json` | Plugin manifest | Created |
| `kit/plugins/team-defaults/agents/ts-commenter.md` | Agent | Created |
| `kit/plugins/team-defaults/agents/css-generator.md` | Agent | Created |
| `kit/plugins/team-defaults/rules/` | Global rules | Created |
| `kit/plugins/team-defaults/skills/sync-rules/SKILL.md` | Sync skill | Created |
| `kit/plugins/team-defaults/README.md` | Plugin documentation | Created |
| `kit/plugins/team-defaults/CHANGELOG.md` | Release notes | Created |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `tests/publish/smoke-clean-dist.sh` | Smoke test | Modified |
| `CLAUDE.md` | Plugin reference table | Modified |

## How it works

The plugin bundles team-wide defaults that belong in every session but are otherwise distributed only via hand-copying dotfiles. The `sync-rules` skill copies rules into `~/.claude/rules/` with a per-file confirmation gate so each team member can accept or skip individual rules without running a blind overwrite.

The project-specific `ticket-creator.md` agent was excluded since it is specific to one project and does not belong as a team default.

## How to use it

```
/plugin install team-defaults@agentics-kit
```

Then run `sync team rules` or `/team-defaults:sync-rules` to install the rules interactively.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
