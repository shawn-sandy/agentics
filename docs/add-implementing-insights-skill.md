# Add implementing-insights skill

> Moves the `implementing-insights` skill from `~/.claude/skills/` into the memory-tools plugin, rewrites it to repo conventions, and ships it as the plugin's third installed skill.

<!-- generated:start -->

**Status:** Shipped 2026-08-19 **Plan:** [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
**Type:** feature

## What shipped

- Moved `~/.claude/skills/implementing-insights/` into `kit/plugins/memory-tools/skills/implementing-insights/`.
- Rewrote to repo conventions: progressive disclosure, references/*.md for supporting content, verification gate.
- Updated `marketplace.json` to memory-tools 4.2.0.
- Updated memory-tools CHANGELOG and README.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill core | Created |
| `kit/plugins/memory-tools/skills/implementing-insights/references/` | Supporting references | Created |
| `kit/plugins/memory-tools/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/memory-tools/README.md` | Plugin readme | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

`implementing-insights` captures what was learned during an implementation session and writes it to memory in a structured format. It asks a few targeted questions (what worked, what didn't, which patterns emerged) and produces a memory entry that later sessions can retrieve when working on similar code.

Moving it from `~/.claude/skills/` to the plugin means it installs automatically with memory-tools, travels with the plugin version, and can be tested alongside the other memory-tools skills. Previously it was a local skill that only worked if manually copied to each machine.

The rewrite aligned it with the repo's authoring conventions: the SKILL.md core is under 600 words, supporting detail lives in `references/`, and a verification gate checks that the memory write was acknowledged before the skill completes.

## How to use it

```
/memory-tools:implementing-insights
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
