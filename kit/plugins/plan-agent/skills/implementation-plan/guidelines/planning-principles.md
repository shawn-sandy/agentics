# Planning Principles

Principles, not markup. The renderer owns how a plan looks; these rules govern
what a good plan *says*. Apply them to every plan regardless of size.

## Make "done" falsifiable

- Every acceptance criterion is a short statement that is verifiably true or
  false — "`npm test` exits 0 with the new suite included", never "tests are
  improved".
- If you cannot name the command, file state, or observable behaviour that
  proves a criterion, the criterion is not ready — sharpen it or cut it.
- Criteria describe the *result* from the requester's perspective; steps
  describe the work. Never restate a step as a criterion.

## Every step: what, why, verify

- **Action** — one imperative sentence naming real files, functions, or
  commands. A step that touches "various files" is two or more steps.
- **Why** — the reason this step exists, phrased for a reader who wasn't in
  the planning session. If you cannot say why, the step is speculative — cut
  it.
- **Verify** — how to confirm *this step* worked before moving on: a command
  to run, a file state to inspect, an output to compare. Step-local, cheap,
  immediate.

## Verification is end-to-end, not just per-step

Per-step verifies prove each move; the Verification section proves the
*objective*. Walk the whole change as a user or caller would — run the app,
call the API, open the page. A plan where every step verified but the
objective was never exercised end-to-end is unfinished.

## Surface risks and open questions — never bury them

- A known risk belongs in Context (with its mitigation) or in a step's why —
  not silently absorbed.
- A question only the user can answer is an open question; ask it during
  Clarify or the interview rather than planning around a guess.
- Never present an assumption as a fact. Say "assumes X; confirm before step
  3" and make the confirmation part of the plan.

## Scope is explicit

Three buckets, never mixed:

1. **Requested work** — what the user asked for. This is the steps.
2. **Follow-ups** — worthwhile but not asked for. These go in a Next steps
   list in the spec, never in the steps.
3. **Wish list** — speculative, blue-sky. Label them as such or omit them.

Plan only what was requested. A plan that quietly grows extra steps is a
scope defect, not thoroughness.

## Right depth beats full coverage

A two-line dependency bump does not need a Context essay, a file-tree, or
three test tiers. An architecture change does. Read `right-sizing.md` and
match the plan's depth to the work — the required core (objective, steps,
acceptance criteria, verification) is always present; everything else earns
its place.
