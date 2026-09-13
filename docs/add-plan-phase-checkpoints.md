# Phase checkpoints and a Decisions ledger for plan specs

> Added optional `### Phase:` groupings and a `## Decisions` section to the plan spec format, with a checkpoint loop in the build skill that stops at each phase boundary and a finalize-plan gate that refuses to close a plan with unfinished phases.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
**Type:** feature

## What shipped

- Extended `parseSpecMarkdown` in `scripts/lib/plan-spec.mjs` to be phase-aware: the Steps chunk is split on `### Phase:` headings before the existing numbered-item split, returning `sections.phases` as an ordered array of `{name, firstStep, lastStep}` (fixing a pre-existing bug where a heading between two steps was silently appended to the preceding step's `Verify:` text).
- Extended `buildDigest` to re-emit `### Phase:` headings above the first step of each phase, making it the documented exact inverse of `parseSpecMarkdown`.
- Extended `extractSections` to read phase names from `data-phase` wrapper attributes in rendered HTML, and patched `stripHeading` to leave phase `<h3>` elements alone (step cards are sliced at their own div boundaries, so a phase heading cannot reach a step's action text).
- Added phase rendering to `scripts/build-plan-html.mjs` and `scripts/lib/plan-shell.mjs`: each phase group is a `<div class="phase-group" data-phase="…"><h3>…</h3>` wrapper with steps nested inside it, keeping the flat `.step-card` count intact for the progress bar.
- Added `## Decisions` end-to-end: parsed as a bullet list, re-emitted in digest, extracted from DOM, rendered as a `sectionCard` after Context, with a sidebar nav entry.
- Re-copied all three edited renderer sources byte-for-byte to `kit/plugins/plan-agent/scripts/`.
- Rewrote Step 2 of `skills/build/SKILL.md` as a phase checkpoint loop with a `--continue` flag and a three-option boundary offer (Compact and continue / Stop here / Continue without compacting), including a printed `/compact` command rather than calling it directly.
- Taught `skills/finalize-plan/SKILL.md` to refuse `status: completed` while any phase holds unmarked steps, recording unfinished phases in `## Completion Report`.
- Updated `guidelines/section-catalog.md` and `guidelines/right-sizing.md` to replace the dead-end "probably two plans — split it" sentence with the phase profile.
- Added `tests/plugins/test-plan-phases.mjs` and extended `test-build-plan-html.mjs` and `test-extract-plan-spec.mjs` with phase and Decisions cases.
- Bumped plan-agent from 8.5.1 to 8.6.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Phase-aware step splitting, Decisions parsing, digest re-emission, DOM extraction | Modified |
| `scripts/build-plan-html.mjs` | Group step cards by phase, render Decisions section (repo-root source) | Modified |
| `scripts/lib/plan-shell.mjs` | Phase header helper, SECTION_CHROME entry for Decisions, phase CSS (repo-root source) | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical re-copy | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Phase checkpoint loop and `--continue` override | Modified |
| `kit/plugins/plan-agent/skills/build/references/phase-checkpoints.md` | Checkpoint contract (extracted from SKILL.md due to word ceiling) | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Refuse to complete a plan with unfinished phases | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Note phases and Decisions in the renderer-derives list | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Syntax entries for both new sections | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Replace dead-end split advice with phase profile | Modified |
| `tests/plugins/test-plan-phases.mjs` | Objective-verification smoke test | Created |
| `tests/plugins/test-build-plan-html.mjs` | Phase and Decisions render cases | Modified |
| `tests/plugins/test-extract-plan-spec.mjs` | Phase and Decisions extraction cases | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 8.5.1 → 8.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 8.6.0 entry | Modified |

## How it works

The spec format is bidirectional: `buildDigest` is the documented exact inverse of `parseSpecMarkdown`, and `extractSections` derives a spec back out of rendered HTML for legacy HTML-only plans. A new grouping level therefore had to be carried at four sites — parse, render, extract-from-DOM, re-emit — with the fidelity tests guarding all four.

Phase headings are placed between numbered steps using `### Phase: <name>` syntax. The parser splits the Steps chunk on these headings before the numbered-item split, returning the phase array alongside the flat step list. This fixes a pre-existing correctness bug: a heading between two steps was previously appended to the preceding step's `Verify:` text with no parse error.

In the renderer, each phase group becomes a `<div class="phase-group" data-phase="…">` wrapper containing an `<h3>` and the step cards for that phase. The `<h3>` keeps phases in the document outline (h1→h2→h3) for screen-reader navigation. The `.step-card` selector used by the progress bar JavaScript counts all cards regardless of nesting, so the progress total is unaffected.

The Decisions section is a standard `## Decisions` bullet list. It renders as a dedicated section card placed after Context in the HTML, gains a sidebar nav entry, and round-trips cleanly through all four pipeline sites. The ledger's purpose is to let a resumed session see the choices an earlier session already made, preventing re-derivation or contradiction.

The checkpoint loop in `skills/build/SKILL.md` implements one phase, appends decisions to `## Decisions`, then reaches a three-option boundary offer. The `/compact` command is printed rather than called because it is a user-typed CLI built-in. The `--continue` flag pushes straight through phases. Unphased specs see no behaviour change. The `skills/finalize-plan/SKILL.md` gate was updated to match, as required by the build skill's documented consistency rule at line 303.

The Completion Report recorded two deviations from plan: the version shipped as 8.6.0 (not 7.1.0, since plan-agent was already at 8.5.1); and the checkpoint contract lives in `build/references/phase-checkpoints.md` rather than inline in `SKILL.md`, because the core was at the 598-of-600-word ceiling the `test-progressive-disclosure.sh` test enforces.

## How to use it

Add `### Phase: <name>` headings between numbered steps in a plan spec to declare phase boundaries:

```markdown
## Steps
### Phase: Setup
1. Install dependencies ...
2. Configure environment ...

### Phase: Build
3. Write the feature ...
4. Add tests ...
```

Run `/plan-agent:build <spec>.md` — the skill implements the first unmarked phase, then stops with a boundary offer. Use `--continue` to run all phases in one session. A `## Decisions` section records settled choices:

```markdown
## Decisions
- Chose approach A over B because ...
- Deferred X to a follow-on plan
```

`/plan-agent:finalize-plan` refuses `status: completed` while any phase holds unmarked steps.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
