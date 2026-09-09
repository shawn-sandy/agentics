---
status: in-progress
type: feature
created: 2026-09-09
effort: high
workflow: never
artifact-url: https://claude.ai/code/artifact/8f06405f-b026-4b37-8fe4-2d55b9cbfef5
issue: https://github.com/shawn-sandy/agentics/issues/626
design: https://claude.ai/code/artifact/1dff40ee-ae10-4aa2-8ad5-a242368b01fe
design-dir: docs/designs/add-lane-orchestration
glance: A plan today is something one agent reads top to bottom; after this, the plan itself declares which groups of steps are independent (lanes) and build runs one isolated worker per lane, merging their branches back in order. Done when a laned plan builds itself in parallel, old plans render byte-for-byte unchanged, and the pilot publishes measured time and token numbers against a sequential run.
---

# Plan: Make the plan the dispatch contract

## Objective

Deliver the four phases of the orchestrate-plan-implementation proposal in roadmap order — lane parsing in the renderer, lane authoring in implementation-plan, a lane dispatcher in build, and a measured Workflow-engine pilot — one phase per PR, each with its own minor version bump (9.14.0 through 9.17.0).

## Context

Claude Code already ships every engine plan-agent could want for parallel work: worktree-isolated subagents, the Workflow runtime, background agents. plan-agent even drives two of them (the review-plan panel, build-fleet). What no engine gets from a plan today is a unit it can hand to a worker: a spec step is `action / Why: / Verify:` with no owned files and no dependency edge, and the build skill runs every step itself, in order, with neither Agent nor Workflow in its allowed tools.

This plan executes the converged proposal at docs/prompts/proposal-orchestrate-plan-implementation.md (16 locked decisions; treat them as settled). One new grouping, `### Lane: <name> (owns: ...; after: ...)`, declares which steps are independent and which files each group owns. The renderer parses and validates it, implementation-plan authors it, and build Step 2 becomes a dispatcher that runs one worktree-isolated Sonnet worker per lane and merges lane branches in dependency order. Backward compatibility is non-negotiable: a spec with no `### Lane:` heading renders, builds, and round-trips exactly as today.

Known risks, each with its mitigation in the steps: a bad split costs more than a sequential run (the human confirms lanes in Align, `--check` rejects overlap, two reviewers audit, the pilot measures before the default is trusted); subagent worktrees fork from the default branch (build commits the spec on the plan branch before the first dispatch, and the existing staleness guard stays); token cost multiplies roughly 7x to 15x on fan-out (the pilot publishes real numbers, and `--sequential` is always one flag away); in manual permission mode worker prompts bubble to the lead session (build warns once, never silently degrades).

This plan is itself authored sequential — lanes do not exist until Phase 1 ships. The Phase 4 pilot plan (the Workflow-engine escalation) is the first plan ever authored with `### Lane:` headings, and building it with the new dispatcher is the measurement.

## Decisions

