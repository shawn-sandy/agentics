---
status: todo
type: feature
created: 2026-08-14
glance: Plan `build`'s final gate tells the model to confirm five DOM invariants named as CSS selectors, with no way to evaluate them — so it greps the HTML and gets false drift. This adds `plan-agent-render --check`, which byte-compares the rendered file against a fresh in-memory render and asserts a `completed` spec is internally consistent, and rewires the gate to call it.
effort: medium
workflow: never
---

# Plan: Replace build's grep drift check with a deterministic render check

## Objective

Add a `--check` mode to `plan-agent-render` that proves a plan's HTML is
current and that a `completed` spec is internally consistent, then rewire
`build` Step 5.3 and `finalize-plan` to run it instead of describing DOM
invariants the model can only reach with `Grep`.

## Context

The 2026-08-14 usage report names grep-as-verification as the single largest
source of wasted passes: *"Verification greps counted CSS selectors instead of
rendered elements, producing false drift signals and forcing a second
verification pass"* and *"Grep patterns didn't match the renderer's actual
markup, so Claude needed repeated passes just to confirm the spec's
status/checkbox state."*

**The instruction causes the behaviour.**
`skills/build/references/completion-gates.md` Step 5.3 says to confirm the
HTML matches the spec, and then names the evidence as five CSS selectors —
`.step-card` elements completed, criteria inputs `checked`, three status
representations, cc1–cc3, `completion-checklist` carrying `all-complete`. It
prescribes no mechanism. A model handed selector names and no tool reaches for
`Grep`, which searches the source markup rather than evaluating anything, so a
selector defined in the stylesheet counts as a match and a class the renderer
emits conditionally does not. Both failure directions were observed.

**The check is aimed at the wrong artifact.** The HTML is *derived* from the
spec by a deterministic function this repo owns. Two separate properties got
conflated into one DOM inspection:

1. *Is the HTML current?* — a build-freshness question. If the file on disk was
   produced from this spec, it is byte-identical to a fresh render. A stale
   file means a re-render was skipped, the write partially failed, or someone
   hand-edited the HTML. All three are caught by one comparison.
2. *Is a `completed` spec internally consistent?* — a Markdown question. Every
   step marked `[x]`, every criterion `- [x]`, `status: completed`. Nothing
   here needs the HTML at all; the render is what *displays* the answer, not
   what determines it.

Neither property requires reading rendered markup, so the whole DOM-inspection
framing goes away rather than getting a better tool.

**The parser is already written and already proven.** `scripts/lib/plan-spec.mjs`
carries `parseSpecMarkdown` and `extractSections`, and the round-trip property
`extractSections(render(spec))` deep-equals the spec's sections is already
enforced by `tests/plugins/test-build-plan-html.mjs`. `--check` composes
existing, tested pieces.

**The renderer lives at the repo root; the plugin carries a copy.** `scripts/`
is canonical and `kit/plugins/plan-agent/scripts/` is a bundled duplicate —
byte-identical today, and held that way by an assertion in
`tests/plugins/test-build-plan-html.mjs` whose failure message is *"drifted
from scripts/… — re-copy it"*. The unit tests import the **root** module
(`../../scripts/build-plan-html.mjs`), so an edit confined to the plugin copy
would both fail the parity assertion and leave every test blind to `--check`.
Four files are mirrored this way: `build-plan-html.mjs`,
`extract-plan-spec.mjs`, `lib/plan-spec.mjs`, and `lib/plan-shell.mjs`. Every
step below edits the root and re-copies, in that order.

**Determinism is a precondition, not an assumption.** The renderer keeps
`plan-created` stable across re-renders by reading the value back from the
existing HTML, and `created` comes from frontmatter — so an unchanged spec
should render byte-identically. Should is not measured. Step 1 establishes it
by experiment before Step 2 builds a comparison on top of it, because a single
non-deterministic field would make `--check` fail on every correct plan and
the gate would be disabled within a day.

**Scope.** This does not touch the renderer's output, the plan CSS, or the
gallery. `--check` writes nothing.

## Files

- scripts/build-plan-html.mjs (modified) — canonical source; `--check` mode: render to memory, compare, assert spec consistency, print a table
- kit/plugins/plan-agent/scripts/build-plan-html.mjs (modified) — byte-identical re-copy of the above, held by the parity assertion
- kit/plugins/plan-agent/skills/build/references/completion-gates.md (modified) — Step 5.3 becomes one command; the selector list is deleted
- kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md (modified) — same gate, kept consistent per completion-gates.md's own instruction
- kit/plugins/plan-agent/README.md (modified) — document `--check`
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 9.3.0 entry
- .claude-plugin/marketplace.json (modified) — plan-agent 9.2.0 to 9.3.0
- tests/plugins/test-build-plan-html.mjs (modified) — determinism and check-mode assertions

