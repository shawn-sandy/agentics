# Let create-issue ingest plans and offer issue creation at plan completion

> Closes the plan-to-issue loop: `create-issue` now accepts a plan file as a source, and `implementation-plan` Step 8 offers issue creation at every plan run's end.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Added a `plan` source to `git-agent:create-issue` — keyword parsing (a `.md` or `.html` token implies the source), resolution under the plans directory, and a mapping of plan title → issue title, Objective → Summary, Steps → `- [ ]` checklist, and Acceptance Criteria carried over.
- Created `references/plan-issue.md` with the Objective / Plan / Steps / Acceptance Criteria / Additional Context body skeleton, title rule, and label mapping from `type:` frontmatter.
- Extended `implementation-plan` Step 8 with a batched "Create a tracking issue for this plan?" `AskUserQuestion`; on yes it invokes `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")` and records the returned URL as the spec's `issue:` frontmatter key.
- Graceful degradation when git-agent is not installed: a one-line notice and the plan flow continues unblocked.
- Added smoke test `tests/plugins/test-create-issue-plan-source.sh`.
- Bumped git-agent to 3.12.0 and plan-agent to 2.22.0 with matching CHANGELOG and README entries.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | `plan` source keyword, per-source mapping, template routing | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` | Plan-to-issue body skeleton | Created |
| `tests/plugins/test-create-issue-plan-source.sh` | Objective-verification smoke test | Created |
| `kit/plugins/git-agent/README.md` | Plan source documented with example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v3.12.0 entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Step 8 batched tracking-issue question and handler | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.22.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 3.11.1 → 3.12.0, plan-agent 2.21.0 → 2.22.0 | Modified |
| `CLAUDE.md` | Plugin table rows updated for both plugins | Modified |

## How it works

Before this change, `implementation-plan` already ingested issues — Step 0.5 maps an issue URL or `#n` into a plan and records it as an `issue:` frontmatter key — but the reverse path did not exist. A drafted plan could not become a tracked ticket without hand-writing one. The `issue:` frontmatter key now carries the link in both directions.

The `create-issue` skill's Phase 3 source parsing was extended to recognize a fifth source: `plan`. A `.md` or `.html` token in the arguments implies the source automatically, so `create-issue plan docs/plans/add-dark-mode.md` and `create-issue docs/plans/add-dark-mode.md` both resolve the plan source. Phase 5 routes the `plan` source to `references/plan-issue.md`, which holds the body skeleton with template variables for the plan's Objective, a repo-relative link to the spec, a `- [ ]` checklist of step action texts (no `Why:` / `Verify:` detail), the Acceptance Criteria, and any relevant Context. The `type:` frontmatter field maps to a label hint: `fix` → `bug`, `feature` → `enhancement`, `docs` → `documentation`, `refactor`/`chore` → `chore`.

`implementation-plan` Step 8 already carried a four-option `AskUserQuestion` menu at the `AskUserQuestion` four-option maximum. The issue question rides as a second batched question, separate from that menu, so neither question displaces the other. The handler invokes `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")` and writes the returned issue URL into the spec's `issue:` frontmatter, then re-renders the HTML. When git-agent is not installed, the skill notes it and continues — cross-plugin dependency must never block the plan flow.

The smoke test in `tests/plugins/test-create-issue-plan-source.sh` verifies three things without running any live `gh` call: that `create-issue/SKILL.md` declares the `plan` source and routes it to `references/plan-issue.md` (which it confirms exists), that `implementation-plan/SKILL.md` invokes `git-agent:create-issue` with a `plan` argument in Step 8, and that `marketplace.json` carries git-agent ≥ 3.12.0 and plan-agent ≥ 2.22.0.

## How to use it

Turn a plan file into a GitHub issue:

```bash
/git-agent:create-issue plan docs/plans/add-dark-mode.md
# or: the .md extension implies the source
/git-agent:create-issue docs/plans/add-dark-mode.md
```

The issue title is taken from the plan's `# Plan: <title>` heading. The body carries the Objective verbatim, a link to the spec, each step as a `- [ ]` checklist item, the Acceptance Criteria, and relevant Context. The confirmation gate appears before any `gh`/`glab` call.

The issue URL is written back to the plan's `issue:` frontmatter, creating a bidirectional link with the plan's existing issue-ingestion path.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
