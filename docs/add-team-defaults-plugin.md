# Add team-defaults plugin

> Create `kit/plugins/team-defaults/` carrying shareable agents and global rules, with a `sync-rules` skill that installs rules into `~/.claude/rules/` with per-file confirmation, and register it in the marketplace at v0.1.0.

<!-- generated:start -->

**Status:** Shipped 2026-07-13  **Plan:** [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
**Type:** feature

## What shipped

- Created the `team-defaults` plugin scaffold at `kit/plugins/team-defaults/` carrying two shareable agents (`ts-commenter`, `css-generator`) and four global rules plus a plan skeleton reference.
- Rewrote the bundled `plan-mode.md` to remove the machine-local `~/.claude/hooks/validate-plan-filename.py` reference, replacing it with the correct attribution to `plan-agent` (so teammates without that hook path can install cleanly).
- Authored the `sync-rules` skill with `allowed-tools` frontmatter and per-file confirmation prompts, so rules are never blindly overwritten.
- Registered `team-defaults` v0.1.0 in `.claude-plugin/marketplace.json` under category `productivity` with a relative `git-subdir` source.
- Extended `tests/publish/smoke-clean-dist.sh` and the CLAUDE.md plugin table to include the new plugin, ensuring the build pipeline distributes it.

> **Note:** `team-defaults` was subsequently retired on 2026-08-23 as unused (see `removed-plugins` rule). The plugin source was preserved in git history.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/team-defaults/.claude-plugin/plugin.json` | Plugin manifest (no version key) | Missing (removed) |
| `kit/plugins/team-defaults/skills/sync-rules/SKILL.md` | Sync skill with allowed-tools | Missing (removed) |
| `kit/plugins/team-defaults/README.md` | Plugin overview and usage | Missing (removed) |
| `kit/plugins/team-defaults/CHANGELOG.md` | v0.1.0 entry | Missing (removed) |
| `.claude-plugin/marketplace.json` | Marketplace registration at v0.1.0 | Modified |
| `tests/publish/smoke-clean-dist.sh` | Smoke test extended for new plugin | Modified |

## How it works

The plugin was designed as a version-controlled distribution channel for team-wide dotfiles. Because the agentics repo is already a plugin marketplace, a plugin is the natural mechanism — teammates install it once and get the same agents and rules without hand-copying files.

The scaffold followed the repo's required plugin structure: a `plugin.json` at `.claude-plugin/plugin.json` with no `version` key (version lives only in `marketplace.json`), a `skills/` directory, `README.md`, and `CHANGELOG.md`. The version was registered exclusively in `marketplace.json` at `0.1.0` to avoid the silent-override footgun documented in `CLAUDE.md`.

Content curation was deliberate: project-specific content (`ticket-creator.md`, an astro-basics-only agent) was excluded, and the `plan-mode.md` rule copy was rewritten so the `validate-plan-filename` hook reference pointed at `plan-agent` rather than a machine-local path. This ensures teammates without that specific hook installed don't get a broken rule.

The `sync-rules` skill asked for per-file confirmation before copying anything into `~/.claude/rules/`, which was the key safety mechanism — the install is interactive, not a silent overwrite.

The `smoke-clean-dist.sh` test and CLAUDE.md plugin table were updated alongside the plugin, ensuring the daily publish build would include `dist/kit/plugins/team-defaults` and the CI smoke test would catch any missing distribution.

## How to use it

> This plugin was retired (2026-08-23) and is no longer in the marketplace. The source is recoverable from git history.

Previously:
```text
/plugin marketplace add shawn-sandy/agentics
/plugin install team-defaults@agentics-kit
```
Then run the `sync team rules` skill to install global rules into `~/.claude/rules/`.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
