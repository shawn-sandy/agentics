---
status: in-progress
type: feature
created: 2026-09-09
effort: medium
workflow: auto
glance: The lane dispatcher runs every laned plan on the Agent tool today; this adds the Workflow-engine escalation for six-plus lanes or `workflow: always`, and it is the first plan ever authored with `### Lane:` headings — building it with the new dispatcher is the pilot run the lane feature has been waiting on. Done when the three lanes merge back in order, the script parses as a workflow body, and the tests exit 0 on the merged tree.
---

# Plan: Ship the Workflow-engine escalation as the lane pilot

## Objective

Add `implement-workflow.mjs` — a Workflow script that runs one worktree-isolated Sonnet worker per lane with `after:` edges expressed as promise-ordered pipeline stages — wire its selection into `build` behind `workflow: always`, `--workflow`, or six or more lanes, and pin it with a static test suite, all authored as three worker lanes plus `lead`.

## Context

Phase 3 of `docs/plans/add-lane-orchestration.md` made `build` a lane dispatcher on the `Agent` tool. The proposal's decision 6 names a Workflow script as the escalation for six or more lanes or `workflow: always`, mirroring the shape `review-plan` already proves in `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs`. This plan ships that script and is deliberately the first laned plan in the repository: the `script`, `wiring`, and `tests` lanes own disjoint files, `wiring` and `tests` both wait on `script`, and `lead` holds the version bump, changelog, and docs. Building it with `/plan-agent:build` is the pilot — the dispatch run's wall-clock and tokens against a `--sequential` run of the same plan are the numbers the 9.17.0 changelog publishes.

Constraints every lane inherits: `kit/plugins/plan-agent/skills/build/SKILL.md` must stay under 600 words (`tests/plugins/test-progressive-disclosure.sh`), no Markdown under `kit/plugins/` may carry a shell-expansion sequence (`tests/plugins/test-no-shell-expansion.sh`), and a Workflow script is a hybrid — module-level `export const meta` plus a top-level `return` — that `node --check` rejects, so it is parsed the way `tests/review-plan-workflow.test.mjs` parses `review-workflow.mjs`.

## Decisions

- Wave ordering is a promise per lane, not a barrier: each lane awaits the promises its `after:` names and then calls `agent()`, so a lane starts the moment its dependencies finish and a dead worker resolves to null instead of rejecting the run.
- The script never runs git. It returns the reports and a topological `mergeOrder`; the lead merges lane branches with the same section-6 audit the Agent path uses, so there is one merge procedure, not two.
- The selection gate is probed, never version-asserted, exactly as `review-plan` Step 3 probes for the Workflow tool.
- `tests` depends only on `script`, not on `wiring`: the selection rule is stated in the script's own header comment so the suite can assert it without waiting for the skill text, which keeps `wiring` and `tests` in the same wave.

## Files

- kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs (new) — the Workflow-engine script
- tests/implement-workflow.test.mjs (new) — parse, schema, wave ordering, selection gate, hard-stop
- kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md (modified) — the Workflow engine section
- kit/plugins/plan-agent/skills/build/SKILL.md (modified) — the selection clause and `--workflow` in the argument hint
- kit/plugins/plan-agent/skills/build/references/invocation.md (modified) — the `--workflow` flag
- .claude-plugin/marketplace.json (modified) — 9.17.0
- kit/plugins/plan-agent/CHANGELOG.md (modified) — the 9.17.0 entry with the pilot numbers
- README.md (modified) — regenerated Plugin Reference Table
- docs/guides/how-to/plan-agent.md (modified) — the build entry's command and flags
- CHANGELOG.md (modified) — the root Unreleased bullets

## Steps

### Lane: script (owns: kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs)

