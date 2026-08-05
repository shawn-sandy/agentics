---
status: completed
modified: 2026-08-05
type: feature
created: 2026-07-30
effort: high
workflow: never
glance: Long plans have to be implemented in one sitting today, because nothing in the spec marks a safe stopping point and nothing records the decisions an earlier session already made. Phases add declared checkpoints and a Decisions ledger so a plan can be picked up cold in a fresh context window. Done when a phased plan survives render, extract, and re-render with its phases intact, and build stops at the first phase boundary with a resume command.
---

# Plan: Phase checkpoints and a Decisions ledger for plan specs

## Objective

Add an optional `### Phase: <name>` grouping level over `## Steps` and an optional `## Decisions` section to the plan spec format, and turn `build`'s existing resume-from-first-unmarked-step behaviour into a designed checkpoint loop, so a long sequential plan can be implemented across several context windows without re-deriving earlier decisions.

## Context

Implementation plans that exceed roughly ten steps consume more context than one session can hold. The repo already reaches this conclusion: `guidelines/right-sizing.md` line 35 tells the author that a plan needing more than ten steps "is probably two plans — split it". It then offers no mechanism to split with. A grep of the whole plugin for parent, child, and subplan concepts returns nothing.

Two capabilities are missing, and only one of them is about parallelism. The `workflow` prompt already fans out across subagents, which helps when slices are independent — migrations, renames, per-file sweeps. Context exhaustion bites hardest on long *sequential* plans, where step seven depends on decisions made in step two, and there fan-out does nothing. The fix for that shape is checkpointing.

Most of the machinery already exists. `build/SKILL.md` line 152 resumes from the first unmarked step, so implement-some-steps, clear the context, re-run already works by accident. What is missing is a declared safe stopping point and a record of decisions already settled. The `## Completion Report` section is a gap ledger, not a decision ledger, so a resumed session re-derives — or contradicts — choices the first session made.

The format is bidirectional, and that is the main cost driver. `buildDigest` is documented as the exact inverse of `parseSpecMarkdown`, and `extractSections` derives a spec back out of rendered HTML for legacy HTML-only plans. A new grouping level therefore has to be carried at four sites — parse, render, extract-from-DOM, re-emit — with `test-build-plan-html.mjs` and `test-extract-plan-spec.mjs` guarding fidelity. Anything carried at fewer than four sites is a silent data loss rather than a missing feature.

One hazard is already latent. `parseSpecMarkdown` splits the Steps chunk with `split(/\n(?=\d+\.\s)/)` and folds each piece to a single line with `inline()`, so a `### Phase:` heading placed between steps two and three is appended to **step two's `Verify:` text** with no parse error at all. Phases are actively unsafe to author until step 1 of this plan lands, which is also why this plan does not use phase headings itself.

Alternatives weighed. A `phases:` frontmatter key holding step ranges (`phases: 1-3 Setup, 4-6 Build`) would cost almost nothing — the frontmatter parser already keeps arbitrary keys and the digest round trip could not break — but inserting a step silently shifts every later range, so the grouping rots in exactly the situation it is meant to survive. Headings are self-maintaining and were chosen for that reason. Full parent and child plan files were also considered and deliberately deferred: they additionally solve authoring size, but they force a position on progress rollup, gallery nesting, and archiving before phases have been used even once. Phase boundaries are designed here to be extractable into child files later.

The remaining decisions, recorded here as well as in this plan's own `## Decisions` section because the renderer skips that section until step 5 lands and the gallery, the extractor, and plan reviewers all read the rendered HTML. A phase name renders as an `<h3>` inside a `data-phase` wrapper, so phases join the document outline for screen-reader navigation while the attribute carries extraction. Phases group the same flat step numbering, so adding them to an in-progress plan keeps every existing `[x]` marker valid and `build` still resumes at the first unmarked step rather than at a phase start. The boundary offers to compact the session rather than only stopping, and `build` prints the `/compact` command rather than running it, since compaction is a user-typed CLI built-in and not a callable tool — safe mid-plan only because durable state lives in the spec rather than the conversation. `finalize-plan` is in scope because `build/SKILL.md` line 303 requires the two skills' completion rules to stay consistent. The checkpoint contract in both skills is guarded by a prose grep in the style of `test-exitplanmode-guard.sh`, which catches deletion of the contract rather than proving runtime behaviour.

The renderer has two homes, and that shaped the step order. `tests/plugins/test-build-plan-html.mjs` line 837 asserts the three files under `kit/plugins/plan-agent/scripts/` are byte-identical to their repo-root counterparts under `scripts/`, so every renderer edit lands at the root and is re-copied into the bundle before any test runs. The extractor is not mirrored at all — `extract-plan-spec.mjs` ships only at the repo root.

