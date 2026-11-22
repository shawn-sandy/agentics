# Make the plan the dispatch contract

> `### Lane: <name> (owns: ...; after: ...)` groupings in plan specs declare which steps are independent; `build` runs one worktree-isolated agent per lane and merges lane branches in dependency order, delivering a Workflow-engine escalation path and a measured pilot for the new default.

<!-- generated:start -->

**Status:** Shipped 2026-09-09 **Plan:** [add-lane-orchestration.md](plans/add-lane-orchestration.md)
**Type:** feature

## What shipped

- Added `### Lane: <name> (owns: ...; after: ...)` parsing to `scripts/lib/plan-spec.mjs`: sections.lanes returned as `{ name, owns, after, firstStep, lastStep }[]`; a `### Phase:` inside a lane stays a checkpoint; lane headings round-trip verbatim through `buildDigest`.
- Added `--check` ownership rules to `scripts/build-plan-html.mjs`: overlapping `owns:`, nested globs across lanes, unknown `after:`, `after: lead`, cyclic dependencies, and unlaned steps each exit 1 naming the lane; a dead-glob warns with exit 0; `--lanes` flag prints lanes and steps as JSON.
- Rendered lane surfaces in `scripts/lib/plan-shell.mjs`: text-labeled lane chip on each step card, Lanes panel between Files and Steps, one "Copy worker brief — lane <name>" row per lane in the More-ways drawer, `plan-lanes` meta tag carrying JSON.
- Rewrote `build/SKILL.md` Step 2 as a dispatcher: 2+ lanes uses `references/dispatch-lanes.md`; 1 lane, `workflow: never`, or `--sequential` takes the sequential path unchanged; flags `--max` (default 3, cap 5), `--worker-model`, and `--sequential` added.
- Added `kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md`: dispatch sequence, worker brief template, ownership audit via `git diff --name-only`, per-lane progress table, merge order, conflict-stop rule, failed-lane re-dispatch via fresh fork.
- Added `kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs`: Workflow-engine escalation selected at 6+ lanes or `workflow: always`; wave ordering from `after:` edges; LANE_REPORT schema.
- Added `tests/plan-lanes.test.mjs` and `tests/implement-workflow.test.mjs` covering parse, round-trip, --check rules, --lanes JSON shape, no-lanes byte-stability, wave ordering, and selection gate.
- Updated `implementation-plan` guidelines (section-catalog, right-sizing, planning-principles, SKELETON.md) with lane grammar, two-lane-plus-lead example, and "a lane is a deliverable" principle.
- Updated `plan-reviewer-completeness` and `plan-reviewer-risk` agents with one-file-one-owner and lane-independence checks.
- Passed `--sequential` in `build-fleet/SKILL.md` to prevent nested worktree dispatch.
- Bumped `plan-agent` from 9.13.2 through four minor versions (9.14.0–9.17.0) and 9.17.1 patch with measured pilot numbers.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Lane parsing and round-trip | Modified |
| `scripts/build-plan-html.mjs` | --check rules, --lanes flag, workflow gate | Modified |
| `scripts/lib/plan-shell.mjs` | Lane chip, Lanes panel, worker brief drawer row | Modified |
| `kit/plugins/plan-agent/scripts/` (three files) | Byte-identical copies | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Step 2 dispatcher branch, flags | Modified |
| `kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md` | Dispatch sequence reference | Created |
| `kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs` | Workflow-engine escalation | Created |
| `kit/plugins/plan-agent/commands/fix.md` | Agent + Artifact in allowed-tools | Modified |
| `kit/plugins/plan-agent/commands/refactor.md` | Agent + Artifact in allowed-tools | Modified |
| `kit/plugins/plan-agent/skills/build-fleet/SKILL.md` | --sequential flag | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Lane-split pass, Align question | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | `### Lane:` grammar | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md` | Chain-vs-lanes case split | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md` | "A lane is a deliverable" | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Two-lane-plus-lead example | Modified |
| `kit/plugins/plan-agent/skills/build/references/phase-checkpoints.md` | Chain-vs-lanes case split | Modified |
| `kit/plugins/plan-agent/agents/plan-reviewer-completeness.md` | One-file-one-owner check | Modified |
| `kit/plugins/plan-agent/agents/plan-reviewer-risk.md` | Lane-independence check | Modified |
| `tests/plan-lanes.test.mjs` | Parse, round-trip, --check, --lanes, stability | Created |
| `tests/implement-workflow.test.mjs` | Wave ordering, LANE_REPORT, selection gate | Created |
| `.claude-plugin/marketplace.json` | Four minor bumps + 9.17.1 patch | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Four entries + 9.17.1 patch with pilot numbers | Modified |

## How it works

A `### Lane: <name> (owns: <glob>[, ...][; after: <lane>[, ...]])` heading inside `## Steps` groups steps into independent work units. The renderer validates the split at authoring time with `--check` — overlapping ownership, unknown dependencies, cycles, and unlaned steps all fail with the offending lane named. `--lanes` outputs the validated split as JSON for the dispatcher to consume without re-parsing Markdown.

`build` Step 2 branches on lane count: 1 lane or `--sequential` takes the existing sequential path unchanged. At 2+ lanes the dispatcher commits the spec on the plan branch (`chore(plan): start <stem>`) before the first dispatch (subagent worktrees fork from committed state only), then dispatches one worktree-isolated Sonnet worker per wave of lanes whose `after:` dependencies have all merged — up to `--max` (default 3) concurrent agents. Each worker runs only the steps in its brief, commits on a `<plan-branch>--<lane>` branch, and exits. The lead merges each lane branch `--no-ff` in dependency order, audits `git diff --name-only` against `owns:` before merging, and runs the completion gates once on the merged tree.

Backward compatibility is enforced by test: a no-lanes spec must reproduce the pre-9.14.0 output byte-for-byte (no chips, no Lanes panel, no briefs, no plan-lanes meta). The file-count workflow gate is preserved for lane-free specs; lane-count semantics (`auto` at 2+, `never`, `always`) apply only when lanes are present.

The Phase 4 Workflow-engine escalation (`implement-workflow.mjs`) mirrors `review-workflow.mjs` and is selected at 6+ lanes or `workflow: always`. The measured pilot ran the same three-lane plan in two fresh sessions: dispatch used 466,207 worker tokens in 651 s for the lane work; sequential used 12,423,454 tokens (cache reads included) in 411 s for the lane work / 1,531 s for the whole session (the two figures are not the same measure).

## How to use it

Add `### Lane:` groupings inside `## Steps` to declare independent work units. Each lane needs at least `owns:` (file globs its worker may touch) and optionally `after:` (prerequisite lanes):

```markdown
### Lane: parser (owns: scripts/lib/plan-spec.mjs)
### Lane: renderer (owns: scripts/lib/plan-shell.mjs; after: parser)
### Lane: tests (owns: tests/plan-lanes.test.mjs; after: parser)
### Lane: lead (owns: kit/plugins/plan-agent/CHANGELOG.md, .claude-plugin/marketplace.json)
```

Validate the split with `node scripts/build-plan-html.mjs <spec>.md --check`, inspect it with `--lanes`. Then run `/plan-agent:build` — it dispatches workers automatically when 2+ lanes are present. Pass `--sequential` to disable dispatch, `--max` to change concurrency (default 3, cap 5), and `--worker-model` to override the worker model.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `c3514b71` | 2026-09-09 | docs(plan-agent): publish the pilot's --sequential figures and complete the lane plan (9.17.1) (#629) |

<!-- generated:end -->

## References

- Plan: [add-lane-orchestration.md](plans/add-lane-orchestration.md)
