# Add implementing-insights skill to memory-tools

> `implementing-insights` is a third skill in the `memory-tools` plugin that codifies the repeatable workflow for acting on usage-insights reports — triage, place, implement, clean up — replacing a personal `~/.claude/skills/` copy with a versioned plugin skill.

<!-- generated:start -->

**Status:** Shipped 2026-08-19 **Plan:** [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
**Type:** feature

## What shipped

- Moved `~/.claude/skills/implementing-insights/` into `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md`.
- Rewrote frontmatter and body to repo conventions: three-part ≤200-char description, `allowed-tools` including `ToolSearch` + `ExitPlanMode`, verbatim plan-mode guard as first step, and generalized absolute paths.
- Bumped `memory-tools` to `4.2.0` in `.claude-plugin/marketplace.json` only (MINOR — new skill); extended the plugin description and tags; did not add `version` to `plugin.json`.
- Added a `v4.2.0` entry to `kit/plugins/memory-tools/CHANGELOG.md` and documented the new skill in the plugin README (skills table, section, structure tree, current version).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | New skill | Created |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin documentation | Modified |

## How it works

`implementing-insights` codifies the 2026-08-19 usage-insights session's repeatable workflow: triage every recommendation against existing config before implementing anything, place each open item at the correct config layer (plugin / user-global / repo), implement one item per PR with worktree isolation for parallel agents, and clean up afterward.

The skill lives in `memory-tools` because workflow-shaped behavior belongs in the user's own plugins — versioned and synced across machines — rather than in personal `~/.claude/skills/`. `memory-tools` already owns Claude Code configuration quality via `agentic-memory-management` and `path-rules-advisor`, making it the natural home for a skill that acts on usage reports.

The personal `~/.claude/skills/implementing-insights/` copy was retired on ship to prevent it from shadowing the plugin skill in sessions where both paths are loaded.

## How to use it

```
/memory-tools:implementing-insights
```

Activated by description match on requests to act on usage reports or implement insights. The skill guides through triage, placement, implementation, and cleanup in order.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb7` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
