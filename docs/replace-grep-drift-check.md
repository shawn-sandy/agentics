# Replace build's grep drift check with a deterministic render check

> Plan `build`'s final gate tells the model to confirm five DOM invariants named as CSS selectors, with no way to evaluate them — so it greps the HTML and gets...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
**Type:** feature

## What shipped

- Establish that rendering an unchanged spec is byte-deterministic **at a fixed output path**: render a committed plan spec, keep a copy of the bytes, render again over that same path, and `diff` the copy against the result. Compare at one path only — never across two — because `plan-file` and `plan-path` are derived from the output path and are meant to differ when it does.
- Add `--check` to the canonical `scripts/build-plan-html.mjs`: parse the spec, render to a string, compare against the existing output file, and report the first differing line with its line number and 40 characters of context on each side. Missing output file is a FAIL naming the render command, not a crash.
- Extend `--check` with the spec-consistency assertions, evaluated on the parsed Markdown and skipped entirely unless `status: completed`: every numbered step carries `[x]`, every `## Acceptance Criteria` bullet is `- [x]`.
- Make `--check` print a fixed PASS/FAIL table — one row per property (`html`, `steps`, `criteria`), a summary line, and exit 0 only when every row passes.
- Re-copy the edited renderer to `kit/plugins/plan-agent/scripts/build-plan-html.mjs` so the bundled copy is byte-identical again, and confirm the other three mirrored files (`extract-plan-spec.mjs`, `lib/plan-spec.mjs`, `lib/plan-shell.mjs`) were not touched.
- Rewrite `skills/build/references/completion-gates.md` Step 5.3 as a single command — `plan-agent-render "<stem>.md" -o "<stem>.html" --check` — stating that a non-zero exit names the property and that the fix is always in the spec, never the HTML. Delete the five-selector paragraph. Keep sub-step 4's "fix the spec, never the HTML" rule and its no-promoting-status clause verbatim.
- Apply the same replacement to `skills/finalize-plan/references/write-completions.md`, which runs the same completion rules for plans implemented outside `build`.
- Extend `tests/plugins/test-build-plan-html.mjs` with the determinism case, the stale-HTML case, the missing-HTML case, the completed-with-unchecked-criterion case, and the in-progress skip case — importing from `../../scripts/build-plan-html.mjs` as the file already does — while keeping every existing assertion green, the byte-identical parity assertion included.
- Bump plan-agent to 9.4.0 in `.claude-plugin/marketplace.json`, add the CHANGELOG entry, and document `--check` in the README's renderer section.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/build-plan-html.mjs` | canonical source; `--check` mode: render to memory, compare, assert spec consistency, print a table | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | byte-identical re-copy of the above, held by the parity assertion | Modified |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Step 5.3 becomes one command; the selector list is deleted | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | same gate, kept consistent per completion-gates.md's own instruction | Modified |
| `kit/plugins/plan-agent/README.md` | document `--check` | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 9.3.0 to 9.4.0 | Modified |
| `tests/plugins/test-build-plan-html.mjs` | determinism and check-mode assertions | Modified |

## How it works

Add a `--check` mode to `plan-agent-render` that proves a plan's HTML is current and that a `completed` spec is internally consistent, then rewire `build` Step 5.3 and `finalize-plan` to run it instead of describing DOM invariants the model can only reach with `Grep`.

The 2026-08-14 usage report names grep-as-verification as the single largest source of wasted passes: *"Verification greps counted CSS selectors instead of rendered elements, producing false drift signals and forcing a second verification pass"* and *"Grep patterns didn't match the renderer's actual markup, so Claude needed repeated passes just to confirm the spec's

