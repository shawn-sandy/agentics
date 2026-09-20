# Add repo discovery and global-dir fallback to implementing-insights

> Make the skill resolve target repos discover-first (ask only as a last resort) and route workflow-shaped items to `~/.claude/` when the user has no plugin re...

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
**Type:** feature

## What shipped

- Rewrite Step 3's resolution paragraph in `SKILL.md` — as a three-step sequence: inventory from `~/.claude/projects/` slugs (worktree slugs filtered, non-alphanumeric characters encoded as `-` so it holds on Windows), name-suffix matching verified against a real git checkout, then ask-for-directory fallback scanned one level deep.
- Add the plugin-layer fallback — to Step 3's workflow-shaped bullet: no personal plugin repo → route to `~/.claude/` as the next-best fit.
- Bump memory-tools to 4.3.0 — in `.claude-plugin/marketplace.json`, add the CHANGELOG entry, and sync the plugin README (version line + step list).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `SKILL.md` | Skill instructions | Modified |

## How it works

Make the skill resolve target repos discover-first (ask only as a last resort) and route workflow-shaped items to `~/.claude/` when the user has no plugin repo of their own — portable to any Claude Code install, including Windows.

The `implementing-insights` skill (memory-tools 4.2.0) resolved target repos passively: it took repo names from the insights report and, the moment one was not immediately found, asked the user for a path. It had no way to find local repos on its own, no heuristic for recommendations that name no repo, and its workflow-behavior layer assumed every user maintains a personal plugin repo. The skill ships to marketplace users, so resolution must not assume any machine-specific layout.

The implementation proceeded through the following steps: Rewrite Step 3's resolution paragraph in `SKILL.md` — as a three-step sequence: inventory from `~/.claude/projects/` slugs (worktree slugs filtered, non-alphanumeric characters encoded as `-` so it holds on Windows), name-suffix matching verified against a real git checkout, then ask-for-directory fallback scanned one level deep.; Add the plugin-layer fallback — to Step 3's workflow-shaped bullet: no personal plugin repo → route to `~/.claude/` as the next-best fit.; Bump memory-tools to 4.3.0 — in `.claude-plugin/marketplace.json`, add the CHANGELOG entry, and sync the plugin README (version line + step list)..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f25758e` | 2026-08-19 | feat(memory-tools): implementing-insights discovers repos, global-dir fallback (4.3.0) (#587) |

<!-- generated:end -->

## References

- Plan: [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
