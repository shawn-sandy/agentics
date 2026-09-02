---
status: completed
type: refactor
created: 2026-09-01
effort: high
artifact-url: https://claude.ai/code/artifact/f76eae5d-3895-4c54-82a2-8c4c9b146742
glance: Plan review currently hides behind an experimental feature flag, so most users who ask for it get a hard stop instead of a review. Swapping the engine to a Workflow script removes that gate, returns findings as typed data instead of prose the lead has to re-read, and adds a refutation pass before a finding is allowed to edit anyone's plan.
---

# Plan: Take plan review off the experimental flag

## Objective

Replace `review-plan`'s Agent Teams engine with a Workflow-tool script, deleting the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` hard stop, and add an adversarial verify pass so high-severity findings are refuted before they become plan edits.

## Context

`review-plan` is a ten-reviewer panel that improves plans in place. Today it cannot run at all unless the user has set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` and is on Claude Code 2.1.32+. Step 3 of the skill is an unconditional stop otherwise. That means the plugin's most expensive feature is dark for anyone who never flipped a flag they were never told about.

Three further problems sit behind that gate. Reviewers report findings as free text through `SendMessage`, and the lead re-reads that prose into the "Inline Edits to Apply" table — every re-parse is a chance to silently drop a finding. Failure handling is hand-rolled ("respawn once, then mark unavailable"). And nothing checks a finding before it edits the plan, so a confident-but-wrong reviewer claim lands as a real edit.

The Workflow tool addresses all four. It needs no feature flag. Its `schema` option forces subagents through a `StructuredOutput` tool, so findings arrive validated instead of parsed. Its `parallel()` resolves a failed agent to `null` rather than throwing, which replaces the respawn logic with a `.filter(Boolean)`. And its `pipeline()` gives a second stage that can refute each finding as soon as its reviewer finishes, with no barrier in between.

Two facts make the change cheap. `agent()` accepts `agentType`, resolved from the same registry as the `Agent` tool, so the ten `plan-reviewer-*` agents this plugin already ships are reused as-is rather than rewritten. And the Workflow tool's opt-in rule explicitly accepts "a skill whose instructions tell you to call Workflow" — which is what makes a plugin skill calling it legitimate rather than a policy violation.

Risk: the change deletes a working path for flag-enabled users. Mitigated by keeping every step outside the engine untouched — Steps 1, 2, 3b, 6b, 7 and 8 are not in scope — and by an existing regression test (`tests/review-plan-skill.test.mjs`) that must keep passing.

## Decisions

- Replace Agent Teams outright rather than keeping it as a fallback — the flag gate is the defect being fixed, and a fallback keeps it alive plus doubles the spawn/collect logic forever.
- Reviewer lenses come from `agentType` pointing at the shipped `plan-reviewer-*` agents, not from re-authored prompts — which orphans `references/role-prompts.md`, so deleting it is in scope for this change rather than a drive-by.
- Verify only `high` and `critical` findings by default. Verifying all ~40 findings from ten reviewers would run ~50 agents per review; this keeps it near 18. `--deep` verifies everything, and `log()` always names how many passed through unverified — silent truncation reads as full coverage when it is not.
- The script ships as `.mjs` and the test parses it with the `AsyncFunction` constructor after stripping its `export`s. `node --check` cannot be used: a workflow script is a hybrid the runtime splices together, carrying module-level `export const meta` *and* a top-level `return` that is only legal inside the async wrapper, and no single parser accepts both. The skill `Read`s it and passes the contents as Workflow's inline `script` input, which sidesteps the `${CLAUDE_PLUGIN_ROOT}` expansion trap that makes documented path-based invocations unrunnable in this repo.
- The `## Team Review (YYYY-MM-DD HH:MM UTC)` timestamp stays in the main session's Step 7. `Date.now()` and argless `new Date()` throw inside a workflow script — moving the append into the script would break it at runtime.
- Steps are ordered test-first (the regression test lands and goes red before the engine changes) without formal `### Phase: RED/GREEN` headings — the plan fits one context window, so the phase ceremony buys nothing here.
- Step 3 **probes** for the `Workflow` tool instead of asserting a minimum Claude Code version. This settles the plan's original open question: there is no version number to look up, because a capability check answers the only question that matters and stays correct as availability changes, where a hardcoded minimum silently blocks working sessions the moment it is wrong.
- The Verify stage's `agent()` call deliberately omits `agentType`, running as a generic skeptic rather than reusing the reviewing lens. A verifier wearing the claimant's persona would be checking its own work; the independence is what makes the refutation a real check rather than an echo.

