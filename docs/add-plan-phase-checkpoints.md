# Phase Checkpoints and a Decisions Ledger for Plan Specs

> Long plans have to be implemented in one sitting today, because nothing in the spec marks a safe stopping point and nothing records the decisions an earlier session already made. Phases add declared checkpoints and a Decisions ledger so a plan can be picked up cold in a fresh context window.

<!-- generated:start -->

**Status:** Shipped 2026-08-05  **Plan:** [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
**Type:** feature

## What shipped

- Added an optional `### Phase: <name>` grouping level over `## Steps` in the plan spec format, so a long sequential plan can declare safe stopping points that survive step insertion and reordering (using headings rather than frontmatter ranges, which rot when steps shift).
- Added an optional `## Decisions` section to the spec format, persisted through every pipeline stage, rendering as a visible card on the plan page — giving a resumed session access to choices already settled rather than re-deriving them.
- Turned `build`'s existing resume-from-first-unmarked-step behavior into a designed checkpoint loop: implement one phase, run its verify gate, append decisions, then stop at the phase boundary with an offer to compact the session before continuing.
- Updated `finalize-plan` to refuse `status: completed` while any phase holds unmarked steps, naming the unfinished phase in the Completion Report.
- Carried all four changes through the bidirectional pipeline: parse, render, extract-from-DOM, and re-emit in `buildDigest` — so no format data is silently lost on round-trip.
- Added `tests/plugins/test-plan-phases.mjs` and extended the existing `test-build-plan-html.mjs` and `test-extract-plan-spec.mjs` suites, and bumped plan-agent to 8.6.0.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `scripts/lib/plan-spec.mjs` | Parser/digest — phase-aware step splitting and Decisions parsing | Modified |
| `scripts/build-plan-html.mjs` | Renderer — phase group wrappers, Decisions section card | Modified |
| `scripts/lib/plan-shell.mjs` | Shell helpers — `phaseHeader`, SECTION_CHROME entry for Decisions, phase CSS | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundle copy — byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundle copy — byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundle copy — byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Build skill — phase checkpoint loop and `--continue` flag | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Finalize skill — refuses to complete a plan with unfinished phases | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Authoring skill — phases and Decisions in renderer-derives list | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Guideline — syntax entries for both new sections | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Guideline — phase profile replaces dead-end split advice | Modified |
| `tests/plugins/test-plan-phases.mjs` | Smoke test — render-extract-re-render cycle for phases and Decisions | Created |
| `tests/plugins/test-build-plan-html.mjs` | Unit tests — phase and Decisions render cases | Modified |
| `tests/plugins/test-extract-plan-spec.mjs` | Integration tests — phase and Decisions extraction cases | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent 8.5.1 to 8.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 8.6.0 entry | Modified |

## How it works

The plan spec format is bidirectional: `parseSpecMarkdown()` parses a markdown spec into a structured object, `buildDigest()` is documented as its exact inverse, and `extractSections()` derives a spec back out of rendered HTML for legacy plans. A new grouping level therefore had to be carried at all four sites — parse, render, extract-from-DOM, and re-emit — or any data touching only three would be silently lost on round-trip.

`parseSpecMarkdown()` in `scripts/lib/plan-spec.mjs` now splits the Steps chunk on `^###\s+Phase:` lines before the numbered-item split. Without this, a `### Phase:` heading placed between two steps was appended to the preceding step's `Verify:` text with no parse error. The phase names are returned as `sections.phases`, an ordered array of `{name, firstStep, lastStep}`, or `null` when no heading is present. `buildDigest()` re-emits `### Phase: <name>` above the first step of each phase, preserving the flat numbering so adding phases to an in-progress plan leaves every existing `[x]` marker valid.

The renderer in `scripts/build-plan-html.mjs` groups step cards under `<div class="phase-group" data-phase="…"><h3>…</h3>` wrappers, keeping every `.step-card` in flat document order inside them. The progress bar counts `.step-card` elements with `querySelectorAll`, so nesting that broke the selector would silently zero progress — the wrapper preserves it. The `<h3>` keeps the document outline at h1→h2→h3 with no skipped level for screen-reader navigation.

`extractSections()` in `extract-plan-spec.mjs` reads phases back out of rendered HTML by matching the `data-phase` attribute on each group wrapper. The existing `stripHeading` helper was left stripping only `<h2>` elements — step cards are sliced at their own `div` boundaries, so a phase `<h3>` can never reach a step's action text, and stripping `<h3>` would drop legitimate headings from legacy Context sections.

The `build` skill's Step 2 was rewritten as a phase checkpoint loop. After implementing one phase and running its verify gate, the skill appends a Decisions bullet and reaches the boundary offer: three options — Compact and continue (recommended), Stop here, or Continue without compacting. The compact branch prints the `/compact` command with instructions naming the spec path and the finished phase, then stops. `/compact` is a user-typed CLI built-in, not a callable tool, so the skill recommends it rather than running it. Compaction is safe mid-plan because all durable state — step markers, `status:`, and the Decisions ledger — lives in the spec. A `--continue` flag pushes straight through. An unphased spec follows the original single uninterrupted walk with no behavior change.

The three repo-root renderer sources are copied byte-for-byte under `kit/plugins/plan-agent/scripts/` after every edit, because `test-build-plan-html.mjs` line 837 asserts the bundled copies are byte-identical. Editing only one side ships a phase-blind renderer to plugin installers while failing the suite.

## How to use it

Add `### Phase: <name>` headings between steps in a plan spec to declare phase groupings:

```markdown
## Steps

### Phase: Setup

1. [ ] Create the schema

### Phase: Build

2. [ ] Implement the handler
```

Add a `## Decisions` section with a bullet list to record settled choices. Run `/plan-agent:build <spec>.md` — the skill implements one phase, stops at the boundary, and prompts for next action. Pass `--continue` to push through all phases without stopping.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