1. Write kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs, a Workflow script mirroring kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs in shape — read that file first and copy its header-comment style, its `export const meta` pure literal, and its use of `agent()` — with this contract: the header comment states that the script is passed inline as the Workflow tool's `script` input and never launched by path, that it is selected only on a plan with 2 or more lanes and only by `workflow: always`, the `--workflow` flag, or 6 or more lanes, that fewer than 2 lanes runs sequentially and only emits the /workflows prompt, and that the Workflow tool is probed for availability and never version-asserted; `export const meta` has name `plan-implement-lanes`, a one-line description, and phases `Implement` and `Report`; the body reads `args.planPath`, `args.planBranch`, `args.workerModel` (default `'sonnet'`), and `args.lanes` — an array of `{ name, owns, after, brief }` where `brief` is the fully substituted worker brief — and throws an Error naming the missing key when `planPath`, `planBranch`, or `lanes` is absent or `lanes` is empty; it skips any lane named `lead` (the lead runs it, never a worker); it defines `const LANE_REPORT` as a JSON schema with `type: 'object'`, `required: ['lane', 'branch', 'steps_done', 'verify', 'files_changed', 'blocked']`, where `steps_done` and `files_changed` are arrays of strings and the rest are strings; wave ordering is a `Map` from lane name to a promise — each lane's promise first awaits the promises of every lane its `after:` names, then calls `agent(lane.brief, { label: 'lane:' + lane.name, phase: 'Implement', isolation: 'worktree', agentType: 'general-purpose', model: workerModel, schema: LANE_REPORT })` and resolves to that result (null when the worker died — never reject); after every promise settles it calls `log()` with one line counting reported and dead lanes and returns `{ reports, mergeOrder }` where `reports` is `[{ name, after, report }]` and `mergeOrder` is the worker lane names topologically sorted by `after:`; it uses no `Date.now()`, `Math.random()`, `new Date()`, or Node API, and never runs git. Why: the Workflow engine mirrors the proven review-workflow shape, and a promise per lane is what turns `after:` edges into pipeline stages without a barrier. Verify: `node --input-type=module -e "import('node:fs').then(fs=>{const s=fs.readFileSync('kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs','utf8');new (Object.getPrototypeOf(async function(){}).constructor)('args','agent','pipeline','parallel','log','phase','budget','workflow',s.replace(/^export /gm,''));console.log('parses')})"` prints `parses`, and `grep -c "LANE_REPORT\|mergeOrder\|isolation: 'worktree'\|6 or more lanes" kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs` is at least 4.

### Lane: wiring (owns: kit/plugins/plan-agent/skills/build/SKILL.md, kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md, kit/plugins/plan-agent/skills/build/references/invocation.md; after: script)

2. Append a `## Workflow engine (escalation)` section to the end of kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md stating: it is selected only on a spec with 2 or more lanes, and only by `workflow: always`, the `--workflow` flag, or 6 or more lanes — fewer than 2 lanes runs the sequential Step 2 and only emits the /workflows prompt, whatever the frontmatter says; before using it, probe that the `Workflow` tool is callable in this session the way review-plan Step 3 does, never asserting a version, and when it is absent print exactly `This laned build asked for the Workflow engine, which is not available in this session; re-run without --workflow (or with workflow: auto) to use the Agent dispatcher.` and stop; otherwise Read `references/implement-workflow.mjs` and pass its contents as the Workflow tool's inline `script` input, never by path, with `args` as a real object — `planPath`, `planBranch`, `workerModel`, and `lanes` as `[{ name, owns, after, brief }]` where each brief is the renderer's worker brief with `<plan-branch>` substituted and `lead` omitted; on return merge each lane in the returned `mergeOrder` using section 6 exactly as the Agent path does, then run `lead` and the gates; and that calling Workflow from this skill is authorized by the tool's own opt-in rule for a skill whose instructions say to call it. Why: one merge procedure serves both engines, and the escalation needs a canonical home the core can point at without growing. Verify: `grep -c "Workflow engine (escalation)\|--workflow\|6 or more lanes\|implement-workflow.mjs\|not available in this session" kit/plugins/plan-agent/skills/build/references/dispatch-lanes.md` prints at least 5.
3. In kit/plugins/plan-agent/skills/build/SKILL.md, add `[--workflow]` to the `argument-hint` and extend the "2 or more lanes" bullet of Step 2 with one clause — `workflow: always`, `--workflow`, or 6+ lanes takes that reference's Workflow engine section — without pushing the file to 600 words or more (count with `python3 -c "print(len(open('kit/plugins/plan-agent/skills/build/SKILL.md',encoding='utf-8').read().split()))"`; trim only prose you added if needed, never the sequential wording, the permission warning, or the plan-mode guard line); then in kit/plugins/plan-agent/skills/build/references/invocation.md add `--workflow` to the Rule 0 strip list and a valueless-flag bullet beside `--sequential` saying it selects the Workflow engine on a laned spec, is ignored below 2 lanes, and that `--sequential` and `--workflow` together is an error naming both. Why: the core stays a pointer under its word ceiling while the flag parses like every other flag. Verify: `bash tests/plugins/test-progressive-disclosure.sh` and `bash tests/plugins/test-build-skill.sh` both exit 0, and `grep -c -- "--workflow" kit/plugins/plan-agent/skills/build/SKILL.md kit/plugins/plan-agent/skills/build/references/invocation.md` shows at least 1 for each file.