## Files

- `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs` (new) — the Workflow script: reviewer pipeline, findings schema, refutation stage.
- `kit/plugins/plan-agent/skills/review-plan/SKILL.md` (modified) — Step 3 becomes an availability check, Steps 4–5 collapse into one run-the-workflow step, Step 6 consumes typed findings, `allowed-tools` gains `Workflow`.
- `kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md` (deleted) — orphaned by `agentType` reuse.
- `kit/plugins/plan-agent/skills/review-plan/references/output-template.md` (modified) — the synthesis template's findings table gains the verdict column.
- `kit/plugins/plan-agent/agents/agent-review-plan.md` (modified) — `tools:` gains `Workflow`, since it invokes a skill that now calls it.
- `kit/plugins/plan-agent/README.md` (modified) — the reference-file listing near line 604 names `role-prompts.md`.
- `kit/plugins/plan-agent/CHANGELOG.md` (modified) — 9.12.0 entry.
- `.claude-plugin/marketplace.json` (modified) — plan-agent 9.11.0 to 9.12.0.
- `tests/review-plan-workflow.test.mjs` (new) — static assertions plus a real parse of the script in its spliced-body shape.

## Steps

1. [x] Write `tests/review-plan-workflow.test.mjs` following the `check(name, cond)` pattern already in `tests/review-plan-skill.test.mjs`, asserting that SKILL.md contains no `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` token, that it documents a `Workflow` call, that `references/review-workflow.mjs` exists and parses, and that `references/role-prompts.md` does not exist. Why: the test has to go red before the change so it is proving the change rather than describing it after the fact. Verify: `node tests/review-plan-workflow.test.mjs` exits non-zero and names the assertions that fail, with no assertion passing vacuously against the unchanged tree.
2. [x] Create `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs` with a pure-literal `export const meta = {name, description, phases: [{title: 'Review'}, {title: 'Verify'}]}`, a `FINDINGS` schema (a top-level `{assessment, findings}` object whose findings each carry `target`, `action`, `content`, `rationale`, `severity` in critical/high/medium/low — no `id`; `reviewer` is stamped on by the pipeline afterward, not returned by the agent) and a `VERDICT` schema (`refuted` boolean plus `reason`), then a `pipeline()` over the reviewer list whose first stage calls `agent(prompt, {agentType, phase: 'Review', schema: FINDINGS, label})` and whose second stage refutes only findings with `severity` of high or critical via `parallel()`, returning `.filter(Boolean)` results. Why: `pipeline()` starts verifying one reviewer's findings while others are still reviewing, so wall-clock is the slowest single chain rather than the sum of both stages. Verify: the test's parse assertion passes — `node tests/review-plan-workflow.test.mjs` reports `parses as a workflow body`.
3. [x] Add a `log()` line to the script naming how many findings were passed through unverified and read a `--deep` token from `args` that lifts the severity filter so every finding is refuted. Why: a bounded review that does not announce its bound reads as full coverage, and some users will want the exhaustive pass. Verify: `grep -n 'log(' review-workflow.mjs` shows the unverified count in the message, and `grep -n 'deep' review-workflow.mjs` shows the flag lifting the filter.
4. [x] Rewrite SKILL.md Step 3 as a Workflow-availability check that replaces the version-and-flag gate, and add `Workflow` to the skill's `allowed-tools` frontmatter. Why: this single edit is what takes the feature off the experimental flag, which is the whole objective. Verify: `grep -c CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS kit/plugins/plan-agent/skills/review-plan/SKILL.md` returns 0 and the frontmatter lists `Workflow`.
5. [x] Collapse SKILL.md Steps 4 and 5 into one step that `Read`s `references/review-workflow.mjs`, passes its contents as Workflow's inline `script` with the resolved plan path and the reviewer list (seven core, plus the three UI reviewers when Step 3b set `ui_signals_present`) as `args`, and drops the respawn-once-then-mark-unavailable prose. Why: passing the file contents inline avoids the `${CLAUDE_PLUGIN_ROOT}` expansion the Bash tool rejects outright, and the runtime's own null-on-failure contract replaces the hand-rolled retry. Verify: SKILL.md has no `SendMessage` collection step, and Step 3b's `ui_signals_present` variable is still what selects seven versus ten reviewers.
6. [x] Rewrite SKILL.md Step 6 so synthesis consumes the workflow's returned objects directly into the "Inline Edits to Apply" table, add a Verdict column to that table in `references/output-template.md`, and state that unverified findings are labelled as such in Step 6b's triage. Why: the prose round-trip is where findings were being dropped, and the triage gate should show the user which findings survived refutation and which were never checked. Verify: the output-template table header carries the verdict column, and SKILL.md Step 6 no longer instructs anyone to parse reviewer prose.
7. [x] Delete `references/role-prompts.md`, update the reference-file listing in `kit/plugins/plan-agent/README.md`, and add `Workflow` to the `tools:` frontmatter in `agents/agent-review-plan.md`. Why: the background agent invokes a skill that now calls Workflow, so without the grant the background path breaks in a way no static test would catch. Verify: `grep -rn 'role-prompts' kit/` returns nothing outside CHANGELOG.md, and `agent-review-plan.md` lists `Workflow` in `tools:`.
8. [x] Add the 9.12.0 CHANGELOG entry and bump plan-agent from 9.11.0 to 9.12.0 in `.claude-plugin/marketplace.json`. Why: this repo's CI guard fails any PR whose touched plugin version does not exceed the base branch. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.

