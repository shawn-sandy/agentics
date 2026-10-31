# Replace build's grep drift check with a deterministic render check

> Adds a `--check` mode to `plan-agent-render` that byte-compares a plan's HTML against a fresh in-memory render and asserts a `completed` spec is internally consistent, then rewires the build and finalize-plan gates to call it instead of describing DOM selectors to grep.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [replace-grep-drift-check](plans/replace-grep-drift-check.md)
**Type:** feature

## What shipped

- Added `--check` mode to canonical `scripts/build-plan-html.mjs`: renders the spec to a string, compares byte-for-byte against the on-disk HTML at the same path, and reports the first differing line with its line number and 40 characters of context
- Extended `--check` with spec-consistency assertions gated on `status: completed`: all numbered steps must carry `[x]` and all acceptance criteria bullets must be `- [x]`
- Made `--check` print a fixed PASS/FAIL table (`html`, `steps`, `criteria`) with a summary line, exiting non-zero when any row fails
- Re-copied the edited renderer to `kit/plugins/plan-agent/scripts/build-plan-html.mjs` byte-identical
- Rewrote `skills/build/references/completion-gates.md` Step 5.3 as a single `plan-agent-render "<stem>.md" -o "<stem>.html" --check` command, deleting the five-selector paragraph
- Applied the same replacement to `skills/finalize-plan/references/write-completions.md`
- Extended `tests/plugins/test-build-plan-html.mjs` with determinism, stale-HTML, missing-HTML, completed-with-unchecked-criterion, and in-progress-skip cases
- Bumped plan-agent to 9.4.0

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | Script — `--check` mode | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy — byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Reference — Step 5.3 rewritten | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Reference — same gate updated | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — `--check` documented | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release history — 9.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent 9.4.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Smoke test — new check-mode cases | Modified |

## How it works

The build skill's Step 5.3 asked the model to confirm five DOM invariants by naming CSS selectors — `.step-card` elements completed, criteria inputs `checked`, three status representations, cc1–cc3, `completion-checklist` carrying `all-complete`. A model handed selector names and no evaluator reaches for `Grep`, which searches source markup rather than evaluating anything: a class defined in the stylesheet matches while a class the renderer emits conditionally does not. Both failure directions were observed in usage data.

The root problem: the HTML is *derived* from the spec by a deterministic function this repo owns, so "is the HTML current?" is a byte-comparison question, not a DOM-inspection question. Two separate properties had been conflated: (1) freshness — the on-disk file was produced from this exact spec; (2) internal consistency — a `completed` spec has every step and criterion checked. Neither property requires reading rendered markup.

`--check` separates the two. The freshness check renders the spec to a string and compares byte-for-byte against the file at the output path; a first-difference report includes line number and context, making the failure immediately actionable. Determinism at a fixed path is guaranteed because the renderer reads `plan-created` back from the existing file (keeping it stable) and derives `plan-file`/`plan-path` from the output path (so those two fields are meaningfully different when the path differs — a stale copy from another location fails). The consistency assertions parse the Markdown directly and are gated on `status: completed` so in-progress plans see those rows reported as skipped rather than failing.

The fix to `completion-gates.md` is one line: `plan-agent-render "<stem>.md" -o "<stem>.html" --check`, with a note that a non-zero exit names the failing property and the fix is always in the spec. The five-selector paragraph is deleted. `write-completions.md` receives the same replacement to keep the two gate files consistent.

One deviation from the plan as authored: the version was specified as 9.3.0, but PR #554 shipped 9.3.0 to `main` after this plan was written, so 9.3.0 would not exceed the base branch. The shipped version is 9.4.0.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [replace-grep-drift-check](plans/replace-grep-drift-check.md)
