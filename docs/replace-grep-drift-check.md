# Replace Build's Grep Drift Check with a Deterministic Render Check

> Plan `build`'s final gate tells the model to confirm five DOM invariants named as CSS selectors, with no way to evaluate them — so it greps the HTML and gets false drift. This adds `plan-agent-render --check`, which byte-compares the rendered file against a fresh in-memory render and asserts a `completed` spec is internally consistent, and rewires the gate to call it.

<!-- generated:start -->

**Status:** Shipped 2026-08-14  **Plan:** [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
**Type:** feature

## What shipped

- Added a `--check` mode to `scripts/build-plan-html.mjs` (and the byte-identical bundled copy) that renders a plan spec in memory, byte-compares the result against the on-disk HTML, and reports the first differing line with its number and 40 characters of context on each side.
- Extended `--check` with spec-consistency assertions (active only when `status: completed`): every numbered step must carry `[x]` and every `## Acceptance Criteria` bullet must be `- [x]`.
- Made `--check` print a fixed PASS/FAIL table with one row per property (`html`, `steps`, `criteria`), exiting 0 only when all rows pass.
- Rewired `skills/build/references/completion-gates.md` Step 5.3 to run `plan-agent-render "<stem>.md" -o "<stem>.html" --check` as a single command, deleting the five-selector DOM inspection paragraph that was producing false drift signals.
- Applied the same replacement to `skills/finalize-plan/references/write-completions.md` for consistency.
- Extended `tests/plugins/test-build-plan-html.mjs` with determinism, stale-HTML, missing-HTML, completed-with-unchecked-criterion, and in-progress-skip test cases.
- Bumped `plan-agent` to 9.4.0 and added a CHANGELOG entry and README documentation for `--check`.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `scripts/build-plan-html.mjs` | Canonical renderer — `--check` mode implementation | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy — byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Build completion gate — Step 5.3 replaced with `--check` command | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Finalize completion gate — same `--check` replacement | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — `--check` mode documented in renderer section | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog — 9.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — plan-agent 9.3.0 → 9.4.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Test suite — determinism and check-mode assertions added | Modified |

## How it works

The original Step 5.3 in `completion-gates.md` told the implementing agent to confirm five CSS selectors as DOM invariants: `.step-card` elements completed, criteria inputs `checked`, three status representations, and `completion-checklist` carrying `all-complete`. Because the agent has no DOM evaluator, it reached for `Grep`, which searches raw source markup rather than evaluating rendered state. A selector defined in a stylesheet counts as a match; a class the renderer emits conditionally does not. Both failure modes were observed in practice: unnecessary second verification passes caused by false drift, and spec/checkbox state mismatches that `Grep` could not distinguish.

The check addresses two separate properties that the old DOM inspection conflated. The first is build freshness: if the file on disk was produced from this spec by a deterministic function, it is byte-identical to a fresh render. Staleness means a re-render was skipped, the write partially failed, or someone hand-edited the HTML. All three are caught by a single byte comparison. The second is spec consistency: a `completed` spec must have every step as `[x]` and every acceptance criterion as `- [x]`. Neither property requires reading rendered markup.

`--check` is implemented entirely in `scripts/build-plan-html.mjs`. It renders the spec to an in-memory string using the same `renderPlanHtml` function as the normal build path, then compares against the on-disk file byte-for-byte. Determinism was verified at a fixed output path before implementation: two renders of the same unchanged spec over the same path produce identical bytes, because `plan-created` is read back from the existing HTML on re-render and `created` comes from frontmatter. The `plan-file` and `plan-path` fields are derived from the output path, so cross-path comparisons were deliberately not normalized — doing so would make `--check` pass an HTML file copied in from another location, which is one of the stale states it exists to detect.

The spec-consistency assertions run only when `status: completed` is present in frontmatter. For an `in-progress` plan, the `steps` and `criteria` rows are reported as skipped rather than passed. A missing output file reports FAIL naming the render command rather than throwing, making the failure immediately actionable. The printed table has a fixed row order (`html`, `steps`, `criteria`) regardless of which properties pass or fail, so tests can assert against it stably.

The bundled copy at `kit/plugins/plan-agent/scripts/build-plan-html.mjs` is held byte-identical to the root by an existing test assertion. Re-copying it after every root edit is the entire contract. The test suite was extended with five new cases — render determinism at a fixed path, stale-HTML failure with differing-line report, missing-HTML failure with render-command name, completed-with-unchecked-criterion failure, and in-progress skip — while all existing assertions (including the round-trip property and the parity assertion) remained green.

## How to use it

Run `plan-agent-render "<stem>.md" -o "<stem>.html" --check` after any plan build or finalize step. A zero exit with a PASS row for each property confirms the HTML is current and (for a completed plan) the spec is internally consistent. A non-zero exit names the failing property: a `html FAIL` row reports the first differing line, a `criteria FAIL` row quotes the unchecked criterion text. The fix is always in the spec (or a missing re-render), never in the HTML.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
