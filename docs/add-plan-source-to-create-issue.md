# Let create-issue ingest plans and offer issue creation at plan completion

> Wires git-agent's `create-issue` skill to accept plan files as a source and adds a tracking-issue offer to plan-agent's `implementation-plan` Step 8 menu, closing the plan-to-issue loop.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Added the `plan` source to `create-issue/SKILL.md`: keyword parsing (a `.md`/`.html` token implies the source), resolution under the plans directory, per-source field mapping (plan title → issue title, Objective → Summary, Steps → `- [ ]` checklist, Acceptance Criteria carried over, `type:` frontmatter → label hint, plan path cited in the body), and routing to `references/plan-issue.md`.
- Created `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` with the Objective / Plan / Steps / Acceptance Criteria / Additional Context body skeleton, title rule (plan title, no prefix), and label mapping (the four existing sources each have their own template; the plan shape fits none of them).
- Extended `implementation-plan` Step 8 to batch a second `AskUserQuestion` — "Create a tracking issue for this plan?" — that on yes invokes `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")`, records the returned URL as the spec's `issue:` frontmatter key, and re-renders; when git-agent is not installed, a one-line notice is printed and the plan flow continues unblocked.
- Bumped git-agent from 3.11.1 to 3.12.0 and plan-agent from 2.21.0 to 2.22.0 in `.claude-plugin/marketplace.json`, added matching CHANGELOG entries to both plugins, and updated the git-agent README and CLAUDE.md plugin-table with the new `plan` source and example.

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

## How it works

Before this change, `implementation-plan` ingested issues (Step 0.5 mapped an issue URL or `#n` into a plan and recorded it as an `issue:` frontmatter key) but offered no reverse path. A drafted plan could not become a tracked ticket without hand-writing one. The same `issue:` frontmatter key now carries the link in both directions.

The `create-issue` skill's Phase 3 parses source type from the command arguments. The new `plan` case matches either the literal keyword `plan` or a `.md`/`.html` token, which avoids requiring the user to type the keyword when the path makes the intent unambiguous. Resolution falls under the plans directory so relative paths work from any working directory.

Phase 5 routes `plan` to `references/plan-issue.md`, which defines the body skeleton: Objective maps to the issue Summary, Steps map to a `- [ ]` task list, and Acceptance Criteria are carried verbatim. The `type:` frontmatter key feeds a label hint. All other per-source templates (bug, feature, selection, session) are unchanged.

The implementation-plan Step 8 menu already carried an `AskUserQuestion` 4-option maximum, so the tracking-issue question rides as a second batched question rather than expanding the existing menu. On a "yes" answer, the skill calls `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")` and writes the returned issue URL into the spec's `issue:` frontmatter before re-rendering. A missing cross-plugin dependency (git-agent not installed) logs a one-line notice and continues — issue creation is never allowed to block the plan flow.

The smoke test `tests/plugins/test-create-issue-plan-source.sh` asserts that `create-issue/SKILL.md` declares the `plan` source and routes it to `references/plan-issue.md` (which exists), that `implementation-plan/SKILL.md` invokes `git-agent:create-issue` with a `plan` argument in Step 8, and that `marketplace.json` reports the bumped versions for both plugins.

## How to use it

**Create an issue from a plan:**

```bash
/git-agent:create-issue plan docs/plans/my-plan.md
# or, from the path alone:
/git-agent:create-issue docs/plans/my-plan.md
```

The skill maps the plan's title, objective, steps, and acceptance criteria into the issue body, prompts for confirmation, and records the created issue URL as `issue:` in the plan's frontmatter.

**At plan completion:**

When `/plan-agent:implementation-plan` reaches Step 8, it asks a second batched question: "Create a tracking issue for this plan?" Answering yes invokes `create-issue` automatically and writes the issue URL back into the spec.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