### Lane: tests (owns: tests/implement-workflow.test.mjs; after: script)

4. Write tests/implement-workflow.test.mjs mirroring tests/review-plan-workflow.test.mjs — read it first and reuse its `check()` helper and its AsyncFunction `parsesAsWorkflowBody()` trick verbatim — asserting on kit/plugins/plan-agent/skills/build/references/implement-workflow.mjs that: the file exists and parses as a workflow body; `export const meta` names `plan-implement-lanes` and a phase titled `Implement`; the `LANE_REPORT` schema requires `lane`, `branch`, `steps_done`, `verify`, `files_changed`, and `blocked`; wave ordering is derived from `after:` — the source awaits the after-named lanes' promises before its `agent(` call, and that call passes `isolation: 'worktree'` and `schema: LANE_REPORT`; a lane named `lead` is skipped; the script returns `mergeOrder`; the selection gate is documented in the header — `workflow: always`, `--workflow`, and `6 or more lanes` all appear, as does the fewer-than-2-lanes sequential rule; the script says the Workflow tool is probed rather than version-asserted; and the source uses none of `Date.now`, `Math.random`, `new Date(`, or `require(`. End with the PASS/FAIL tally and `process.exit(fail > 0 ? 1 : 0)`. Why: a workflow script has no runner of its own, so the suite is the contract that keeps the script and the selection rule from drifting apart. Verify: `node tests/implement-workflow.test.mjs` exits 0 with every line PASS.

### Lane: lead (after: script, wiring, tests)

5. Bump plan-agent to 9.17.0 in .claude-plugin/marketplace.json, write the kit/plugins/plan-agent/CHANGELOG.md entry carrying the pilot's measured dispatch-versus-sequential wall-clock and token numbers, run docs-sync so README.md, docs/guides/how-to/plan-agent.md, and the root CHANGELOG.md pick up 9.14.0 through 9.17.0, and run the merge gate. Why: the pilot numbers are the release's headline and the quick docs must not drift four minor versions behind. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` and `bash scripts/verify.sh` both exit 0.

## Tests

Tier 1 — This plan changes application code
- Objective: the escalation engine ships and is selectable. File: tests/implement-workflow.test.mjs; Type: smoke; Asserts: implement-workflow.mjs parses as a workflow body, carries the LANE_REPORT schema and promise-ordered waves, and documents the three selectors; Run: node tests/implement-workflow.test.mjs
- Integration: the lane pipeline's contract. File: tests/implement-workflow.test.mjs; Targets: implement-workflow.mjs; Key cases: wave ordering derived from after edges, LANE_REPORT schema shape, selection gate (6+ lanes or workflow always or --workflow), lead skipped, graceful hard-stop text when the Workflow tool is absent

## Acceptance Criteria

- [ ] `plan-agent-render docs/plans/add-workflow-engine-escalation.md --check` exits 0 and `--lanes` lists script, wiring, tests, and lead with their steps
- [ ] implement-workflow.mjs parses as a workflow body, runs one `agent()` per non-lead lane with `isolation: 'worktree'` and `schema: LANE_REPORT`, and orders lanes by `after:` without a barrier
- [ ] `build` selects the Workflow engine only on a 2+ lane spec by `workflow: always`, `--workflow`, or 6+ lanes, and hard-stops with the named message when the tool is absent
- [ ] `node tests/implement-workflow.test.mjs` exits 0 on the merged tree
- [ ] The three worker lanes merged back onto the plan branch in `after:` order with every `git diff --name-only` path inside its lane's `owns:`
- [ ] The 9.17.0 CHANGELOG entry carries measured wall-clock and token figures for the dispatch run against the `--sequential` run

## Verification

Build this plan with `/plan-agent:build docs/plans/add-workflow-engine-escalation.md` and watch it commit the spec, dispatch the `script` worker, then `wiring` and `tests` together once `script` merges, audit each lane branch's diff against its `owns:`, and merge `--no-ff` in that order; then run `lead` in the session. On the merged tree `node tests/implement-workflow.test.mjs` exits 0, `bash tests/run-all.sh` exits 0 with the new suite included, and `bash tests/plugins/test-progressive-disclosure.sh` confirms the build core stayed under its ceiling. Rebuild the same plan with `--sequential` in a fresh session on a scratch branch, and record both sessions' wall-clock and `/usage` tokens into the 9.17.0 changelog entry.
