# Add Optional Deep Grill Step to Plan Interview Skill

> Adds an optional Step 4.5 "deep grill" session to `plan-interview` that relentlessly walks every decision branch, provides recommended answers, and explores the codebase when answers live there.

<!-- generated:start -->

**Status:** Shipped 2026-03-26   **Plan:** [add-deep-grill-step-plan-interview.md](plans/add-deep-grill-step-plan-interview.md)   **Type:** feature

## What shipped

- New optional **Step 4.5 — Deep Grill** inserted between Step 4 (out-of-scope concerns) and Step 5 (summary) in `kit/plugins/plan-interview/skills/plan-interview/SKILL.md`.
- After Step 4, the user is prompted: "Would you like a deep-grill session?" — declining skips immediately to Step 5.
- When accepted, the step walks each design branch one at a time, provides a recommended answer for each question, uses `Glob`/`Grep`/`Read` for codebase-answerable questions, and resolves sub-questions before moving to the next branch.
- Findings feed into Step 5 under a new **Deep Grill Findings** section in the summary.
- `plan-interview` plugin bumped to `1.6.0`.

> See [CHANGELOG v1.6.0](../kit/plugins/plan-interview/CHANGELOG.md#160---2026-03-26) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/skills/plan-interview/SKILL.md` | Skill instructions — plan-interview | Modified |
| `kit/plugins/plan-interview/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump to 1.6.0 | Modified |

## How it works

Step 4.5 is opt-in by design. After completing the four structured rounds of the plan interview, the skill surfaces the deep-grill offer before finalizing the summary. This makes it easy to skip for straightforward plans while making it accessible for complex ones where decision branches remain uncertain.

When the user accepts, the step iterates the plan's design tree depth-first. For each decision node it asks a focused question and provides its own recommended answer before waiting for the user's input — preventing the back-and-forth of open-ended questioning. When a question can be answered from the codebase (e.g., "does this helper already exist?"), the skill uses `Glob`, `Grep`, or `Read` to find the answer and presents that finding as the recommendation.

Sub-questions are resolved before the step advances to the next branch, ensuring the full depth of each decision tree path is explored rather than breadth-first hopping across branches. The session ends either when all branches are exhausted or the user signals they are done.

All decisions and insights gathered during the deep grill are collected and appended to the Step 5 summary under a **Deep Grill Findings** section, so they inform the final review output rather than being lost to conversation history.

## How to use it

**Skill activation** — auto-activates when you ask to "stress-test this plan", "validate my plan", or similar. After the structured interview rounds, the deep-grill offer appears:

```
Would you like a deep-grill session? I'll interview you relentlessly about
every decision branch until we reach a shared understanding — providing my
recommended answer for each question. Where answers can be found in the
codebase, I'll explore it instead of guessing.
```

Reply "yes" or "no". No special invocation syntax is needed.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [add-deep-grill-step-plan-interview.md](plans/add-deep-grill-step-plan-interview.md)
- Changelog: [CHANGELOG v1.6.0](../kit/plugins/plan-interview/CHANGELOG.md#160---2026-03-26)
