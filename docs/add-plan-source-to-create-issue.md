# Add plan source to create-issue skill

> Wires `plan-agent:implementation-plan` to `git-agent:create-issue` so finishing a plan can automatically open a tracking GitHub issue pre-populated from the plan's context.

<!-- generated:start -->

**Status:** Shipped 2026-07-13  **Plan:** [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
**Type:** feature

## What shipped

- Added a `plan` source variant to `git-agent:create-issue`: a leading `.md`/`.html` token in arguments is now treated as a plan path, and the issue body is built from `create-issue/references/plan-issue.md`.
- Added `create-issue/references/plan-issue.md` — the mapping template that converts a plan's Goal, Context, Steps, and Resources sections into a structured GitHub issue body.
- Updated `implementation-plan/SKILL.md` Step 8 to offer a batched "Create a tracking issue?" question; on accept it invokes `git-agent:create-issue plan <path>` and records the returned issue URL in the plan frontmatter as `issue:`.
- Updated `CLAUDE.md` root plugin reference table.
- Bumped `git-agent` to `3.12.0` and `plan-agent` to `2.22.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/git-agent/skills/create-issue/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/skills/create-issue/references/plan-issue.md` | Plan-to-issue mapping template | Created |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `CLAUDE.md` | Root plugin reference table | Modified |
| `tests/plugins/test-create-issue-plan-source.sh` | Smoke test | Created |

## How it works

`create-issue` inspects its leading argument: a token ending in `.md` or `.html` activates the `plan` source path. The skill reads the plan file, extracts its Goal, Context, Steps summary, and Resources sections, and passes them through `plan-issue.md` to produce a structured issue body. The resulting issue links back to the plan file and includes the plan's Goal as the issue title.

`implementation-plan` already ends at Step 8 with a gate asking whether to proceed or exit. The plan source change adds a third batched question: "Create a tracking issue?" If the user accepts, the skill delegates to `git-agent:create-issue plan <spec-path>` and writes the returned issue URL into the plan's frontmatter under `issue:`, making the connection between plan and tracking issue durable across sessions.

## How to use it

```
/git-agent:create-issue plans/my-feature.md
```

Or, from inside `implementation-plan`, accept the "Create a tracking issue?" prompt at Step 8.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [add-plan-source-to-create-issue.md](plans/add-plan-source-to-create-issue.md)
