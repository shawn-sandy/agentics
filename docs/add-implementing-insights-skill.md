# Add the implementing-insights skill to memory-tools

> Ships `implementing-insights` as a third skill in the `memory-tools` plugin (v4.2.0), conforming to repo skill-authoring conventions and removing the personal-skill copy.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-implementing-insights-skill](plans/add-implementing-insights-skill.md)
**Type:** feature

## What shipped

- Moved `~/.claude/skills/implementing-insights/` to `kit/plugins/memory-tools/skills/implementing-insights/`
- Rewrote `SKILL.md` frontmatter and body to repo conventions: three-part description ≤200 chars, `allowed-tools` including `ToolSearch` + `ExitPlanMode`, verbatim plan-mode guard as first step, verification-gate line in reporting step
- Removed machine-specific absolute paths, generalized to portable references
- Bumped `memory-tools` to `4.2.0` in marketplace.json (MINOR — new skill); no version in `plugin.json`
- Added `v4.2.0` entry to `CHANGELOG.md`; updated plugin README (skills table, section, structure tree, version)
- `bash tests/run-all.sh` and `BASE_REF=main node scripts/check-plugin-versions.mjs` both pass

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill instructions — insights implementation workflow | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — memory-tools 4.2.0 | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | Release history — v4.2.0 entry | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin docs — third skill documented | Modified |

## How it works

The `implementing-insights` skill encodes the workflow for acting on usage-insights reports. It triages every recommendation against existing config before implementing anything, places each open item at the correct config layer (plugin / user-global / repo), and implements one item per PR with worktree isolation for parallel agents.

The skill belongs in `memory-tools` because config-layer placement is already the domain of `agentic-memory-management` and `path-rules-advisor` — the two existing skills in that plugin. Workflow-shaped behavior belongs in a versioned plugin rather than a personal skill file so it is synced across machines and available to all marketplace users.

The repo convention for `version` placement is critical: `memory-tools` is a relative-path plugin, so the version lives only in `.claude-plugin/marketplace.json`. Adding a version to `plugin.json` would silently override the marketplace value — the plan explicitly documents this as a gotcha.

## How to use it

Activation: the skill is auto-activated when the user asks about implementing or acting on a usage-insights report.

```
/memory-tools:implementing-insights      # start the insights triage workflow
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-implementing-insights-skill](plans/add-implementing-insights-skill.md)
