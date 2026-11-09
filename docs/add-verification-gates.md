# Add Verification Gates

> Redefines "done" as artifact + verification in five highest-blast-radius skills: `settings-restore`, `code-review` (both paths), `ship`/`agent-ship`, `code-testing-agent` (both skills), and `review-plan`.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [add-verification-gates](plans/add-verification-gates.md)
**Type:** fix

## What shipped

- **settings-restore**: new Step 7 re-runs the Step 4 comparison for every restored entry, checks hook execute bits; Step 9 report leads with `Restore INCOMPLETE` on any failure
- **code-review** (skill + agent): Verify Findings step re-reads each cited file:line, pastes verbatim snippet, drops or labels `Unconfirmed` anything unsubstantiated; background agent gains the same as a workflow step plus a filled example finding
- **ship/agent-ship**: STOP only on `"state":"OPEN"`/`"opened"`; merged, closed, or no-PR states proceed to create (ported from pr-agent 3.3.2 fix)
- **code-testing-agent** (skill + reviewing-tests): execute written/edited tests via Bash, bounded 3-iteration fix loop, honest hard stops; stale-mock findings need paired mock+source quotes
- **review-plan**: edit the spec, not the render; verification step reads the spec after editing to confirm the edit landed

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/settings-sync/skills/settings-restore/SKILL.md` | Skill — Step 7 re-verification, Step 9 gate | Modified |
| `kit/plugins/code-review/skills/code-review-agent/SKILL.md` | Skill — Verify Findings step | Modified |
| `kit/plugins/code-review/agents/agent-code-reviewer.md` | Agent — verify step + filled example | Modified |
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | Reference — PR state check fix | Modified |
| `kit/plugins/git-agent/agents/agent-ship.md` | Agent — PR state check fix | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Skill — PR state check fix | Modified |
| `kit/plugins/code-testing-agent/skills/code-testing-agent/SKILL.md` | Skill — execute-what-you-write gate | Modified |
| `kit/plugins/code-testing-agent/skills/reviewing-tests/SKILL.md` | Skill — execute-what-you-write gate | Modified |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Skill — edit spec, verify edit | Modified |

## How it works

The central finding of the agent-prompting audit (Tier 2): agents produce plausible-looking work and confidently declare completion — a skill can report "done" while having generated broken output because "done" was defined as producing the artifact, not verifying it.

Each fix follows the same pattern: after the mutation step, add an explicit re-read or re-run that confirms the artifact is correct before the skill reports success. `settings-restore` re-runs the diff it ran in Step 4 and fails loudly if any entry is still wrong. `code-review` re-reads the file at the cited line and drops findings that don't survive the re-read. `ship` queries the PR state before opening (rather than assuming it needs to be created). `code-testing-agent` executes the tests it writes. `review-plan` reads the spec after editing to confirm the edit actually landed.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [add-verification-gates](plans/add-verification-gates.md)
