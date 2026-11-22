# Add phase checkpoints and Decisions ledger for plan specs

> An optional `### Phase: <name>` grouping level and `## Decisions` section let long sequential plans span multiple context windows; `build` stops at each phase boundary by default and offers a compact-and-continue path.

<!-- generated:start -->

**Status:** Shipped 2026-08-05 **Plan:** [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
**Type:** feature

## What shipped

- Made `parseSpecMarkdown()` in `scripts/lib/plan-spec.mjs` phase-aware: splits Steps on `^###\s+Phase:` before the numbered-item split, returning `sections.phases` as `{ name, firstStep, lastStep }[]`.
- Added `## Decisions` section end-to-end: parsed as a bullet list, re-emitted in `buildDigest`, extracted in `extractSections`, rendered as a Decisions card after Context.
- Rendered phase groups in `plan-shell.mjs`: `<div class="phase-group" data-phase="…"><h3>…</h3>` wrappers around step cards, leaving `.step-card` selectors intact (progress bar unaffected).
- Rewrote `build/SKILL.md` Step 2 as a phase checkpoint loop: implement one phase, run its verify gate, append decisions to `## Decisions`, then reach the boundary offer — `Compact and continue` (recommended), `Stop here — resume later`, `Continue without compacting`. The `--continue` flag pushes straight through. Unphased specs take the existing uninterrupted walk.
- Taught `finalize-plan/SKILL.md` to refuse `status: completed` while any phase holds unmarked steps, recording each unfinished phase in `## Completion Report`.
- Documented both sections in `guidelines/section-catalog.md`, replaced the "probably two plans — split it" dead end in `guidelines/right-sizing.md` with a phase profile, and added both to the renderer-derives list in `implementation-plan/SKILL.md`.
- Added `tests/plugins/test-plan-phases.mjs` asserting the render-extract-re-render cycle preserves both phases and Decisions, and that an unphased spec renders byte-identically.
- Re-copied the three renderer sources to `kit/plugins/plan-agent/scripts/` for byte-identical parity.
- Bumped `plan-agent` from `8.5.1` to `8.6.0` with matching CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Phase and Decisions parsing | Modified |
| `scripts/build-plan-html.mjs` | Phase rendering, Decisions card | Modified |
| `scripts/lib/plan-shell.mjs` | Phase header helper, Decisions chrome | Modified |
| `kit/plugins/plan-agent/scripts/` (three files) | Byte-identical copies | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Phase checkpoint loop | Modified |
| `kit/plugins/plan-agent/skills/build/references/phase-checkpoints.md` | Checkpoint reference | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Phase-aware completion gate | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Renderer-derives list | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Phase and Decisions syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Phase profile | Modified |
| `tests/plugins/test-plan-phases.mjs` | Smoke test | Created |
| `tests/plugins/test-build-plan-html.mjs` | Phase and Decisions cases | Modified |
| `tests/plugins/test-extract-plan-spec.mjs` | Phase and Decisions extraction | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |

## How it works

`### Phase: <name>` headings are pure grouping over the existing flat step numbering — adding them to an in-progress plan keeps every existing `[x]` marker valid and `build` still resumes at the first unmarked step, not at a phase start. Phases are encoded as `<div class="phase-group" data-phase="…">` wrappers in the rendered HTML so `extractSections` can recover them from legacy HTML-only plans.

The `## Decisions` section is a ledger of choices already settled: a resumed session reads it to avoid re-litigating what the first session decided. `## Completion Report` remains the gap ledger; the two sections serve distinct purposes.

The phase checkpoint loop in `build` pairs with the `/compact` command: when a phase boundary is reached, `build` prints the `/compact` command with focus instructions naming the spec path and the finished phase, then stops. Compaction is safe mid-plan precisely because all durable state (step markers, `status:`, Decisions) lives in the spec rather than the conversation.

The `finalize-plan` gate is kept consistent with `build`'s completion rules: it refuses to set `status: completed` while any phase has unmarked steps, naming the unfinished phase in the Completion Report.

## How to use it

Add `### Phase: <name>` headings in the `## Steps` section to group steps into phases. Add `## Decisions` to record settled choices. Run `/plan-agent:build <spec>.md` — it implements one phase at a time and stops at each boundary with the compact-and-continue offer.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `7ded3bec` | 2026-08-05 | feat(plan-agent): phase checkpoints and a Decisions ledger for plan specs (8.6.0) (#528) |

<!-- generated:end -->

## References

- Plan: [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
