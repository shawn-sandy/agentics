# Add repo discovery and global-dir fallback to implementing-insights

> `implementing-insights` now resolves target repos discover-first via `~/.claude/projects/` slugs and routes workflow-shaped items to `~/.claude/` when the user has no plugin repo of their own — portable to any Claude Code install.

<!-- generated:start -->

**Status:** Shipped 2026-08-19 **Plan:** [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
**Type:** feature

## What shipped

- Rewrote Step 3's resolution paragraph in `SKILL.md` as a three-step sequence: inventory from `~/.claude/projects/` slugs (worktree slugs filtered, non-alphanumeric characters encoded as `-` for Windows portability), name-suffix matching verified against a real git checkout, then ask-for-directory fallback scanned one level deep.
- Added a plugin-layer fallback to Step 3's workflow-shaped bullet: when the user has no personal plugin repo, items route to `~/.claude/` as the next-best fit.
- Bumped `memory-tools` to `4.3.0` in `.claude-plugin/marketplace.json`, added the CHANGELOG entry, and synced the plugin README with the updated version line and step list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill instructions | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin documentation | Modified |

## How it works

`~/.claude/projects/` exists on every Claude Code install and is the same usage data the insights report is generated from, so every repo the report can name has a slug there. The slug inventory gives the skill a machine-independent way to find repos without requiring any hardcoded or machine-specific path.

Worktree slugs are filtered out (they carry a `-claude-worktrees-` marker), and each remaining slug is decoded and verified against a real git checkout before being offered. If a repo name from the report still can't be resolved by slug inventory and name-suffix matching, the user is asked to point at a projects directory (scanned one level deep), never for per-repo paths first.

The global-dir fallback ensures the skill works for marketplace users who have no personal plugin repo: workflow-shaped items that would normally go into a plugin repo are routed to `~/.claude/` instead.

## How to use it

The discovery is built into `/memory-tools:implementing-insights`. When the skill encounters a repo name from an insights report, it resolves it automatically via `~/.claude/projects/` before asking the user. The ask is for a projects directory, not for individual repo paths.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f25758e2` | 2026-08-19 | feat(memory-tools): implementing-insights discovers repos, global-dir fallback (4.3.0) (#587) |

<!-- generated:end -->

## References

- Plan: [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
