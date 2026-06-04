# Add `type` frontmatter field to plan-status skill

> Separates lifecycle position (`status`) from documentation classification (`type`) in the plan-status skill, replacing `artifact` as a status value with a dedicated `type: artifact` field on completed plans.

<!-- generated:start -->

**Status:** Shipped 2026-03-29   **Plan:** [add-type-field-to-plan-status-skill.md](plans/add-type-field-to-plan-status-skill.md)   **Type:** standard

## What shipped

- `artifact` removed as a `status` value; statuses simplified to three: `todo`, `in-progress`, `completed`.
- New `type` frontmatter field introduced for completed plans with values `standard` (default) and `artifact`.
- Step 3 gains legacy `status: artifact` migration: existing plans with that value are normalized to `status: completed` + `type: artifact` automatically.
- Step 5 rewritten to set `type` instead of changing status — always asks "Classify as `standard` or `artifact`?" (default: `standard`); nudges toward artifact when plan is 30+ days old.
- Step 6 summary table gains a conditional `Type` row (only for completed plans).
- Step 7 now writes `type` for completed plans; `todo` and `in-progress` plans never get a `type` field.
- `plan-interview` plugin bumped to `1.11.0`.

> See [CHANGELOG v1.11.0](../kit/plugins/plan-interview/CHANGELOG.md#1110---2026-03-29) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/skills/plan-status/SKILL.md` | Skill instructions — plan-status | Modified |
| `kit/plugins/plan-interview/commands/plan-status.md` | Command wrapper — plan-status | Modified |
| `kit/plugins/plan-interview/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-interview/CHANGELOG.md` | Plugin changelog | Modified |

## How it works

The original design conflated two concerns in a single `status` field: where a plan sits in its lifecycle (`todo` → `in-progress` → `completed`) and whether a completed plan is valued as long-term documentation (`artifact`). Using a status value for the latter meant `artifact` plans couldn't also express `completed`, and the 30-day promotion logic was a side effect of status assignment.

The refactoring introduces `type` as an orthogonal field: `status` tracks lifecycle position, `type` classifies what kind of record the completed plan is. Only completed plans get a `type` field — `todo` and `in-progress` plans are unaffected.

Step 5 now always runs when status resolves to `completed` (whether determined by codebase analysis or manually set). If the plan already has `type: artifact`, the step reports it and skips the prompt. Otherwise it asks the user directly: "Classify as `standard` or `artifact`?" When the plan's modified date is 30+ days old, the prompt adds context to nudge toward `artifact`, but the user always decides.

Legacy migration is handled in Step 3: if a plan's existing frontmatter has `status: artifact`, the skill informs the user and normalizes it to `status: completed` + `type: artifact` before continuing.

**Written frontmatter for completed standard plan:**
```yaml
---
status: completed
type: standard
created: 2026-01-15
modified: 2026-03-29
---
```

**Written frontmatter for completed artifact plan:**
```yaml
---
status: completed
type: artifact
created: 2026-01-15
modified: 2026-03-29
---
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `56e7c41` | 2026-03-29 | feat(plugins/plan-interview): add batch-status command (v1.12.0) |

<!-- generated:end -->

## References

- Plan: [add-type-field-to-plan-status-skill.md](plans/add-type-field-to-plan-status-skill.md)
- Changelog: [CHANGELOG v1.11.0](../kit/plugins/plan-interview/CHANGELOG.md#1110---2026-03-29)
