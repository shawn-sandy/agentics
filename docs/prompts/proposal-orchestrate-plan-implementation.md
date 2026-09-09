---
type: proposal
intent: Make plan-agent an orchestration engine by turning the plan spec into the dispatch contract and having build run one worktree-isolated worker per lane
techniques: long-context grounding, XML structure, comparison tables, positive framing, output format
created: 2026-09-09
status: converged
modified: 2026-09-09
generated-sha: ae65538e9fd0aebca518e970960c0b76e9ecdb51799d5ba8c1842c9be742adc4
---

# Proposal: Orchestrate Plan Implementation

> This is a proposal for review, not an execution plan. It carries the
> grounded research and the decisions already made; the final instruction
> below hands off to drafting an execution plan from it.

<tldr>
Claude Code already ships every engine plan-agent could want for running work across agents: worktree-isolated subagents, `/batch`, the Workflow runtime, agent view, and experimental agent teams. plan-agent already drives two of them: the reviewer panel runs on Workflow, and `build-fleet` runs one worktree agent per plan. What no engine gets from a plan today is a step it can hand to a worker. A spec step is `action / Why: / Verify:` with no owned files and no dependency edge, and `build` runs every step itself, in order, with neither `Agent` nor `Workflow` in its allowed tools. This proposal adds one grouping to the spec, `### Lane:`, that declares which steps are independent and which files each group owns; teaches `implementation-plan` to author lanes; and turns `build` Step 2 into a dispatcher that runs one worktree-isolated Sonnet worker per lane, merges the lane branches in dependency order, and keeps the three completion gates for the lead. A plan without lanes behaves exactly as it does today.
</tldr>

<context>
**Why now.** Fable 5.1 (2026-09-01, `claude-fable-5-1`, $10/$50 per million tokens) is "built for jobs that take hours" and runs unattended. Sonnet 5 (2026-06-30, `claude-sonnet-5`, $2/$10) is positioned as near-Opus coding at Sonnet cost. Opus 5 (2026-07-24, $5/$25) is "built for long-running, multi-step work." A strong lead with cheap capable workers is now the economical shape, and Claude Code's cost guidance says "Use Sonnet for teammates" (https://code.claude.com/docs/en/costs). Anthropic reports Claude authored more than 80 percent of the code merged into its own codebase. Plans that run one step at a time on one thread leave that capacity idle.

**How a plan is created today.** `/plan-agent:implementation-plan <objective>` runs the workflow in `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` (716 lines, plus 7 bundled guideline and reference files totalling 2,748 lines): Explore, Clarify, Author the spec, Frontmatter, Rename, Align, Interview, Tests, Render, Publish, then Implement/Edit/Exit. The output is a Markdown spec at `<plans-dir>/<verb-target>.md` with the sections `## Objective`, `## Context`, `## Files`, `## Steps`, `## Tests`, `## Acceptance Criteria`, `## Verification`, `## Next Steps`, `## Unresolved Questions`, `## Resources` (`reference/SKELETON.md`). The bundled renderer (`bin/plan-agent-render` wrapping `scripts/build-plan-html.mjs`, 770 lines; parser in `scripts/lib/plan-spec.mjs`, 827 lines) turns the spec into a self-contained HTML plan. The HTML is never hand-edited; the spec is the source of truth.

**How prompts enter a plan today.** Three implement prompts are derived by the renderer, never authored (`scripts/build-plan-html.mjs:404-427`): the Implement prompt ("Read and implement all steps in the plan at <spec>..."), the Goal prompt, and a Workflow prompt ("Run a workflow to implement the plan at <spec>... Brief subagents with the plan file... Reserve a final verification phase for the lead agent, not a subagent."). They land in `<meta name="plan-implement|plan-goal|plan-workflow">` tags and the "More ways" drawer (`scripts/lib/plan-shell.mjs:2047-2060`, `:2211-2230`). The Workflow prompt is gated by a two-variable heuristic: `workflow: auto` fires at 4+ files across 2+ top-level directories (`build-plan-html.mjs:410-413`). Step 8's "Run as workflow" option only prints it for the user to paste (`SKILL.md:680-683`). The only author-written prompts are the paste-ready blocks inside `## Next Steps` cards. `--from-prompt <path>` feeds a saved prompt (this document's shape) in as context, never as a step list.

