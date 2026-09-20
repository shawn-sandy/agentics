# Phase checkpoints and a Decisions ledger for plan specs

> Long plans have to be implemented in one sitting today, because nothing in the spec marks a safe stopping point and nothing records the decisions an earlier...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
**Type:** feature

## What shipped

- Make `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` phase-aware by splitting the Steps chunk on `^###\s+Phase:` lines before the existing numbered-item split, returning `sections.phases` as an ordered array of `{ name, firstStep, lastStep }` and `null` when no heading is present.
- Emit phases from `buildDigest` as a `### Phase: <name>` line above the first step of each phase, keeping the flat numbering unchanged.
- Read phases back out of rendered HTML in `extractSections` by matching the `data-phase` attribute on each phase group wrapper, and extend the existing `stripHeading` helper to remove the phase `<h3>` as well as the section `<h2>`.
- Render phase groups by adding a `phaseHeader` helper to `scripts/lib/plan-shell.mjs` that emits `<div class="phase-group" data-phase="…"><h3>…</h3>`, and group the step cards under those wrappers in `build-plan-html.mjs`, leaving every `.step-card` in flat document order inside them.
- Add the `## Decisions` section end-to-end — parse it as a bullet list in `parseSpecMarkdown`, re-emit it in `buildDigest`, extract it in `extractSections`, add a `decisions` key to `SECTION_CHROME`, and render it with a `sectionCard` call placed after Context.
- Re-copy the three edited renderer sources — `scripts/build-plan-html.mjs`, `scripts/lib/plan-spec.mjs`, and `scripts/lib/plan-shell.mjs` — over their counterparts under `kit/plugins/plan-agent/scripts/`, after steps 1 through 5 are complete and before any test run.
- Rewrite Step 2 of `skills/build/SKILL.md` as a phase checkpoint loop — implement one phase, run its verify gate, append the decisions made to `## Decisions`, then reach the boundary offer — with a `--continue` flag that pushes straight through and no behaviour change for a spec that declares no phases.
- Add the phase boundary offer to that same Step 2 — an `AskUserQuestion` presenting `Compact and continue` (recommended), `Stop here — resume later`, and `Continue without compacting`, where the compact branch prints the `/compact` command with focus instructions naming the spec path and the phase just finished, then stops so the user can run it.
- Teach `skills/finalize-plan/SKILL.md` about phases so it refuses to set `status: completed` while any phase still holds unmarked steps, recording each unfinished phase as a `## Completion Report` bullet instead.
- Document both sections in `guidelines/section-catalog.md` with their exact syntax, and replace the "probably two plans — split it" sentence in `guidelines/right-sizing.md` with a phase profile naming when a plan earns phases, then add both to the renderer-derives list in `implementation-plan/SKILL.md`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | phase-aware step splitting, Decisions parsing, digest re-emission, DOM extraction | Modified |
| `scripts/build-plan-html.mjs` | group step cards by phase, render the Decisions section | Modified |
| `scripts/lib/plan-shell.mjs` | phase header helper, SECTION_CHROME entry for decisions, phase CSS | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | re-copied from the repo-root source | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | re-copied from the repo-root source | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | re-copied from the repo-root source | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | phase checkpoint loop and the --continue override | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | refuse to complete a plan with unfinished phases | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | note phases and Decisions in the renderer-derives list | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | syntax entries for both new sections | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | replace the dead-end split advice with the phase profile | Modified |
| `tests/plugins/test-plan-phases.mjs` | objective-verification smoke test | Created |
| `tests/plugins/test-build-plan-html.mjs` | phase and Decisions render cases | Modified |
| `tests/plugins/test-extract-plan-spec.mjs` | phase and Decisions extraction cases | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 8.5.1 to 8.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 8.6.0 entry | Modified |

## How it works

Add an optional `### Phase: <name>` grouping level over `## Steps` and an optional `## Decisions` section to the plan spec format, and turn `build`'s existing resume-from-first-unmarked-step behaviour into a designed checkpoint loop, so a long sequential plan can be implemented across several context windows without re-deriving earlier decisions.

