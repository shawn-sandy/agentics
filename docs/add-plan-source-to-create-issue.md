# Let create-issue ingest plans and offer issue creation at plan completion

> A `plan` source keyword for `git-agent:create-issue` turns a finished plan spec into a GitHub/GitLab issue; `implementation-plan` Step 8 now offers to create a tracking issue at the end of every plan run, closing the plan-to-issue loop.

<!-- generated:start -->

**Status:** Shipped 2026-07-13 **Plan:** [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Added the `plan` source to `create-issue/SKILL.md`: keyword parsing (a `.md`/`.html` token implies the source), resolution under the plans directory, and a plan-to-issue mapping (title → issue title, Objective → Summary, Steps → `- [ ]` checklist, Acceptance Criteria carried over, `type:` frontmatter → label hint).
- Added `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` with the Objective / Plan / Steps / Acceptance Criteria / Additional Context body skeleton and the `type:` → label mapping.
- Extended `implementation-plan` Step 8 with a second batched `AskUserQuestion` — "Create a tracking issue for this plan?" — that invokes `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")` on yes, records the returned URL as the spec's `issue:` frontmatter key, and re-renders; a missing git-agent install degrades to a one-line notice.
- Bumped `git-agent` from 3.11.1 to `3.12.0` and `plan-agent` from 2.21.0 to `2.22.0` in `.claude-plugin/marketplace.json` with matching CHANGELOG entries, README, and CLAUDE.md plugin-table updates.
- Added `tests/plugins/test-create-issue-plan-source.sh` asserting the wiring between the two skills and both version bumps.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` | Issue body template | Created |
| `tests/plugins/test-create-issue-plan-source.sh` | Smoke test | Created |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Step 8 tracking-issue question | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `CLAUDE.md` | Plugin table | Modified |

## How it works

`implementation-plan` already ingested issues (Step 0.5 maps an issue URL or `#n` into a plan and records it as an `issue:` frontmatter key). The reverse path — a drafted plan becoming a tracked ticket — is now wired through `create-issue`'s new `plan` source.

The plan body template in `references/plan-issue.md` maps plan sections to issue sections: the plan title becomes the issue title (no prefix), the Objective section becomes the Summary, Steps become a `- [ ]` checklist, and Acceptance Criteria are carried over. The `type:` frontmatter value provides a label hint (feature, bug, etc.).

The Step 8 batched question rides alongside the existing four-option menu (which has the `AskUserQuestion` 4-option maximum). A missing git-agent plugin degrades gracefully to a one-line notice so the plan flow is never blocked.

The same `issue:` frontmatter key carries the link in both directions: an issue seeding a plan records it on intake, and a plan creating an issue records it on delivery.

## How to use it

```
/git-agent:create-issue plan docs/plans/my-plan.md
/git-agent:create-issue plan docs/plans/my-plan.html
```

The `plan` keyword (or a `.md`/`.html` token) routes the issue to the plan body template. At the end of any `implementation-plan` run, Step 8 also offers to create the tracking issue automatically.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `9cacc212` | 2026-07-13 | feat(git-agent,plan-agent): plan source for create-issue + end-of-plan issue option (#391) |

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
