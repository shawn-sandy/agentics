# Make the plan the dispatch contract

> Delivers lane-based parallel dispatch for plan-agent: a plan spec now declares which step groups are independent, the renderer validates the split, and build dispatches one worktree-isolated worker per lane — while old plans render byte-for-byte unchanged.

<!-- generated:start -->

**Status:** Shipped 2026-09-09  **Plan:** [add-lane-orchestration.md](plans/add-lane-orchestration.md)
**Type:** feature

## What shipped

- Added `### Lane: <name> (owns: ...; after: ...)` grammar to `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` — parsed into `sections.lanes` with `name`, `owns`, `after`, `firstStep`, `lastStep`; re-emitted verbatim in `buildDigest()` for byte-stable round-trips.
- Added `--check` ownership validation to `kit/plugins/plan-agent/scripts/build-plan-html.mjs`: overlapping `owns:`, nested `owns:` globs across lanes, unknown `after:`, `after: lead`, dependency cycles, and unlaned steps in a laned spec each exit 1 naming the offending lane; a dead `owns:` glob warns with exit 0. Added `--lanes` JSON output for programmatic consumption.
- Scoped the file-count `workflow:` gate to lane-free specs; added lane-count `workflow:` semantics (`auto` dispatches at 2+ lanes, `never` suppresses, `always` keeps).
- Added lane UI surfaces to `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs`: text-labeled lane chip on each step card, a Lanes panel card between Files and Steps with sidebar nav, one "Copy worker brief — lane `<name>`" row per lane in the More-ways drawer, and a `plan-lanes` meta tag.
- Extended `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` with a lane-split pass in Step 2 (five authoring rules: disjoint paths, chain-per-lane, same-file → one lane, shared files → `lead`, 2–5 lanes), lane confirmation in Align (Step 5), and Step 8 dispatch wording.
- Updated `guidelines/section-catalog.md`, `reference/SKELETON.md`, `guidelines/planning-principles.md`, and `guidelines/right-sizing.md` with `### Lane:` grammar, examples, and the "a lane is a deliverable" principle.
- Added dispatch sequence to `kit/plugins/plan-agent/skills/build/SKILL.md` Step 2: branches on lane count; added `--sequential`, `--max` (default 3, cap 5), and `--worker-model` flags; added `Agent` to `allowed-tools`; propagated the same fix to `commands/fix.md` and `commands/refactor.md`.
- Created `kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md` with the full dispatch reference: guards, wave loop, ownership audit, merge order, worker brief template, LANE REPORT schema, conflict stop, and failed-lane choices.
- Created `kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs` — Workflow-engine escalation selected at 6+ lanes or `workflow: always`.
- Added lane paragraphs to `agents/plan-reviewer-completeness.md` and `agents/plan-reviewer-risk.md`.
- Passed `--sequential` in `build-fleet`'s dispatch prompt to prevent nested worktrees.
- Added `tests/plan-lanes.test.mjs` and `tests/implement-workflow.test.mjs`.
- Delivered as four release commits (9.14.0–9.17.0) on one branch, merged as PR #628. A 9.17.1 patch added the sequential pilot figures to the CHANGELOG.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/lib/plan-spec.mjs` | Lane parser and digest emitter | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | `--check` rules, `--lanes` output, workflow gate | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Lane UI: chips, panel, drawer rows, meta tag | Modified |
| `tests/plan-lanes.test.mjs` | Parse, round-trip, check rules, JSON shape, no-lanes stability | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Lane-split pass, Align question, Step 8 wording | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | `### Lane:` grammar and syntax | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md` | Two-lane plus lead example | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Dispatch branch, flags, Agent in allowed-tools | Modified |
| `kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md` | Dispatch sequence reference | Created |
| `kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs` | Workflow-engine escalation script | Created |
| `tests/implement-workflow.test.mjs` | Wave ordering, LANE REPORT schema, selection gate | Created |
| `.claude-plugin/marketplace.json` | Four minor bumps (9.14.0–9.17.0) | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Four entries with pilot numbers | Modified |

## How it works

**Phase 1 — Renderer (9.14.0):** `parseSpecMarkdown()` in `plan-spec.mjs` recognizes the new `### Lane:` heading inside `## Steps`, returns `sections.lanes`, and re-emits lane headings verbatim in `buildDigest()`. Lane-free plans round-trip byte-identically — the parser only activates when `### Lane:` headings are present. The `--check` flag in `build-plan-html.mjs` validates ownership rules at authoring time using Node's `path.matchesGlob()`, setting a documented Node 22 floor. `--lanes` outputs JSON for programmatic consumption by the dispatcher.

**Phase 2 — Authoring (9.15.0):** The `implementation-plan` skill's Step 2 gained a lane-split pass with five rules: disjoint owned paths, each lane's steps form a chain, same-file steps stay in one lane, shared files go to `lead`, and aim for 2–5 lanes. The Align step (Step 5) presents a lane-confirmation question before proceeding, because dispatch never re-derives the split — it dispatches exactly what the human approved. `section-catalog.md` documents the grammar; `SKELETON.md` provides a worked two-lane example.

**Phase 3 — Dispatch (9.16.0):** `build` Step 2 branches on lane count. For 2+ laned specs, the dispatcher runs `plan-agent-render --check` then `--lanes`, commits the spec, and dispatches one background `Agent(isolation: "worktree")` per lane up to `--max` concurrency (default 3, hard cap 5). Each worker receives a fully-substituted brief (no `${CLAUDE_PLUGIN_ROOT}` placeholders), commits on `<plan-branch>--<lane>`, and reports via a fixed LANE REPORT block. After each completion the dispatcher audits `git diff --name-only` against the lane's `owns:` patterns, merges `--no-ff` in `after:` order, and dispatches newly unblocked lanes. The `lead` lane always runs in the main session. `commands/fix.md` and `commands/refactor.md` received the `Agent` + `Artifact` addition at the same time to keep their `allowed-tools` in lockstep with `build`.

**Phase 4 — Pilot (9.17.0):** The Workflow-engine escalation (`implement-workflow.mjs`) was authored as a three-lane plan and built via the dispatcher — the first plan built with the new system. The measured pilot numbers in the 9.17.0 CHANGELOG entry: dispatch used 466,207 worker tokens and 651 s for the three lanes; sequential used 12,423,454 tokens (with cache reads) and 411 s for the lanes themselves, 1,531 s for the whole session. These two figures are not the same measure (worker tokens vs. full-session tokens), stated in the entry.

## How to use it

```
/plan-agent:build                     # dispatch by plan shape (auto-lanes if present)
/plan-agent:build --sequential        # force sequential regardless of lanes
/plan-agent:build --max 2             # cap concurrency at 2 lanes
/plan-agent:build --worker-model opus # override worker model
```

Plans authored with `implementation-plan` can include `### Lane:` groupings:
```markdown
### Lane: core (owns: src/core/**; after:)
### Lane: tests (owns: tests/**; after: core)
### Lane: lead (owns: CHANGELOG.md, README.md)
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `c3514b71` | 2026-09-09 | docs(plan-agent): publish the pilot's --sequential figures and complete the lane plan (9.17.1) (#629) |
| `f3be0249` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `e6cc1796` | 2026-09-09 | docs: add plan-agent lane orchestration proposal, plan, and design canvas (#627) |

<!-- generated:end -->

## References

- Plan: [add-lane-orchestration.md](plans/add-lane-orchestration.md)
- Related: `docs/prompts/proposal-orchestrate-plan-implementation.md` — 16 locked decisions
- Related: `kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md` — dispatch sequence reference
