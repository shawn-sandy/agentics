# Phase checkpoints and a Decisions ledger for plan specs

> Adds optional `### Phase:` groupings and a `## Decisions` section to the plan spec format, enabling long sequential plans to be implemented across multiple context windows with a durable ledger of settled choices.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
**Type:** feature

## What shipped

- Extended `parseSpecMarkdown` and `buildDigest` in `scripts/lib/plan-spec.mjs` to split the Steps chunk on `### Phase:` headings before the existing numbered-item split, making phases a round-trippable part of the spec format.
- Added `## Decisions` section parsing, digest re-emission, DOM extraction, and a rendered card placed after Context.
- Rendered phase groups as `<div class="phase-group" data-phase="…"><h3>…</h3>` wrappers in `build-plan-html.mjs`, preserving flat step numbering and screen-reader outline order (h1 → h2 → h3).
- Extended `extractSections` in `extract-plan-spec.mjs` to recover phase names from the `data-phase` attribute, completing the render-extract-re-render round trip.
- Rewrote Step 2 of `skills/build/SKILL.md` as a phase checkpoint loop: implement one phase, run its verify gate, append decisions to `## Decisions`, then reach a three-option boundary offer (`Compact and continue`, `Stop here — resume later`, `Continue without compacting`).
- Taught `skills/finalize-plan/SKILL.md` to refuse `status: completed` while any phase still holds unmarked steps.
- Replaced the dead-end "probably two plans — split it" advice in `guidelines/right-sizing.md` with the phase profile.
- Added `tests/plugins/test-plan-phases.mjs` and extended `test-build-plan-html.mjs` and `test-extract-plan-spec.mjs`.
- Bumped plan-agent to 8.6.0.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Phase-aware step splitting, Decisions parsing, digest re-emission, DOM extraction | Modified |
| `scripts/build-plan-html.mjs` | Groups step cards by phase, renders Decisions section | Modified |
| `scripts/lib/plan-shell.mjs` | Phase header helper, SECTION_CHROME entry for Decisions, phase CSS | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Re-copied from repo-root source | Generated |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Re-copied from repo-root source | Generated |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Re-copied from repo-root source | Generated |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Phase checkpoint loop and `--continue` override | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Refuses to complete a plan with unfinished phases | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Notes phases and Decisions in renderer-derives list | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Syntax entries for both new sections | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Phase profile replaces dead-end split advice | Modified |
| `tests/plugins/test-plan-phases.mjs` | Objective-verification smoke test | Created |
| `tests/plugins/test-build-plan-html.mjs` | Phase and Decisions render cases | Modified |
| `tests/plugins/test-extract-plan-spec.mjs` | Phase and Decisions extraction cases | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 8.5.1 → 8.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 8.6.0 entry | Modified |

## How it works

The spec format is bidirectional: `buildDigest` is documented as the exact inverse of `parseSpecMarkdown`, and `extractSections` derives a spec back out of rendered HTML for legacy plans. This meant any new grouping level had to be carried at four sites — parse, render, extract-from-DOM, re-emit — or it would silently disappear on the next round trip. The implementation lands at all four in steps 1 through 5, followed by a bundle re-copy in step 6 so the plugin's own scripts stay byte-identical to the repo-root originals.

`parseSpecMarkdown` now splits the Steps chunk on `^###\s+Phase:` lines before the existing `split(/\n(?=\d+\.\s)/)` numbered-item split. Previously, a phase heading placed between two steps would be silently appended to the preceding step's `Verify:` text with no parse error. After the fix, `sections.phases` is an ordered array of `{ name, firstStep, lastStep }` objects, or `null` when no heading is present. `buildDigest` emits a `### Phase: <name>` line above the first step of each phase, keeping the flat numbering unchanged so a phase addition to an in-progress plan never invalidates existing `[x]` markers.

The renderer in `build-plan-html.mjs` groups step cards under `<div class="phase-group" data-phase="…"><h3>…</h3>` wrappers. The progress bar JavaScript counts `.step-card` elements with `querySelectorAll` — nesting cards inside the wrappers rather than replacing the flat selector was deliberate to avoid silently zeroing the progress count. The phase heading introduces an `<h3>` into the outline, which runs h1 (page title) → h2 (section) → h3 (phase) with no skipped level, preserving screen-reader navigation. `extractSections` reads phase names back out of the `data-phase` attribute, and `stripHeading` was intentionally left stripping only h2 because step cards are sliced at their own div boundaries, so a phase h3 can never reach a step's action text.

The `## Decisions` section is a bullet list that persists independently of step completion state. It is parsed as `sections.decisions`, re-emitted by `buildDigest`, recovered by `extractSections`, rendered by a `sectionCard` call placed after Context, and given a `SECTION_CHROME` entry that adds a sidebar nav item. The ledger's purpose is durable record of settled choices so a resumed session in a fresh context window does not re-litigate decisions already made in an earlier session.

`build/SKILL.md` Step 2 was rewritten as a phase checkpoint loop. When the spec declares phases, the skill implements one phase, runs its verify gate, appends any decisions made to `## Decisions`, and reaches the boundary offer — three options presented via `AskUserQuestion`: compact and continue, stop for later, or continue without compacting. The compact option prints the `/compact` command with a focus instruction naming the spec path and the phase just finished, then stops — `/compact` is a user-typed CLI built-in, not a callable tool, so the skill can only recommend it. The `--continue` flag pushes straight through phase boundaries for unattended runs. For specs with no phases, Step 2 reads as a single uninterrupted walk. The boundary contract in both `build` and `finalize-plan` is guarded by a prose grep in `test-plan-phases.mjs`, following the pattern established by `test-exitplanmode-guard.sh`. The checkpoint loop detail lives in `build/references/phase-checkpoints.md` rather than inline in `SKILL.md` because the core was at the 598-of-600-word ceiling enforced by `test-progressive-disclosure.sh`.

## How to use it

Add phase headings to any plan spec to group steps into checkpoint units:

```markdown
## Steps

### Phase: Setup

1. Create the config file. Why: … Verify: …
2. Wire the provider. Why: … Verify: …

### Phase: Build

3. Implement the feature. Why: … Verify: …
```

Record decisions as they are made:

```markdown
## Decisions

- Chose `### Phase:` headings over `phases:` frontmatter ranges — headings survive step insertion.
- The Decisions card renders so it is visible on the plan page and in the gallery.
```

Run the build skill against a phased plan:

```bash
/plan-agent:build docs/plans/<slug>.md
# stops at each phase boundary with the three-option prompt
# use --continue to push through all phases in one pass
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-plan-phase-checkpoints.md](plans/add-plan-phase-checkpoints.md)