- The split lives in the plan spec: implementation-plan authors `### Lane:` groupings with `owns:` and `after:`, the human reviews the split in Align, and build dispatches against it without ever re-splitting — a worker brief derived from anything but the spec would drift from what the human approved.
- Engine is the Agent tool with `isolation: "worktree"`, `run_in_background: true`, `subagent_type: "general-purpose"` — exactly the shape build-fleet already proves; a Workflow script is the escalation for 6+ lanes or `workflow: always`; agent teams (experimental, no isolation) and /batch (re-splits, one PR per unit) are rejected.
- The lead merges lane branches with `git merge --no-ff` in `after:` order and is the spec's only writer; workers commit on `<plan-branch>--<lane>`, never push, never edit the spec — N branches each editing the spec would conflict on every merge.
- Workers default to Sonnet (`--worker-model` overrides); concurrency defaults to 3, hard-capped at 5 (`--max` overrides) — the docs' cost guidance and build-fleet's proven default.
- build commits the spec on the plan branch (`chore(plan): start <stem>`) before the first dispatch, because subagent worktrees fork from committed state only; Step 6's "leave tree uncommitted" becomes "leave tree committed on the plan branch, unpushed".
- The 4-files/2-directories workflow heuristic is retired as a dispatch trigger but kept as the render gate for lane-free specs, so existing plans render byte-for-byte; once a spec has lanes, `workflow:` keeps its three values with lane-count meaning — `auto` dispatches at 2+ lanes, `never` stays sequential, `always` also emits the /workflows prompt — and the Workflow engine is only ever selected on a 2+ lane plan.
- build-fleet passes `--sequential` to every fleet agent so worktrees never nest inside worktrees; nested dispatch is deferred until the pilot has numbers.
- Each phase ships as its own PR with its own minor bump in .claude-plugin/marketplace.json (9.14.0, 9.15.0, 9.16.0, 9.17.0) — lanes without headings are a no-op, so no phase is breaking.
- Roadmap phases win the step headings over RED/GREEN/VERIFY/SHIP: four independent PRs cannot share one RED phase. The test-first discipline lives inside Phase 1 — step 1 authors the failing suite before any parser code exists.
- `owns:` globs are evaluated with the Node standard library's path matcher (matchesGlob), which sets a documented Node 22 floor for the renderer — zero dependencies beats a hand-rolled matcher that is one more parser to get subtly wrong.
- Backward compatibility is proven by digest round-trip plus zero-lane-markup assertions, not a full-HTML snapshot — a pinned snapshot breaks on every unrelated renderer change and the drift noise would hide real regressions.
- Ownership is enforced twice: --check rejects overlap at authoring time — both listed-path collisions and nested `owns:` globs across lanes, by a pairwise prefix test rather than full glob intersection — and build audits each lane branch's `git diff --name-only` against `owns:` before merging — the LANE REPORT is self-reported, so the boundary the whole model depends on cannot rest on worker discipline alone.
- In a laned spec every step belongs to a named lane or `lead` (an unlaned step is a --check error), `after: lead` is a --check error (lead runs last and owns the shared files), and an `owns:` glob matching no `## Files` path warns without failing (lanes may own paths created during implementation).
- A failed lane re-dispatches by deleting its branch and forking fresh from the current plan branch — a retry never resumes half-done state its own report flagged as failed.
- The pilot's two runs are measured in two fresh sessions, one per run — a single accumulating session cannot attribute tokens cleanly.
- Skill-edit phases verify in a live session started with --plugin-dir and --add-dir, because a plain session runs the pinned plugin snapshot and greenlights against text that is not the working tree's.

## Files

- kit/plugins/plan-agent/scripts/lib/plan-spec.mjs (modified) — parse `### Lane:` headings into sections.lanes; re-emit them verbatim in buildDigest
- kit/plugins/plan-agent/scripts/build-plan-html.mjs (modified) — three --check ownership rules, --lanes JSON output, retire the file-count workflow gate, lane-count `workflow:` semantics
- kit/plugins/plan-agent/scripts/lib/plan-shell.mjs (modified) — lane chip per step card, Lanes panel, one copyable worker brief per lane, plan-lanes meta tag
- tests/plan-lanes.test.mjs (new) — parse, round-trip, check rules, JSON shape, no-lanes byte-stability
- kit/plugins/plan-agent/skills/implementation-plan/SKILL.md (modified) — lane-split pass in Step 2, lane question in Align, Step 8 wording
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md (modified) — `### Lane:` grammar beside `### Phase:`
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/right-sizing.md (modified) — chain-vs-lanes case split
- kit/plugins/plan-agent/skills/implementation-plan/guidelines/planning-principles.md (modified) — "a lane is a deliverable" principle
- kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md (modified) — two-lane plus lead example
- kit/plugins/plan-agent/skills/build/references/phase-checkpoints.md (modified) — same case split as right-sizing
- kit/plugins/plan-agent/agents/plan-reviewer-completeness.md (modified) — one-file-one-owner check paragraph
- kit/plugins/plan-agent/agents/plan-reviewer-risk.md (modified) — lane-independence check paragraph
- kit/plugins/plan-agent/skills/build/SKILL.md (modified) — Step 2 branches into the dispatcher; Agent in allowed-tools; --sequential/--max/--worker-model flags
- kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md (new) — dispatch sequence, worker brief, conflict and failed-lane handling
- kit/plugins/plan-agent/commands/fix.md (modified) — allowed-tools lockstep with build (adds Agent, fixes the missing Artifact)
- kit/plugins/plan-agent/commands/refactor.md (modified) — same lockstep edit
- kit/plugins/plan-agent/skills/build-fleet/SKILL.md (modified) — dispatch prompt passes --sequential
- kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs (new) — Workflow-engine escalation mirroring review-workflow.mjs
- tests/implement-workflow.test.mjs (new) — wave ordering, LANE REPORT schema, selection gate
- .claude-plugin/marketplace.json (modified) — four minor bumps, one per phase
- kit/plugins/plan-agent/CHANGELOG.md (modified) — four entries; the Phase 4 entry carries the measured pilot numbers