Implementation plans that exceed roughly ten steps consume more context than one session can hold. The repo already reaches this conclusion: `guidelines/right-sizing.md` line 35 tells the author that a plan needing more than ten steps "is probably two plans — split it". It then offers no mechanism to split with. A grep of the whole plugin for parent, child, and subplan concepts returns nothing. Two capabilities are missing, and only one of them is about parallelism. The `workflow` prompt already fans out across subagents, which helps when slices are independent — migrations, renames, per-file sweeps. Context exhaustion bites hardest on long *sequential* plans, where step seven depends on decisions made in step two, and there fan-out does nothing. The fix for that shape is checkpointing. Most of the machinery already exists. `build/SKILL.md` line 152 resumes from the first unmarked step, so implement-some-steps, clear the context, re-run already works by accident. What is missing is a declared safe stopping point and a record of decisions already settled. The `## Completion Report` section is a gap ledger, not a decision ledger, so a resumed session re-derives — or contradicts — choices the first session made. The format is bidirectional, and that is the main cost driver. `buildDigest` is documented as the exact inverse of `parseSpecMarkdown`, and `extractSections` derives a spec back out of rendered HTML for legacy HTML-only plans. A new grouping level therefore has to be carried at four sites — parse, render, extract-from-DOM, re-emit — with `test-build-plan-html.mjs` and `test-extract-plan-spec.mjs` guarding fidelity. Anything carried at fewer than four sites is a silent data loss rather than a missing feature. One hazard is already latent. `parseSpecMarkdown` splits the Steps chunk with `split(/\n(?=\d+\.\s)/)` and folds each piece to a single line with `inline()`, so a `### Phase:` heading placed between steps two and three is appended to **step two's `Verify:` text** with no parse error at all. Phases are actively unsafe to author until step 1 of this plan lands, which is also why this plan does not use phase headings itself.

The implementation proceeded through the following steps: Make `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` phase-aware by splitting the Steps chunk on `^###\s+Phase:` lines before the existing numbered-item split, returning `sections.phases` as an ordered array of `{ name, firstStep, lastStep }` and `null` when no heading is present. Why: the current splitter folds a heading between two steps into the preceding step's `Verify:` text with no error raised, so phase headings silently corrupt content until this lands. Verify: parse a two-phase fixture and confirm both phase names come back in order and no step's `verify` string contains a `#` character.; Emit phases from `buildDigest` as a `### Phase: <name>` line above the first step of each phase, keeping the flat numbering unchanged. Why: `buildDigest` is documented as the exact inverse of `parseSpecMarkdown`, so a phase it does not emit disappears whenever a spec is reconstructed from HTML. Verify: assert `parseSpecMarkdown(buildDigest(parsed)).phases` is deep-equal to `parsed.phases` for the two-phase fixture.; Read phases back out of rendered HTML in `extractSections` by matching the `data-phase` attribute on each phase group wrapper, and extend the existing `stripHeading` helper to remove the phase `<h3>` as well as the section `<h2>`. Why: `extract-plan-spec.mjs` derives specs from legacy HTML-only plans, and an unstripped `<h3>` would leak the phase name into the first step's extracted action text. Verify: run `extractSections` against the Step 4 render output and confirm the phase names come back in document order with no step action containing a phase name.; Render phase groups by adding a `phaseHeader` helper to `scripts/lib/plan-shell.mjs` that emits `<div class="phase-group" data-phase="…"><h3>…</h3>`, and group the step cards under those wrappers in `build-plan-html.mjs`, leaving every `.step-card` in flat document order inside them. Why: the progress and completion JavaScript at `plan-shell.mjs` line 1324 counts `.step-card` elements with `querySelectorAll`, so nesting that breaks the selector would silently zero the progress bar, and an `<h3>` keeps the outline at h1 to h2 to h3 with no skipped level for screen-reader navigation. Verify: render the fixture and confirm the progress bar total equals the step count, each phase heading precedes its own steps, and no heading level is skipped.; Add the `## Decisions` section end-to-end — parse it as a bullet list in `parseSpecMarkdown`, re-emit it in `buildDigest`, extract it in `extractSections`, add a `decisions` key to `SECTION_CHROME`, and render it with a `sectionCard` call placed after Context. Why: a resumed session that cannot see settled choices re-litigates them, and `## Completion Report` records gaps rather than decisions, so reusing it would conflate the two. Verify: a spec carrying three Decisions bullets renders a Decisions card, gains a sidebar nav entry, and survives the parse-digest-parse round trip.; Re-copy the three edited renderer sources — `scripts/build-plan-html.mjs`, `scripts/lib/plan-spec.mjs`, and `scripts/lib/plan-shell.mjs` — over their counterparts under `kit/plugins/plan-agent/scripts/`, after steps 1 through 5 are complete and before any test run. Why: `tests/plugins/test-build-plan-html.mjs` line 837 asserts the bundled copies are byte-identical to the repo-root sources, so editing only one side fails an existing test and ships a phase-blind renderer to anyone who installs the plugin. Verify: `diff scripts/build-plan-html.mjs kit/plugins/plan-agent/scripts/build-plan-html.mjs` and the same for both `lib/` files each report no differences..

- Version shipped as 8.6.0, not 7.1.0 — plan-agent was already at 8.5.1 when this landed; 7.1.0 would fail the version guard - Phase and Decisions styling is element-local, not new shared CSS — the plan stylesheet is emitted verbatim into every plan, so a new rule breaks the byte-identical-unphased criterion - The checkpoint loop lives in build/references/phase-checkpoints.md, not inline in SKILL.md — that core was at 598 of the 600-word ceiling test-progressive-disclosure.sh enforces - stripHeading was left stripping only h2 — step cards are sliced at their own div boundaries so a phase h3 can never reach a step's action text, and stripping h3 would drop legitimate headings from legacy Context sections

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
