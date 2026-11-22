# Replace build's grep drift check with a deterministic render check

> Plan `build`'s final gate told the model to confirm five DOM invariants named as CSS selectors, with no way to evaluate them — so it grepped the HTML and got false drift. This adds `plan-agent-render --check`, which byte-compares the rendered file against a fresh in-memory render and asserts a `completed` spec is internally consistent, then rewires the gate to call it.

<!-- generated:start -->

**Status:** Shipped 2026-08-14 **Plan:** [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
**Type:** feature

## What shipped

- Added `--check` mode to `scripts/build-plan-html.mjs` (and byte-identical plugin copy): renders the spec to a string, byte-compares against the existing output file, and reports the first differing line with its line number and 40 characters of context on each side. Missing output file is a FAIL naming the render command, not a crash.
- Extended `--check` with spec-consistency assertions evaluated on the parsed Markdown, skipped unless `status: completed`: every numbered step carries `[x]`, every `## Acceptance Criteria` bullet is `- [x]`.
- `--check` prints a fixed PASS/FAIL table — one row per property (`html`, `steps`, `criteria`) — and exits 0 only when every row passes. Writes no files.
- Re-copied the edited renderer to `kit/plugins/plan-agent/scripts/build-plan-html.mjs` (byte-identical, confirmed with `cmp`).
- Rewrote `skills/build/references/completion-gates.md` Step 5.3 as a single command — `plan-agent-render "<stem>.md" -o "<stem>.html" --check` — deleted the five-selector paragraph. The fix is always in the spec, never the HTML.
- Applied the same replacement to `skills/finalize-plan/references/write-completions.md` (kept `.step-card` mentions in the legacy-mode path where the selector is an edit target, not drift evidence).
- Extended `tests/plugins/test-build-plan-html.mjs` with determinism, stale-HTML, missing-HTML, completed-with-unchecked-criterion, and in-progress-skip cases.
- Shipped as plan-agent **9.4.0** — the originally specified 9.3.0 was taken by PR #554 after this plan was written.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | `--check` mode implementation | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical bundled copy | Modified |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Step 5.3 → single `--check` command | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Same replacement, legacy path preserved | Modified |
| `kit/plugins/plan-agent/README.md` | `--check` documented | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent → 9.4.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | Determinism and check-mode assertions | Modified |

## How it works

**Two properties, not one**: The old Step 5.3 conflated freshness ("is the HTML current?") and consistency ("is the completed spec internally consistent?"). `--check` evaluates them separately and reports which one failed — a stale HTML exits non-zero on the `html` row; an unchecked criterion exits non-zero on the `criteria` row; a stale-and-inconsistent spec fails both.

**Byte-determinism at a fixed output path**: The renderer keeps `plan-created` stable across re-renders by reading it back from the existing HTML. `plan-file` and `plan-path` are derived from the output path and differ when it does — `--check` fixes the output path and compares there, so a copied-in stale file still fails.

**Spec over HTML**: Consistency assertions evaluate the parsed Markdown, not rendered markup. No HTML needs to be opened for verification. The model is told: the fix is always in the spec; never hand-edit the HTML.

## How to use it

```bash
plan-agent-render "<stem>.md" -o "<stem>.html" --check
```

Exit 0 prints a PASS row per property. Non-zero names the failing property and the first differing line or unchecked criterion. Used automatically by `build` Step 5.3 and `finalize-plan`'s completion gate.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-08-14 | feat(plan-agent): add render --check mode, replace selector drift check in completion-gates (9.4.0) |

<!-- generated:end -->

## References

- Plan: [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
