# Add repo discovery and global-dir fallback to implementing-insights

> Makes `implementing-insights` resolve target repos from `~/.claude/projects/` slugs before asking the user, and routes workflow-shaped items to `~/.claude/` when the user has no personal plugin repo.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
**Type:** feature

## What shipped

- Rewrote Step 3's resolution paragraph in `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` as a three-step sequence: inventory repos from `~/.claude/projects/` slugs (worktree slugs filtered by the `-claude-worktrees-` marker; non-alphanumeric characters encoded as `-` for Windows portability), name-suffix match verified against a real git checkout, then ask-for-directory fallback scanned one level deep.
- Added the plugin-layer fallback to Step 3's workflow-shaped bullet: when the user has no personal plugin repo, route those items to `~/.claude/` as the next-best fit.
- Bumped `memory-tools` to `4.3.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry and synced the plugin README (version line and step list).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill instructions — repo resolution rewrite | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry — memory-tools 4.3.0 | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Changelog — 4.3.0 entry | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin docs — version and step list | Modified |

## How it works

The previous skill asked the user for a path the moment a named repo was not immediately found in common locations. This was fragile for marketplace users whose machine layouts differ from the skill author's.

The fix exploits `~/.claude/projects/`: every repo Claude Code has ever opened has a slug directory there, because that's where the usage-insights data itself comes from. Slug names encode the repo path with `/` replaced by `-`, so `agentics` at `/Users/shawnsandy/devbox/agentics` appears as `-Users-shawnsandy-devbox-agentics`. The skill builds an inventory by listing slug directories, filtering out worktree slugs (identified by the `-claude-worktrees-` segment), decoding slug names back to candidate paths, and verifying each against a real git checkout.

When a finding names a repo, the skill tries a name-suffix match against this inventory (e.g., "agentics" matches any path ending in `/agentics`) before falling back to asking the user to point at a projects directory (not a per-repo path), which the skill then scans one level deep. This reduces the ask from "where is X?" to "where are your projects?" — asked at most once per session.

The `~/.claude/` fallback for workflow-shaped items handles the common case of a marketplace user with no personal plugin repo. Rather than stalling on a missing repo, those items are routed to the user-global config directory, which exists on every Claude Code install including Windows.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
- Related: [add-implementing-insights-skill.md](add-implementing-insights-skill.md) — the skill this builds on
