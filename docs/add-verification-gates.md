# Add verification gates to highest-blast-radius skills

> Redefines "done" as artifact + verification in five high-blast-radius skills — settings-restore, code-review, ship, code-testing-agent, and review-plan — so each closes its own loop instead of reporting success on "looks done".

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-verification-gates.md](plans/add-verification-gates.md)
**Type:** fix

## What shipped

- `settings-restore/SKILL.md`: new Step 7 re-runs the Step 4 comparison for every restored entry, checks hook execute bits, and the Step 9 report uses verified results only, leading with `Restore INCOMPLETE` on any failure.
- `code-review-agent/SKILL.md` and `agents/agent-code-reviewer.md`: a Verify Findings step re-Reads each cited file:line, pastes the verbatim snippet, drops or labels **Unconfirmed** anything unsubstantiated; background agent gets the same plus a filled example finding.
- `ship/references/pr-body.md`, `agents/agent-ship.md`, and `ship/SKILL.md`: STOP only on `"state":"OPEN"`/`"opened"`; merged, closed, or no-PR proceeds to create — porting the fix from pr-agent 3.3.2.
- `code-testing-agent/SKILL.md` Step 6a and `reviewing-tests/SKILL.md` Step 7: execute written/edited tests via Bash with a bounded 3-iteration fix loop and honest hard stops; behavior-gap failures reported as findings.
- `review-plan/SKILL.md`, `references/output-template.md`, `agents/agent-review-plan.md`, `commands/review-plan-bg.md`: Step 1 spec/legacy mode detection; spec mode maps edits to spec sections and re-renders with `plan-agent-render`; Team Review appended to the spec; Step 7 verifies each edit landed with an applied/skipped tally.
- Bumped `code-review` to `3.3.4`, `code-testing-agent` to `3.5.1`, `git-agent` to `4.19.1`, `settings-sync` to `1.1.3`, `plan-agent` to `9.4.3`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/settings-sync/skills/settings-restore/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/code-review/skills/code-review-agent/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/code-review/agents/agent-code-reviewer.md` | Agent prompt | Modified |
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | Ship reference | Modified |
| `kit/plugins/git-agent/agents/agent-ship.md` | Agent prompt | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/code-testing-agent/skills/code-testing-agent/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/code-testing-agent/skills/reviewing-tests/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/review-plan/references/output-template.md` | Output template | Modified |
| `kit/plugins/plan-agent/agents/agent-review-plan.md` | Agent prompt | Modified |
| `kit/plugins/plan-agent/commands/review-plan-bg.md` | Background command | Modified |
| `.claude-plugin/marketplace.json` | Marketplace versions | Modified |

## How it works

The central finding from the Tier 2 agent-prompting audit: agents produce plausible-looking work and confidently declare completion because "done" is defined as producing the artifact, not verifying it. Each fix redefines the terminal condition.

For code-review, the verification step re-reads the actual file at the cited line number and discards any finding whose quoted snippet does not appear verbatim — preventing the most common false-positive pattern.

For ship, the state-check fix (ported from pr-agent 3.3.2) prevents `gh pr view` from blocking on a merged or closed PR. Previously any non-OPEN state caused ship to stop rather than proceeding to create a new PR.

For review-plan, the spec/legacy mode detection routes edits through the markdown spec rather than the rendered HTML, preventing changes from being regenerated away by the plan pipeline's own hook.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [add-verification-gates.md](plans/add-verification-gates.md)
