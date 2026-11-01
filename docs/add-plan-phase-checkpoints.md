# Phase checkpoints and a Decisions ledger for plan specs

> Adds optional `### Phase:` groupings and a `## Decisions` section to the plan spec format, turning `build`'s existing resume behaviour into a designed checkpoint loop for long sequential plans.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
**Type:** feature

## What shipped

- Made `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` phase-aware: splits the Steps chunk on `^### Phase:` lines before the numbered-item split, returning `sections.phases` as an ordered array of `{ name, firstStep, lastStep }`.
- Extended `buildDigest` to re-emit phase headings, keeping the round-trip `parseSpecMarkdown(buildDigest(parsed)).phases` deep-equal to the original.
- Added phase group rendering in `build-plan-html.mjs` + `plan-shell.mjs`: each phase group is a `<div class="phase-group" data-phase="…"><h3>…</h3>` wrapper over its step cards, so the document outline runs h1 → h2 → h3 with no skipped level.
- Extended `extractSections` in the extractor to read `data-phase` attributes back out of rendered HTML.
- Added the `## Decisions` section end-to-end: parsed as a bullet list, re-emitted by `buildDigest`, extracted by `extractSections`, rendered as a `sectionCard` placed after Context.
- Re-copied all three edited renderer sources to `kit/plugins/plan-agent/scripts/` to keep the bundled copies byte-identical to the repo-root sources.
- Rewrote `build/SKILL.md` Step 2 as a phase checkpoint loop: implement one phase, run its verify gate, append decisions to `## Decisions`, then reach a boundary offer (`Compact and continue` / `Stop here` / `Continue without compacting`). Added `--continue` flag to push straight through.
- Taught `finalize-plan/SKILL.md` to refuse `status: completed` when any phase still holds unmarked steps.
- Updated `guidelines/section-catalog.md` and `guidelines/right-sizing.md`; removed the "probably two plans — split it" dead-end sentence.
- Added `tests/plugins/test-plan-phases.mjs`; extended `test-build-plan-html.mjs` and `test-extract-plan-spec.mjs`.
- Bumped plan-agent to **8.6.0** in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Parser — phase-aware step splitting, Decisions parsing, digest re-emission, DOM extraction | Modified |
| `scripts/build-plan-html.mjs` | Renderer — group step cards by phase, render Decisions section | Modified |
| `scripts/lib/plan-shell.mjs` | Shell helpers — phase header, SECTION_CHROME entry, CSS | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Bundled renderer (byte-identical copy) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Bundled parser (byte-identical copy) | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Bundled shell (byte-identical copy) | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill — phase checkpoint loop and `--continue` override | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Skill — refuse to complete a plan with unfinished phases | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill — note phases and Decisions in renderer-derives list | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Guideline — syntax entries for both new sections | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Guideline — phase profile replaces split advice | Modified |
| `tests/plugins/test-plan-phases.mjs` | Test — render-extract-re-render cycle for phases and Decisions | Created |
| `tests/plugins/test-build-plan-html.mjs` | Test — phase and Decisions render cases | Modified |
| `tests/plugins/test-extract-plan-spec.mjs` | Test — phase and Decisions extraction cases | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — 8.5.1 → 8.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |

## How it works

The format change was implemented in four tightly coupled places. `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` now splits the Steps chunk on `### Phase:` headings before running the per-step numbered-item split. A phase heading placed between two steps no longer gets appended to the preceding step's `Verify:` text — the bug that made phase headings actively unsafe to author before this change.

`buildDigest` emits `### Phase: <name>` above the first step of each group so the round-trip is exact: a spec serialised through `buildDigest` and re-parsed recovers all phase metadata. `extractSections` reads `data-phase` attributes from rendered HTML for the legacy HTML-only plan path.

The renderer groups step cards under `<div class="phase-group" data-phase="…"><h3>…</h3>` wrappers. The progress bar total still equals the flat step count because the progress JavaScript counts `.step-card` elements with `querySelectorAll`; nesting them inside phase wrappers does not break the selector.

`build/SKILL.md` Step 2 was rewritten as a checkpoint loop. At the end of each phase, the skill appends any decisions made to `## Decisions`, then presents three options: `Compact and continue` (prints the `/compact` command with focus instructions naming the spec and the finished phase), `Stop here — resume later`, and `Continue without compacting`. The `--continue` flag skips the offer and pushes straight through all phases. An unphased spec is unaffected — the loop path and the flat path are the same for a spec that declares no phases.

`finalize-plan/SKILL.md` was updated to check for unfinished phases before setting `status: completed`. A plan whose phase two still holds unmarked steps stays at `status: in-progress` with each unfinished phase named in the `## Completion Report`.

The renderer ships at two locations, and `tests/plugins/test-build-plan-html.mjs` line 837 asserts the bundled copies are byte-identical to the repo-root sources. All three sources were edited at the root and re-copied to the bundle before any test run.

## How to use it

Add `### Phase: <name>` headings between step groups in a plan spec. Add a `## Decisions` section to record choices that later phases depend on.

```markdown
## Steps

### Phase: Setup

1. [ ] Create the database schema
   *Why:* …
   *Verify:* …

### Phase: Implementation

2. [ ] Wire the API endpoint
   …

## Decisions

- Schema uses JSONB for the config column — avoids a migration for every new field
```

Running `/plan-agent:build docs/plans/my-plan.md` stops at the first phase boundary and offers to compact before continuing. Use `--continue` to push through all phases without stopping.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18eec` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `1c315692` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83f` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `19a9ae83` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `77aa33e8` | 2026-09-12 | fix(plan-agent): lead the goal prompt with "Goal:" (9.17.2) (#631) |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `b8cfa1fd` | 2026-09-04 | fix(plan-agent): style header links as chips and refocus a leading select after submit (9.13.1) (#623) |
| `d2e9f101` | 2026-09-02 | feat: polish the plan-document HTML output (#617) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
