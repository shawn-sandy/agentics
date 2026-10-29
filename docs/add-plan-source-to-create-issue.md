# Let create-issue ingest plans and offer issue creation at plan completion

> Adds a `plan` source to the `git-agent:create-issue` skill so a plan file can be turned into a GitHub/GitLab issue, and extends `implementation-plan` Step 8 with an optional "create a tracking issue" question.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-plan-source-to-create-issue](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Added `plan` source type to `git-agent/skills/create-issue/SKILL.md` accepting a plan file (Markdown spec or rendered HTML) as input
- Plan-to-issue conversion extracts title from H1, body from Context/Objective/Steps sections, labels from `type:` frontmatter
- Extended `implementation-plan` Step 8 menu with optional "Create a tracking issue" action that invokes `create-issue` with the plan path
- Bumped `git-agent` with CHANGELOG entry and README update

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | Skill — `plan` source type, plan-to-issue conversion | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill — Step 8 tracking-issue action | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — git-agent bump | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release history | Modified |
| `kit/plugins/git-agent/README.md` | Plugin docs | Modified |

## How it works

`create-issue` previously accepted diff, session, and free-text sources. The `plan` source adds a fourth path: read the plan file (either the Markdown spec or its rendered HTML sibling), extract the H1 title as the issue title, map Context → issue description, Objective → first paragraph, and Steps → a task-list body. The `type:` frontmatter field maps to GitHub label names (feature, fix, chore, refactor).

The integration point in `implementation-plan` is Step 8 — the exit menu that runs after a plan is authored. A new "Create a tracking issue" option invokes `git-agent:create-issue` with the plan path pre-filled. This is optional and adaptive: the menu option only appears when a GitHub or GitLab remote is detected.

## How to use it

```
/git-agent:create-issue plan docs/plans/my-plan.md   # create issue from plan file
```

Or via the Step 8 menu after `/plan-agent:implementation-plan`:

```
Step 8 — What next?
> Create a tracking issue   ← new option when a remote is available
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue](plans/add-plan-source-to-create-issue.md)