`workflow: never` is set deliberately. Four of the twelve steps — 1, 2, 3, and 5 — are ordered edits to a single file, `scripts/lib/plan-spec.mjs`, so subagents fanning out would conflict on it. The renderer's own heuristic counts files and directories and would otherwise license fan-out this plan cannot use.

## Files

- scripts/lib/plan-spec.mjs (modified) — phase-aware step splitting, Decisions parsing, digest re-emission, DOM extraction
- scripts/build-plan-html.mjs (modified) — group step cards by phase, render the Decisions section
- scripts/lib/plan-shell.mjs (modified) — phase header helper, SECTION_CHROME entry for decisions, phase CSS
- kit/plugins/plan-agent/scripts/build-plan-html.mjs (generated) — re-copied from the repo-root source
- kit/plugins/plan-agent/scripts/lib/plan-spec.mjs (generated) — re-copied from the repo-root source
- kit/plugins/plan-agent/scripts/lib/plan-shell.mjs (generated) — re-copied from the repo-root source
- kit/plugins/plan-agent/skills/build/SKILL.md (modified) — phase checkpoint loop and the --continue override
- kit/plugins/plan-agent/skills/finalize-plan/SKILL.md (modified) — refuse to complete a plan with unfinished phases
- kit/plugins/plan-agent/skills/implementation-plan/SKILL.md (modified) — note phases and Decisions in the renderer-derives list
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md (modified) — syntax entries for both new sections
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md (modified) — replace the dead-end split advice with the phase profile
- tests/plugins/test-plan-phases.mjs (new) — objective-verification smoke test
- tests/plugins/test-build-plan-html.mjs (modified) — phase and Decisions render cases
- tests/plugins/test-extract-plan-spec.mjs (modified) — phase and Decisions extraction cases
- .claude-plugin/marketplace.json (modified) — plan-agent 8.5.1 to 8.6.0
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 8.6.0 entry

## Steps

