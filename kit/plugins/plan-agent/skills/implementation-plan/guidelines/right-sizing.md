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

- 6–10 steps; if you need more, the objective is probably two plans — split
  it.
- Context carries the decision story: options weighed, why this approach,
  known risks with mitigations. Open questions go to the interview or an
  `## Unresolved Questions` markdown section — never planned around.
- Tests: full Tier 1 spread; Verification walks a real end-to-end scenario.
- Consider `workflow: always` when the work is parallelizable: 5+ files across
  3+ directories, repetitive per-file changes (migrations, renames, sweeps),
  independent steps, or steps needing cross-checking review. The renderer's
  own heuristic only sees file/directory counts — set the key explicitly for
  the other cases.
- Consider `effort: high` explicitly when the interview classified the plan
  as complex but the raw step/file counts alone would read as medium.
- Interview: Rounds 1 + 2 + 3.

For a **spike** (time-boxed investigation), the steps are the questions to
answer and the verify lines are the evidence to collect; acceptance criteria
state what "we learned enough" means. Keep it Tier 2 unless the spike ships
code.

## Calibration knobs, in one place

| Knob | Minimal | Standard | Deep |
|------|---------|----------|------|
| Steps | 1–3 | 3–6 | 6–10 |
| Context | omit | short | decision story |
| Files section | optional | yes | yes |
| Tests | objective only / 1 unit | Tier 1, applicable types | full Tier 1 spread |
| `glance` | no | yes | yes |
| `workflow` key | no | rarely | when parallelizable |
| Interview rounds | 1 | 1–2 | 1–3 |
