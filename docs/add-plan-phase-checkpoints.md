# Phase checkpoints and a Decisions ledger for plan specs

> Adds an optional `### Phase: <name>` grouping level and a `## Decisions` section to the plan spec format, turning `build`'s resume-from-first-unmarked-step behaviour into a designed checkpoint loop for long sequential plans.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
**Type:** feature

## What shipped

- Made `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` phase-aware: splits the Steps chunk on `^###\s+Phase:` lines before the numbered-item split, returning `sections.phases` as an ordered array of `{ name, firstStep, lastStep }` (before this, a phase heading placed between steps was silently appended to the preceding step's `Verify:` text).
- Updated `buildDigest` to re-emit `### Phase: <name>` lines, keeping it the documented exact inverse of `parseSpecMarkdown`.
- Extended `extractSections` in `extract-plan-spec.mjs` to read phase names from `data-phase` attributes on rendered group wrappers.
- Added a `phaseHeader` helper to `scripts/lib/plan-shell.mjs` that emits `<div class="phase-group" data-phase="…"><h3>…</h3>` and groups step cards under those wrappers in `build-plan-html.mjs` (without breaking the flat `.step-card` selector used by the progress bar JavaScript).
- Added the `## Decisions` section end-to-end: parsing, `buildDigest` re-emission, DOM extraction, `SECTION_CHROME` entry, rendered card after Context.
- Re-copied all three renderer sources byte-for-byte to `kit/plugins/plan-agent/scripts/` to satisfy the byte-identical parity assertion in `test-build-plan-html.mjs:837`.
- Rewrote Step 2 of `skills/build/SKILL.md` as a phase checkpoint loop — implement one phase, run verify gate, append decisions to `## Decisions`, reach the boundary offer — with a `--continue` flag; unphased behaviour unchanged.
- Added the boundary offer: `Compact and continue` (recommended), `Stop here — resume later`, `Continue without compacting`; prints the `/compact` command rather than running it, since compaction is a user-typed CLI built-in.
- Taught `skills/finalize-plan/SKILL.md` to refuse `status: completed` while any phase holds unmarked steps, recording each unfinished phase in the `## Completion Report`.
- Added `### Phase:` and `## Decisions` syntax entries to `section-catalog.md`; replaced the "probably two plans — split it" sentence in `right-sizing.md` with a phase profile.
- Added `tests/plugins/test-plan-phases.mjs` and extended the existing HTML and extraction test files; bumped plan-agent to 8.6.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Phase-aware step splitting, Decisions parsing, digest re-emission, DOM extraction | Modified |
| `scripts/build-plan-html.mjs` | Group step cards by phase, render Decisions section | Modified |
| `scripts/lib/plan-shell.mjs` | Phase header helper, SECTION_CHROME entry, phase CSS | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Phase checkpoint loop and `--continue` override | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Refuse completion with unfinished phases | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Note phases and Decisions in renderer-derives list | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Syntax entries for both new sections | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Phase profile replacing dead-end split advice | Modified |
| `tests/plugins/test-plan-phases.mjs` | Objective-verification smoke test | Created |
| `tests/plugins/test-build-plan-html.mjs` | Phase and Decisions render cases | Modified |
| `tests/plugins/test-extract-plan-spec.mjs` | Phase and Decisions extraction cases | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version (plan-agent 8.6.0) | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog | Modified |

## How it works

The core problem was that long sequential plans — where step seven depends on decisions made in step two — consume more context than one session can hold, and there was no mechanism to split them. `build/SKILL.md` already resumed from the first unmarked step, but nothing marked a safe stopping point and nothing recorded decisions already settled.

The format is bidirectional, and that is the main cost driver. `buildDigest` is documented as the exact inverse of `parseSpecMarkdown`, and `extractSections` derives a spec back out of rendered HTML for legacy plans. Any new grouping level had to be carried at all four sites (parse, render, extract-from-DOM, re-emit) or it would silently disappear during a round-trip.

Phase headings are `### Phase: <name>` lines placed inside the `## Steps` section. The old splitter in `plan-spec.mjs` split the Steps chunk on numbered items only, so a phase heading placed between two steps was appended to the preceding step's `Verify:` text with no error. The fix splits on `^###\s+Phase:` first, then on numbered items within each phase chunk.

Rendering groups step cards under `<div class="phase-group" data-phase="…"><h3>…</h3>` wrappers. The phase `<h3>` appears in the document outline between the section `<h2>` headings and the step details, keeping the outline at h1→h2→h3 with no skipped level for screen-reader navigation. The step cards remain flat inside the wrappers so the existing `querySelectorAll('.step-card')` progress bar logic counts them correctly.

The `## Decisions` section is a bullet list that renders after Context as its own `sectionCard`. A resumed session can read settled choices directly from the spec rather than re-deriving them from conversation history.

`build/SKILL.md`'s checkpoint loop implements one phase, appends any decisions made to `## Decisions`, then presents the boundary offer. The recommended choice (`Compact and continue`) prints the `/compact` command with focus instructions naming the spec path and the finished phase, then stops — compaction is safe mid-plan precisely because durable state lives in the spec rather than the conversation.

`finalize-plan` now reads the phase structure before setting `status: completed`. If any phase still holds unmarked steps, it leaves the plan at `status: in-progress` and names each unfinished phase in the `## Completion Report`.

## How to use it

Add `### Phase: <name>` lines inside `## Steps` to group steps into checkpoint phases. Add a `## Decisions` section with bullet points to record design choices.

```
/plan-agent:build docs/plans/my-plan.md              # stops at first phase boundary by default
/plan-agent:build docs/plans/my-plan.md --continue   # pushes through all phase boundaries
```

An existing in-progress plan can gain phase headings retroactively — all existing `[x]` markers remain valid, and `build` still resumes at the first unmarked step rather than at a phase start.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `1c31569` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `19a9ae8` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `77aa33e` | 2026-09-12 | fix(plan-agent): lead the goal prompt with "Goal:" (9.17.2) (#631) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `b8cfa1f` | 2026-09-04 | fix(plan-agent): style header links as chips and refocus a leading select after submit (9.13.1) (#623) |
| `d2e9f10` | 2026-09-02 | feat: polish the plan-document HTML output (#617) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — v8.6.0 entry