**How a plan is implemented today.** `skills/build/SKILL.md` Step 2 (lines 76-79): "work through each step sequentially — apply the changes, verify each step, and mark progress in the spec as you go." Its `allowed-tools` (line 4) has neither `Agent` nor `Workflow`, and the skill has 0 hits for `subagent|parallel|Workflow\(|Agent\(|worktree|fleet|dispatch|delegat|orchestrat`. `commands/fix.md:3` and `commands/refactor.md:3` mirror that tool list and state the lists must stay in sync. Two in-tree files argue against fan-out: `skills/build/references/phase-checkpoints.md:8-13` ("A plan whose steps must run in order cannot be split across subagents: step seven depends on a choice made in step two") and `guidelines/right-sizing.md:52-54`. Both are true of a chain and silent about a plan with independent lanes.

**The step data model.** `scripts/lib/plan-spec.mjs:607` pushes `{ action, why, verify }`, with the done flag in a parallel `stepsDone[]` boolean array. A step has no id, no files, no dependency, no owner; its identity is its 1-based index. Phases (`### Phase: <name>`) group steps for context checkpoints and never restart numbering (`:614`). There is no JSON schema anywhere in the plugin; `ENUMS` at `build-plan-html.mjs:256-261` is the whole validation surface.

**What plan-agent already runs in parallel.** `skills/build-fleet/SKILL.md` (176 lines, 32 orchestration hits): one `Agent` per plan, `subagent_type: "general-purpose"`, `isolation: "worktree"`, `run_in_background: true`, `--max` 3, dispatch-only by construction, self-reports verified with `gh pr view --json state,headRefName`. `skills/review-plan/references/review-workflow.mjs` (201 lines): a Workflow script that fans out 7 to 10 reviewer agents via `pipeline()` with `agentType` and a JSON `schema`, then adversarially verifies high-severity findings. Twelve agent definitions ship in `agents/`; none implements. `git-agent` supplies the five-command background-dispatch pattern (`commands/*-bg.md`). Plugin at marketplace version 9.13.2; 18 skills, 12 agents, 9 commands, 3,848 SKILL.md lines.

