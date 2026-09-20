# Let create-issue ingest plans and offer issue creation at plan completion

> Plans and issues only linked in one direction — an issue could seed a plan, but a finished plan could not become a tracked ticket. Now create-issue accepts a...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Add the `plan` source to create-issue's SKILL.md: keyword parsing (a `.md`/`.html` token implies the source), resolut...
- Create `references/plan-issue.md` with the Objective / Plan / Steps / Acceptance Criteria / Additional Context body s...
- Extend implementation-plan Step 8 to batch a second AskUserQuestion — "Create a tracking issue for this plan?" — and...
- Bump versions (git-agent 3.12.0, plan-agent 2.22.0) in marketplace.json, add CHANGELOG entries to both plugins, and u...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | `plan` source keyword + path implication, per-source mapp... | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` | plan-to-issue body skeleton | Created |
| `tests/plugins/test-create-issue-plan-source.sh` | objective-verification smoke test | Created |
| `kit/plugins/git-agent/README.md` | plan source documented with example | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v3.12.0 entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Step 8 batched tracking-issue question + handler | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 2.22.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 3.11.1 → 3.12.0, plan-agent 2.21.0 → 2.22.0 | Modified |
| `CLAUDE.md` | plugin table rows for both plugins | Modified |

## How it works

Add a `plan` source to the git-agent `create-issue` skill so a plan file (markdown spec or rendered HTML) can be turned into a GitHub/GitLab issue, and extend the plan-agent `implementation-plan` Step 8 menu with an optional "create a tracking issue" question that invokes it.

`implementation-plan` already ingests issues (Step 0.5 maps an issue URL or `#n` into a plan and records it as an `issue:` frontmatter key), but the reverse path did not exist: a drafted plan could not become a tracked ticket without hand-writing one. `create-issue` supported four sources (bug, feature, selection, session) and its Step 8 counterpart in plan-agent ended without any issue hand-off. Wiring the two skills together closes the loop — the same `issue:` frontmatter key carries the link ...

The implementation proceeded through these steps: Add the `plan` source to create-issue's SKILL.md: keyword parsing (a `.md`/`.html` token implies the source), resolut...; Create `references/plan-issue.md` with the Objective / Plan / Steps / Acceptance Criteria / Additional Context body s...; Extend implementation-plan Step 8 to batch a second AskUserQuestion — "Create a tracking issue for this plan?" — and ...; Bump versions (git-agent 3.12.0, plan-agent 2.22.0) in marketplace.json, add CHANGELOG entries to both plugins, and u....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
