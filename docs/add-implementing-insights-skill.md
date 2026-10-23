# Add the implementing-insights skill to memory-tools

> Ships `implementing-insights` as a third skill in the `memory-tools` plugin, replacing a personal `~/.claude/skills/` copy with a versioned, marketplace-distributed workflow.

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
**Type:** feature

## What shipped

- Moved `~/.claude/skills/implementing-insights/` to `kit/plugins/memory-tools/skills/implementing-insights/` and removed the personal copy.
- Rewrote `SKILL.md` to repo conventions: three-part description ≤200 chars, `allowed-tools` including `ToolSearch` + `ExitPlanMode`, the verbatim plan-mode guard as the first step, and personal absolute paths generalized for any Claude Code install.
- Bumped `memory-tools` to `4.2.0` in `.claude-plugin/marketplace.json` (MINOR — new skill) with CHANGELOG entry and plugin README update.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill instructions | Created |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin documentation | Modified |

## How it works

The `implementing-insights` skill encodes a repeatable workflow for acting on usage-insights reports: triage each recommendation against existing config before implementing, place each open item at the correct config layer (plugin / user-global / repo), implement one item per PR with worktree isolation for parallel agents, and clean up afterward.

The skill lives in `memory-tools` because that plugin already owns Claude Code configuration quality (`agentic-memory-management`, `path-rules-advisor`). The plan-mode guard appears as the skill's first step, since it writes files and can mutate git state.

## How to use it

Activate when Claude Code surfaces a usage-insights report. The skill walks through triage, placement, per-item implementation, and cleanup.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `7a4214f` | 2026-09-26 | feat(memory-tools): implementing-insights publishes a live record per item (4.4.0) (#638) |
| `19174f7` | 2026-08-23 | fix(memory-tools): stricter repo resolution in implementing-insights (4.3.1) (#597) |

<!-- generated:end -->

## References

- Plan: [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
