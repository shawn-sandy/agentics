# Add repo discovery and global-dir fallback to implementing-insights

> Makes `implementing-insights` resolve target repos discover-first via `~/.claude/projects/` slugs and routes workflow-shaped items to `~/.claude/` when the user has no plugin repo — portable to any Claude Code install.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-insights-repo-discovery](plans/add-insights-repo-discovery.md)
**Type:** feature

## What shipped

- Rewrote Step 3's resolution paragraph as a three-step sequence: inventory from `~/.claude/projects/` slugs, name-suffix matching verified against a real git checkout, then ask-for-directory fallback scanned one level deep
- Added `~/.claude/` as the workflow-shaped item destination when the user has no personal plugin repo
- Bumped `memory-tools` to `4.3.0` in marketplace.json with CHANGELOG entry and README sync (version line + step list)
- Discovery verified live: `~/.claude/projects/` slugs decode to real checkouts; worktree slugs distinguishable by `-claude-worktrees-` marker

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill instructions — discover-first resolution, global fallback | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — memory-tools 4.3.0 | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Release history — 4.3.0 entry | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin docs — version and step list | Modified |

## How it works

The previous version of `implementing-insights` asked the user for a repo path whenever a named repo wasn't immediately found. This was a machine-specific interaction pattern that broke on any install that didn't match the author's local layout.

The fix uses `~/.claude/projects/` — which exists on every Claude Code install and is the same usage data that generated the insights report — as the repo inventory source. Every repo the report can name has a slug there because the report is generated from that data. Worktree slugs are filtered out by detecting the `-claude-worktrees-` marker in the path.

Name resolution is a three-step sequence: first, build an inventory of all project slugs and decode them to filesystem paths (non-alphanumeric characters were encoded as `-`, reversibly). Second, find a name-suffix match against the decoded paths and verify it points to an actual git checkout. Third, if nothing matches, ask the user for a projects directory to scan one level deep.

The plugin-layer fallback routes workflow-shaped items (those that would normally go into a personal plugin repo) to `~/.claude/` when no plugin repo is found. This makes the skill useful for generic marketplace users who have no custom plugin directory.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-insights-repo-discovery](plans/add-insights-repo-discovery.md)
