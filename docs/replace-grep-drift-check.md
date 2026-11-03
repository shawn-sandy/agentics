# Replace build's grep drift check with a deterministic render check

> Add a `--check` mode to `plan-agent-render` that byte-compares the on-disk HTML against a fresh in-memory render and verifies spec consistency, replacing grep-based DOM inspection that produced false drift signals.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
**Type:** feature

## What shipped

- Added `--check` mode to the canonical `scripts/build-plan-html.mjs`: renders to memory, compares against the existing output file, and reports the first differing line with line number and context
- Extended `--check` with spec-consistency assertions for `status: completed` plans: every step carries `[x]`, every acceptance criterion is `- [x]`
- Implemented a fixed PASS/FAIL table output (`html`, `steps`, `criteria` rows) with exit 0 only when all rows pass
- Re-copied the edited renderer to `kit/plugins/plan-agent/scripts/build-plan-html.mjs` to maintain byte-identical parity
- Rewrote `skills/build/references/completion-gates.md` Step 5.3 as a single `plan-agent-render --check` command, deleting the five-selector DOM inspection paragraph
- Applied the same replacement to `skills/finalize-plan/references/write-completions.md`
- Extended `tests/plugins/test-build-plan-html.mjs` with determinism, stale-HTML, missing-HTML, completed-with-unchecked-criterion, and in-progress-skip test cases
- Bumped plan-agent to 9.4.0 in `.claude-plugin/marketplace.json` and documented `--check` in the README

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | Canonical renderer — added `--check` mode | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled copy — re-copied byte-for-byte from root | Modified |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Step 5.3 rewritten to invoke `--check` | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Same gate update for consistency | Modified |
| `kit/plugins/plan-agent/README.md` | Documented `--check` in renderer section | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent bumped to 9.4.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | New determinism and check-mode test cases | Modified |

## How it works

Before this change, the `build` skill's Step 5.3 completion gate told the model to confirm the plan HTML matched its spec by checking five CSS selectors: `.step-card` elements completed, criteria inputs checked, status representations, and `completion-checklist` carrying `all-complete`. The model reached for `Grep`, which searches source markup rather than evaluating rendered elements. A selector defined only in the stylesheet counted as a match; a class the renderer emits conditionally could be missed. Both failure directions were observed in practice, producing false drift signals and forcing second verification passes.

The core insight is that two separate properties were conflated into one DOM inspection: (1) *is the HTML current?* — a build-freshness question answered by comparing the file on disk to a fresh render; and (2) *is a `completed` spec internally consistent?* — a Markdown question answered by reading the spec's frontmatter and checkbox state. Neither property requires reading rendered markup.

`--check` addresses the freshness question by rendering the spec to an in-memory string and comparing it byte-for-byte against the existing HTML file. Because the renderer derives `plan-file` and `plan-path` from the output path, the check always fixes the output path and compares there — normalizing those fields would let a copied HTML file from another path pass, which is exactly one of the stale states the check exists to catch. A missing output file reports FAIL naming the render command, not a crash.

For spec consistency, `--check` evaluates the Markdown directly — parsing the spec's frontmatter and section structure — and skips these assertions entirely unless `status: completed`. A plan in progress is not required to have all steps checked, so reporting skipped rather than failed avoids spurious failures during active work.

The output is a fixed three-row table (`html`, `steps`, `criteria`) so the model knows which property broke without guessing. Exit 0 only when every row passes. The fix is always in the spec, never in the HTML, since the HTML is derived output.

The renderer lives in two locations: `scripts/build-plan-html.mjs` (canonical, imported by all tests) and `kit/plugins/plan-agent/scripts/build-plan-html.mjs` (bundled copy). A parity assertion in `test-build-plan-html.mjs` enforces byte-identical matching. Every change edits the root file first, then re-copies; editing only the plugin copy would both fail CI and leave the tests blind to the change.

## How to use it

Run `plan-agent-render "<spec>.md" -o "<spec>.html" --check` after building or finalizing a plan. A non-zero exit names the failing property; the fix is always in the spec file.

- `html PASS` — the on-disk HTML is current with the spec
- `steps FAIL` — one or more numbered steps lack `[x]` (only for `status: completed`)
- `criteria FAIL` — one or more acceptance criteria are `- [ ]` (only for `status: completed`)

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `19a9ae8` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `22e2280` | 2026-08-30 | fix(plan-agent): unbreak the build completion gate for artifact-only plans (9.10.1) (#610) |
| `94c0569` | 2026-08-23 | feat(plan-agent): add design phase — canvas link, gallery, and drift check (#596) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
