# Right-Sizing

Match the plan's depth to the work. The required core (title, objective,
steps, acceptance criteria, verification) is always present; everything else
scales with scope. Pick the closest profile, then adjust — profiles are
starting points, not templates.

## Minimal — chores, typo-class fixes, dependency bumps

Single concern, 1–2 files, no judgment calls.

- 1–3 steps; terse whys ("the lockfile must match" is enough).
- Omit Context and Tests tier extras; a Tier 2 objective test still applies
  when nothing runnable changes, Tier 1 with one unit test when code changes.
- 2–3 acceptance criteria; Verification is one short paragraph.
- No `glance`, no `workflow`. Interview: Round 1 only (or skipped via
  `--quick`).

## Standard — features and multi-file fixes

A feature with UI + logic, a fix spanning 2 domains, a focused refactor.

- 3–6 steps at one-action granularity; include `## Files` and `## Context`.
- Tests: Tier 1 with the objective test plus the unit/integration/E2E types
  the steps actually warrant.
- Set `glance` — a reader-facing summary earns its place once a plan has
  more than a handful of steps.
- Interview: Rounds 1 + 2 (UI signals always pull in Round 2, even for
  short plans).

## Deep — architecture changes, migrations, spikes

Cross-cutting work, 3+ domains, decisions that are expensive to reverse.

- 6–10 steps; past that, group them into phases rather than splitting the
  objective (see **Phased** below).
- Context carries the decision story: options weighed, why this approach,
  known risks with mitigations. Open questions go to the interview or an
  `## Unresolved Questions` markdown section — never planned around.
- Tests: full Tier 1 spread; Verification walks a real end-to-end scenario.
- When the work is parallelizable — independent file sets, repetitive
  per-file changes (migrations, renames, sweeps), steps that never touch
  each other's files — declare it as `### Lane:` groupings (see **Laned**
  below) rather than reaching for `workflow: always`. `build` dispatches by
  lane count; the renderer's file-count heuristic only ever decided a
  paste-prompt, and only for lane-free specs.
- Consider `effort: high` explicitly when the interview classified the plan
  as complex but the raw step/file counts alone would read as medium.
- Interview: Rounds 1 + 2 + 3.

## Chain or lanes? The case split

Long work comes in two shapes, and each has its own tool:

- **A chain** — step seven depends on a choice made in step two. Its limit is
  *context*, not parallelism; phases bound it (below).
- **Independent lanes** — groups of steps that touch disjoint files and can
  each be verified on their own. Their limit is *wall-clock*; lanes fan them
  out (**Laned**, further below).
- **Both** — a plan with two independent lanes whose steps are each a long
  chain. Lanes are the outer grouping; phases go *inside* a lane as that
  worker's checkpoints.

Fan-out helps exactly one of these shapes. A chain gains nothing from
subagents, and a set of lanes gains nothing from compaction — pick by shape,
not by size.

## Phased — long sequential work that outlasts one context window

A Deep plan whose steps must run **in order**, where step seven depends on a
choice made in step two. The limit here is context, not parallelism.

Reach for phases when any of these hold:

- More than ~10 steps, or steps whose implementation is large enough that
  ten of them will not fit in one session.
- Natural seams where a run of steps ends in something verifiable on its own
  (parse works / render works / docs updated), not mid-refactor.
- Ordered edits to the same file — the exact shape lanes cannot help with,
  because one file has one owner.

Then:

- Group the steps with `### Phase: <name>` headings (syntax in
  `section-catalog.md`). Numbering stays flat; phases are pure grouping.
- 2–5 phases, each ending at a state a fresh session could pick up from. A
  phase that leaves the tree broken is a boundary in the wrong place.
- Add `## Decisions` and write the load-bearing choices into it up front.
  `/plan-agent:build` appends to it at each boundary, so it becomes the record
  the next context window reads instead of re-deriving.
- `/plan-agent:build` stops at each boundary and offers to compact; `--continue`
  pushes straight through. `finalize-plan` will not mark a plan completed while
  any phase still holds an unmarked step.

Splitting into separate plan files is still the answer when the objectives are
genuinely different — phases are for one objective that is simply long.

## Laned — independent work that fans out

A Standard or Deep plan whose steps fall into groups that touch **disjoint
files** — a parser and the skill that documents it, three sweeps over three
directories, a script and its tests. `/plan-agent:build` runs one
worktree-isolated worker per lane and merges the lane branches back in
`after:` order; the human confirms the split in Align before anything runs.

Reach for lanes when all of these hold:

- Two or more groups of steps whose owned paths do not overlap — no path or
  glob in two lanes, no glob nested inside another lane's.
- Each group ends in a `Verify:` that holds on its own branch before the
  others merge (`planning-principles.md`, "A lane is a deliverable").
- The shared files — `CHANGELOG.md`, `README.md`, `marketplace.json`,
  generated indexes — fit in one trailing `lead` lane that runs last in the
  main session.

Then:

- Group the steps with `### Lane: <name> (owns: …; after: …)` headings
  (syntax and the `--check` rules in `section-catalog.md`). Numbering stays
  flat; lanes are pure grouping. 2 to 5 lanes; never force lanes on a chain.
- Declare every real dependency as an `after:` edge; an undeclared one shows
  up as a merge conflict or a lane that fails in isolation.
- Leave `workflow:` at `auto` — two or more lanes is what makes `build`
  dispatch. `never` keeps a laned plan sequential; `always` also asks for the
  Workflow-engine escalation.
- Long chains inside a lane take `### Phase:` headings inside that lane.

Phases have a second, unrelated use: the RED/GREEN/VERIFY/SHIP shape in
`red-green-verify.md` groups by discipline rather than by context budget, and
applies to plans of any size that touch code with a test runner behind it. Same
headings, same flat numbering.

The two rationales cannot share one heading run — a plan does not get
`### Phase: Parse` and `### Phase: RED` side by side, because the reader cannot
tell what a boundary means. When long *sequential* work also wants the RGV
discipline, **RGV wins the headings** and the context seams live inside it:
run RED for the whole plan, then GREEN in the order the dependencies demand,
and let `build` stop at the four RGV boundaries. If that makes GREEN too large
for one context window, the objective is genuinely two plans — split it, and
give each its own four phases.

For a **spike** (time-boxed investigation), the steps are the questions to
answer and the verify lines are the evidence to collect; acceptance criteria
state what "we learned enough" means. Keep it Tier 2 unless the spike ships
code.

## Calibration knobs, in one place

| Knob | Minimal | Standard | Deep | Phased | Laned |
|------|---------|----------|------|--------|-------|
| Steps | 1–3 | 3–6 | 6–10 | 10+, in 2–5 phases | 4+, in 2–5 lanes |
| Context | omit | short | decision story | decision story | decision story |
| `## Decisions` | no | no | optional | yes | optional |
| Files section | optional | yes | yes | yes | yes — it is what `owns:` is checked against |
| Tests | objective only / 1 unit | Tier 1, applicable types | full Tier 1 spread | full Tier 1 spread | full Tier 1 spread, one verify per lane |
| `glance` | no | yes | yes | yes | yes |
| `### Lane:` headings | no | when 2+ disjoint file sets | when 2+ disjoint file sets | inside a lane if both | yes |
| `workflow` key | no | rarely | rarely | usually `never` | `auto`; `never` opts out |
| Red-green-verify | rarely | when code + a runner | when code + a runner | wins the headings; see above | inside each lane |
| Interview rounds | 1 | 1–2 | 1–3 | 1–3 | 1–3 |
