# Make the plan the dispatch contract

> Delivers four phases of lane-based parallel plan execution: lane parsing in the renderer, lane authoring in implementation-plan, a lane dispatcher in build, and a measured Workflow-engine pilot — shipped as plan-agent 9.14.0–9.17.0.

<!-- generated:start -->

**Status:** Shipped 2026-09-09  **Plan:** [add-lane-orchestration.md](plans/add-lane-orchestration.md)
**Type:** feature

## What shipped

- **Phase 1 (9.14.0):** Lane parsing in `plan-spec.mjs` — `### Lane: <name> (owns: ...; after: ...)` grammar parsed from `## Steps`; `--check` ownership rules (no overlapping owns, no nested globs across lanes, no unknown after, no `after: lead`, no cycles, no unlaned steps); `--lanes` JSON output; lane surfaces rendered in `plan-shell.mjs` (chips, Lanes panel, per-lane worker briefs, `plan-lanes` meta tag); backward compatibility proven by byte-identical no-lanes round-trip
- **Phase 2 (9.15.0):** Lane authoring in `implementation-plan/SKILL.md` — five-rule lane-split pass in Step 2, lane confirmation in Align, lane grammar documented in `section-catalog.md` and `SKELETON.md`, `planning-principles.md` updated, `right-sizing.md` and `phase-checkpoints.md` rewritten as chain-vs-lanes case split; lane paragraphs in `plan-reviewer-completeness.md` and `plan-reviewer-risk.md`
- **Phase 3 (9.16.0):** Lane dispatcher in `build/SKILL.md` — Step 2 branches on lane count; `references/dispatch-lanes.md` with the full dispatch sequence (guards, wave loop, ownership audit, merge order, worker brief template, LANE REPORT verification, conflict/failed-lane handling); `--sequential`, `--max`, `--worker-model` flags; `build-fleet` passes `--sequential` to prevent nested dispatch; `Agent` added to `allowed-tools` in `build/SKILL.md`, `fix.md`, and `refactor.md`
- **Phase 4 (9.17.0):** Workflow-engine escalation — `implement-workflow.mjs` written as a three-lane plan built by the new dispatcher; `tests/implement-workflow.test.mjs` covering wave ordering, LANE REPORT schema, selection gate; measured pilot numbers published in CHANGELOG (dispatch: 466,207 worker tokens, 651 s; sequential: 12,423,454 tokens with cache reads, 411 s for three-lane work)

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Parser — `### Lane:` grammar, sections.lanes, digest round-trip | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Build script — `--check` rules, `--lanes` JSON, workflow gate, lane-count semantics | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Renderer — lane chips, Lanes panel, per-lane briefs, plan-lanes meta | Modified |
| `tests/plan-lanes.test.mjs` | Tests — parse, round-trip, check rules, JSON shape, no-lanes byte-stability | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Skill instructions — lane-split pass, Align question, Step 8 wording | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Authoring guide — `### Lane:` grammar beside `### Phase:` | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill instructions — dispatcher branch, flags, Agent in allowed-tools | Modified |
| `kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md` | Dispatch reference — full sequence, brief template, failure rules | Created |
| `kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs` | Workflow escalation — mirroring review-workflow.mjs | Created |
| `tests/implement-workflow.test.mjs` | Tests — wave ordering, LANE REPORT schema, selection gate | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry — four minor bumps (9.14.0–9.17.0) | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes — four entries, Phase 4 carries measured pilot numbers | Modified |

## How it works

A `### Lane: <name> (owns: <glob>[, ...][; after: <lane>[, ...]])` heading inside `## Steps` declares which steps are independent and which files each group owns. The parser in `plan-spec.mjs` reads these headings and returns `sections.lanes` alongside the existing phases structure. Lane headings in a spec with no `### Lane:` entries are simply absent, so the renderer produces byte-identical output for all existing plans.

The `--check` mode in `build-plan-html.mjs` enforces ownership rules at authoring time: each `## Files` path matches at most one lane's `owns:` glob (evaluated with Node 22's `path.matchesGlob`), no two lanes' `owns:` patterns nest, every `after:` names an existing lane and is not `lead`, the dependency graph is acyclic, every step in a laned spec sits under a lane heading. An `owns:` glob matching no `## Files` path warns without failing.

The build dispatcher in `build/SKILL.md` Step 2 branches on lane count. With fewer than 2 lanes, `workflow: never`, or `--sequential`, it takes the unchanged sequential path. With 2+ lanes it follows `references/dispatch-lanes.md`: commits the spec on the plan branch, runs one `Agent` call per lane (up to `--max` concurrently, default 3), verifies each LANE REPORT against the lane branch's git diff, audits ownership, merges `--no-ff` in `after:` order, then runs the `lead` lane in the main session.

The Phase 4 pilot dogfooded the dispatcher by building the Workflow-engine escalation plan itself as a three-lane spec. The measured token multiplier (~37x on worker tokens vs sequential, with cache reads blurring the absolute comparison) is recorded in the 9.17.0 CHANGELOG entry.

## How to use it

Lane authoring is integrated into `/plan-agent:implementation-plan` Step 2. The skill's five rules guide the split: disjoint file ownership, steps as a chain per lane, shared files in the `lead` lane, 2–5 lanes, no forced lanes on a chain.

```
/plan-agent:build                        # dispatches lanes if 2+ lanes present
/plan-agent:build --sequential           # always sequential, regardless of lane count
/plan-agent:build --max 5                # raise concurrency cap (default 3)
/plan-agent:build --worker-model sonnet  # override worker model
```

The renderer's `--check` and `--lanes` flags are available via the `plan-agent-render` CLI:

```
plan-agent-render <spec> --check         # validate lane ownership rules
plan-agent-render <spec> --lanes         # print lanes as JSON for the dispatcher
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `1c31569` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `19a9ae8` | 2026-09-20 | fix(plan-agent): lead the goal prompt with `/goal` (9.18.1) (#637) |
| `77aa33e` | 2026-09-12 | fix(plan-agent): lead the goal prompt with "Goal:" (9.17.2) (#631) |
| `c3514b7` | 2026-09-09 | docs(plan-agent): publish the pilot's --sequential figures and complete the lane plan (9.17.1) (#629) |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `e6cc179` | 2026-09-09 | docs: add plan-agent lane orchestration proposal, plan, and design canvas (#627) |
| `22e2280` | 2026-08-30 | fix(plan-agent): unbreak the build completion gate for artifact-only plans (9.10.1) (#610) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-lane-orchestration.md](plans/add-lane-orchestration.md)
- Proposal: `docs/prompts/proposal-orchestrate-plan-implementation.md` — 16 locked decisions; Appendices A–E
- Design: https://claude.ai/code/artifact/1dff40ee-ae10-4aa2-8ad5-a242368b01fe