## Steps

1. Establish that rendering an unchanged spec is byte-deterministic: render a committed plan spec twice to two output paths, `diff` them, then render again over an existing output file and diff against the first. Why: `--check` is a byte comparison, so a single volatile field — a timestamp, a generated id, a locale-dependent date — would make it fail on every correct plan, and the fix belongs in the comparison rather than in a gate nobody trusts. Verify: both diffs are empty; if either is not, name the volatile field in this plan's Context and carry it as a normalization the comparison applies before diffing.
2. Add `--check` to the canonical `scripts/build-plan-html.mjs`: parse the spec, render to a string, compare against the existing output file, and report the first differing line with its line number and 40 characters of context on each side. Missing output file is a FAIL naming the render command, not a crash. Why: freshness is the property the old Step 5.3 was actually reaching for, and a first-difference report is what makes the failure actionable — a bare "files differ" sends the model back to grepping; the root file is the one the tests import, so implementing anywhere else leaves the change untested. Verify: `--check` on a freshly rendered plan exits 0 and prints `html  PASS`; the same plan with one character edited into its HTML exits non-zero and prints the edited line's number.
3. Extend `--check` with the spec-consistency assertions, evaluated on the parsed Markdown and skipped entirely unless `status: completed`: every numbered step carries `[x]`, every `## Acceptance Criteria` bullet is `- [x]`. Why: this is the half of Step 5.3 that is not a freshness question, and evaluating it on the spec is what removes the last reason to open the HTML. Verify: a spec with `status: completed` and one `- [ ]` criterion exits non-zero and names that criterion's text; the same spec at `status: in-progress` exits 0 with the consistency rows reported as skipped.
4. Make `--check` print a fixed PASS/FAIL table — one row per property (`html`, `steps`, `criteria`), a summary line, and exit 0 only when every row passes. Why: the model needs to know *which* property broke to fix the right file, and a stable table is also what the test asserts against. Verify: the table's row labels appear in the same order for a passing plan, a stale-HTML plan, and an inconsistent-spec plan.
5. Re-copy the edited renderer to `kit/plugins/plan-agent/scripts/build-plan-html.mjs` so the bundled copy is byte-identical again, and confirm the other three mirrored files (`extract-plan-spec.mjs`, `lib/plan-spec.mjs`, `lib/plan-shell.mjs`) were not touched. Why: the parity assertion fails the moment the two diverge, and its failure message — "drifted from scripts/… — re-copy it" — is the whole contract; skipping this makes every later step's test run red for an unrelated reason. Verify: `cmp scripts/build-plan-html.mjs kit/plugins/plan-agent/scripts/build-plan-html.mjs` exits 0, and `plan-agent-render --check` invoked by bare name (which resolves through the plugin's `bin/`) behaves identically to the root module.
6. Rewrite `skills/build/references/completion-gates.md` Step 5.3 as a single command — `plan-agent-render "<stem>.md" -o "<stem>.html" --check` — stating that a non-zero exit names the property and that the fix is always in the spec, never the HTML. Delete the five-selector paragraph. Keep sub-step 4's "fix the spec, never the HTML" rule and its no-promoting-status clause verbatim. Why: the selector list is the instruction that produced the defect, and leaving it beside the new command lets a future run fall back to it. Verify: `grep -c 'step-card' kit/plugins/plan-agent/skills/build/references/completion-gates.md` returns 0, and the file names the `--check` invocation exactly once.
7. Apply the same replacement to `skills/finalize-plan/references/write-completions.md`, which runs the same completion rules for plans implemented outside `build`. Why: completion-gates.md ends by instructing that the two stay consistent, so a one-sided change is a defect the next reader inherits. Verify: both files reference `--check` and neither mentions `.step-card`.
8. Extend `tests/plugins/test-build-plan-html.mjs` with the determinism case, the stale-HTML case, the missing-HTML case, the completed-with-unchecked-criterion case, and the in-progress skip case — importing from `../../scripts/build-plan-html.mjs` as the file already does — while keeping every existing assertion green, the byte-identical parity assertion included. Why: the gate is only worth what its failure modes are worth, each of these is a way `--check` could silently pass, and the parity assertion is what catches a Step 5 re-copy that was skipped. Verify: `node tests/plugins/test-build-plan-html.mjs` reports zero failures with a higher assertion count than before the change, including the `plugin-bundled renderer copies are byte-identical to the repo-root sources` check.
9. Bump plan-agent to 9.3.0 in `.claude-plugin/marketplace.json`, add the CHANGELOG entry, and document `--check` in the README's renderer section. Why: the CI guard fails any PR whose touched plugin does not exceed the base branch version, and an undocumented flag is a flag the next session re-invents. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.

