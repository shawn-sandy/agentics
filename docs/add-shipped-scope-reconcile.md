# Reconcile a plan against what actually shipped

> Adds a reconcile step to `finalize-plan` that compares a plan against the commits that actually shipped it, recording work that was shipped but unplanned and work built differently into the plan spec.

<!-- generated:start -->

**Status:** Shipped 2026-08-30  **Plan:** [add-shipped-scope-reconcile](plans/add-shipped-scope-reconcile.md)
**Type:** feature

## What shipped

- Added reconcile step to `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` that runs after plan completion is confirmed
- Reconcile reads `git log --since=<created> --until=<modified>` on the plan file and all files mentioned in the plan body
- Records shipped-but-unplanned work as a `## Divergences` section in the plan spec
- Records built-differently work as inline annotations on the relevant steps
- Published plan artifact reflects what was built, not only what was imagined

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill — reconcile step | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent bump | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history | Modified |

## How it works

Implementation never perfectly follows a plan. The reconcile step closes the gap between "what the plan says happened" and "what actually shipped" by reading the git history.

After `finalize-plan` confirms the plan is complete (all steps checked, objective-verification test passing), the reconcile step runs `git log` over the plan file and all file paths mentioned in the plan body, bounded to the plan's creation-to-modification window. It compares the actual diff against the plan's Steps and Files sections.

Work found in commits but absent from the plan goes into a `## Divergences` section: shipped files not in the plan, steps that were added beyond what the plan described. Work where the actual approach differed from the plan — same file but different mechanism — gets an inline `> Note: built as...` annotation on the relevant step.

This makes a finalized plan a more accurate reference document: readers see both the original intent and the actual outcome.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `b7c4e91` | 2026-08-30 | feat(plan-agent): add shipped-scope reconcile to finalize-plan |

<!-- generated:end -->

## References

- Plan: [add-shipped-scope-reconcile](plans/add-shipped-scope-reconcile.md)
