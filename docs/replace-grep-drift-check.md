# Replace build's grep drift check with a deterministic render check

> `plan-agent build`'s final gate described DOM invariants as CSS selectors the model could only reach by grepping HTML source, producing false drift signals. This adds `--check` to `plan-agent-render` and rewires the gate to call it instead.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
**Type:** feature

## What shipped

- Added `--check` mode to the canonical `scripts/build-plan-html.mjs`: renders the spec to memory, byte-compares against the existing output file, and reports the first differing line with its number and 40 characters of context.
- Extended `--check` with spec-consistency assertions evaluated on the parsed Markdown (not the HTML): for a `status: completed` spec, every numbered step must carry `[x]` and every `## Acceptance Criteria` bullet must be `- [x]`. Skipped entirely for `status: in-progress`.
- Made `--check` print a fixed PASS/FAIL table with one row per property (`html`, `steps`, `criteria`) and exit 0 only when all rows pass.
- Re-copied the edited renderer to `kit/plugins/plan-agent/scripts/build-plan-html.mjs` so the bundled copy is byte-identical (held by a parity assertion in the test suite).
- Rewrote `skills/build/references/completion-gates.md` Step 5.3 as a single command: `plan-agent-render "<stem>.md" -o "<stem>.html" --check`; deleted the five-selector paragraph.
- Applied the same replacement to `skills/finalize-plan/references/write-completions.md` for consistency.
- Extended `tests/plugins/test-build-plan-html.mjs` with determinism, stale-HTML, missing-HTML, completed-with-unchecked-criterion, and in-progress-skip cases.
- Bumped plan-agent to 9.4.0 in `.claude-plugin/marketplace.json` (the spec said 9.3.0 but PR #554 shipped that version to `main` during review; the guard requires exceeding the base branch).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | Canonical renderer; added `--check` mode at line 719 | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical copy of the canonical renderer | Modified |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Step 5.3 replaced with `--check` command; selector list deleted | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Same `--check` replacement for consistency | Modified |
| `kit/plugins/plan-agent/README.md` | Documents `--check` in the renderer section | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 9.4.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Added determinism, check-mode, and spec-consistency test cases | Modified |

## How it works

The old Step 5.3 instructed the model to confirm five CSS selectors as evidence of render freshness. A model with selector names and no evaluation tool reaches for `Grep`, which searches source markup rather than evaluating selectors — a class defined in a stylesheet counts as a match, and a class the renderer emits conditionally does not. Both failure modes were observed in the 2026-08-14 usage report, which named grep-as-verification as the single largest source of wasted passes.

The plan identified that the DOM inspection conflated two distinct properties. Freshness (`is the HTML current?`) is answered by byte-comparing the on-disk file against a fresh in-memory render — same spec rendered to the same output path is deterministic, because `plan-created` is preserved by reading back from the existing file and `created` comes from frontmatter. Consistency (`is a completed spec internally consistent?`) is a Markdown question evaluated on the spec itself, not the HTML. Neither property requires reading rendered markup.

The renderer keeps `plan-file` and `plan-path` stable only at a fixed output path; rendering to a different path changes exactly those two fields. The `--check` implementation compares at the same path and never normalizes those fields, so a plan HTML copied in from another location correctly fails the check.

`scripts/build-plan-html.mjs` is canonical; `kit/plugins/plan-agent/scripts/build-plan-html.mjs` is a bundled duplicate held byte-identical by a parity assertion whose failure message is "drifted from scripts/… — re-copy it". Every step edits the root module first and re-copies, so tests always import the canonical code and the parity assertion stays meaningful.

One minor deviation from the plan as written: `write-completions.md` retains two `.step-card` mentions — one explaining what the renderer derives (an argument against HTML surgery) and one in the legacy edit path for plans that have no `.md` spec, where the selector is an edit target rather than drift evidence. The acceptance criterion "neither file names a CSS selector as evidence" is met; the literal string just survives in a different role.

## How to use it

```bash
# Check that a plan's HTML is current and its completed spec is internally consistent
node scripts/build-plan-html.mjs docs/plans/my-plan.md -o docs/plans/my-plan.html --check
# Or via the plugin binary
plan-agent-render docs/plans/my-plan.md -o docs/plans/my-plan.html --check
```

The command prints a table:
```
html    PASS
steps   PASS
criteria PASS
```
Exit 0 means all rows passed. A non-zero exit names the failing property and gives the first differing line number or the offending criterion's text. Fix is always in the spec, never the HTML.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