## Tests

Tier 1 — This plan changes application code

- Objective: a plan whose HTML is stale, or whose `completed` spec has an unchecked criterion, fails the gate without any HTML being searched. File: tests/plugins/test-build-plan-html.mjs; Type: smoke; Asserts: `--check` exits 0 on a freshly rendered consistent plan, and non-zero with the offending property named for a stale render and for an unchecked criterion under `status: completed`; Run: node tests/plugins/test-build-plan-html.mjs
- Unit: render determinism. File: tests/plugins/test-build-plan-html.mjs; Targets: renderPlanHtml; Key cases: two renders of one unchanged spec are byte-identical, and a re-render over an existing output file preserves `plan-created`
- Unit: check-mode reporting. File: tests/plugins/test-build-plan-html.mjs; Targets: the `--check` code path; Key cases: missing output file reports FAIL naming the render command rather than throwing, the first differing line is reported with its line number, and the table's rows appear in fixed order
- Unit: consistency assertions gate on status. File: tests/plugins/test-build-plan-html.mjs; Targets: the spec-consistency branch; Key cases: `status: in-progress` with unchecked criteria exits 0, `status: completed` with an unchecked step exits non-zero, and a plan with no `## Acceptance Criteria` section does not crash
- Integration: existing render behaviour survives. File: tests/plugins/test-build-plan-html.mjs; Targets: the whole renderer; Key cases: every current assertion, including the `extractSections(render(spec))` round-trip property

## Acceptance Criteria

- [ ] `plan-agent-render <spec>.md -o <plan>.html --check` exits 0 for a freshly rendered, internally consistent plan and prints a PASS row per property.
- [ ] A hand-edited or stale HTML file fails the check with the first differing line number reported.
- [ ] A missing HTML file fails the check with the render command named, and does not throw.
- [ ] A `status: completed` spec with any unchecked step or criterion fails the check with the offending item's text quoted.
- [ ] The same spec at `status: in-progress` passes, with the consistency rows reported as skipped rather than passed.
- [ ] `--check` writes no files.
- [ ] `--check` is implemented in the canonical `scripts/build-plan-html.mjs`, and `cmp` reports the plugin-bundled copy byte-identical to it.
- [ ] The `plugin-bundled renderer copies are byte-identical to the repo-root sources` assertion still passes.
- [ ] `completion-gates.md` and `write-completions.md` both invoke `--check` and neither names a CSS selector as evidence.
- [ ] `node tests/plugins/test-build-plan-html.mjs` reports zero failures with more assertions than before this change.
- [ ] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.

## Verification

Run `node tests/plugins/test-build-plan-html.mjs` and confirm zero failures.
Then run `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs`
and confirm exit 0.

End-to-end, take a committed plan from `docs/plans/` that is `status: completed`
and copy its `.md` and `.html` into the scratchpad. Run `--check` on the copy
and confirm exit 0. Append a stray character to the copied HTML and confirm the
check exits non-zero naming that line. Restore the HTML, flip one acceptance
criterion in the copied spec back to `- [ ]`, and confirm the check exits
non-zero quoting that criterion — while the HTML row still passes, proving the
two properties are reported independently.

Finally, run `build` against a small plan end to end and confirm Step 5 issues
exactly one `--check` invocation and no `Grep` call against the plan HTML.

## Next Steps

- Wire the check into the plan-write hook

  ```text
  In the agentics repo, kit/plugins/plan-agent/hooks/render-plan-html.py
  re-renders a plan's HTML on every spec write. Now that
  scripts/build-plan-html.mjs has a --check mode, evaluate whether the hook
  should run it after rendering and surface a failure to the session, or
  whether that duplicates the build skill's Step 5 gate for no benefit. Note
  that plugin hooks do not register in the Claude Code desktop app, so the
  hook cannot be the only place the check runs. If you recommend adding it,
  bump the plan-agent version in .claude-plugin/marketplace.json, add a
  CHANGELOG entry, and extend tests/plugins/test-build-plan-html.mjs. Verify
  with `node tests/plugins/test-build-plan-html.mjs` reporting zero failures.
  ```

## Resources

- kit/plugins/plan-agent/skills/build/references/completion-gates.md — Step 5.3, the instruction being replaced
- scripts/lib/plan-spec.mjs — `parseSpecMarkdown` and `extractSections`, reused by `--check` (canonical copy; the plugin mirrors it)
- tests/plugins/test-build-plan-html.mjs — the round-trip property this builds on, and the byte-identical parity assertion at its tail
- ~/.claude/usage-data/report-2026-08-14-071004.html — the four verification-failure entries motivating this plan
