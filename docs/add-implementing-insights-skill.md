# Add the implementing-insights skill to memory-tools

> Ships `implementing-insights` as a third skill in the `memory-tools` plugin (v4.2.0), conforming to repo skill-authoring conventions, and removes the personal-skill copy from `~/.claude/skills/`.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
**Type:** feature

## What shipped

- Moved `~/.claude/skills/implementing-insights/` to `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` (personal copy removed)
- Rewrote SKILL.md frontmatter and body to repo conventions: three-part description ≤200 chars, `allowed-tools` including `ToolSearch` + `ExitPlanMode`, verbatim plan-mode guard as first step, verification-gate line in reporting step, personal absolute paths generalized
- `memory-tools` bumped to `4.2.0` in `.claude-plugin/marketplace.json` only (MINOR — new skill); `plugin.json` has no `version` field
- `v4.2.0` entry added to `kit/plugins/memory-tools/CHANGELOG.md`
- Plugin README updated: skills table, section, structure tree, current version

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill instructions — triage-first workflow for acting on usage-insights reports | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry — memory-tools 4.2.0 | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Release notes — v4.2.0 entry | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin documentation — third skill listed | Modified |

## How it works

The `implementing-insights` skill encodes a repeatable workflow for acting on usage-insights reports. The workflow's key insight is that triage must happen before implementation: each recommendation is evaluated against existing config before any changes are made, and each open item is placed at the correct config layer (plugin / user-global / repo) rather than applied uniformly.

The skill routes parallel implementations through worktree-isolated agents, using one PR per item to keep changes reviewable and reversible. Items that belong in the user's own plugins go to a versioned plugin repo; items that belong in user-global config go to `~/.claude/`; items that belong in the current repo stay there.

Moving the skill from `~/.claude/skills/` to the `memory-tools` plugin means it is versioned, synced across machines via the marketplace, and available in worktrees without manual copying. The personal copy was removed to prevent the plugin skill from being shadowed.

Conforming to repo conventions required updating the description to the three-part format, adding `ToolSearch` and `ExitPlanMode` to `allowed-tools` (required for skills that call deferred tools), and replacing machine-specific absolute paths with environment variables.

## How to use it

The skill activates when discussing implementing usage insights or acting on usage recommendations:

```
/memory-tools:implementing-insights      # process a usage-insights report
```

The skill's first step is a triage pass — it reads the full report, groups findings by config layer, and surfaces conflicts with existing config before any changes. The user confirms the triage before implementation begins.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `7a4214f` | 2026-09-26 | feat(memory-tools): implementing-insights publishes a live record per item (4.4.0) (#638) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