**What the platform ships** (official docs): subagents nest three layers deep by default and accept `isolation: worktree`, `background: true`, and `model:` in frontmatter (https://code.claude.com/docs/en/sub-agents). `/batch` "decomposes the work into 5 to 30 independent units, and presents a plan. Once approved, spawns one background subagent per unit in an isolated git worktree... runs tests, and opens a pull request" (https://code.claude.com/docs/en/commands). The Workflow runtime's `agent()` accepts `isolation: 'worktree'`, `agentType`, `model`, `effort`, and `schema`, caps 16 concurrent agents, and treats "a skill whose instructions tell you to call Workflow" as opt-in (https://code.claude.com/docs/en/workflows). Agent view dispatches background sessions that auto-isolate in worktrees and commit, push, and draft a PR (https://code.claude.com/docs/en/agent-view). Agent teams are experimental, off by default, do not isolate teammates in worktrees, and never spawn in `-p` mode (https://code.claude.com/docs/en/agent-teams). Subagent worktrees branch from the repository's default branch unless `worktree.baseRef` is `"head"` (https://code.claude.com/docs/en/worktrees).

**What the sources agree on.** "Each subagent needs an objective, an output format, guidance on the tools and sources to use, and clear task boundaries" (https://www.anthropic.com/engineering/multi-agent-research-system); vague briefs made subagents "duplicate efforts rather than divide labor." "Two teammates editing the same file leads to overwrites. Break the work so each teammate owns a different set of files"; "Start with 3-5 teammates"; "Just right: self-contained units that produce a clear deliverable" (https://code.claude.com/docs/en/agent-teams). "The bottleneck is no longer generation. It's verification" (https://addyosmani.com/blog/code-agent-orchestra/). Multi-agent runs cost roughly 7x (teams in plan mode, https://code.claude.com/docs/en/costs) to 15x (research system) the tokens of a single session.
</context>

<finding>
Every orchestration engine plan-agent could want already ships inside Claude Code; the one thing none of them gets from a plan today is a step it can hand to a worker. plan-agent's job is therefore not to build a scheduler but to make the plan the dispatch contract, every lane a self-contained brief with owned files, a verify command, and dependency edges, and to make `build` dispatch against it.
</finding>

<comparison>
| Dimension | The idea | Today |
|---|---|---|
| Unit of parallel work | A **lane**: an ordered group of steps with disjoint file ownership, run by one worker | The whole plan (`build-fleet`) or nothing (`build`) |
| Step shape | `### Lane: <name> (owns: ...; after: ...)` grouping over unchanged `action / Why / Verify` steps | `{ action, why, verify }` plus a positional done flag |
| Who splits the work | `implementation-plan` at authoring time; the human reviews the split in Align; `review-plan` reviewers check it | Nobody. The paste prompt tells subagents to brief themselves from the plan |
| Who implements | One `Agent` per lane, `isolation: worktree`, `run_in_background`, `model: sonnet` | The main session, one step at a time |
| Who edits the spec | The lead only; workers report, the lead ticks `[x]` after merge | The single session |
| Integration | Lead merges lane branches onto the plan branch in `after:` order, then runs the gates once | Not applicable |
| Trigger | The plan's shape: two or more lanes means dispatch; `workflow: never` opts out | A file-count heuristic that emits a string to paste |
| Chains | A single-lane plan (no `### Lane:` headings) runs sequentially, unchanged | Sequential |
| Engine | The harness's own `Agent` plus worktree isolation (as `build-fleet`); a Workflow script as a later escalation | Nothing dispatches |
</comparison>

<decisions>
Locked and resolved — treat these as settled; do not reopen them:

Settled before this draft:

1. **Deliverable: proposal only.** No plugin code, no plan. The handoff is `/plan-agent:implementation-plan ... --from-prompt <this file>`.
2. **The exploration centres on `implementation-plan`.** It is where a plan and its prompts are written, so the split has to be authored there (user's refinement, 2026-09-09).
3. **Backward compatibility is non-negotiable.** A spec with no `### Lane:` heading must render, build, and round-trip byte-for-byte as today. Existing plans in `docs/plans/` are never re-shaped.

Resolved in the 2026-09-09 review:

4. **The split lives in the plan spec.** `implementation-plan` authors `### Lane:` groupings with `owns:` and `after:`; the human reviews the split before any agent runs; `review-plan`'s completeness and risk reviewers check that ownership is disjoint and lanes are genuinely independent. Propagates to WS-A (parser), WS-B (authoring rules), WS-C (the dispatcher reads lanes and never re-splits).
5. **Multi-agent implementation is the default, gated by shape.** `build` dispatches whenever the spec has two or more lanes; a single-lane plan stays sequential; `workflow: never` opts out. The 4-files/2-directories heuristic is retired as a dispatch trigger — `build` never consults it — and survives only as the render-time gate for the workflow prompt on lane-free specs, so those keep rendering byte-for-byte (decision 3); `workflow:` keeps its three values with new meaning (Appendix A). Propagates to WS-A (`workflow:` semantics), WS-B (right-sizing guidance), WS-C (dispatch condition).
6. **Engine: the `Agent` tool first.** One `Agent` call per lane with `subagent_type: "general-purpose"`, `isolation: "worktree"`, `run_in_background: true`, `model: "sonnet"`, exactly the shape `build-fleet` proves. No opt-in keyword, no feature flag, works in every session that has `Agent`. A Workflow-script engine is a later escalation (WS-E) for six or more lanes or `workflow: always`. Agent teams are rejected: experimental, no worktree isolation, absent in `-p`. `/batch` is rejected as the engine because it re-splits the work itself and opens one PR per unit, which changes what a plan delivers. Propagates to WS-C, WS-E, Appendix D.
7. **Integration: the lead merges lane branches.** Each worker commits on `<plan-branch>--<lane>` inside its worktree and never pushes. `build` merges lanes onto the plan branch in `after:` order with `git merge --no-ff`, resolves conflicts, ticks the spec, re-renders, then runs the three completion gates once on the merged tree. "One plan, one PR" stays true; `build-fleet` and `/batch` keep the one-PR-per-unit model for their own use. Propagates to WS-C, Appendix C, Risks.
8. **Fleet agents run laned plans sequentially for now.** `build-fleet` passes `--sequential` to each fleet agent, so concurrency stays at `--max` plans with no worktrees nested inside worktrees. Nested dispatch is deferred until the WS-D pilot has numbers; it gets no roadmap phase in this round. Propagates to WS-C (the `build-fleet` edit), Appendix E, Risks.
9. **In manual permission mode, `build` dispatches and warns.** Before the first `Agent` call it prints one line saying worker permission prompts will bubble to this session and that the docs recommend pre-approving tools. It never falls back to sequential on permission mode alone. Propagates to WS-C, Appendix C.
10. **The pilot dogfoods WS-E.** The Workflow-engine escalation is authored as a three-lane plan (script, `build` skill wiring, tests) once WS-A through WS-C have shipped, and is built with the new dispatcher. Its wall-clock and token numbers against a `--sequential` run of the same plan are the pilot measurement. Propagates to WS-D, Roadmap.

Defaults taken from the evidence (overridable by flag, not re-decided here):

11. **Verification stays with the lead.** Workers run only their steps' `Verify:` commands; the acceptance-criteria, end-to-end, and completion-checklist gates (`skills/build/references/completion-gates.md`) run once, by the lead, on the merged tree. This is already the rule in the derived Workflow prompt.
12. **Workers run on Sonnet; the lead keeps the session model.** From the docs' cost guidance and the 5x price gap. `--worker-model <alias>` overrides.
13. **Concurrency defaults to 3, hard-capped at 5.** `build-fleet` already uses `--max` 3; the docs say 3 to 5. `--max <n>` overrides up to 5.
14. **Workers never edit the spec.** N lane branches each editing the spec would conflict on every merge. Workers report; the lead is the spec's only writer.
15. **`build` commits the spec on the plan branch before dispatch.** Subagent worktrees fork from the default branch and share the repo's `.git`, so a lane branch can start from the plan branch only if the plan branch's state is committed; uncommitted work never travels (the `build-fleet` dirty-tree rule, `SKILL.md:36-38`). `build` therefore makes one commit (`chore(plan): start <verb-target>` with `status: in-progress`) before the first `Agent` call. Step 6's "leave tree uncommitted" becomes "leave tree committed on the plan branch, unpushed"; `git-agent:ship-autonomous` is indifferent to which.
16. **Version bumps are minor.** Lanes without headings are a no-op, so each phase ships as a minor bump in `.claude-plugin/marketplace.json` (9.14.0, 9.15.0, ...), consistent with 9.3.0 (`build-fleet`) and 9.12.0 (Workflow review).
</decisions>

<workstreams>
### WS-A — Renderer: parse, validate, and expose lanes

Scope: `scripts/lib/plan-spec.mjs`, `scripts/build-plan-html.mjs`, `scripts/lib/plan-shell.mjs`, `tests/`.

- `parseSpecMarkdown()` recognises `### Lane: <name> (owns: <glob>[, <glob>...][; after: <lane>[, <lane>...]])` inside `## Steps` and returns `sections.lanes: [{ name, owns, after, firstStep, lastStep }]` alongside the existing `phases`. A `### Phase:` inside a lane is a checkpoint for that lane's worker; top-level phases with no lanes behave exactly as today. Numbering stays flat and global.
- `buildDigest()` re-emits lane headings verbatim so HTML to spec to HTML stays byte-stable (the existing round-trip contract, `plan-spec.mjs:771-827`).
- `--check` gains four rules: every path in `## Files` matches at most one lane's `owns:` (one file, one owner); no two lanes' `owns:` patterns nest — the wildcard-free prefix of one pattern must not match another lane's pattern, so `scripts/**` beside `scripts/lib/**` is rejected even when no listed file sits in the overlap, with both lanes named (a pairwise prefix test, not full glob intersection; a merge conflict between lanes remains a plan bug that stops the run, Appendix C step 6); every `after:` names an existing lane; the `after:` graph is acyclic. The reserved lane name `lead` may omit `owns:` and runs in the main session after everything it lists in `after:`. Violations exit 1 with the offending lane named, and the fix is always to the spec.
- `--lanes` prints `sections.lanes` plus each lane's steps as JSON, so the dispatcher never parses Markdown by hand.
- The HTML gains a lane chip on each step card, a "Lanes" panel listing owned paths and dependencies, one copyable worker brief per lane (Appendix B), and `<meta name="plan-lanes">` carrying the JSON. The existing `plan-implement`, `plan-goal`, and `plan-workflow` metas are unchanged.
- `workflow:` frontmatter: `auto` (default) dispatches when there are two or more lanes; `never` runs sequentially even with lanes; `always` dispatches and also emits the `/workflows` prompt for the Workflow engine. The `fileCount >= 4 && dirCount >= 2` gate at `build-plan-html.mjs:410-413` is kept for lane-free specs only — it still decides whether their `plan-workflow` meta and drawer row render, exactly as today, so decision 3's byte-for-byte guarantee holds — and is never consulted once a spec has a `### Lane:` heading, where the lane count decides instead. It stops being a dispatch trigger: `build` dispatches by lane count alone.
- Tests: `tests/plan-lanes.test.mjs` covers parse, round-trip, the three `--check` rules, the `--lanes` JSON shape, and a no-lanes fixture producing today's exact output.

### WS-B — Authoring: `implementation-plan` writes lanes by default

Scope: `skills/implementation-plan/SKILL.md`, `guidelines/section-catalog.md`, `guidelines/right-sizing.md`, `guidelines/planning-principles.md`, `reference/SKELETON.md`, `skills/build/references/phase-checkpoints.md`, `agents/plan-reviewer-completeness.md`, `agents/plan-reviewer-risk.md`.

- Step 2 gains a "split into lanes" pass with five rules: a lane owns a disjoint set of paths; a lane's steps form a chain the worker runs in order; steps that touch the same file stay in one lane; shared files (`CHANGELOG.md`, `README.md`, `marketplace.json`, generated indexes) belong to the `lead` lane; aim for 2 to 5 lanes and never force lanes on a chain. Lanes are proposed in Align (Step 5) as their own batched question so the human confirms the split.
- `section-catalog.md` documents the `### Lane:` syntax next to `### Phase:` with the parser's literal grammar; `SKELETON.md` shows a two-lane example plus a `lead` lane.
- `right-sizing.md:41-54` and `phase-checkpoints.md:8-13` are rewritten as a case split: a chain bounds context with phases; independent lanes fan out; a plan can be both (phases inside lanes).
- `planning-principles.md` adds "a lane is a deliverable": each lane's last step's `Verify:` proves the lane on its own.
- Step 8: "Implement now, this session" keeps its wording; `build` now dispatches by shape. "Run as workflow" is kept as the Workflow-engine escalation and its help text says so.
- Reviewer prompts: `plan-reviewer-completeness` checks every `## Files` path is owned by exactly one lane; `plan-reviewer-risk` checks lanes are independent (no hidden shared state, no missing `after:` edge). One paragraph each; no new agent.

### WS-C — Dispatch: `build` Step 2 becomes a lane dispatcher

Scope: `skills/build/SKILL.md`, new `skills/build/references/dispatch-lanes.md`, `commands/fix.md`, `commands/refactor.md`, `skills/build-fleet/SKILL.md`.

- `allowed-tools` adds `Agent` in `build`, `fix.md`, and `refactor.md` in the same commit (the lockstep rule those files state). The existing drift, both commands lacking `Artifact`, is fixed in the same edit.
- Step 2 branches on `plan-agent-render --lanes`: zero or one lane, `workflow: never`, or `--sequential` takes today's sequential path, unchanged. Two or more lanes takes the dispatch sequence in Appendix C: commit the spec, dispatch wave 1 (lanes with empty `after:`) in one message with `--max` concurrency, on each completion merge the lane branch in `after:` order, tick its steps, re-render, dispatch newly unblocked lanes from the updated plan branch, run the `lead` lane last, then the three gates.
- Each worker gets the brief in Appendix B with every placeholder substituted (a cold worktree resolves nothing, `build-fleet` `SKILL.md:115-116`). Workers end with a fixed `LANE REPORT` block; `build` verifies self-reports with `git log --oneline <plan-branch>..<plan-branch>--<lane>` and marks unverifiable rows the way `build-fleet` Step 4 does.
- Merge conflicts on a disjoint-ownership plan are a plan bug: `build` stops, names the two lanes and the file, and asks whether to resolve by hand or fix the lanes and re-run. It never auto-resolves outside the registered merge drivers.
- A failed lane (worker died, `Verify:` failed, blocked) is reported and the lead offers three choices: re-dispatch the lane, run it sequentially in the lead, or stop. The other lanes' merged work is kept.
- Flags: `--sequential`, `--max <n>` (at most 5), `--worker-model <alias>`. In manual permission mode the one-line warning from decision 9 is printed once before dispatch.
- `build-fleet` Step 3's dispatch prompt passes `--sequential` to `Skill(skill: "plan-agent:build", ...)` (decision 8).

### WS-D — Pilot and measure by dogfooding WS-E

Scope: the WS-E plan, `CHANGELOG.md`, `README.md`, `docs/guides/how-to/` via `docs-sync`.

- Author WS-E as a three-lane plan (lane `script`: `skills/build/references/implement-workflow.mjs`; lane `wiring`: `skills/build/SKILL.md` and `references/dispatch-lanes.md`; lane `tests`: `tests/implement-workflow.test.mjs`; `lead`: version bump and CHANGELOG), build it with the new dispatcher, then build the same plan again with `--sequential` on a scratch branch and record wall-clock and tokens from `/usage` for both. Publish both numbers in the CHANGELOG entry; never estimate them.
- Fix whatever the pilot breaks before the WS-E PR opens.

### WS-E — Workflow engine escalation

Scope: new `skills/build/references/implement-workflow.mjs`, `skills/build/SKILL.md`, `tests/implement-workflow.test.mjs`.

- Mirrors `review-workflow.mjs`: `pipeline(lanes, lane => agent(brief(lane), { isolation: 'worktree', agentType: 'general-purpose', model: 'sonnet', schema: LANE_REPORT, phase: 'Implement' }))`, followed by a lead-side merge and gate phase. Selected only on a plan with two or more lanes, by `workflow: always`, `--workflow`, or six or more lanes; with fewer than two lanes there is nothing to fan out, so the plan runs sequentially and only the `/workflows` prompt is emitted, as Appendix A states. Probed the way `review-plan` Step 3 probes, never version-asserted. Wave ordering for `after:` is expressed as pipeline stages that wait on the named lanes' results.
</workstreams>

<risks>
- **The split is the product, and it is written by a model.** A bad split costs more than a sequential run. Mitigations: the human confirms lanes in Align; `--check` rejects overlapping ownership; two reviewers audit it; WS-D measures before the default is trusted on large plans.
- **Worktrees fork from the default branch, not the plan branch.** Decision 15 handles it with a pre-dispatch commit, but a plan branch that is behind `origin/main` still forks lanes from a stale base. `build`'s staleness guard (`references/resolve-plan.md:41-53`) already runs first; keep it.
- **Token cost multiplies.** The docs report roughly 7x for teams and Anthropic reports 15x for research fan-out; this repo has no measurement for lane dispatch. WS-D produces one before the default reaches every user, and `--sequential` is always one flag away.
- **Permission prompts bubble.** In manual permission mode, three workers' prompts land in the lead's session. Decision 9 accepts this with a warning rather than silently degrading to sequential.
- **`Skill()` runs inline under the caller's permissions.** Adding `Agent` to `build` without `fix.md` and `refactor.md` stalls those commands on the first dispatch. Shipped as one commit.
- **Nested dispatch inside `build-fleet` is deferred, not solved.** Decision 8 keeps fleet agents sequential. If a fleet agent ever runs `build` without `--sequential`, it would spawn lane workers two levels deep and multiply concurrency to plans times lanes.
- **Two `todo` plans in `docs/plans/` target the removed Agent Teams API** (`add-research-agent-team.html`, `fix-review-plan-agent-frontmatter.html`). Incidental; they should be archived or rewritten, not built.
- **The `build-proposal` skill still instructs a deprecated dual write** to `docs/proposals/` that its own text says was removed in 6.1.0; the two most recent proposals have no such copy, and this one follows them. Incidental doc drift in `skills/build-proposal/SKILL.md` Step 6.
</risks>

<roadmap>
| Phase | Work | Size | Depends on |
|---|---|---|---|
| 1 | WS-A renderer: lane parser, `--check` rules, `--lanes` JSON, HTML chips and briefs, `workflow:` semantics, round-trip tests (9.14.0) | M | none |
| 2 | WS-B authoring: lane rules in Step 2 and Align, section catalog, right-sizing and phase-checkpoints case split, skeleton, reviewer paragraphs (9.15.0) | M | 1 |
| 3 | WS-C dispatch: `build` Step 2 dispatcher, worker brief, merge and gate sequence, flags, `allowed-tools` lockstep, `build-fleet --sequential` (9.16.0) | L | 1, 2 |
| 4 | WS-D plus WS-E: author the Workflow engine as a three-lane plan, build it with the dispatcher, measure against `--sequential`, ship with numbers in the CHANGELOG and synced docs (9.17.0) | M | 3 |
</roadmap>

<appendices>
### Appendix A — Lane syntax (the spec contract)

```markdown
---
status: todo
type: feature
created: 2026-09-09
workflow: auto        # auto | never | always
---

## Files
- scripts/lib/plan-spec.mjs (modified) — parse lanes
- scripts/build-plan-html.mjs (modified) — check rules, --lanes
- skills/build/SKILL.md (modified) — dispatcher
- CHANGELOG.md (modified)

## Steps

### Lane: renderer (owns: scripts/lib/plan-spec.mjs, scripts/build-plan-html.mjs, tests/plan-lanes.test.mjs)
1. Parse `### Lane:` headings into `sections.lanes`. Why: ... Verify: `node --test tests/plan-lanes.test.mjs`
2. Add the three `--check` rules. Why: ... Verify: `plan-agent-render tests/fixtures/overlap.md --check` exits 1

### Lane: build-skill (owns: skills/build/**, commands/fix.md, commands/refactor.md; after: renderer)
3. Rewrite Step 2 as the dispatcher. Why: ... Verify: ...

### Lane: lead (after: renderer, build-skill)
4. Bump marketplace.json and write the CHANGELOG entry. Why: ... Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs`
```

Grammar: `### Lane: <name> (owns: <path-or-glob>{, <path-or-glob>}[; after: <lane>{, <lane>}])`. `name` is kebab-case; `lead` is reserved and may omit `owns:`. A spec with no `### Lane:` heading is one implicit lane and is sequential. `### Phase:` remains valid at top level or inside a lane.

`workflow:` semantics after WS-A:

| Value | Fewer than 2 lanes | 2 or more lanes |
|---|---|---|
| `auto` (default) | sequential (the workflow prompt row still follows today's file-count gate) | dispatch via `Agent` |
| `never` | sequential | sequential (lanes still document ownership) |
| `always` | sequential plus the `/workflows` prompt | dispatch plus the `/workflows` prompt (WS-E engine when present) |

### Appendix B — Worker brief (derived per lane by the renderer, consumed by `build`)

```text
You are implementing lane "<lane>" of the plan at <abs-spec-path> — <plan title>.
You own ONLY these paths: <owns list>. Do not create, edit, or delete any file outside them; if a step needs one, stop and report it.

1. git checkout -b <plan-branch>--<lane> <plan-branch>
2. Implement these steps in order, exactly as written:
   <step N>. <action> Why: <why> Verify: <verify>
   ...
3. After each step run its Verify command and record pass or fail.
4. Commit on your branch after the last step. Do not push. Do not edit <spec-path>.
5. End with exactly this block:

LANE REPORT
lane: <lane>
branch: <plan-branch>--<lane>
steps_done: <comma-separated step numbers>
verify: <N: pass|fail, one per step>
files_changed: <paths>
blocked: <none | what and why>
```

Agent call: `subagent_type: "general-purpose"`, `isolation: "worktree"`, `run_in_background: true`, `model: "sonnet"` (or `--worker-model`), `description: "Lane <lane>"`. The Workflow engine (WS-E) sends the same text with `schema: LANE_REPORT` instead of the trailing block.

### Appendix C — `build` dispatch sequence (Step 2, laned plans)

1. `plan-agent-render <spec> --check`, then `--lanes` for JSON. Fewer than 2 lanes, `workflow: never`, or `--sequential` takes today's Step 2.
2. Staleness guard (`git log HEAD..<base>`) and dirty-tree guard (as `build-fleet`).
3. Set `status: in-progress`, re-render, commit `chore(plan): start <verb-target>`.
4. In manual permission mode, print the one-line bubbling warning once.
5. Wave loop: dispatch every lane whose `after:` lanes are all merged, up to `--max` at once, all `Agent` calls in one message.
6. On each completion: verify the self-report against `git log`; `git merge --no-ff <plan-branch>--<lane>` into the plan branch; on conflict stop and ask; tick the lane's steps `[x]`; re-render; return to 5.
7. Run the `lead` lane's steps in the main session.
8. Completion gates 3 to 5 unchanged (`references/completion-gates.md`).
9. Report a per-lane table (steps, verify, branch, verified or unverified), then stop. The tree is committed on the plan branch, unpushed.

### Appendix D — Engine matrix

| Engine | Isolation | Opt-in gate | Works in `-p` | Repeatable | Verdict |
|---|---|---|---|---|---|
| `Agent` plus `isolation: worktree` | per worker | none | yes | worker definition | **Default** (WS-C), proven by `build-fleet` |
| Workflow script | `agent({ isolation: 'worktree' })` | skill instruction counts; hard-stops if the tool is absent | yes (permission rule) | the script, resumable | **Escalation** (WS-E) for 6 or more lanes |
| `/batch` | per unit | user runs it | not applicable | no | Rejected: re-splits, one PR per unit |
| Agent teams | none (partition by hand) | env flag, experimental | no | team definition | Rejected |
| Agent view (`claude --bg`) | per session | none | not applicable | no | Out of scope: whole sessions, not steps |

### Appendix E — Surfaces touched (inventory)

| File | Workstream | Change |
|---|---|---|
| `scripts/lib/plan-spec.mjs` | A | lane parse plus digest round-trip |
| `scripts/build-plan-html.mjs` | A | `--check` rules, `--lanes`, scope the file-count gate to lane-free specs, `workflow:` semantics |
| `scripts/lib/plan-shell.mjs` | A | lane chips, Lanes panel, briefs, `plan-lanes` meta |
| `tests/plan-lanes.test.mjs` | A | new |
| `skills/implementation-plan/SKILL.md` | B | Step 2 split pass, Step 5 lane question, Step 8 wording |
| `skills/implementation-plan/guidelines/{section-catalog,right-sizing,planning-principles}.md`, `reference/SKELETON.md` | B | syntax, case split, principle, example |
| `skills/build/references/phase-checkpoints.md` | B | case split |
| `agents/plan-reviewer-{completeness,risk}.md` | B | one paragraph each |
| `skills/build/SKILL.md`, `skills/build/references/dispatch-lanes.md` (new) | C | dispatcher |
| `commands/fix.md`, `commands/refactor.md` | C | `allowed-tools` lockstep (plus the `Artifact` drift) |
| `skills/build-fleet/SKILL.md` | C | pass `--sequential` in the dispatch prompt |
| `skills/build/references/implement-workflow.mjs` (new), `tests/implement-workflow.test.mjs` (new) | D, E | Workflow engine, authored as the pilot's laned plan |
| `.claude-plugin/marketplace.json`, `CHANGELOG.md`, `README.md`, `docs/guides/how-to/` | each phase | bump plus docs |
</appendices>

Author an execution plan that delivers WS-A through WS-D in roadmap order, one phase per PR with its own minor version bump. Draft real, actionable steps naming the files in Appendix E; do not restate the workstream headings as steps. Treat locked decisions 1 to 16 as settled inputs; there are no open questions to carry forward. The plan itself should be authored with lanes once WS-A lands; until then, author it as today's sequential spec, and note in its Context that Phase 4 is the first plan that will be authored with `### Lane:` headings.