## Tests

Tier 1 — This plan changes application code
- Objective: the review runs with no experimental flag set and returns typed, verdict-carrying findings. File: `tests/review-plan-workflow.test.mjs`; Type: smoke; Asserts: SKILL.md contains no `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` token, documents a `Workflow` call, lists `Workflow` in `allowed-tools`; `references/review-workflow.mjs` exists and parses as a workflow body; `references/role-prompts.md` is absent; Run: `node tests/review-plan-workflow.test.mjs`
- Integration: the new test is picked up by the suite's glob and the existing review-plan assertions still hold. File: `tests/run-all.sh` (existing, unmodified — it discovers `*.test.mjs` by find); Targets: both `review-plan-skill.test.mjs` and `review-plan-workflow.test.mjs`; Key cases: the untouched Step 6b/`accepted_edits`/`--triage-top` assertions must still pass, proving the engine swap did not disturb triage.
- E2E: a real review of a real plan. File: manual run, recorded in the PR's VERIFICATION section; Targets: the live Workflow runtime; Key cases: run `/plan-agent:review-plan docs/plans/replace-review-team-with-workflow.md` in a shell with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` unset, confirm ten (or seven) reviewers appear in `/workflows`, confirm returned findings carry `severity` and `verdict`, and confirm the unverified-count `log()` line appears.

## Acceptance Criteria

- [x] `grep -c CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS kit/plugins/plan-agent/skills/review-plan/SKILL.md` returns 0.
- [x] `kit/plugins/plan-agent/skills/review-plan/references/review-workflow.mjs` parses as a workflow body (exports stripped, spliced into an async function) with no syntax error.
- [x] `references/role-prompts.md` no longer exists and `grep -rn 'role-prompts' kit/` matches nothing outside CHANGELOG.md.
- [x] `review-plan`'s `allowed-tools` and `agent-review-plan.md`'s `tools:` both list `Workflow`.
- [x] A live review run with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` unset completes and returns findings carrying `severity` and `verdict` fields.
- [x] The workflow emits a `log()` line stating how many findings passed through unverified.
- [x] `--deep` lifts the severity filter so every finding is refuted.
- [x] `tests/review-plan-workflow.test.mjs` passes, and the pre-existing `tests/review-plan-skill.test.mjs` still passes unchanged.
- [x] `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with plan-agent at 9.12.0.
- [x] `bash scripts/verify.sh` exits 0.

