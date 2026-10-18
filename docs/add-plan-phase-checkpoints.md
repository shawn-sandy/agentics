# Phase checkpoints and a Decisions ledger for plan specs

> Adds `### Phase:` groupings over `## Steps` and a `## Decisions` section to the plan spec format, enabling long sequential plans to be implemented across several context windows without re-deriving earlier decisions.

<!-- generated:start -->

**Status:** Shipped 2026-08-05  **Plan:** [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
**Type:** feature

## What shipped

- Made `parseSpecMarkdown` phase-aware: splits the Steps chunk on `### Phase:` headings before numbered-item splitting, returning `sections.phases` as `{ name, firstStep, lastStep }`.
- Updated `buildDigest` to re-emit phase headings above their steps, preserving the exact inverse relationship with `parseSpecMarkdown`.
- Updated `extractSections` to read phases back from rendered HTML via `data-phase` attributes.
- Added a `phaseHeader` helper to `plan-shell.mjs` and grouped step cards by phase in `build-plan-html.mjs`; progress bar uses flat `.step-card` selector unchanged.
- Added `## Decisions` section end-to-end: parsed, digest-re-emitted, extracted, and rendered as a `sectionCard` after Context.
- Rewrote `build/SKILL.md` Step 2 as a phase checkpoint loop with `--continue` to push straight through; no behavior change for unphased specs.
- Added phase boundary `AskUserQuestion`: `Compact and continue` (prints `/compact` command with spec path), `Stop here — resume later`, `Continue without compacting`.
- Taught `finalize-plan/SKILL.md` to refuse `status: completed` while any phase holds unmarked steps.
- Updated `guidelines/section-catalog.md`, `guidelines/right-sizing.md`, and `implementation-plan/SKILL.md` renderer-derives list.
- Added `tests/plugins/test-plan-phases.mjs`; extended `test-build-plan-html.mjs` and `test-extract-plan-spec.mjs`.
- Bumped `plan-agent` to `8.6.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `scripts/lib/plan-spec.mjs` | Plan parser | Modified |
| `scripts/build-plan-html.mjs` | HTML renderer | Modified |
| `scripts/lib/plan-shell.mjs` | Shell/UI layer | Modified |
| `kit/plugins/plan-agent/scripts/` (3 files) | Bundled renderer copies | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Build skill | Modified |
| `kit/plugins/plan-agent/skills/build/references/phase-checkpoints.md` | Checkpoint contract | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Finalize skill | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Section catalog | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Depth profiles | Modified |
| `tests/plugins/test-plan-phases.mjs` | Phase smoke test | Created |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |

## How it works

Phase headings are `### Phase: <name>` placed inside `## Steps`. They are safe to add to an in-progress plan because `build` resumes from the first unmarked step (not the start of a phase), so existing `[x]` markers remain valid.

At each phase boundary, `build` stops by default and offers three choices: compact the session (prints `/compact` with the spec path so the user can run it; safe because durable state lives in the spec), continue without compacting, or stop entirely for later resumption. The `--continue` flag bypasses this offer.

The Decisions ledger (`## Decisions`) holds choices made during implementation. A resumed session reads the ledger before proceeding, preventing re-derivation or contradiction of settled choices.

`finalize-plan` reads the phase structure before setting `status: completed` and refuses when any phase still has unmarked steps, recording each unfinished phase in the Completion Report.

The checkpoint contract in `build` and `finalize-plan` is guarded by a prose grep in `test-plan-phases.mjs`, catching deletion of the contract string.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
