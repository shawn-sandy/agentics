# Add the implementing-insights skill to memory-tools

> Ships `implementing-insights` as a third skill in the `memory-tools` plugin — a repeatable workflow for triaging and acting on usage-insights reports — and removes the personal-skill copy.

<!-- generated:start -->

**Status:** Shipped 2026-08-19  **Plan:** [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
**Type:** feature

## What shipped

- Moved the `implementing-insights` skill from `~/.claude/skills/implementing-insights/` into `kit/plugins/memory-tools/skills/implementing-insights/` (the personal copy was deleted).
- Rewrote `SKILL.md` frontmatter and body to conform to repo conventions: three-part description within 200 chars, `allowed-tools` including `ToolSearch` and `ExitPlanMode`, the verbatim plan-mode guard as the first step, a verification-gate line in the reporting step, and all personal absolute paths generalized.
- Bumped `memory-tools` to `4.2.0` in `.claude-plugin/marketplace.json` only (MINOR — new skill); description and tags extended; `plugin.json` updated without adding a `version` field (which would silently override the marketplace value).
- Added a `v4.2.0` entry to `kit/plugins/memory-tools/CHANGELOG.md` and documented the skill in the plugin README (skills table, section, structure tree, current version line).
- The full suite (`bash tests/run-all.sh`) passes: `test-exitplanmode-guard.sh` and `test-description-budget.sh` sweep every `kit/plugins/**/skills/**/SKILL.md`, so the new skill is covered automatically with no CI wiring change.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill instructions | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Changelog | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin README | Modified |

## How it works

The `implementing-insights` skill encodes a workflow for acting on usage-insights reports: triage every recommendation against existing config before implementing anything, place each open item at the correct config layer (plugin / user-global / repo), implement one item per PR with worktree isolation for parallel agents, and clean up afterward.

This workflow was originally captured as a personal skill at `~/.claude/skills/implementing-insights/`. The config-layer placement rule from the 2026-08-19 usage-insights session determined that workflow-shaped behavior belongs in versioned plugins, not personal skill files — plugins are synced across machines and are visible to other Claude Code users. `memory-tools` was the natural home because it already owns Claude Code configuration quality via `agentic-memory-management` and `path-rules-advisor`.

The SKILL.md rewrite generalized all personal absolute paths and added the structural elements required by the repo's skill-authoring conventions: the plan-mode guard as the very first step, `ExitPlanMode` in `allowed-tools`, and a verification gate in the final reporting step. The three-part description was trimmed to fit the 200-character budget enforced by `test-description-budget.sh`.

The `version` field was intentionally omitted from `plugin.json` — a version there silently overrides the marketplace value, which is a documented gotcha in `CLAUDE.md`. Version authority lives solely in `.claude-plugin/marketplace.json`.

## How to use it

```text
/memory-tools:implementing-insights
```

Invoke the skill after receiving a usage-insights report to triage and act on its recommendations systematically. The skill walks through: reading the report, checking existing config at each layer, placing open items, implementing changes in isolated worktrees, and verifying results.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
