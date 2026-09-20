# Let create-issue ingest plans and offer issue creation at plan completion

> Plans and issues only linked in one direction — an issue could seed a plan, but a finished plan could not become a tracked ticket. Now create-issue accepts a...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Add the `plan` source to create-issue's SKILL.md: keyword parsing (a `.md`/`.html` token implies the source), resolution under the plans directory, and the mapping — plan title → issue title, Objective → Summary, Steps → `- [ ]` checklist, Acceptance Criteria carried over, `type:` frontmatter → label hint, plan path cited in the body.
- Create `references/plan-issue.md` with the Objective / Plan / Steps / Acceptance Criteria / Additional Context body skeleton, title rule (plan title, no prefix), and label mapping.
- Extend implementation-plan Step 8 to batch a second AskUserQuestion — "Create a tracking issue for this plan?" — and on yes invoke `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")`, record the returned issue URL as the spec's `issue:` frontmatter key, and re-render; if git-agent is not installed, note it and continue.
- Bump versions (git-agent 3.12.0, plan-agent 2.22.0) in marketplace.json, add CHANGELOG entries to both plugins, and update the README and CLAUDE.md plugin-table mentions.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | `plan` source keyword + path implication, per-source mapping, template routing | Modified |
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

`implementation-plan` already ingests issues (Step 0.5 maps an issue URL or `#n` into a plan and records it as an `issue:` frontmatter key), but the reverse path did not exist: a drafted plan could not become a tracked ticket without hand-writing one. `create-issue` supported four sources (bug, feature, selection, session) and its Step 8 counterpart in plan-agent ended without any issue hand-off. Wiring the two skills together closes the loop — the same `issue:` frontmatter key carries the link in both directions.

The implementation proceeded through the following steps: Add the `plan` source to create-issue's SKILL.md: keyword parsing (a `.md`/`.html` token implies the source), resolution under the plans directory, and the mapping — plan title → issue title, Objective → Summary, Steps → `- [ ]` checklist, Acceptance Criteria carried over, `type:` frontmatter → label hint, plan path cited in the body. Why: the skill's phases are the runtime contract; the mapping must be explicit so drafts are deterministic. Verify: SKILL.md Phase 3 lists five sources and a `plan` per-source block; Phase 5 routes `plan` → `plan-issue.md`.; Create `references/plan-issue.md` with the Objective / Plan / Steps / Acceptance Criteria / Additional Context body skeleton, title rule (plan title, no prefix), and label mapping. Why: the other four sources each have a template; the plan shape (objective + checklists) fits none of them. Verify: the file exists and the Reference Files list in SKILL.md names it.; Extend implementation-plan Step 8 to batch a second AskUserQuestion — "Create a tracking issue for this plan?" — and on yes invoke `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")`, record the returned issue URL as the spec's `issue:` frontmatter key, and re-render; if git-agent is not installed, note it and continue. Why: the Step 8 menu already carries the AskUserQuestion 4-option maximum, so the issue choice must ride as a second batched question, and a missing cross-plugin dependency must never block the plan flow. Verify: Step 8 shows two batched questions and a `Yes — create an issue` handler that names the fallback.; Bump versions (git-agent 3.12.0, plan-agent 2.22.0) in marketplace.json, add CHANGELOG entries to both plugins, and update the README and CLAUDE.md plugin-table mentions. Why: marketplace versioning is manual per repo rules (new skill capability = minor), and docs drift is a defect. Verify: marketplace.json carries both new versions; both CHANGELOGs lead with the new entries; README and CLAUDE.md mention the plan source..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
