# Add the implementing-insights skill to memory-tools

> Moves the `implementing-insights` skill from a personal `~/.claude/skills/` copy into the versioned `memory-tools` plugin, conforming to repo conventions, and removes the personal copy.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
**Type:** feature

## What shipped

- Moved `~/.claude/skills/implementing-insights/` into `kit/plugins/memory-tools/skills/implementing-insights/` as the third skill in `memory-tools`, alongside `agentic-memory-management` and `path-rules-advisor`.
- Rewrote `SKILL.md` frontmatter and body to repo conventions: three-part description ≤200 chars, `allowed-tools` including `ToolSearch` + `ExitPlanMode`, the verbatim plan-mode guard as the first step, verification-gate line in the reporting step, and personal absolute paths generalized.
- Bumped `memory-tools` to `4.2.0` in `.claude-plugin/marketplace.json` only (MINOR — new skill); extended description and tags; mirrored description/keywords in `plugin.json` without adding `version` there.
- Added a `v4.2.0` entry to `kit/plugins/memory-tools/CHANGELOG.md` and documented the skill in the plugin README (skills table, section, structure tree, current version).
- Removed the personal copy at `~/.claude/skills/implementing-insights/`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill instructions — triage, placement, and implementation workflow | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry — memory-tools 4.2.0 | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Changelog — v4.2.0 entry | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin docs — skills table and section | Modified |

## How it works

The `implementing-insights` skill encodes a repeatable workflow for acting on usage-insights reports: triage every recommendation against existing config before implementing anything, place each open item at the correct config layer (plugin / user-global / repo), implement one item per PR with worktree isolation for parallel agents, and clean up afterward.

The key placement decision was to put this skill in `memory-tools` rather than creating a new plugin or adding it to `git-agent`. The `memory-tools` plugin already owns Claude Code configuration quality (`agentic-memory-management`, `path-rules-advisor`), and the workflow is config-shaped — it directs which config layer to touch for each finding. Workflow-shaped behavior belongs in a versioned plugin rather than a personal skill so it syncs across machines.

Per the CLAUDE.md gotcha on versioning: `version` was bumped only in `.claude-plugin/marketplace.json` and not in `plugin.json`. Adding `version` to a relative-path `plugin.json` would silently override the marketplace value, which is the bug this convention exists to prevent.

The `tests/run-all.sh` auto-discovery covers the new skill automatically — `test-exitplanmode-guard.sh` and `test-description-budget.sh` sweep every `kit/plugins/**/skills/**/SKILL.md`, so no CI wiring was needed.

## How to use it

`implementing-insights` is activated by its description: "Implements usage-insights report findings across local repos. Triages against config; implements open items, each with a live record."

```
/memory-tools:implementing-insights    # start implementing findings from the latest insights report
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
- Related: [add-insights-repo-discovery.md](add-insights-repo-discovery.md) — follow-up that adds repo auto-discovery to this skill
