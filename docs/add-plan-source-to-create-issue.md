# Let create-issue ingest plans and offer issue creation at plan completion

> Add a `plan` source to the git-agent `create-issue` skill so a plan file can be turned into a GitHub/GitLab issue, and extend the plan-agent `implementation-plan` Step 8 menu with an optional tracking-issue question.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [add-plan-source-to-create-issue](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Added a `plan` source keyword to `git-agent:create-issue`, with path implication from `.md`/`.html` tokens, a mapping from plan sections into the issue body, and routing through a new `plan-issue.md` template.
- Created `references/plan-issue.md` with an Objective / Plan / Steps / Acceptance Criteria body skeleton and a `type:` → label mapping.
- Extended `implementation-plan` Step 8 to batch a second AskUserQuestion offering to create a tracking issue, invoking `git-agent:create-issue` on yes and recording the returned URL as the spec's `issue:` frontmatter key.
- Bumped git-agent to 3.12.0 and plan-agent to 2.22.0 with matching CHANGELOG entries, and updated CLAUDE.md and both plugin READMEs.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | `plan` source keyword, path implication, per-source mapping, template routing | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` | Plan-to-issue body skeleton | Created |
| `tests/plugins/test-create-issue-plan-source.sh` | Objective-verification smoke test | Created |
| `kit/plugins/git-agent/README.md` | Plan source documented with example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v3.12.0 entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Step 8 batched tracking-issue question and handler | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.22.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 3.11.1 → 3.12.0, plan-agent 2.21.0 → 2.22.0 | Modified |
| `CLAUDE.md` | Plugin table rows for both plugins | Modified |

## How it works

`implementation-plan` already ingested issues at Step 0.5 — an issue URL or `#n` is mapped into a plan and recorded as an `issue:` frontmatter key. The reverse path did not exist: a finished plan could not become a tracked ticket without hand-writing one. This plan closes the loop so the same `issue:` key carries the link in both directions.

The `plan` source was added to `create-issue`'s SKILL.md Phase 3 alongside the four existing sources (bug, feature, selection, session). A `.md` or `.html` token in the argument implies the source without requiring the keyword. Phases 4-5 resolve the file under the plans directory and map the plan's title to the issue title, Objective to Summary, Steps to a `- [ ]` checklist, Acceptance Criteria carried over verbatim, `type:` frontmatter to a label hint, and the plan path cited in the body.

`references/plan-issue.md` provides the body skeleton for this mapping. Each of the other four sources already had a dedicated template; the plan shape (objective plus checklists) fit none of them, so a new one was required.

`implementation-plan` Step 8 now batches a second AskUserQuestion — "Create a tracking issue for this plan?" — immediately after its existing four-option next-action menu. On yes it invokes `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")`, writes the returned issue URL into the spec's `issue:` frontmatter, and re-renders. When git-agent is not installed the step prints one notice and continues — issue creation never blocks the plan flow.

## How to use it

```bash
# Turn a plan file into a GitHub issue:
/git-agent:create-issue plan docs/plans/<slug>.md

# Or, at the end of any implementation-plan run, answer yes to:
# "Create a tracking issue for this plan?"
# — the step calls create-issue automatically and records the URL.
```

Run the smoke test:

```bash
bash tests/plugins/test-create-issue-plan-source.sh
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `9cacc21` | 2026-07-13 | feat(git-agent,plan-agent): plan source for create-issue + end-of-plan issue option (#391) |

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue](plans/add-plan-source-to-create-issue.md)
