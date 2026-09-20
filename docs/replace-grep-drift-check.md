# Replace build's grep drift check with a deterministic render check

> Plan `build`'s final gate tells the model to confirm five DOM invariants named as CSS selectors, with no way to evaluate them — so it greps the HTML and gets...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
**Type:** feature

## What shipped

- Establish that rendering an unchanged spec is byte-deterministic **at a fixed output path**: render a committed plan...
- Add `--check` to the canonical `scripts/build-plan-html.mjs`: parse the spec, render to a string, compare against the...
- Extend `--check` with the spec-consistency assertions, evaluated on the parsed Markdown and skipped entirely unless `...
- Make `--check` print a fixed PASS/FAIL table — one row per property (`html`, `steps`, `criteria`), a summary line, an...
- Re-copy the edited renderer to `kit/plugins/plan-agent/scripts/build-plan-html.mjs` so the bundled copy is byte-ident...
- Rewrite `skills/build/references/completion-gates.md` Step 5.3 as a single command — `plan-agent-render "<stem>.md" -...
- Apply the same replacement to `skills/finalize-plan/references/write-completions.md`, which runs the same completion...
- Extend `tests/plugins/test-build-plan-html.mjs` with the determinism case, the stale-HTML case, the missing-HTML case...
- Bump plan-agent to 9.4.0 in `.claude-plugin/marketplace.json`, add the CHANGELOG entry, and document `--check` in the...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | canonical source; `--check` mode: render to memory, compa... | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | byte-identical re-copy of the above, held by the parity a... | Modified |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Step 5.3 becomes one command; the selector list is deleted | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | same gate, kept consistent per completion-gates.md's own ... | Modified |
| `kit/plugins/plan-agent/README.md` | document `--check` | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 9.3.0 to 9.4.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | determinism and check-mode assertions | Modified |

## How it works

Add a `--check` mode to `plan-agent-render` that proves a plan's HTML is current and that a `completed` spec is internally consistent, then rewire `build` Step 5.3 and `finalize-plan` to run it instead of describing DOM invariants the model can only reach with `Grep`.

The 2026-08-14 usage report names grep-as-verification as the single largest source of wasted passes: *"Verification greps counted CSS selectors instead of rendered elements, producing false drift signals and forcing a second verification pass"* and *"Grep patterns didn't match the renderer's actual

The implementation proceeded through these steps: Establish that rendering an unchanged spec is byte-deterministic **at a fixed output path**: render a committed plan ...; Add `--check` to the canonical `scripts/build-plan-html.mjs`: parse the spec, render to a string, compare against the...; Extend `--check` with the spec-consistency assertions, evaluated on the parsed Markdown and skipped entirely unless `...; Make `--check` print a fixed PASS/FAIL table — one row per property (`html`, `steps`, `criteria`), a summary line, an...; Re-copy the edited renderer to `kit/plugins/plan-agent/scripts/build-plan-html.mjs` so the bundled copy is byte-ident....

- Step 9 version, authored as 9.3.0 — `origin/main` moved to plan-agent 9.3.0 in PR #554 after this plan was written, so 9.3.0 no longer exceeds the base. Shipped 9.4.0 instead. Measured against the guard's own `findViolations`: 9.3.0 returns `version not bumped`, 9.4.0 passes. - Step 7 verify line,

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