## Steps

### Phase: Renderer (9.14.0)

1. [x] Author tests/plan-lanes.test.mjs with failing cases for lane parsing, digest round-trip, the --check rules, the --lanes JSON shape, and two lane-free fixtures — one asserting the digest round-trips byte-stably and the rendered HTML contains zero lane markup (no chips, no Lanes panel, no briefs, no plan-lanes meta), one with four files across two directories asserting its plan-workflow meta still renders under today's file-count gate. Why: the suite is the contract for the new grammar, and targeted compat assertions survive unrelated renderer changes where a full-HTML snapshot would drown real regressions in drift noise — tests/run-all.sh auto-discovers any tests/**/*.test.mjs, so nothing needs wiring. Verify: `node tests/plan-lanes.test.mjs` exits non-zero with lane cases failing for missing lane support (not import errors) — paste the failure output.
2. [x] Teach parseSpecMarkdown() in kit/plugins/plan-agent/scripts/lib/plan-spec.mjs to recognise `### Lane: <name> (owns: <glob>[, ...][; after: <lane>[, ...]])` inside `## Steps`, returning sections.lanes as `{ name, owns, after, firstStep, lastStep }` alongside the existing phases (a `### Phase:` inside a lane stays a checkpoint; numbering stays flat and global), and re-emit lane headings verbatim in buildDigest(). Why: the parser is the single source every consumer reads, and the digest round-trip is the byte-stability contract every existing plan relies on. Verify: the parse and round-trip cases in tests/plan-lanes.test.mjs pass and the no-lanes fixture still produces byte-identical output.
3. [x] Add the lane --check rules to kit/plugins/plan-agent/scripts/build-plan-html.mjs — every `## Files` path matches at most one lane's `owns:` (evaluated with node:path matchesGlob, documenting the Node 22 floor it implies), no two lanes' `owns:` patterns nest (the wildcard-free prefix of one must not match the other's glob, so `scripts/**` beside `scripts/lib/**` fails naming both lanes even when no listed file sits in the overlap — a pairwise prefix test, not full glob intersection), every `after:` names an existing lane and never `lead`, the `after:` graph is acyclic, every step in a laned spec sits under a lane heading, and the reserved `lead` lane may omit `owns:`; an `owns:` glob matching no `## Files` path prints a warning without failing (lanes may own paths created during implementation); add a `--lanes` flag that prints sections.lanes and each lane's steps as JSON. Why: --check makes a bad split fail at authoring time with the offending lane named — explicit membership beats implicit, `after: lead` would deadlock a lane that owns the shared files, and a dead glob is usually a typo worth flagging — while --lanes lets the dispatcher consume lanes without hand-parsing Markdown. Verify: the check-rule cases pass — overlap, nested globs, unknown after, after lead, cycle, and unlaned step each exit 1 naming the lane, and a dead glob warns with exit 0.
4. [x] Scope the `fileCount >= 4 && dirCount >= 2` workflow gate in build-plan-html.mjs to lane-free specs and add lane-count semantics beside it — with no `### Lane:` heading the gate decides the prompt exactly as today; with lanes, `auto` emits the workflow prompt at 2+ lanes, `never` suppresses it, `always` keeps it, `true`/`false` stay accepted as aliases. Why: lane-free plans must render byte-for-byte, so the old gate survives for them, while a laned plan's declared shape — not incidental file spread — is what licenses fan-out, and build dispatches by lane count alone. Verify: the prompt-gating cases pass — a two-lane spec under `auto` emits the plan-workflow meta, a one-lane spec does not, and the lane-free four-file fixture still does.
5. [x] Render the lane surfaces in kit/plugins/plan-agent/scripts/lib/plan-shell.mjs: a text-labeled lane chip on each step card using the existing chip palette in both themes (never color alone), a Lanes panel as its own card between Files and Steps with a sidebar nav entry and real list semantics (one list item per lane, nested lists for owns and after, like the file tree), one "Copy worker brief — lane <name>" row per lane in the More-ways drawer alongside the implement/goal/workflow rows, and a `plan-lanes` meta tag carrying the JSON. Why: the split is what the human reviews before any agent runs, so it earns first-class placement, and reusing the proven chip tokens and drawer copy-row pattern means nothing new to contrast-audit and each button announces which lane it copies. Verify: the rendered laned fixture contains the labeled chips, the panel card with nav entry, one named drawer row per lane, and the meta; the no-lanes fixture output carries none of them.
6. [x] Bump plan-agent to 9.14.0 in .claude-plugin/marketplace.json, write the CHANGELOG entry, run the merge gate, and open the Phase 1 PR. Why: each phase ships as its own minor bump, and the CI guard fails any plugin edit whose version does not exceed the base branch. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` and `bash scripts/verify.sh` both exit 0.

### Phase: Authoring (9.15.0)

7. Add the lane-split pass to Step 2 of kit/plugins/plan-agent/skills/implementation-plan/SKILL.md — five rules: a lane owns a disjoint set of paths; a lane's steps form a chain the worker runs in order; steps touching the same file stay in one lane; shared files (CHANGELOG.md, README.md, marketplace.json, generated indexes) belong to the `lead` lane; aim for 2 to 5 lanes and never force lanes on a chain — and add a batched lane-confirmation question to Align (Step 5) plus the Step 8 wording that build now dispatches by shape. Why: the split is authored where the plan is written and a human confirms it before any agent runs — dispatch never re-derives it. Verify: grep finds all five rules and the Align lane question in SKILL.md.
8. Document the `### Lane:` grammar beside `### Phase:` in guidelines/section-catalog.md using the parser's literal syntax, add a two-lane-plus-lead example to reference/SKELETON.md, and add "a lane is a deliverable — its last step's Verify proves the lane on its own" to guidelines/planning-principles.md. Why: the catalog is the syntax contract future sessions author against, and a worked example is what keeps hand-authored lanes parseable. Verify: `grep -l '### Lane:'` matches all three files.
9. Rewrite guidelines/right-sizing.md and kit/plugins/plan-agent/skills/build/references/phase-checkpoints.md as a case split — a chain bounds context with phases, independent lanes fan out, a plan can be both (phases inside lanes). Why: both files currently argue against all fan-out; the claim is true of chains and silent about lanes, and left unedited it would contradict the new default from inside the plugin's own guidance. Verify: grep shows the lanes case in both files and no unqualified cannot-be-split claim remains.
10. Add one paragraph to kit/plugins/plan-agent/agents/plan-reviewer-completeness.md (every `## Files` path is owned by exactly one lane) and one to agents/plan-reviewer-risk.md (lanes are genuinely independent — no hidden shared state, no missing `after:` edge). Why: reviewers are the second check on the split after the human, catching what --check's mechanical rules cannot. Verify: grep finds the lane paragraph in both agent files.
11. Bump plan-agent to 9.15.0, write the CHANGELOG entry, run the merge gate, and open the Phase 2 PR. Why: authoring guidance ships separately from the renderer so each PR stays reviewable, and skill edits must be exercised live because a plain session runs the pinned plugin snapshot, not the working tree. Verify: the version guard and `bash scripts/verify.sh` both exit 0, and a session started with `claude --plugin-dir kit/plugins/plan-agent --add-dir <repo-root>` authors a laned plan from the edited Step 2 rules (not the stale snapshot).

### Phase: Dispatch (9.16.0)

12. Add Agent to allowed-tools in kit/plugins/plan-agent/skills/build/SKILL.md, commands/fix.md, and commands/refactor.md in one commit, fixing the existing drift (both commands are missing Artifact). Why: Skill() runs inline under the caller's permissions, so a dispatching build stalls inside /fix and /refactor unless the three tool lists move in lockstep — the rule those files themselves state. Verify: the allowed-tools lines in all three files carry Agent and Artifact and otherwise match.
13. Write kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md carrying the full dispatch sequence — `plan-agent-render --check` then `--lanes`; staleness and dirty-tree guards; set `status: in-progress`, re-render, commit `chore(plan): start <stem>`; wave loop dispatching every lane except `lead` whose `after:` lanes are merged, up to --max at once, all Agent calls in one message (`lead` is never dispatched as a worker); on each completion verify the LANE REPORT against `git log <plan-branch>..<plan-branch>--<lane>`, audit ownership with `git diff --name-only` on the lane branch and stop naming the file and lane if any path falls outside the lane's `owns:`, merge --no-ff, tick the lane's steps, re-render, print the running per-lane table (lane, steps, verify results, branch, merged or pending), dispatch newly unblocked lanes; run the `lead` lane in the main session; then the three completion gates once — plus the worker brief template (owns-only file boundary, ordered steps, per-step Verify, commit-don't-push, the fixed LANE REPORT block) and the failure rules: a merge conflict on a disjoint-ownership plan stops and asks (never auto-resolved outside the registered merge drivers), and a failed lane offers re-dispatch, run-in-lead, or stop while keeping the other lanes' merged work — a re-dispatch deletes the failed lane branch and forks fresh from the current plan branch, never resuming half-done state the report already flagged. Why: the dispatch contract needs one canonical reference the skill can point at, the ownership audit is what turns self-reported discipline into an enforced boundary, the per-merge table keeps a multi-worker run legible, and a cold worktree resolves no placeholders — every brief must arrive fully substituted. Verify: the file exists, covers guards, waves, the ownership audit, merge order, brief, LANE REPORT verification, the progress table, conflict stop, and failed-lane choices including the fresh-fork rule, and build Step 2 references it.
14. Branch build Step 2 on the lane count: fewer than 2 lanes, `workflow: never`, or --sequential takes today's sequential path with unchanged wording; 2+ lanes follows references/dispatch-lanes.md; add the --sequential, --max (default 3, cap 5), and --worker-model flags plus the one-line manual-permission-mode warning printed once before the first dispatch. Why: dispatch is gated by the plan's shape with sequential always one flag away, and permission bubbling is warned about rather than silently degraded around. Verify: grep finds the branch condition, all three flags, and the warning in build SKILL.md, and the sequential wording matches today's text.
15. Pass --sequential in build-fleet's dispatch prompt — kit/plugins/plan-agent/skills/build-fleet/SKILL.md Step 3's `Skill(skill: "plan-agent:build", ...)` line. Why: a fleet agent running a laned plan would otherwise spawn lane workers inside its own worktree, nesting worktrees and multiplying concurrency to plans times lanes. Verify: grep shows --sequential in the fleet dispatch prompt.
16. Bump plan-agent to 9.16.0, write the CHANGELOG entry, run the merge gate, and open the Phase 3 PR. Why: the dispatcher is the largest behavioural change and ships alone so a revert stays surgical, and the dispatch path only exists in the working tree until released. Verify: the version guard and `bash scripts/verify.sh` both exit 0, and a session started with `claude --plugin-dir kit/plugins/plan-agent --add-dir <repo-root>` runs /plan-agent:build on a two-lane scratch spec and takes the dispatch branch (not the pinned snapshot's sequential-only Step 2).

### Phase: Pilot (9.17.0)

17. Author the Workflow-engine escalation as a three-lane plan — lane `script` owning kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs, lane `wiring` owning the build SKILL.md selection hook, lane `tests` owning tests/implement-workflow.test.mjs, plus a `lead` lane for the version bump and CHANGELOG — the first plan ever authored with `### Lane:` headings. Why: the pilot dogfoods the dispatcher on the escalation engine itself, so the feature ships by using the feature. Verify: `plan-agent-render <pilot-spec> --check` exits 0 and `--lanes` lists the four lanes with their steps.
18. Build the pilot plan with the new dispatcher, delivering implement-workflow.mjs — a pipeline of agent() calls with worktree isolation, Sonnet workers, a LANE_REPORT schema, and wave ordering expressed as pipeline stages — selected only on a plan with 2+ lanes by `workflow: always`, --workflow, or 6+ lanes (fewer than two lanes runs sequentially and only emits the /workflows prompt), probed for Workflow-tool availability rather than version-asserted, plus tests/implement-workflow.test.mjs. Why: the Workflow engine mirrors the proven review-workflow.mjs shape, and building it via dispatch is the pilot run. Verify: the dispatch run completes with all lanes merged and `node tests/implement-workflow.test.mjs` exits 0.
19. Re-build the same pilot plan with --sequential on a scratch branch, running each build in its own fresh session and recording per-session /usage tokens plus wall-clock for both. Why: the token multiplier is the proposal's open empirical question — the default is not trusted on large plans until this repo has its own measurement, and one accumulating session would blur which run spent what, so each gets a clean session and the numbers come from actual runs, never estimates. Verify: both wall-clock and token figures are captured from the two isolated sessions and written into the draft CHANGELOG entry.
20. Bump plan-agent to 9.17.0, write the CHANGELOG entry carrying the measured dispatch-vs-sequential numbers, run docs-sync so README.md and docs/guides/how-to/ pick up the four releases, run the merge gate, and open the Phase 4 PR. Why: the pilot numbers are the release's headline and the quick docs must not drift four minor versions behind. Verify: the version guard and `bash scripts/verify.sh` exit 0 and the CHANGELOG entry contains both measured figures.

## Tests

Tier 1 — This plan changes application code
- Objective: a laned spec is a dispatch contract and old plans are untouched. File: tests/plan-lanes.test.mjs; Type: smoke; Asserts: a two-lane spec parses, round-trips byte-stably, gates the workflow prompt, and emits --lanes JSON, while a no-lanes fixture reproduces today's renderer output byte-for-byte; Run: node tests/plan-lanes.test.mjs
- Unit: lane validation rules. File: tests/plan-lanes.test.mjs; Targets: parseSpecMarkdown, buildDigest, the --check rules; Key cases: overlapping owns, nested owns globs across lanes, unknown after, after lead, cyclic after, unlaned step in a laned spec, dead-glob warning with exit 0, lead without owns, phase-inside-lane, no-lanes digest stability with zero lane markup, lane-free four-file fixture keeps its workflow prompt
- Integration: Workflow-engine lane pipeline. File: tests/implement-workflow.test.mjs; Targets: implement-workflow.mjs; Key cases: wave ordering derived from after edges, LANE_REPORT schema shape, selection gate (6+ lanes or workflow always), graceful hard-stop when the Workflow tool is absent

## Acceptance Criteria

- [ ] A spec with no `### Lane:` heading renders byte-for-byte identically to the 9.13.2 output, its workflow prompt included — proven by the lane-free fixture tests, not by inspection
- [ ] `plan-agent-render <spec> --check` exits 1 naming the lane on overlapping ownership, nested `owns:` globs across lanes, an unknown `after:`, `after: lead`, a dependency cycle, or a step outside every lane, exits 0 with a warning on an `owns:` glob matching no `## Files` path, and exits 0 clean on the proposal's Appendix A example
- [ ] build refuses to merge a lane branch whose diff touches a path outside that lane's `owns:`, stopping with the file and lane named
- [ ] `plan-agent-render <spec> --lanes` prints every lane with its owns, after, and steps as JSON
- [ ] On a 2+ lane spec, /plan-agent:build commits the spec, dispatches one worktree Agent per lane, merges lane branches --no-ff in `after:` order, and runs the completion gates once on the merged tree
- [ ] On a no-lane spec, with `workflow: never`, or with --sequential, /plan-agent:build behaves exactly as today
- [ ] The allowed-tools lines of build SKILL.md, fix.md, and refactor.md all carry Agent and Artifact and match
- [ ] Four PRs merged, each with its own minor bump (9.14.0, 9.15.0, 9.16.0, 9.17.0) passing scripts/check-plugin-versions.mjs
- [ ] The Phase 4 CHANGELOG entry publishes measured wall-clock and token numbers for the dispatch run against the --sequential run
- [ ] `bash tests/run-all.sh` exits 0 with tests/plan-lanes.test.mjs and tests/implement-workflow.test.mjs included

## Verification

Render the proposal's Appendix A example spec and confirm --check passes, --lanes emits the three lanes as JSON, and the HTML shows lane chips, the Lanes panel, and per-lane briefs. Render an existing pre-lane plan from docs/plans/ and diff its HTML against the 9.13.2 output — zero bytes changed. Then run the pilot end to end: author the Phase 4 three-lane plan with /plan-agent:implementation-plan, build it with /plan-agent:build, and watch it dispatch three worktree workers, merge their branches in order, and pass the three completion gates on the merged tree. Finally run `bash tests/run-all.sh` (exit 0) and confirm all four PRs carry their version bumps and the Phase 4 CHANGELOG entry carries the two measured pilot numbers.

## Next Steps

- Enable nested dispatch inside build-fleet
  Deferred by decision 8 until the pilot has numbers; fleet agents currently run laned plans with --sequential.
  ```text
  In the agentics repo, revisit build-fleet's --sequential rule: using the
  Phase 4 pilot numbers in kit/plugins/plan-agent/CHANGELOG.md, decide whether
  fleet agents may run /plan-agent:build without --sequential (worktrees
  nested inside worktrees, concurrency = plans x lanes, capped). If yes,
  update kit/plugins/plan-agent/skills/build-fleet/SKILL.md, bump the
  plan-agent minor version in .claude-plugin/marketplace.json, and add a
  CHANGELOG entry. Verify with bash scripts/verify.sh.
  ```
- Archive the two stale agent-teams plans
  Both target the removed Agent Teams API and should not be built.
  ```text
  In the agentics repo, run /plan-agent:plan-status on
  docs/plans/add-research-agent-team.html and
  docs/plans/fix-review-plan-agent-frontmatter.html, then archive or rewrite
  them — they target the removed experimental Agent Teams API. Verify the
  plans gallery no longer lists them as todo.
  ```
- Fix the deprecated dual-write instruction in build-proposal
  Incidental doc drift found while grounding this plan.
  ```text
  In the agentics repo, remove the deprecated docs/proposals/ dual-write
  instruction from kit/plugins/plan-agent/skills/build-proposal/SKILL.md
  Step 6 (its own text says the copy was removed in 6.1.0 and recent
  proposals write none). Bump the plan-agent patch version in
  .claude-plugin/marketplace.json and add a CHANGELOG entry. Verify with
  git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs.
  ```

## Resources

- docs/prompts/proposal-orchestrate-plan-implementation.md — the converged proposal; its 16 locked decisions and Appendices A–E are this plan's settled inputs
- kit/plugins/plan-agent/skills/build-fleet/SKILL.md — the proven one-worktree-agent-per-unit dispatch shape the lane dispatcher copies
- kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs — the Workflow-script shape the Phase 4 engine mirrors
- https://code.claude.com/docs/en/sub-agents — worktree isolation, background, and model frontmatter for subagents
- https://code.claude.com/docs/en/costs — "Use Sonnet for teammates"; the roughly 7x team-mode token figure behind the pilot measurement
