# Let create-issue ingest plans and offer issue creation at plan completion

> Adds a `plan` source to the git-agent `create-issue` skill so a completed plan can be turned into a GitHub/GitLab issue, and extends the `implementation-plan` Step 8 menu with a "create a tracking issue" option.

<!-- generated:start -->

**Status:** Shipped 2026-07-13 **Plan:** [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Added a `plan` source to `create-issue/SKILL.md`: keyword parsing (a `.md`/`.html` token implies the source), resolution under the plans directory, and a per-source mapping (plan title → issue title, Objective → Summary, Steps → `- [ ]` checklist, Acceptance Criteria carried over, `type:` frontmatter → label hint).
- Created `references/plan-issue.md` with the Objective / Plan / Steps / Acceptance Criteria / Additional Context body skeleton.
- Extended `implementation-plan` Step 8 to batch a second `AskUserQuestion` ("Create a tracking issue for this plan?"), and on yes invoke `git-agent:create-issue plan <spec path>` and record the returned URL as the spec's `issue:` frontmatter key.
- Bumped `git-agent` to `3.12.0` and `plan-agent` to `2.22.0` in `.claude-plugin/marketplace.json`.
- Added `tests/plugins/test-create-issue-plan-source.sh`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` | Issue body template | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |
| `tests/plugins/test-create-issue-plan-source.sh` | Smoke test | Created |

## How it works

The `create-issue` skill previously accepted four sources (bug, feature, selection, session). The `plan` source is the fifth, wired through Phase 3's source-keyword parsing: a `.md` or `.html` path token is enough to infer the `plan` source. Phase 5 routes it to `references/plan-issue.md`, which templates the plan's Objective as the issue Summary, its Steps as a `- [ ]` checklist, and its Acceptance Criteria verbatim.

The `implementation-plan` Step 8 change batches the tracking-issue question as a second `AskUserQuestion` after the plan delivery. A missing `git-agent` plugin degrades to a one-line notice so the plan flow is never blocked by a cross-plugin dependency.

The `issue:` frontmatter key is the same key that `implementation-plan`'s Step 0.5 reads when ingesting an issue as a plan seed — closing the loop in both directions.

## How to use it

```
/git-agent:create-issue plan docs/plans/my-feature.md    # from a plan spec
/git-agent:create-issue plan docs/plans/my-feature.html  # from rendered HTML
```

Or accept the "Create a tracking issue?" offer at the end of `/plan-agent:implementation-plan`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
- Changelog: [git-agent CHANGELOG v3.12.0](../kit/plugins/git-agent/CHANGELOG.md)
- Changelog: [plan-agent CHANGELOG v2.22.0](../kit/plugins/plan-agent/CHANGELOG.md)