## Completion Report

- Live-run verification ran as a 2-reviewer smoke test, not the full 10-reviewer roster — architecture and testability against this plan exercised every mechanism the objective names: `agentType` resolved the shipped agents, findings returned typed with `severity`, the filter routed 3 of 6 findings to skeptics, all 3 were refuted with substantive reasons and dropped, and the coverage line logged (run `wf_356f54f2-3aa`, 5 agents, 0 errors, 288s).
- The edited skill was not run end to end — this session loads `review-plan` from the pinned 9.11.0 plugin cache, so invoking it here would exercise the old skill; verifying the new Step 3/4/6 wiring needs a fresh session started with `--plugin-dir` and `--add-dir` pointed at this worktree.
- Two gate stages were skipped, not passed — `scripts/verify.sh` reported `e2e SKIP (not configured)` and `tests/publish/test-dist-transforms.mjs` skipped per the suite's skip list.

## Verification

Run the whole gate first: `bash scripts/verify.sh` must exit 0, and `bash tests/run-all.sh` must show both `review-plan-skill.test.mjs` and `review-plan-workflow.test.mjs` passing. A `SKIP (not configured)` line is a skip, not a pass — record it as one in the PR's VERIFICATION section.

Then prove the objective in a real session, because no static assertion can. Open a shell with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` explicitly unset (`env -u CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS claude ...`), load the plugin from this worktree with both `--plugin-dir` and `--add-dir` so the skill's `references/` resolve against the edited copy rather than a pinned cache, and run `/plan-agent:review-plan` against a real plan in `docs/plans/`. The run is correct when: it does not stop at Step 3; `/workflows` shows a Review phase and a Verify phase; the returned findings carry `severity` and `verdict` fields rather than prose; the unverified-count line appears in the narrator output; and Step 6b still presents the per-finding triage questions with a Source / Rationale for each.

Finally, confirm nothing outside the engine moved: the plan the review edited must still show a `## Team Review (YYYY-MM-DD HH:MM UTC)` section with a real timestamp, and its sibling HTML or artifact must have been re-rendered — that is the Step 7 path this change deliberately did not touch.

## Next Steps

- Port `build-fleet` to a Workflow script
  `agent()` supports `isolation: 'worktree'`, so the blocker that looked real during investigation does not exist. A typed return would delete build-fleet's whole Step 4, which currently re-verifies every agent's self-reported PR with `gh pr view` because `Skill()` has no return value.
  ```text
  Port /plan-agent:build-fleet from N parallel Agent calls to a Workflow script. Use agent() with isolation: 'worktree' per plan and a schema returning {plan, branch, prUrl, blockedOn}. The typed return should let you delete Step 4's gh pr view reconciliation pass, which only exists because Skill() has no documented return value. Keep the Step 2 AskUserQuestion confirmation in the main session — a workflow script cannot prompt. Read kit/plugins/plan-agent/skills/build-fleet/SKILL.md first.
  ```
- Schedule a backlog drift sweep
  Plans go stale on other people's clock: a plan says `status: todo` after the code shipped, or `completed` after a refactor deleted the files its criteria named. `plan-status --all` already does the scoring; nothing schedules it.
  ```text
  Set up a weekly scheduled routine that runs /plan-agent:plan-status --all against docs/plans/ and reports only the plans whose recorded status disagrees with the codebase evidence. Use the schedule skill (a cron routine), not /loop — /loop dies with the session and this needs to survive it. Read kit/plugins/plan-agent/skills/plan-status/references/bulk-mode.md for the existing scoring rules.
  ```

## Resources

- `kit/plugins/plan-agent/skills/review-plan/SKILL.md` — the skill being changed; Steps 3, 4, 5 and 6 are the edit surface, everything else is out of scope.
- `tests/review-plan-skill.test.mjs` — the existing static-assertion test for this skill, and the pattern the new test copies.
- The built-in `workflow-authoring` skill — the script API reference (`agent`/`pipeline`/`parallel`/`phase`/`log`, the schema contract, the `Date.now()` restriction, the concurrency cap). It is bundled in the `claude` binary, not on disk.