1. [x] Make `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` phase-aware by splitting the Steps chunk on `^###\s+Phase:` lines before the existing numbered-item split, returning `sections.phases` as an ordered array of `{ name, firstStep, lastStep }` and `null` when no heading is present. Why: the current splitter folds a heading between two steps into the preceding step's `Verify:` text with no error raised, so phase headings silently corrupt content until this lands. Verify: parse a two-phase fixture and confirm both phase names come back in order and no step's `verify` string contains a `#` character.
2. [x] Emit phases from `buildDigest` as a `### Phase: <name>` line above the first step of each phase, keeping the flat numbering unchanged. Why: `buildDigest` is documented as the exact inverse of `parseSpecMarkdown`, so a phase it does not emit disappears whenever a spec is reconstructed from HTML. Verify: assert `parseSpecMarkdown(buildDigest(parsed)).phases` is deep-equal to `parsed.phases` for the two-phase fixture.
3. [x] Read phases back out of rendered HTML in `extractSections` by matching the `data-phase` attribute on each phase group wrapper, and extend the existing `stripHeading` helper to remove the phase `<h3>` as well as the section `<h2>`. Why: `extract-plan-spec.mjs` derives specs from legacy HTML-only plans, and an unstripped `<h3>` would leak the phase name into the first step's extracted action text. Verify: run `extractSections` against the Step 4 render output and confirm the phase names come back in document order with no step action containing a phase name.
4. [x] Render phase groups by adding a `phaseHeader` helper to `scripts/lib/plan-shell.mjs` that emits `<div class="phase-group" data-phase="…"><h3>…</h3>`, and group the step cards under those wrappers in `build-plan-html.mjs`, leaving every `.step-card` in flat document order inside them. Why: the progress and completion JavaScript at `plan-shell.mjs` line 1324 counts `.step-card` elements with `querySelectorAll`, so nesting that breaks the selector would silently zero the progress bar, and an `<h3>` keeps the outline at h1 to h2 to h3 with no skipped level for screen-reader navigation. Verify: render the fixture and confirm the progress bar total equals the step count, each phase heading precedes its own steps, and no heading level is skipped.
5. [x] Add the `## Decisions` section end-to-end — parse it as a bullet list in `parseSpecMarkdown`, re-emit it in `buildDigest`, extract it in `extractSections`, add a `decisions` key to `SECTION_CHROME`, and render it with a `sectionCard` call placed after Context. Why: a resumed session that cannot see settled choices re-litigates them, and `## Completion Report` records gaps rather than decisions, so reusing it would conflate the two. Verify: a spec carrying three Decisions bullets renders a Decisions card, gains a sidebar nav entry, and survives the parse-digest-parse round trip.
6. [x] Re-copy the three edited renderer sources — `scripts/build-plan-html.mjs`, `scripts/lib/plan-spec.mjs`, and `scripts/lib/plan-shell.mjs` — over their counterparts under `kit/plugins/plan-agent/scripts/`, after steps 1 through 5 are complete and before any test run. Why: `tests/plugins/test-build-plan-html.mjs` line 837 asserts the bundled copies are byte-identical to the repo-root sources, so editing only one side fails an existing test and ships a phase-blind renderer to anyone who installs the plugin. Verify: `diff scripts/build-plan-html.mjs kit/plugins/plan-agent/scripts/build-plan-html.mjs` and the same for both `lib/` files each report no differences.
7. [x] Rewrite Step 2 of `skills/build/SKILL.md` as a phase checkpoint loop — implement one phase, run its verify gate, append the decisions made to `## Decisions`, then reach the boundary offer — with a `--continue` flag that pushes straight through and no behaviour change for a spec that declares no phases. Why: bounding context is the objective, and stopping is the correct default because the skill's headless contract at line 106 already stops and reports rather than choosing for the user. Verify: grep the skill for `--continue` and the resume line, confirm the unphased path in Step 2 still reads as a single uninterrupted walk, and confirm a phased spec carrying partial `[x]` markers is documented as resuming at the first unmarked step rather than at a phase start.
8. [x] Add the phase boundary offer to that same Step 2 — an `AskUserQuestion` presenting `Compact and continue` (recommended), `Stop here — resume later`, and `Continue without compacting`, where the compact branch prints the `/compact` command with focus instructions naming the spec path and the phase just finished, then stops so the user can run it. Why: `/compact` is a user-typed CLI built-in rather than a callable tool, so the skill can only recommend it, and compaction is safe mid-plan precisely because the durable state — step markers, status, and the Decisions ledger — already lives in the spec rather than in the conversation. Verify: confirm all three options and the printed `/compact` line appear in the skill, and that the headless path falls back to reporting the options rather than choosing one.
9. [x] Teach `skills/finalize-plan/SKILL.md` about phases so it refuses to set `status: completed` while any phase still holds unmarked steps, recording each unfinished phase as a `## Completion Report` bullet instead. Why: `build/SKILL.md` line 303 states that finalize-plan applies the same completion rules and instructs that the two be kept consistent when either changes, so a phase-blind finalize-plan would close out a plan that stopped at its first checkpoint. Verify: run finalize-plan against a phased spec with phase two unmarked and confirm the status stays `in-progress` with the unfinished phase named in the report.
10. [x] Document both sections in `guidelines/section-catalog.md` with their exact syntax, and replace the "probably two plans — split it" sentence in `guidelines/right-sizing.md` with a phase profile naming when a plan earns phases, then add both to the renderer-derives list in `implementation-plan/SKILL.md`. Why: right-sizing currently sends the author to a mechanism that does not exist, which is the specific gap this plan closes. Verify: confirm the old sentence is gone and that both guideline files show a `### Phase:` example.
11. [x] Extend `tests/plugins/test-build-plan-html.mjs` and `tests/plugins/test-extract-plan-spec.mjs` with phase and Decisions cases, and add `tests/plugins/test-plan-phases.mjs` asserting the render-extract-re-render cycle preserves both, that an unphased spec renders unchanged, and that `build/SKILL.md` and `finalize-plan/SKILL.md` still carry their phase contract strings. Why: the render-extract-render pair catches a format change applied to one side and missed on the other, and the prose-contract grep follows the established pattern in `test-exitplanmode-guard.sh`, which guards a required skill string the same way. Verify: run all three test files and confirm each exits 0.
12. [x] Bump plan-agent from 8.5.1 to 8.6.0 in `.claude-plugin/marketplace.json` and add the matching `kit/plugins/plan-agent/CHANGELOG.md` entry describing both new sections, the build checkpoint loop, and the finalize-plan gate. Why: repo convention requires any change under `kit/plugins/` to ship a version exceeding the value on main, and a new spec section is a minor bump. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.

## Decisions

