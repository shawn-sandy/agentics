# Add Verification Gates

> Redefine "done" as artifact plus verification in five highest-blast-radius skills so an agent cannot declare success on broken or incomplete output.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-verification-gates.md](plans/add-verification-gates.md)
**Type:** fix

## What shipped

- `settings-restore` gained a Step 7 re-verification pass that re-runs the file comparison for every restored entry, checks hook execute bits, and gates the Step 9 report — the step now leads with `Restore INCOMPLETE` on any failure rather than reporting planned counts
- `code-review-agent` and `agents/agent-code-reviewer.md` gained a Verify Findings step that re-Reads each cited file at the cited line, pastes the verbatim snippet, and drops or labels **Unconfirmed** any finding that cannot be substantiated
- `ship/SKILL.md`, `ship/references/pr-body.md`, and `agents/agent-ship.md` were updated to query `gh pr view --json state` and halt only on `"OPEN"` — merged, closed, or no-PR states all proceed to create instead of stalling
- Both code-testing-agent skills (`code-testing-agent/SKILL.md` and `reviewing-tests/SKILL.md`) now execute the test files they write or edit via Bash, with a bounded three-iteration fix loop and honest hard stops
- `review-plan/SKILL.md` gained spec/legacy mode detection (Step 1), maps selector targets to spec sections, re-renders with `plan-agent-render`, and produces an applied/skipped tally at Step 7 with `REVIEW INCOMPLETE` in background mode on any skip
- Bumped five plugin versions: code-review 3.3.4, code-testing-agent 3.5.1, git-agent 4.19.1, settings-sync 1.1.3, plan-agent 9.4.3

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/settings-sync/skills/settings-restore/SKILL.md` | settings-restore with Step 7 verification gate | Modified |
| `kit/plugins/code-review/skills/code-review-agent/SKILL.md` | Code review agent with re-read requirement | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Ship skill with PR state check | Modified |
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | PR body reference with state query | Modified |
| `kit/plugins/code-testing-agent/skills/code-testing-agent/SKILL.md` | Test writing skill with execution gate | Modified |
| `kit/plugins/code-testing-agent/skills/reviewing-tests/SKILL.md` | Test review skill with execution gate | Modified |
| `kit/plugins/plan-agent/skills/review-plan/SKILL.md` | Review-plan with spec mode and tally | Modified |
| `.claude-plugin/marketplace.json` | Version bumps for five plugins | Modified |

## How it works

This plan was Tier 2 of a broader agent-prompting audit run against a published prompt-engineering guide. Tier 1 addressed security issues; Tier 2 targeted the five skills where "done" was defined as producing the artifact rather than verifying it — the audit's central finding that agents produce plausible-looking work and confidently declare completion.

The settings-restore fix was the highest blast-radius change: the skill previously reported planned file counts, not verified ones. A restore that failed partway could report success. The new Step 7 re-runs the file comparison from Step 4 for every restored entry and checks executable bits on hook files, so the Step 9 summary reflects what actually landed.

Code review had no evidence requirement — a finding could appear in the checklist-to-report pipeline without the agent ever opening the cited file. The new Verify Findings step re-Reads each file at the cited line number and pastes the verbatim snippet directly into the finding. Anything that cannot be substantiated is either dropped or labeled **Unconfirmed**.

The ship skill stalled when it encountered a merged or closed PR because `gh pr view` returned a non-empty result that the old logic treated as "PR exists, stop". The `pr-agent` plugin had fixed this at v3.3.2 by querying `state`; this change ported that fix to ship, reading the JSON `state` field and proceeding on anything that is not `"OPEN"`.

Both code-testing skills previously wrote test files and then handed verification to the user, despite having Bash available. The fix adds a bounded execution loop: write the tests, run them via Bash, and if they fail iterate up to three times before issuing a hard stop with an honest failure report. Stale-mock findings now require paired quotes from both the mock and the production source.

Review-plan was editing rendered HTML that the pipeline's own rebuild hook regenerated on the next plan write, silently discarding the edits. The spec/legacy mode detection at Step 1 identifies whether the plan lives in a `.md` spec file and, if so, maps all edits to the spec's sections rather than the rendered output. Step 7 then verifies each edit landed and produces an applied/skipped tally.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `28c3d70` | 2026-09-03 | fix(settings-sync): add marketplace step to install docs and stop false exec-bit failures (1.1.5) (#618) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-verification-gates.md](plans/add-verification-gates.md)
- Audit source: <https://shumer.dev/prompting-ai-agents>
- Related: [add-verification-standards.md](add-verification-standards.md) (Tier 3)
