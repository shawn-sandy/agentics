# Make a finished plan admit it is finished

> Closes the plan-completion gap by adding a drift-detector hook that fires when every step and criterion is ticked but `status` is still not `completed`, and unlocks `finalize-plan` so the model can act on the signal.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [fix-plan-completion-drift.md](plans/fix-plan-completion-drift.md)
**Type:** fix

## What shipped

- Added `detect-plan-completion-drift.py` hook (registered in `hooks.json`) that fires on every plan-spec write and reports a contradiction when all steps and criteria are ticked but `status` is not `completed`
- Removed `disable-model-invocation: true` from `finalize-plan/SKILL.md` so the model can invoke the skill when the detector fires
- Generalised `buildImplementPrompt()` in `plan-shell.mjs` into a shared builder; rewired `copyGoal` and `copyWorkflow` to use it so all three copy handlers teach the check-off loop
- Carried the check-off clause into the `plan-goal` and `plan-workflow` meta tags in `build-plan-html.mjs` so the primary workflow prompt path also instructs ticks
- Added the Completion Report clause to every prompt variant so a bypassed step is recorded rather than falsely ticked
- Bumped `plan-agent` to `3.1.0` with a CHANGELOG entry naming the activation change

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/hooks/detect-plan-completion-drift.py` | Drift-detector hook — fires on plan-spec writes, exits 2 when all-ticked/not-completed | Missing |
| `kit/plugins/plan-agent/hooks.json` | Hook registry — registers the detector as a fifth PostToolUse entry | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Finalize skill — `disable-model-invocation` removed, description retuned | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Implementation skill — Exit branch and Step 6 reference the detector | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Plan shell — shared `buildImplementPrompt()` wired to all three copy handlers | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | HTML builder — `plan-goal` and `plan-workflow` meta tags carry the check-off clause | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Test — asserts all three prompts instruct check-off | Modified |
| `tests/plugins/test-plan-completion-drift.sh` | Test — six fixtures covering the drift state and the noise contract | Missing |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release entry for 3.1.0 | Modified |
| `.claude-plugin/marketplace.json` | Version bump to 3.1.0 | Modified |

## How it works

Before this change the plan-completion machinery existed but was unreachable. `finalize-plan` was blocked by `disable-model-invocation: true`, so the only path to it was a manually typed command. No hook watched for the contradiction between a fully-ticked spec and a non-`completed` status. The dominant workflow — generate a plan, exit, implement it in a later session — hit no gate at all, so plans routinely finished implementation and stayed silently at `todo` forever.

The fix adds a deterministic contradiction detector: `detect-plan-completion-drift.py` runs on every `Write`, `Edit`, or `MultiEdit` that touches a plan spec inside the resolved plans directory. It parses the spec for three facts — the `status:` value in frontmatter, whether every numbered step carries `[x]`, and whether every `- [ ]` acceptance criterion has been ticked to `- [x]`. When all three conditions hold simultaneously (at least one step, at least one criterion, all ticked, status not `completed`), it writes a message to stderr naming the spec and pointing at `/plan-agent:finalize-plan`, then exits 2. Every other case exits 0 silently.

The hook reports; it never writes. Resolving the contradiction is delegated to `finalize-plan`, which already inspects codebase evidence and gates on an `AskUserQuestion` before any status write. Removing `disable-model-invocation` from that skill is the second half of the fix: without it, the detector's advice is unactionable because the model cannot reach `finalize-plan` and the user must hand-type the command — the same habit that produced the original bug.

Four conditions must hold simultaneously for the hook to fire: the written file must be a `# Plan:` spec inside the resolved plans directory, every step must be `[x]`, every criterion must be `- [x]`, and `status` must not be `completed`. This means the hook cannot fire in a session with no plan in play. Partial progress (some steps ticked, not all) exits 0 — that is a genuinely unfinished plan and `status: in-progress` is accurate.

The detector is only half the mechanism. It fires on ticks, so a session where the prompts never ask for any ticks would leave the hook permanently silent. Three prompts start an implementation — Implement, Goal, and Workflow — but before this change only the Implement prompt taught the check-off loop. The Goal and Workflow handlers copied a bare `textContent` one-liner with no check-off instruction. `buildImplementPrompt()` was generalised into a shared builder that all three handlers now call, ensuring they cannot drift apart. The `plan-goal` and `plan-workflow` meta tags in the rendered HTML were also updated, because `implementation-plan/SKILL.md` hands the workflow prompt to a subagent by reading the meta tag directly — a copy-handler fix alone would miss the primary workflow path entirely.

A Completion Report clause was added to every prompt variant. When an agent achieves the objective by a different route than the plan's steps, it records the discrepancy as a `## Completion Report` bullet instead of ticking the bypassed step, which prevents a goal-driven run from producing a false record.

The known remaining hole is a session that implements a plan and never writes to the spec at all. With no write event there is no hook event, and the plan stays silently at `todo`. Closing that fully requires a `Stop` hook that can distinguish "implemented this plan" from "happened to read it" — a distinction that cannot be made reliably from the transcript, and a noisy hook that nags about every in-progress plan on every session end would be worse than the bug. This is named in Next Steps rather than smuggled into this change.

## How to use it

No manual action is required. Once `plan-agent` 3.1.0 is installed, the hook fires automatically on every plan-spec write. When a plan reaches the all-ticked/not-completed state, the session surfaces a message naming the spec and instructing `/plan-agent:finalize-plan <path>`. The model can now act on that signal directly — `finalize-plan` verifies against the codebase and asks before writing `status`. A completion that was never verified still cannot happen.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [fix-plan-completion-drift.md](plans/fix-plan-completion-drift.md)
