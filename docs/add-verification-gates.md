# Add Verification Gates

> Redefine "done" as artifact plus verification in the five highest-blast-radius skills: settings-restore, code-review, ship/agent-ship, code-testing-agent, and review-plan.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-verification-gates.md](plans/add-verification-gates.md)
**Type:** fix

## What shipped

- Added a mandatory re-read verification step (Step 7) to `settings-restore` that re-runs the comparison for every restored entry and checks hook execute bits, reporting `Restore INCOMPLETE` on any failure rather than trusting planned counts.
- Extended `code-review-agent/SKILL.md` and `agents/agent-code-reviewer.md` with a Verify Findings step that re-reads each cited file and line, pastes verbatim snippets, and drops or labels `Unconfirmed` anything unsubstantiated.
- Updated the `ship` skill and `agent-ship` to query PR state and proceed to creation only when the existing PR is `OPEN`; merged and closed PRs no longer falsely block new PR creation.
- Rewrote both `code-testing-agent` skills (`SKILL.md` Step 6a and `reviewing-tests/SKILL.md` Step 7) to execute written and edited tests via Bash with a bounded 3-iteration fix loop, reporting behavior-gap failures as findings.
- Fixed `review-plan` to detect spec-backed plans and edit the `.md` source directly (not the rendered HTML), appending a Team Review section to the spec and verifying each edit landed with an applied/skipped tally; background mode reports `REVIEW INCOMPLETE` on any skip.
- Bumped five plugin versions: code-review 3.3.4, code-testing-agent 3.5.1, git-agent 4.19.1, settings-sync 1.1.3, plan-agent 9.4.3.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/settings-sync/skills/settings-restore/SKILL.md` | Restore skill with verification gate | Modified |
| `kit/plugins/code-review/skills/code-review-agent/SKILL.md` | Code review with re-read requirement | Modified |
| `kit/plugins/code-review/agents/agent-code-reviewer.md` | Background reviewer with evidence requirement | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Ship skill with PR state check | Modified |
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | PR body reference with state query | Modified |
| `kit/plugins/git-agent/agents/agent-ship.md` | Ship agent with PR state check | Modified |
| `kit/plugins/code-testing-agent/skills/code-testing-agent/SKILL.md` | Test agent with execute gate | Modified |
| `kit/plugins/code-testing-agent/skills/reviewing-tests/SKILL.md` | Review-tests skill with execute gate | Modified |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Review-plan with spec/legacy mode detection | Modified |
| `kit/plugins/plan-agent/skills/review-plan/references/output-template.md` | Output template for spec mode | Modified |
| `kit/plugins/plan-agent/agents/agent-review-plan.md` | Background review agent | Modified |
| `kit/plugins/plan-agent/commands/review-plan-bg.md` | Background review command | Modified |
| `.claude-plugin/marketplace.json` | Version bumps for five plugins | Modified |

## How it works

This fix closed the "done means the artifact exists" gap across the five skills with the highest blast radius — the ones where a false completion report has the largest downstream cost.

For `settings-restore`, the core problem was that the restore step reported the count of entries it *planned* to restore, not the count it *verified* restored. The new Step 7 re-runs the same comparison that Step 4 uses and checks that every expected entry is present in `~/.claude/` with correct content and, for hooks, executable permissions. The Step 9 summary is only reachable through the gate, and leads with `Restore INCOMPLETE` on any failure.

For `code-review`, the problem was that findings could be asserted from memory rather than from the current file state. The Verify Findings step requires reading each cited file at the cited line and pasting the verbatim snippet into the report. Any finding without a current-file quote is either dropped or labeled `Unconfirmed` with a note that it could not be substantiated.

For `ship`, the problem was that `gh pr view` resolves merged and closed PRs, but the skill stopped on any non-empty result. The fix narrows the stop condition to `"state":"OPEN"` so a merged or closed PR is treated as "no open PR" and the new PR creation proceeds. The `pr-agent` plugin had fixed this in v3.3.2; this change ports the fix to `ship`.

For both `code-testing` skills, the problem was that both handed verification to the user despite having Bash available. The new requirement is that any test file the skill writes or edits must be executed via Bash before the skill reports done, with a bounded 3-iteration fix loop and an honest hard stop when the loop is exhausted.

For `review-plan`, the core defect was that editing the rendered HTML was silently undone by the plan pipeline's own re-render hook. The fix adds a spec/legacy mode detection step: on spec-backed plans the skill maps selector targets to spec sections, edits the `.md` source directly, and appends a Team Review section. Step 7 verifies each edit landed and reports an applied/skipped tally.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-verification-gates.md](plans/add-verification-gates.md)
