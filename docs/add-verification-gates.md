# Add Verification Gates

> Redefine "done" as artifact + verification in the five highest-blast-radius skills, so no skill can declare success on plausible-looking but broken output.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-verification-gates.md](plans/add-verification-gates.md)
**Type:** fix

## What shipped

- Added a re-run verification step (Step 7) to `settings-restore/SKILL.md` that re-runs the Step 4 comparison for every restored entry, checks `~/.claude/hooks` execute bits, and requires the Step 9 report to use verified results only, leading with `Restore INCOMPLETE` on any failure.
- Added a "Verify Findings" step to `code-review-agent/SKILL.md` and `agents/agent-code-reviewer.md` that re-Reads each cited file:line, pastes the verbatim snippet, and drops or labels `Unconfirmed` anything unsubstantiated.
- Fixed ship/agent-ship PR state check to stop only on `"state":"OPEN"` and proceed on merged, closed, or no-PR — porting the fix from pr-agent 3.3.2 that ship had never received.
- Added bounded 3-iteration fix loops with honest hard stops to both code-testing-agent skills, requiring tests to be executed via Bash before reporting done.
- Added spec/legacy mode detection to `review-plan` so reviews edit the `.md` spec directly (re-rendering via `plan-agent-render`) rather than the HTML output that gets regenerated away by the pipeline.
- Bumped plugin versions: code-review 3.3.4, code-testing-agent 3.5.1, git-agent 4.19.1, settings-sync 1.1.3, plan-agent 9.4.3.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/settings-sync/skills/settings-restore/SKILL.md` | Added Step 7 verification gate | Modified |
| `kit/plugins/code-review-agent/SKILL.md` | Verify Findings step | Modified |
| `kit/plugins/code-review-agent/agents/agent-code-reviewer.md` | Verify Findings + worked example | Modified |
| `kit/plugins/git-agent/skills/ship/references/pr-body.md` | PR state check | Modified |
| `kit/plugins/git-agent/agents/agent-ship.md` | PR state check | Modified |
| `kit/plugins/git-agent/skills/ship/SKILL.md` | PR state check | Modified |
| `.claude-plugin/marketplace.json` | Five plugin version bumps | Modified |

## How it works

The plan applied the same root-cause fix across five distinct skill patterns: each skill that produces output was declaring "done" the moment the artifact was written, with no check that the artifact was actually correct. The audit from `https://shumer.dev/prompting-ai-agents` identified this as the central failure mode — agents produce plausible-looking work and confidently declare completion.

For `settings-restore`, the destructive nature (rsync + rm) meant a corrupted restore could go undetected until the next session tried to use the misconfigured settings. The new Step 7 re-runs the same diff comparison that Step 4 used to check what needed restoring, and only a clean diff advances to the success report.

For `code-review`, the checklist-to-report flow had no evidence requirement: a finding could cite `file.ts:42` without re-reading that line. The Verify Findings step re-Reads each location and pastes the verbatim snippet — anything that doesn't match gets labeled `Unconfirmed` rather than silently removed, so the user can see what was attempted.

For ship, the `gh pr view` state check had a known gap where a merged PR would stop the flow. The fix mirrors the pattern pr-agent 3.3.2 already landed.

For code-testing-agent, both skills handed verification to the user despite having Bash available. The 3-iteration fix loop gives the skill multiple attempts to produce a passing run before escalating.

For review-plan, edits to the rendered HTML were being regenerated away by the pipeline's rebuild hook. The spec-mode detection directs edits to the `.md` source and re-renders via `plan-agent-render` so changes persist.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `cc28a20d` | 2026-10-28 | fix(settings-sync): restore switches back to this machine's branch (1.3.1) (#665) |
| `2f8b101b` | 2026-10-28 | fix(settings-sync): back up each machine to its own branch (1.3.0) (#662) |
| `28c3d704` | 2026-09-03 | fix(settings-sync): add marketplace step to install docs and stop false exec-bit failures (1.1.5) (#618) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-verification-gates.md](plans/add-verification-gates.md)
- Related: [add-verification-standards.md](add-verification-standards.md) — Tier 3 of the same audit; made gates an authoring standard
