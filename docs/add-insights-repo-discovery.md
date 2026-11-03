# Add repo discovery and global-dir fallback to implementing-insights

> Makes the `implementing-insights` skill resolve target repos discover-first using `~/.claude/projects/` slugs, asking only as a last resort, and routes workflow-shaped items to `~/.claude/` for users without a plugin repo.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
**Type:** feature

## What shipped

- Rewrote Step 3's resolution logic in `implementing-insights/SKILL.md` as a three-step sequence: inventory from `~/.claude/projects/` slugs (worktree slugs filtered; non-alphanumeric characters encoded as `-` for Windows portability), name-suffix matching verified against a real git checkout, then ask-for-directory fallback scanned one level deep.
- Added the plugin-layer fallback to Step 3's workflow-shaped bullet: no personal plugin repo → route to `~/.claude/` as the next-best fit.
- Bumped `memory-tools` to `4.3.0` in `.claude-plugin/marketplace.json` with CHANGELOG entry and README update.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill instructions | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin documentation | Modified |

## How it works

`~/.claude/projects/` exists on every Claude Code install and contains slugs for every project that has been opened. Because the usage-insights report is generated from the same usage data, every repo the report names has a corresponding slug there. The skill decodes slugs by replacing `-` with `/` and verifying the result is a real git checkout, using a worktree slug marker (`-claude-worktrees-`) to filter out isolated worktree entries.

When no match is found, the skill asks only for a projects directory path and scans it one level deep — never asking the user for per-repo paths first. Workflow-shaped items are routed to `~/.claude/` when the user has no personal plugin repo, making the skill portable to any Claude Code installation without assuming a machine-specific layout.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `7a4214f` | 2026-09-26 | feat(memory-tools): implementing-insights publishes a live record per item (4.4.0) (#638) |
| `19174f7` | 2026-08-23 | fix(memory-tools): stricter repo resolution in implementing-insights (4.3.1) (#597) |

<!-- generated:end -->

## References

- Plan: [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
