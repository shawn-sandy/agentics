# Phase checkpoints and a Decisions ledger for plan specs

> Adds an optional `### Phase: <name>` grouping level over `## Steps` and an optional `## Decisions` section, turning `build`'s resume-from-first-unmarked-step behaviour into a designed checkpoint loop for long sequential plans.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-plan-phase-checkpoints](plans/add-plan-phase-checkpoints.md)
**Type:** feature

## What shipped

- Added `### Phase: <name>` grouping level to the plan spec format, parsed by `build-plan-html.mjs`
- Added optional `## Decisions` section to the spec format for recording locked decisions and their rationale
- Updated `build/SKILL.md` to treat phase boundaries as checkpoint opportunities in the resume-from-first-unmarked-step loop
- Updated `implementation-plan/SKILL.md` and `section-catalog.md` to document the new sections
- Updated the HTML renderer's CSS for phase headers and decision entries
- Bumped `plan-agent` with a CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Guidelines — Phase and Decisions section entries | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill — checkpoint loop at phase boundaries | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Renderer — phase header and decisions table HTML | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history | Modified |

## How it works

A long sequential plan implemented across several context windows previously forced the implementing agent to re-derive decisions already made in earlier sessions. The `## Decisions` section addresses this directly: it is a ledger of locked decisions (what was decided, why, and what was rejected) that travels with the plan file and is updated as implementation progresses.

`### Phase: <name>` groups related steps under a named milestone. The `build` skill uses phase boundaries as natural checkpoint points in its resume loop: rather than resuming at the first unchecked step globally, it can report progress at phase completion and confirm before starting the next phase. This keeps long plans manageable without requiring the user to manually track which steps have run.

The renderer adds styled HTML for both: phase headers with a progress indicator, and a decisions table with columns for Decision, Rationale, and Date.

## How to use it

In a plan spec:

```markdown
## Decisions

| Decision | Rationale | Date |
| -------- | --------- | ---- |
| Use squash merge | Keeps main history linear | 2026-07-30 |

## Steps

### Phase: Foundation
1. [ ] Set up database schema...

### Phase: API (after: Foundation)
4. [ ] Implement endpoints...
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-plan-phase-checkpoints](plans/add-plan-phase-checkpoints.md)