- Phase boundaries are `### Phase:` headings rather than a `phases:` frontmatter range list — headings survive step insertion and reordering, which range lists do not.
- The Decisions section renders rather than staying markdown-only, so the ledger is visible on the plan page and in the gallery, not just to an agent reading the spec.
- `build` stops at a phase boundary by default and takes `--continue` to push through, matching the skill's existing headless contract of stopping rather than choosing.
- The phase boundary offers to compact the session rather than only stopping, because continuing in the same session with reclaimed context is usually what the user wants; `build` prints the `/compact` command rather than running it, since compaction is a user-typed CLI built-in and not a callable tool.
- Compaction is safe mid-plan only because durable state lives in the spec — step markers, `status:`, and the Decisions ledger — so a lossy summary of the conversation costs nothing the next phase needs.
- A phase name renders as an `<h3>` inside a `data-phase` group wrapper — the heading puts phases in the document outline for screen-reader navigation, and the wrapper carries the attribute extraction reads.
- Phases are pure grouping over the same flat step numbering, so adding them to an already in-progress plan keeps every existing `[x]` marker valid and `build` still resumes at the first unmarked step rather than at a phase start.
- The checkpoint contract in `build` and `finalize-plan` is guarded by a prose grep in the style of `test-exitplanmode-guard.sh`, accepting that this catches deletion of the contract rather than proving the runtime behaviour.
- `finalize-plan` is in scope because `build/SKILL.md` line 303 requires the two skills' completion rules to stay consistent.
- Parent and child plan files are out of scope; phase boundaries are shaped so they can be extracted into child files in a later change.

## Tests

Tier 1 — This plan changes application code
- Objective: a phased plan with a Decisions ledger survives render, extract, and re-render, and an unphased plan is unaffected. File: tests/plugins/test-plan-phases.mjs; Type: smoke; Asserts: phases and Decisions bullets round-trip through renderPlanHtml and extractSections with names and order preserved, an unphased fixture renders byte-identically to its pre-change output, and build/SKILL.md and finalize-plan/SKILL.md both carry their phase contract strings; Run: node tests/plugins/test-plan-phases.mjs
- Unit: phase-aware step splitting. File: tests/plugins/test-build-plan-html.mjs; Targets: parseSpecMarkdown, buildDigest; Key cases: heading before the first step, heading between two steps, no heading at all, heading with no steps under it, step verify text containing a hash character
- Unit: Decisions section parsing and re-emission. File: tests/plugins/test-build-plan-html.mjs; Targets: parseSpecMarkdown, buildDigest, SECTION_CHROME; Key cases: absent section, single bullet, multiple bullets, present but empty
- Integration: DOM extraction of phases and Decisions. File: tests/plugins/test-extract-plan-spec.mjs; Targets: extractSections; Key cases: phased render, unphased render, phase group with a completed step card, Decisions card present and absent

## Acceptance Criteria

- [x] A spec with two `### Phase:` headings parses with every step's `Verify:` text free of heading markup
- [x] `parseSpecMarkdown(buildDigest(parsed))` returns phases deep-equal to the original for a phased fixture
- [x] `extractSections` on a rendered phased plan returns the phase names in document order, with no phase name leaking into a step's action text
- [x] The rendered progress bar total equals the step count for a phased plan, confirming the `.step-card` selector still matches
- [x] Each phase renders an `<h3>` inside a `data-phase` wrapper, so the outline runs h1 to h2 to h3 with no skipped level
- [x] A phased spec whose first phase is fully `[x]` resumes at the first unmarked step of the next phase rather than restarting
- [x] `finalize-plan` leaves a plan with an unfinished phase at `status: in-progress` and names that phase in the Completion Report
- [x] A spec with a `## Decisions` section renders a Decisions card and a sidebar nav entry
- [x] An unphased spec with no Decisions section renders byte-identically to its output before this change
- [x] `kit/plugins/plan-agent/skills/build/SKILL.md` documents both the stop-at-phase-boundary default and the `--continue` override
- [x] The phase boundary offers `Compact and continue`, `Stop here — resume later`, and `Continue without compacting`, and prints a `/compact` line naming the spec path and the finished phase
- [x] The sentence "probably two plans — split it" no longer appears in `guidelines/right-sizing.md`
- [x] Each of the three renderer sources under `kit/plugins/plan-agent/scripts/` is byte-identical to its repo-root counterpart under `scripts/`
- [x] `node tests/plugins/test-plan-phases.mjs` exits 0
- [x] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with plan-agent at 8.6.0

## Verification

Author a scratch spec with three steps split across two `### Phase:` headings and a `## Decisions` section carrying two bullets. Render it with `node scripts/build-plan-html.mjs <spec>.md -o <spec>.html` and confirm exit 0, two phase headers each preceding their own steps, a Decisions card, and a progress bar whose total reads 3. Run `node scripts/extract-plan-spec.mjs <spec>.html` — the extractor ships only at the repo root, not in the plugin bundle — and confirm the printed spec carries both phase headings and both Decisions bullets; re-render that extracted spec and diff the two HTML files to confirm the cycle is stable.

