# Phase checkpoints and a Decisions ledger for plan specs

> Adds optional `### Phase:` groupings over plan steps and a `## Decisions` section so long sequential plans can be implemented across context windows without re-deriving earlier choices.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
**Type:** feature

## What shipped

- Added phase-aware step splitting to `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs`, preventing `### Phase:` headings from corrupting step text (fixing a silent data-loss bug that predated this plan).
- Added `buildDigest` emission of phase headings so phases survive the parse-digest-parse round trip, keeping `buildDigest` the documented exact inverse of `parseSpecMarkdown`.
- Extended `extractSections` in `extract-plan-spec.mjs` to read phase names from `data-phase` DOM attributes, enabling accurate re-rendering of legacy HTML-only plans with phases.
- Added a `phaseHeader` helper to `scripts/lib/plan-shell.mjs` and grouped step cards under `<div class="phase-group" data-phase="…"><h3>…</h3>` wrappers in `build-plan-html.mjs` (preserving the flat step-card selector so the progress bar still counts correctly).
- Added the `## Decisions` section end-to-end — parse, digest, extract, render — so settled choices are visible in the plan page and gallery rather than only in the markdown spec (keeping them out of the completion-gap `## Completion Report`).
- Re-copied all three edited renderer sources byte-for-byte into `kit/plugins/plan-agent/scripts/` to maintain the byte-identical parity the test suite asserts.
- Rewrote `build/SKILL.md` Step 2 as a phase checkpoint loop — implement one phase, record decisions, reach the boundary — with a `--continue` flag to push through and no behavior change for unphased specs.
- Added the three-option boundary offer (`Compact and continue`, `Stop here — resume later`, `Continue without compacting`) and a printed `/compact` command (not called — it is a user-typed CLI built-in).
- Taught `finalize-plan/SKILL.md` to refuse `status: completed` while any phase holds unmarked steps, naming unfinished phases in the Completion Report (keeping the two skills' completion rules consistent per `build/SKILL.md` line 303).
- Documented both new sections in `guidelines/section-catalog.md` and replaced the dead-end "probably two plans — split it" advice in `guidelines/right-sizing.md` with a phase profile.
- Added `tests/plugins/test-plan-phases.mjs` and extended the existing HTML and extraction test suites to cover phases and Decisions.
- Bumped plan-agent from 8.5.1 to 8.6.0 in `.claude-plugin/marketplace.json` with a matching CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Phase-aware step splitting, Decisions parsing, digest re-emission, DOM extraction | Modified |
| `scripts/build-plan-html.mjs` | Groups step cards by phase, renders the Decisions section | Modified |
| `scripts/lib/plan-shell.mjs` | Phase header helper, SECTION_CHROME entry for Decisions, phase CSS | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical re-copy of repo-root source | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Byte-identical re-copy of repo-root source | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical re-copy of repo-root source | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Phase checkpoint loop and the `--continue` override | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Refuses to complete a plan with unfinished phases | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Notes phases and Decisions in the renderer-derives list | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Syntax entries for both new sections | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Replaces dead-end split advice with the phase profile | Modified |
| `tests/plugins/test-plan-phases.mjs` | Objective-verification smoke test | Created |
| `tests/plugins/test-build-plan-html.mjs` | Phase and Decisions render cases | Modified |
| `tests/plugins/test-extract-plan-spec.mjs` | Phase and Decisions extraction cases | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 8.5.1 to 8.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 8.6.0 entry | Modified |

## How it works

The core change is in `scripts/lib/plan-spec.mjs`. `parseSpecMarkdown` previously split the Steps block with a single numbered-item regex, so a `### Phase:` heading between two steps was silently appended to the preceding step's `Verify:` text. The fix splits the Steps chunk first on `^###\s+Phase:` lines, then applies the numbered-item split within each phase slice, returning `sections.phases` as `[{ name, firstStep, lastStep }]` or `null`. Any spec authored before this fix was blocked from using phase headings without corrupting content.

`buildDigest` is documented as the exact inverse of `parseSpecMarkdown`. Adding phases to the parser without emitting them in `buildDigest` would cause phases to disappear whenever a spec was reconstructed from HTML — a silent data loss. The fix emits a `### Phase: <name>` line above the first step of each phase while keeping the flat numbering unchanged, so adding phases to an in-progress plan invalidates no existing `[x]` markers and `build` still resumes at the first unmarked step regardless of phase boundaries.

`extractSections` in `extract-plan-spec.mjs` derives specs from legacy HTML-only plans (the 69 of 84 non-index plans that have no sibling `.md`). The function now matches `data-phase` attributes on phase group wrappers to recover phase names in document order. The existing `stripHeading` helper was left stripping only `h2` — step cards are sliced at their own `div` boundaries, so a phase `h3` never reaches a step's action text, and stripping `h3` would drop legitimate headings from legacy Context sections.

Rendering groups step cards by phase: `plan-shell.mjs` gained a `phaseHeader(name)` helper that emits `<div class="phase-group" data-phase="…"><h3>…</h3>`, and `build-plan-html.mjs` wraps each phase's step cards inside it. The progress bar at `plan-shell.mjs` line 1324 counts `.step-card` elements with `querySelectorAll`, so the nesting cannot break it. Every phase name is an `h3` inside its wrapper — the heading level runs h1, h2, h3 with no skip, which is required for screen-reader navigation. Styling is element-local, not new shared CSS, because the plan stylesheet is emitted verbatim into every plan and a new shared rule would break the byte-identical-unphased regression criterion.

The `## Decisions` section was added end-to-end at five sites: `parseSpecMarkdown` parses it as a bullet list, `buildDigest` re-emits it, `extractSections` extracts it, `SECTION_CHROME` gained a `decisions` key, and `sectionCard` renders it after the Context card. The placement after Context makes settled choices visible on the plan page and in the gallery without conflating them with the gap-tracking `## Completion Report` section.

The checkpoint loop in `build/SKILL.md` implements one phase per invocation, appends decisions made to `## Decisions`, and stops with a boundary offer rather than continuing automatically — matching the skill's existing headless contract (stop and report rather than choose). The `--continue` flag bypasses the boundary for users who want uninterrupted execution. The boundary offer presents three options via `AskUserQuestion` and prints a `/compact` command with focus instructions naming the spec path and the finished phase; it prints rather than runs because `/compact` is a user-typed CLI built-in and compaction is safe mid-plan precisely because durable state lives in the spec rather than the conversation.

The checkpoint contract in `build` and `finalize-plan` is guarded by a prose grep in `tests/plugins/test-plan-phases.mjs`, following the pattern established by `test-exitplanmode-guard.sh`. This catches deletion of the contract strings rather than proving runtime behavior, which is the established tradeoff in this repo.

## How to use it

Author a plan spec with `### Phase:` headings between numbered steps:

```markdown
## Steps

### Phase: Setup

1. [ ] First setup step. Why: ... Verify: ...

### Phase: Build

2. [ ] First build step. Why: ... Verify: ...
```

Add a `## Decisions` section to record settled choices:

```markdown
## Decisions

- Chose X over Y because Z.
```

Run `/plan-agent:build <spec>.md` — the skill implements the first phase, appends any decisions made, and stops at the boundary with a resume offer. Re-run to continue from the first unmarked step of the next phase. Pass `--continue` to push through all phases without stopping.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `b8cfa1f` | 2026-09-04 | fix(plan-agent): style header links as chips and refocus a leading select after submit (9.13.1) (#623) |
| `d2e9f10` | 2026-09-02 | feat: polish the plan-document HTML output (#617) |
| `3263bbc` | 2026-08-30 | feat(plan-agent): reconcile a plan against what actually shipped (9.11.0) (#613) |
| `22e2280` | 2026-08-30 | fix(plan-agent): unbreak the build completion gate for artifact-only plans (9.10.1) (#610) |
| `4147530` | 2026-08-26 | fix(plan-agent): stop artifact-mode renders leaking local paths (9.7.1) (#602) |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |
| `94c0569` | 2026-08-23 | feat(plan-agent): add design phase — canvas link, gallery, and drift check (#596) |
| `ab2f769` | 2026-08-17 | chore: make verification gates a self-enforcing authoring standard (#569) |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |

<!-- generated:end -->

## References

- Plan: [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