The implementation proceeded through the following steps: Establish that rendering an unchanged spec is byte-deterministic **at a fixed output path**: render a committed plan spec, keep a copy of the bytes, render again over that same path, and `diff` the copy against the result. Compare at one path only — never across two — because `plan-file` and `plan-path` are derived from the output path and are meant to differ when it does. Why: `--check` is a byte comparison, so a genuinely volatile field — a timestamp, a generated id, a locale-dependent date — would make it fail on every correct plan; and normalizing the path fields to force a cross-path diff to zero would make `--check` blind to an HTML file copied in from somewhere else, which is one of the stale states it exists to catch. Verify: the same-path diff is empty; if it is not, name the volatile field in this plan's Context and carry it as a normalization the comparison applies before diffing.; Add `--check` to the canonical `scripts/build-plan-html.mjs`: parse the spec, render to a string, compare against the existing output file, and report the first differing line with its line number and 40 characters of context on each side. Missing output file is a FAIL naming the render command, not a crash. Why: freshness is the property the old Step 5.3 was actually reaching for, and a first-difference report is what makes the failure actionable — a bare "files differ" sends the model back to grepping; the root file is the one the tests import, so implementing anywhere else leaves the change untested. Verify: `--check` on a freshly rendered plan exits 0 and prints `html  PASS`; the same plan with one character edited into its HTML exits non-zero and prints the edited line's number.; Extend `--check` with the spec-consistency assertions, evaluated on the parsed Markdown and skipped entirely unless `status: completed`: every numbered step carries `[x]`, every `## Acceptance Criteria` bullet is `- [x]`. Why: this is the half of Step 5.3 that is not a freshness question, and evaluating it on the spec is what removes the last reason to open the HTML. Verify: a spec with `status: completed` and one `- [ ]` criterion exits non-zero and names that criterion's text; the same spec at `status: in-progress` exits 0 with the consistency rows reported as skipped.; Make `--check` print a fixed PASS/FAIL table — one row per property (`html`, `steps`, `criteria`), a summary line, and exit 0 only when every row passes. Why: the model needs to know *which* property broke to fix the right file, and a stable table is also what the test asserts against. Verify: the table's row labels appear in the same order for a passing plan, a stale-HTML plan, and an inconsistent-spec plan.; Re-copy the edited renderer to `kit/plugins/plan-agent/scripts/build-plan-html.mjs` so the bundled copy is byte-identical again, and confirm the other three mirrored files (`extract-plan-spec.mjs`, `lib/plan-spec.mjs`, `lib/plan-shell.mjs`) were not touched. Why: the parity assertion fails the moment the two diverge, and its failure message — "drifted from scripts/… — re-copy it" — is the whole contract; skipping this makes every later step's test run red for an unrelated reason. Verify: `cmp scripts/build-plan-html.mjs kit/plugins/plan-agent/scripts/build-plan-html.mjs` exits 0, and `plan-agent-render --check` invoked by bare name (which resolves through the plugin's `bin/`) behaves identically to the root module.; Rewrite `skills/build/references/completion-gates.md` Step 5.3 as a single command — `plan-agent-render "<stem>.md" -o "<stem>.html" --check` — stating that a non-zero exit names the property and that the fix is always in the spec, never the HTML. Delete the five-selector paragraph. Keep sub-step 4's "fix the spec, never the HTML" rule and its no-promoting-status clause verbatim. Why: the selector list is the instruction that produced the defect, and leaving it beside the new command lets a future run fall back to it. Verify: `grep -c 'step-card' kit/plugins/plan-agent/skills/build/references/completion-gates.md` returns 0, and the file names the `--check` invocation exactly once..

- Step 9 version, authored as 9.3.0 — `origin/main` moved to plan-agent 9.3.0 in PR #554 after this plan was written, so 9.3.0 no longer exceeds the base. Shipped 9.4.0 instead. Measured against the guard's own `findViolations`: 9.3.0 returns `version not bumped`, 9.4.0 passes. - Step 7 verify line, "neither mentions `.step-card`" — not met, and deliberately so. `write-completions.md` keeps two `.step-card` mentions: one describing what the renderer derives (an argument against HTML surgery) and one in **legacy mode**, the attribute-surgery path for plans that have no `.md` spec, where the selector is an edit target rather than drift evidence. Deleting them would break legacy finalization, which this plan's Scope does not cover. The acceptance criterion as written — neither file "names a CSS selector as evidence" — is met. - Verification section, e2e case 3 expectation that the `html` row still passes — not achievable as written. Flipping an acceptance criterion in the spec changes the rendered progress bar (`10 / 10 done` to `9 / 10 done`), so the on-disk HTML is genuinely stale and the `html` row correctly fails alongside `criteria`. Independent reporting was verified instead on a re-rendered fixture, where `html PASS` appears beside `steps FAIL` and `criteria FAIL`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [replace-grep-drift-check.md](plans/replace-grep-drift-check.md)
