# Add repo discovery and global-dir fallback to implementing-insights

> Make the skill resolve target repos discover-first (ask only as a last resort) and route workflow-shaped items to `~/.claude/` when the user has no plugin re...

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
**Type:** feature

## What shipped

- Rewrite Step 3's resolution paragraph in `SKILL.md` — as a three-step sequence: (`~/.claude/projects/` exists on every install and is the same usage data the)
- Add the plugin-layer fallback — to Step 3's workflow-shaped bullet: no personal (generic plugin users have no plugin repo; without the fallback those items stall.)
- Bump memory-tools to 4.3.0 — in `.claude-plugin/marketplace.json`, add the (MINOR behavior addition per the marketplace versioning rule.)

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `SKILL.md` | Skill instructions | Modified |

## How it works

Make the skill resolve target repos discover-first (ask only as a last resort) and route workflow-shaped items to `~/.claude/` when the user has no plugin repo of their own — portable to any Claude Code install, including Windows.

The `implementing-insights` skill (memory-tools 4.2.0) resolved target repos passively: it took repo names from the insights report and, the moment one was not immediately found, asked the user for a path. It had no way to find local repos on its own, no heuristic for recommendations that name no repo, and its workflow-behavior layer assumed every user maintains a personal plugin repo. The skill ships to marketplace users, so

The implementation proceeded through the following steps: Rewrite Step 3's resolution paragraph in `SKILL.md`: as a three-step sequence:; Add the plugin-layer fallback: to Step 3's workflow-shaped bullet: no personal; Bump memory-tools to 4.3.0: in `.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f25758e` | 2026-08-19 | feat(memory-tools): implementing-insights discovers repos, global-dir fallback (4.3.0) (#587) |

<!-- generated:end -->

## References

- Plan: [add-insights-repo-discovery.md](plans/add-insights-repo-discovery.md)
