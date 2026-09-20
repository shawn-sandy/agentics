# Phase checkpoints and a Decisions ledger for plan specs

> Long plans have to be implemented in one sitting today, because nothing in the spec marks a safe stopping point and nothing records the decisions an earlier...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
**Type:** feature

## What shipped

- Make `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` phase-aware by splitting the Steps chunk on `^###\s+Phase:` l...
- Emit phases from `buildDigest` as a `### Phase: <name>` line above the first step of each phase, keeping the flat num...
- Read phases back out of rendered HTML in `extractSections` by matching the `data-phase` attribute on each phase group...
- Render phase groups by adding a `phaseHeader` helper to `scripts/lib/plan-shell.mjs` that emits `<div class="phase-gr...
- Add the `## Decisions` section end-to-end — parse it as a bullet list in `parseSpecMarkdown`, re-emit it in `buildDig...
- Re-copy the three edited renderer sources — `scripts/build-plan-html.mjs`, `scripts/lib/plan-spec.mjs`, and `scripts/...
- Rewrite Step 2 of `skills/build/SKILL.md` as a phase checkpoint loop — implement one phase, run its verify gate, appe...
- Add the phase boundary offer to that same Step 2 — an `AskUserQuestion` presenting `Compact and continue` (recommende...
- Teach `skills/finalize-plan/SKILL.md` about phases so it refuses to set `status: completed` while any phase still hol...
- Document both sections in `guidelines/section-catalog.md` with their exact syntax, and replace the "probably two plan...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | phase-aware step splitting, Decisions parsing, digest re-... | Modified |
| `scripts/build-plan-html.mjs` | group step cards by phase, render the Decisions section | Modified |
| `scripts/lib/plan-shell.mjs` | phase header helper, SECTION_CHROME entry for decisions, ... | Modified |
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

Implementation plans that exceed roughly ten steps consume more context than one session can hold. The repo already reaches this conclusion: `guidelines/right-sizing.md` line 35 tells the author that a plan needing more than ten steps "is probably two plans — split it". It then offers no mechanism to split with. A grep of the whole plugin for parent, child, and subplan concepts returns nothing. Two capabilities are missing, and only one of them is about parallelism. The `workflow` prompt already...

The implementation proceeded through these steps: Make `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` phase-aware by splitting the Steps chunk on `^###\s+Phase:` l...; Emit phases from `buildDigest` as a `### Phase: <name>` line above the first step of each phase, keeping the flat num...; Read phases back out of rendered HTML in `extractSections` by matching the `data-phase` attribute on each phase group...; Render phase groups by adding a `phaseHeader` helper to `scripts/lib/plan-shell.mjs` that emits `<div class="phase-gr...; Add the `## Decisions` section end-to-end — parse it as a bullet list in `parseSpecMarkdown`, re-emit it in `buildDig....

- Version shipped as 8.6.0, not 7.1.0 — plan-agent was already at 8.5.1 when this landed; 7.1.0 would fail the version guard - Phase and Decisions styling is element-local, not new shared CSS — the plan stylesheet is emitted verbatim into every plan, so a new rule breaks the byte-identical-unphased 

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
