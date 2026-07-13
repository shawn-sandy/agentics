# Add `plan-status` Skill to plan-interview Plugin

> Adds a `plan-status` skill and paired command to `plan-interview` that inspects the codebase for implementation evidence, determines a plan's lifecycle status, and writes it into the plan file's YAML frontmatter.

<!-- generated:start -->

**Status:** Shipped 2026-03-26   **Plan:** [add-plan-status-skill-to-plan-interview.md](plans/add-plan-status-skill-to-plan-interview.md)   **Type:** feature

## What shipped

- New `kit/plugins/plan-interview/skills/plan-status/SKILL.md` — 7-step workflow to resolve plan, get dates, read existing frontmatter, analyze codebase, artifact-check completed plans, confirm with user, and write YAML frontmatter.
- New `kit/plugins/plan-interview/commands/plan-status.md` — self-contained command mirror of the skill, invokable via `/plan-interview:plan-status [path]`.
- Status values: `todo` · `in-progress` · `completed` · `artifact`.
- Completion threshold: 80%+ codebase signals found = `completed`; 1–79% = `in-progress`; 0% = `todo`.
- Artifact promotion: plans completed 30+ days ago are offered `artifact` status.
- Signal extraction scoped to inline backtick tokens only — fenced code block content excluded to avoid false positives.
- `plan-interview` plugin bumped to `1.8.0`.

> See [CHANGELOG v1.8.0](../kit/plugins/plan-interview/CHANGELOG.md#180---2026-03-26) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/skills/plan-status/SKILL.md` | Skill instructions — plan-status | Created |
| `kit/plugins/plan-interview/commands/plan-status.md` | Command wrapper — plan-status | Created |
| `kit/plugins/plan-interview/CHANGELOG.md` | Plugin changelog | Modified |
| `kit/plugins/plan-interview/README.md` | Plugin documentation | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump to 1.8.0 | Modified |

## How it works

The skill resolves the plan file using the same priority order as the main `plan-interview` skill (argument, open IDE file, `plansDirectory` from settings, global settings, `~/.claude/plans/`). It then extracts dates exclusively from git: `git log --follow --diff-filter=A` for the creation date (when the file was first added), `git log -1` for the most recent modification. `stat` is deliberately avoided as it is not cross-platform.

If the plan already has a `status` field in its YAML frontmatter, the skill surfaces the existing value and asks the user whether to re-analyze or confirm it — avoiding redundant codebase sweeps for already-classified plans.

The codebase analysis extracts inline backtick tokens (file paths and identifier names) from the plan body, explicitly excluding content inside fenced code blocks. For each token it runs `Glob` (for file paths) and `Grep` (for named identifiers) and tallies how many were found. The 80% threshold for `completed` was chosen to allow for minor divergence where implementation chose slightly different paths or names without invalidating completion.

For plans that score `completed` and whose `modified` date is 30 or more days ago, the skill prompts an artifact promotion: `artifact` marks a plan as preserved project documentation rather than active implementation work, keeping the plans directory meaningful over long time horizons.

Before writing, a summary table is shown:

```
| Field    | Value                          |
|----------|--------------------------------|
| File     | docs/plans/my-feature.md       |
| Status   | in-progress                    |
| Created  | 2026-01-15                     |
| Modified | 2026-03-26                     |
| Evidence | 3/5 items found in codebase    |
```

The frontmatter write only happens after explicit user confirmation. Fields added/updated: `status`, `created`, `modified` — all other existing frontmatter fields are preserved.

## How to use it

**Skill activation** — triggers on "check the status of this plan", "update plan status", "determine if this plan was implemented":

```
/plan-interview:plan-status
/plan-interview:plan-status docs/plans/my-feature.md
```

**Written frontmatter format:**

```yaml
---
status: completed
created: 2026-01-15
modified: 2026-03-26
---
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [add-plan-status-skill-to-plan-interview.md](plans/add-plan-status-skill-to-plan-interview.md)
- Changelog: [CHANGELOG v1.8.0](../kit/plugins/plan-interview/CHANGELOG.md#180---2026-03-26)
