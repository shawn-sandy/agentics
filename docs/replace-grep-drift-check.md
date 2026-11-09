# Replace grep drift check

> Adds a `--check` mode to `build-plan-html.mjs` that byte-compares generated HTML against committed copies and asserts completed-plan spec consistency, replacing the fragile CSS-selector grep in completion gates.

<!-- generated:start -->

**Status:** Shipped 2026-08-14 **Plan:** [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
**Type:** feature

## What shipped

- Added `--check` mode to `build-plan-html.mjs`: byte-compares the generated HTML against the committed copy and reports PASS/FAIL per plan.
- `--check` also asserts that all completed plans have consistent spec output (no structural drift from template changes).
- Removed the CSS-selector grep from completion gates — the grep was fragile and false-positived on unrelated HTML changes.
- Propagated changes to all bundled copies of `build-plan-html.mjs`.
- Bumped plan-agent to 9.4.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Canonical build script | Modified |
| `kit/plugins/plan-agent/scripts/` (bundled copies) | Bundled copies | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/completion-gates.md` | Completion gates reference | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/write-completions.md` | Write-completions reference | Modified |
| `tests/test-build-plan-html.mjs` | Build script tests | Modified |

## How it works

The `--check` flag runs `build-plan-html.mjs` in read-only mode: it generates the HTML in memory, then byte-compares the result against the committed `.html` file. A mismatch means the committed file is stale — either the plan was edited without regenerating, or a template change wasn't applied. The output is a PASS/FAIL table, one row per plan, making it easy to see which plans need regeneration.

The CSS-selector grep had been used in completion gates to verify that a finished plan's HTML contained the expected section headers. The problem: template changes (adding a new section, renaming a class) would break the grep even when the plan itself was correct. The `--check` mode is more precise: it compares the full generated output, so only real content drift triggers a failure.

Completed-plan spec consistency means `--check` additionally verifies that all plans with `status: completed` generate output that passes the spec validator — same structural rules as a fresh plan would. This catches plans that were completed before a spec version upgrade and haven't been regenerated.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