Then exercise the checkpoint loop for real: run `/plan-agent:build <spec>.md` and confirm it implements only the first phase, appends a Decisions bullet, sets `status: in-progress`, and stops with a resume command rather than continuing into phase two. Re-run the same command and confirm it resumes at the first unmarked step of phase two rather than redoing phase one. With phase two still unmarked, run `/plan-agent:finalize-plan <spec>.md` and confirm it refuses to set `status: completed` and names the unfinished phase in the Completion Report. Separately, add phase headings to a copy of an already in-progress committed plan whose early steps carry `[x]` and confirm those markers still render as completed cards.

Finally run the existing suite — `node tests/plugins/test-build-plan-html.mjs`, `node tests/plugins/test-extract-plan-spec.mjs`, and `node tests/plugins/test-backfill-digest.mjs` — plus `BASE_REF=main node scripts/check-plugin-versions.mjs`, and re-render one committed plan from `docs/plans/` to confirm an unphased plan is untouched.

## Completion Report

- Version shipped as 8.6.0, not 7.1.0 — plan-agent was already at 8.5.1 when this landed; 7.1.0 would fail the version guard
- Phase and Decisions styling is element-local, not new shared CSS — the plan stylesheet is emitted verbatim into every plan, so a new rule breaks the byte-identical-unphased criterion
- The checkpoint loop lives in build/references/phase-checkpoints.md, not inline in SKILL.md — that core was at 598 of the 600-word ceiling test-progressive-disclosure.sh enforces
- stripHeading was left stripping only h2 — step cards are sliced at their own div boundaries so a phase h3 can never reach a step's action text, and stripping h3 would drop legitimate headings from legacy Context sections

## Next Steps

- Make the plans archiver parent-and-child aware
  Needed before parent and child plan files ship, not before phases do.
  ```text
  In the agentics repo at ~/devbox/agentics, .claude/workflows/organize-completed-plans.js
  runs one `git mv` per plan whose frontmatter status is `completed`, moving it into
  docs/plans/archive/<type>/. If plan-agent ever gains parent and child plan files, a
  child that completes while its parent is still in-progress would be archived away from
  its parent, breaking the linkage and any relative link between them. Update the
  archiver so a plan carrying a `parent:` frontmatter key is never archived on its own —
  it is archived only when its parent reaches `completed`, and then parent and children
  move together into the same archive subdirectory. Bump the plan-agent minor version in
  .claude-plugin/marketplace.json and add a CHANGELOG entry. Verify by creating two
  scratch specs in docs/plans/, one with `parent:` pointing at the other, marking only
  the child `completed`, running the archiver, and confirming neither file moved.
  ```
- Extract phases into separate child plan files
  The follow-on that phases are deliberately shaped to allow.
  ```text
  In the agentics repo at ~/devbox/agentics, plan-agent supports `### Phase:` groupings
  inside a single plan spec. Add a `/plan-agent:split-plan <plan.md>` skill that promotes
  each phase into its own child spec in the same plans directory, writing a `parent:`
  frontmatter key into each child and rewriting the original into a coordination plan
  whose steps are "implement child <path>" with a verify of "child reached status:
  completed". The parent keeps its own end-to-end Verification section, because the seams
  between children are the part no child can verify. Read
  kit/plugins/plan-agent/scripts/lib/plan-spec.mjs first: buildDigest is the documented
  exact inverse of parseSpecMarkdown, so any new frontmatter must not break the
  render-extract-render fidelity tests in tests/plugins/. Do not make the renderer read
  sibling files — keep the one-spec-in, one-file-out contract and have whoever completes
  a child write the `[x]` back into the parent. Bump the plan-agent minor version in
  .claude-plugin/marketplace.json and add a CHANGELOG entry. Verify by splitting a
  three-phase plan and confirming each child renders standalone and the parent's step
  count equals the phase count.
  ```

## Unresolved Questions

- Should phase names surface in the plans gallery?
  ```text
  In the agentics repo at ~/devbox/agentics, plan-agent plans can carry `### Phase:`
  groupings. Investigate whether the plans gallery card in
  kit/plugins/plan-agent/templates/plans-gallery.html should show phase progress (for
  example "phase 2 of 4") alongside the existing status and effort chips, and recommend
  one option. Read kit/plugins/plan-agent/hooks/rebuild-plans-index.py and
  hooks/build-index.sh to see what metadata the index already reads from each rendered
  plan, and check whether adding a phase count would require a new meta tag or can be
  derived from existing markup. Report the cost and your recommendation; do not implement.
  ```
