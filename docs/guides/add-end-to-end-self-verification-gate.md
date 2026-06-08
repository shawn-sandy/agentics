# Add End-to-End Self-Verification Gate to plan-agent

> Adds an explicit end-to-end self-verification step to the `plan-agent` plugin so Claude actually *runs* the verification work authored into a plan — executing the objective-verification test and walking the Verification section — before marking a plan completed, in both the implement-now flow and `finalize-plan`.

**Status:** Shipped 2026-06-08   **Branch:** `claude/planning-agent-self-verify-C7BLK`   **Type:** feature

## The problem

Plans authored end-to-end verification at creation time — every plan ships a **Verification** section (`#verification`) and a mandatory **objective-verification test** (`.objective-test-card`) that asserts the plan's goal works in the running app. But when Claude **implemented** a plan, Step 8 only ran two gates:

1. **Acceptance-criteria gate** — verifies each criterion item-by-item
2. **Completion-checklist gate** — confirms three meta-conditions (step TODOs done, criteria checked, status updated)

Neither gate ever *executed* the holistic end-to-end verification or ran the objective-verification test. The plan *described* end-to-end verification; the run-flow never *performed* it. `finalize-plan` had the same gap — it gathered codebase evidence and did per-criterion checks, but never ran the objective test.

## What shipped

- **End-to-end verification gate** added to the implement-now flow (`implementation-plan` Step 8), slotted **between** the acceptance-criteria gate and the completion-checklist gate. It reads the `#verification` section and the Tests section, runs the objective-verification test (plus any unit/integration/E2E tests) via the authored **Run** command, and confirms every end-to-end verification step holds before allowing completion.
- **Bounded fix-and-re-verify loop** on failure — Claude diagnoses the cause, fixes the source, and re-runs the gate up to 3 times. If it still fails (or the failure is environmental/out of scope), it stops, downgrades status to `in-progress`, records the failing test/step in the Completion Report, and asks the user how to proceed (`Keep trying` / `Mark in-progress and stop` / `Mark completed anyway`).
- **Objective-verification test run in `finalize-plan`** (new Step 3c) — executes the `.objective-test-card` **Run** command as an end-to-end pass/fail signal, surfaces the result (`pass` / `fail` / `n/a`) in the Step 4 findings table, warns before completing on failure, and logs failures to the Completion Report (Step 5e). `finalize-plan` inspects only — it does not auto-fix, consistent with its review-and-confirm role.
- README and CHANGELOG updated to document both gates.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Implement-now flow — adds the end-to-end verification gate to Step 8 | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Finalize flow — adds objective-test run (3c), findings row, and report entry | Modified |
| `kit/plugins/plan-agent/README.md` | Documents the new gate and finalize-plan step | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — Unreleased entry | Modified |

> Version was **not** bumped manually — CI auto-bumps `marketplace.json` after merge based on the `feat(...)` commit (minor bump). The `marketplace.json` `version` field was deliberately left untouched.

## How it works

When the user chooses **Implement now** in Step 8, Claude works through the steps, then runs three sequential gates before marking the plan complete:

1. **Acceptance-criteria gate** (unchanged) — verifies and checks off each criterion in `#criteria-list`.
2. **End-to-end verification gate** (new) — the holistic check:
   - Reads `#verification` and the Tests section (`.objective-test-card` + any `.test-card` items).
   - Runs the objective-verification test using its authored **Run** command, then any other tests. For a **Tier 2** plan with no runnable tests, it instead walks each `#verification` step and confirms the end state by inspecting changed files or running the relevant command.
   - On failure, it enters a **bounded loop**: diagnose → fix source → re-run from the test step, up to 3 attempts. Pass on a retry continues to the next gate; persistent failure stops the loop, sets `in-progress`, populates the Completion Report, and prompts the user.
3. **Completion-checklist gate** (unchanged, renumbered to run after the new gate) — confirms the three meta-conditions and checks off `cc1`/`cc2`/`cc3`.

`finalize-plan` gains a parallel signal: Step 3c extracts and runs the objective test's **Run** command so the standalone completion command also confirms the objective works end-to-end, not just that codebase evidence exists.

## Design decisions

- **Process gate, not a new checklist item.** The completion checklist's `cc1`/`cc2`/`cc3` contract is referenced by `finalize-plan` and the plan's inline JS, so adding a fourth checkbox would ripple across the skeleton and break that contract. The end-to-end verification is a process step instead.
- **Auto-fix only in the implement flow.** The implement-now flow fixes and re-verifies (it's already in implementation mode). `finalize-plan` only inspects and reports — it never mutates source — matching its review-and-confirm purpose.
- **Bounded retries.** Capped at 3 attempts to avoid an unbounded fix loop, then hands the decision back to the user.

## How to use it

**Implement-now flow** — create a plan, then choose **Implement now** at Step 8. The end-to-end verification gate runs automatically before completion:

```
/plan-agent:implementation-plan add a dark mode toggle that persists across themes
```

**Finalize flow** — the objective test runs as part of evidence gathering:

```
/plan-agent:finalize-plan add-dark-mode-toggle.html
```
