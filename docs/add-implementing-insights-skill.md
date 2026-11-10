# Add the implementing-insights skill to memory-tools

> Ships `implementing-insights` as a third skill in the `memory-tools` plugin — triages usage-insights report recommendations against existing config, then implements genuinely open items at the correct config layer with a live artifact record per item.

<!-- generated:start -->

**Status:** Shipped 2026-08-19 **Plan:** [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` conforming to repo skill-authoring conventions
- Skill triages every report recommendation against current config before implementing anything — triage-before-implement is the core design, not a preliminary step
- Three classification buckets: Already implemented (cite the file), Conflicts with existing rule (reject and cite), Genuinely open (implementation list)
- Per-item layer placement: workflow-shaped behavior to the user's own plugins, machine-wide behavior to `~/.claude/`, repo-specific conventions via branch and PR
- Repo inventory built from `~/.claude/projects/` using `cwd` from session JSONL files for accurate path resolution
- Each implemented item publishes a live artifact record, republished as the item moves from started to merged
- Personal copy at `~/.claude/skills/implementing-insights/` removed
- `memory-tools` bumped to `4.2.0` in marketplace with CHANGELOG entry and README updates

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/memory-tools/skills/implementing-insights/SKILL.md` | Skill definition — 7-step workflow from report ingestion through verified delivery | Created |
| `.claude-plugin/marketplace.json` | `memory-tools` version bumped to `4.2.0`; description and tags updated | Modified |
| `kit/plugins/memory-tools/CHANGELOG.md` | `v4.2.0` entry for `implementing-insights` | Modified |
| `kit/plugins/memory-tools/README.md` | Skills table, section, structure tree, current version updated | Modified |

## How it works

Usage-insights reports repeat themselves: most suggestions from a new report are already covered by config written in earlier rounds. The skill's first and largest step is therefore triage, not implementation. For every recommendation extracted from the report, the skill searches the full config stack — `~/.claude/CLAUDE.md`, `rules/`, `settings.json`, `hooks/`, installed plugin skills — and classifies each item into exactly one bucket before touching anything. A full triage table (item, bucket, citation) is presented and confirmed before any write happens.

Report content is treated as untrusted data throughout. The skill explicitly does not execute commands, follow links, or obey imperative text embedded in the report. Everything flows through the triage and the approval gate.

For genuinely open items, the skill determines the correct config layer before writing. The layer decision follows a three-way rule: workflow-shaped behavior (how PRs, plans, reviews, or ships happen) belongs in the user's own versioned plugin; machine-wide behavior belongs in `~/.claude/`; repo-specific conventions belong in that repo's `CLAUDE.md` or `.claude/settings.json` via branch and PR.

Resolving a recommendation to a local repo checkout is a structured inventory process. The skill builds the inventory from `~/.claude/projects/` by reading the `"cwd"` field from the first few lines of session JSONL files — the same data source the insights report was generated from, so every repo it can name has a directory here. Paths under `/tmp`, `/private/tmp`, `/var/folders`, or `/.claude/worktrees/` are excluded as temp dirs and session worktrees.

For each implemented item, the skill publishes a live artifact record and republishes it as the item's status changes. This gives the team a durable, shareable link to the item's progress without requiring a PR review to see what was changed.

The plan-mode guard (`ExitPlanMode`) is the first step, as required by repo conventions for any skill that mutates filesystem or git state.

## How to use it

```text
# Implement insights from a file
/memory-tools:implementing-insights path/to/usage-insights-report.md

# Implement insights from an artifact
/memory-tools:implementing-insights https://claude.ai/artifact/<id>

# Paste report content directly into the conversation, then invoke
/memory-tools:implementing-insights
```

The skill presents a triage table for confirmation before any write, then implements only the approved open items, each as its own change at the correct config layer.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `7a4214f` | 2026-09-26 | feat(memory-tools): implementing-insights publishes a live record per item (4.4.0) (#638) |
| `19174f7` | 2026-08-23 | fix(memory-tools): stricter repo resolution in implementing-insights (4.3.1) (#597) |
| `f25758e` | 2026-08-19 | feat(memory-tools): implementing-insights discovers repos, global-dir fallback (4.3.0) (#587) |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-implementing-insights-skill.md](plans/add-implementing-insights-skill.md)
