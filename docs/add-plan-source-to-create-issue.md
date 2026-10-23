# Let create-issue ingest plans and offer issue creation at plan completion

> Wired git-agent's `create-issue` skill to accept a plan file as a source, and added a batched "create a tracking issue" question to plan-agent's `implementation-plan` Step 8 menu, closing the loop between plans and tickets in both directions.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Added a `plan` source to `git-agent`'s `create-issue` skill: keyword parsing (a `.md`/`.html` token implies the source), resolution under the plans directory, and a mapping from plan sections to issue body — plan title → issue title, Objective → Summary, Steps → `- [ ]` checklist, Acceptance Criteria carried over, `type:` frontmatter → label hint, plan path cited in the body.
- Created `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md`, the body skeleton for the new source (Objective / Plan / Steps / Acceptance Criteria / Additional Context), with a title rule (plan title, no prefix) and label mapping.
- Extended `implementation-plan` Step 8 to batch a second `AskUserQuestion` — "Create a tracking issue for this plan?" — that on yes invokes `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")`, records the returned issue URL as the spec's `issue:` frontmatter key, and re-renders. A missing git-agent plugin degrades to a one-line notice without blocking the plan flow.
- Bumped git-agent from 3.11.1 to 3.12.0 and plan-agent from 2.21.0 to 2.22.0 in `.claude-plugin/marketplace.json`, with CHANGELOG entries for both plugins.
- Updated `kit/plugins/git-agent/README.md` with a plan-source example and `CLAUDE.md` plugin table rows.
- Added `tests/plugins/test-create-issue-plan-source.sh` smoke test asserting the wiring and version constraints.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | `plan` source keyword, mapping, template routing | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` | Plan-to-issue body skeleton | Created |
| `tests/plugins/test-create-issue-plan-source.sh` | Objective-verification smoke test | Created |
| `kit/plugins/git-agent/README.md` | Plan source documented with example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v3.12.0 entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Step 8 batched tracking-issue question and handler | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.22.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 3.11.1 → 3.12.0, plan-agent 2.21.0 → 2.22.0 | Modified |
| `CLAUDE.md` | Plugin table rows for both plugins | Modified |

## How it works

`implementation-plan` already ingested issues at Step 0.5 (an issue URL or `#n` is mapped into a plan and recorded as an `issue:` frontmatter key). The reverse path — a drafted plan becoming a tracked ticket — did not exist. This change adds it on both sides of the plugin boundary.

On the git-agent side, `create-issue` previously supported four sources (bug, feature, selection, session). The `plan` source is added as a fifth. Source detection is keyword-first: the literal token `plan` triggers it, and a `.md` or `.html` file token implies it. The skill resolves the file under the plans directory, reads its sections, and maps them deterministically into the issue body using `references/plan-issue.md` as the template. The plan's `type:` frontmatter provides the label hint, and the plan path is cited in the body so the issue links back to the artifact that defined the work.

On the plan-agent side, Step 8's existing four-option menu already held the `AskUserQuestion` maximum, so the tracking-issue offer rides as a second batched question. On yes, the skill invokes `git-agent:create-issue` with the plan path, records the returned URL in `issue:` frontmatter, and re-renders the plan HTML — meaning the rendered plan card and gallery both reflect the link. The handler includes an explicit not-installed fallback: if git-agent is absent, a one-line notice is printed and the plan flow continues normally.

The `issue:` frontmatter key now carries the link in both directions: issue seeding a plan writes it at Step 0.5, plan producing an issue writes it at Step 8. The same key, same format, both flows.

## How to use it

**Create an issue from a plan file:**

```
/git-agent:create-issue plan docs/plans/add-plan-source-to-create-issue.md
```

A `.md` or `.html` file path token also implies the `plan` source without the keyword:

```
/git-agent:create-issue docs/plans/my-feature.md
```

The skill maps the plan's Objective, Steps (as a `- [ ]` checklist), and Acceptance Criteria into the issue body, then presents the confirmation gate before any `gh`/`glab` call.

**From plan completion:** At the end of an `implementation-plan` run, Step 8 asks "Create a tracking issue for this plan?" A yes answer invokes the same flow and records the issue URL as `issue:` in the plan's frontmatter.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
