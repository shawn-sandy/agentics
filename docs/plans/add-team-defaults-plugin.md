---
status: completed
type: feature
created: 2026-07-13
modified: 2026-07-13
repo-name: agentics
---

# Plan: Add team-defaults plugin

## Context

The user's `~/.claude/` folder holds agents and global rules the whole team should share. Hand-copying dotfiles doesn't version or update; this repo is already a plugin marketplace, so a plugin is the natural distribution channel.

## Objective

Create `kit/plugins/team-defaults/` carrying the shareable agents (`ts-commenter`, `css-generator`) and global rules (plan-mode, component-driven-ui, typescript-jsdoc, review-bot-loops + plan skeleton), with a `sync-rules` skill that installs the rules into `~/.claude/rules/` with per-file confirmation, and register it in the marketplace at v0.1.0.

## Steps

1. Copy agents and rules from `~/.claude/` into `kit/plugins/team-defaults/`, excluding project-specific content (`ticket-creator.md` is astro-basics-only) and vendored skills. — *Why:* only genuinely team-wide defaults belong in the plugin. *Verify:* `agents/` has 2 files, `rules/` has 4 + `reference/SKELETON.md`.
2. Rewrite the hook reference in the bundled `plan-mode.md` (the `validate-plan-filename` hook ships with `plan-agent`, not at a home path). — *Why:* teammates won't have `~/.claude/hooks/validate-plan-filename.py`. *Verify:* no `~/.claude/hooks/` path remains in the bundled copy.
3. Write `.claude-plugin/plugin.json` (name only, no version), `skills/sync-rules/SKILL.md` with `allowed-tools`, `README.md`, `CHANGELOG.md`. — *Why:* required plugin structure per repo conventions. *Verify:* `/validate-plugin team-defaults` passes.
4. Register `team-defaults` v0.1.0 in `.claude-plugin/marketplace.json` (category `productivity`). — *Why:* plugins are discovered via the marketplace manifest. *Verify:* JSON validates; entry present.
5. Update `tests/publish/smoke-clean-dist.sh` plugin list and the CLAUDE.md plugin table. — *Why:* both hardcode the plugin roster. *Verify:* `node scripts/build-dist.mjs && bash tests/publish/smoke-clean-dist.sh` prints PASS.

## Tests

> Tier: 2 (non-code — plugin markdown/JSON only)

### Objective-Verification Test

- **File:** `tests/publish/smoke-clean-dist.sh` (extended)
- **Type:** smoke test
- **Asserts:** `dist/kit/plugins/team-defaults` is produced by the publish build, proving the plugin is registered and distributable.
- **Run:** `node scripts/build-dist.mjs && bash tests/publish/smoke-clean-dist.sh`

## Acceptance Criteria

- [ ] `kit/plugins/team-defaults/` exists with plugin.json, 2 agents, 4 rules + skeleton, sync-rules skill, README, CHANGELOG.
- [ ] `marketplace.json` lists `team-defaults` at `0.1.0` with a relative `git-subdir` source; no `version` in `plugin.json`.
- [ ] Bundled `plan-mode.md` does not reference a machine-local hook path.
- [ ] `smoke-clean-dist.sh` passes with the new plugin included.
- [ ] Project-specific `ticket-creator.md` agent is not bundled.

## Verification

Run `node scripts/build-dist.mjs && bash tests/publish/smoke-clean-dist.sh` (PASS expected), then `claude --plugin-dir ./kit/plugins/team-defaults` and confirm the two agents and the sync-rules skill are discovered.

## Next Steps *(optional)*

- Publish and announce to the team:
  ```text
  On the agentics repo, confirm the team-defaults plugin (kit/plugins/team-defaults) has merged to main and the publish-dist workflow has run, then draft a short install note for the team: /plugin marketplace add shawn-sandy/agentics, /plugin install team-defaults@agentics-kit, then run "sync team rules".
  ```
