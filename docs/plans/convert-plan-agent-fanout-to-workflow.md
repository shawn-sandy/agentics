---
status: todo
type: refactor
created: 2026-09-01
effort: high
workflow: never
glance: plan-agent hand-rolls every agent fan-out in prose the model has to obey, and its ten-reviewer panel writes unverified findings straight into plans. Moving both to the Workflow tool makes the orchestration deterministic and adds the refutation pass that is missing today. Done when a live review run produces schema-validated, adversarially-verified findings with no Agent Teams gate in the path.
artifact-url: https://claude.ai/code/artifact/31a64885-e4e1-4617-b1e0-f3311594252b
---

# Plan: Move plan-agent's fan-out from prose to the Workflow runtime

## Objective

Convert plan-agent's two hand-rolled agent fan-outs — the `plan-documenter`
batch sweep and the `review-plan` ten-reviewer panel — to the Workflow tool, and
use the conversion to add the adversarial verification stage `review-plan`
currently lacks.

## Context

Every fan-out in plan-agent today is written as prose a model must follow.
Grep confirms the plugin makes zero use of the `Workflow` tool, `/loop`,
`CronCreate`, `ScheduleWakeup`, or `Monitor`.

That costs three things:

- **`review-plan` carries 46 lines of pure orchestration** across Steps 3, 4, 5
  and 8 of its 255-line SKILL.md — a `claude --version` semver gate, a
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` flag check, the spawn roster, a
  wait/collect/respawn-once retry loop, and "Clean up the team." All of it is
  runtime mechanics expressed as instructions.
- **Findings are free text.** Reviewers report via `SendMessage` in a prose
  block; Step 6 re-parses that prose into Step 7's selector-to-spec-target edit
  table. There are 20 near-identical "Report Back" blocks maintaining that
  format — 10 in `agents/plan-reviewer-*.md` and 10 more in
  `references/role-prompts.md`.
- **No finding is ever checked for correctness.** Step 7 verifies only that an
  edit _landed_ ("re-read the edited file and confirm each accepted edit's
  content is actually present"). Under `--background` the Step 6b human triage
  is skipped entirely, so a plausible-but-wrong finding is written into the
  user's plan with nothing standing between the reviewer and the spec.

The reviewers themselves are fine and stay as they are. `agent()` accepts
`agentType`, so the ten existing subagent definitions are reused verbatim —
this is a change of orchestrator, not a rewrite of the panel.

**Risk — Workflow availability inside a subagent is unconfirmed.** Both
converted surfaces can run detached: `plan-documenter` is a subagent, and
`review-plan --background` runs via the `agent-review-plan` subagent. Whether
the Workflow tool is callable from a subagent is not documented either way.
Step 1 settles it before any conversion work, and both phases carry the same
fallback: dispatch concurrent `Agent` calls instead, which captures most of the
wall-clock win and needs no new tool grant.

**Out of scope, and why:**

- `build` — its steps are sequentially dependent; `references/phase-checkpoints.md`
  already argues this correctly and needs no change.
- `build-fleet` — already fans out with `isolation: "worktree"`; converting it
  trades working dispatch for a report table.
- `plan-maintenance`'s archive render loop — file I/O over `plan-agent-render`,
  not reasoning. A shell loop beats spawning agents.
- Phase checkpoints — they bound context, not parallelism. Different problem.
- Everything in `git-agent` — `ship-autonomous` already event-subscribes for CI
  and explicitly forbids polling. Correct as written.

## Decisions

- **The Agent Teams path is removed outright, not kept as a fallback.** Workflow
  is a built-in tool with no feature flag, so removing the gate lowers the
  plugin's requirements bar rather than raising it. A dual path would need two
  "Report Back" contracts in all 10 reviewer agents and would drift.
- **Adversarial verification is bounded at the top 5 findings by risk.** Ten
  reviewers plus five verifiers is 15 agents, at the medium workflow guideline.
  The bound tracks the Highest-Risk Issues synthesis section, which is what
  Step 6b triages first anyway. Dropped findings are `log()`-ed, per the
  plugin's own "no silent caps" rule.
- **Two shippable phases, not the RED/GREEN/VERIFY/SHIP shape.** Each phase is
  an independent version bump and PR. Test-first ordering is preserved inside
  each phase's steps instead of as top-level phase groups.
- **The schema replaces both "Report Back" contracts.** With `schema` forcing a
  `StructuredOutput` call, the 20 duplicated prose blocks collapse to one shared
  schema definition in `role-prompts.md`.
- **The workflow ends at findings; the skill keeps judgment and every file
  write.** A Workflow script cannot call `AskUserQuestion`, so Step 6b's triage
  and all of Step 7's spec edits, re-render, and artifact republish stay in
  SKILL.md.

## Files

- `kit/plugins/plan-agent/agents/plan-documenter.md` (modified) — Step 5 becomes a Workflow fan-out
- `kit/plugins/plan-agent/skills/review-plan/SKILL.md` (modified) — Steps 3, 4, 5, 8 deleted; Step 6 consumes structured findings
- `kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md` (modified) — 10 SendMessage blocks collapse to one shared schema
- `kit/plugins/plan-agent/skills/review-plan/references/output-template.md` (modified) — Inline Edits table gains a verdict column
- `kit/plugins/plan-agent/agents/plan-reviewer-{architecture,completeness,testability,risk,conventions,product,security,ux,accessibility,frontend}.md` (modified) — 10 files, "Report Back" replaced by the return-value contract
- `kit/plugins/plan-agent/agents/agent-review-plan.md` (modified) — drops the "Agent Team" description
- `kit/plugins/plan-agent/commands/review-plan-bg.md` (modified) — drops the "Agent Team" description
- `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` (modified) — Step 8's Agent-Teams-unavailable handler at lines 691-697 becomes dead code
- `kit/plugins/plan-agent/README.md` (modified) — 11 "Agent Team" mentions
- `kit/plugins/plan-agent/CHANGELOG.md` (modified) — one entry per phase
- `kit/plugins/plan-agent/.claude-plugin/plugin.json` (modified) — version bump per phase
- `tests/plan-documenter-workflow.test.mjs` (new) — Phase 1 static assertions
- `tests/review-plan-skill.test.mjs` (modified) — its Step 4 roster-line parsing breaks when Step 4 is deleted

## Steps

### Phase: 1 — plan-documenter batch sweep

1. Confirm whether the `Workflow` tool is callable from inside a subagent: dispatch a throwaway `general-purpose` agent whose only instruction is to report which of `Workflow` and `Agent` it can see, then record the answer in `## Decisions`. If Workflow is unavailable to subagents, both phases switch to concurrent `Agent` dispatch and every later step reads "Agent fan-out" where it says "Workflow". Why: both converted surfaces run detached, so an unavailable tool would dead-end the conversion after the diff is already written. Verify: the dispatched agent's report names both tools explicitly, and a `## Decisions` bullet records which path the plan is on.

2. Write `tests/plan-documenter-workflow.test.mjs` asserting that `agents/plan-documenter.md` (a) documents a concurrent fan-out in Step 5, (b) still filters to `status: completed` plus 30-days-old, (c) still short-circuits when K is 0, and (d) grants the dispatch tool in its frontmatter `tools:` list. Run it and watch it fail. Why: `tests/run-all.sh` auto-discovers `tests/**/*.test.mjs` with no wiring, and a test written after the edit proves nothing. Verify: `node tests/plan-documenter-workflow.test.mjs` exits non-zero and names the missing assertions.

3. Rewrite Step 5 of `agents/plan-documenter.md` as a concurrent fan-out — one agent per undocumented plan, each delegating to the `documenting-plans` skill for one plan path. No barrier and no worktree isolation: each agent writes a distinct `docs/<slug>.md` and shares no state. Preserve Steps 0-4 verbatim. Why: the outputs are independent, so the sequential loop buys nothing but wall-clock; a barrier would add latency with no cross-item dependency to justify it. Verify: `node tests/plan-documenter-workflow.test.mjs` exits 0.

4. Handle per-item failure explicitly: a failed thunk resolves to `null`, so filter for it and report which plans failed to document rather than dropping them from the tally. Update Step 4's scope report to print attempted / succeeded / failed. Why: the sequential loop surfaced a failure by stopping; a fan-out silently returns a shorter array, which reads as "fewer plans needed docs". Verify: the printed tally distinguishes all three counts on a run where at least one agent fails.

5. Add the dispatch tool to the agent's frontmatter `tools:` list and raise `maxTurns` from 50, or drop the key. Why: the ceiling existed to bound a sequential per-plan loop that no longer runs in this agent's own turns; left at 50 it silently truncates a large sweep. Verify: `grep -n 'maxTurns\|^tools:' kit/plugins/plan-agent/agents/plan-documenter.md` shows the updated values.

6. Run a live sweep against `docs/plans/` in this repo and confirm the documented plans match what a sequential run produces. Why: the static test asserts the markdown says the right thing, not that the agent behaves. Verify: the sweep reports a non-zero K, every reported doc exists at `docs/<slug>.md`, and `git status` shows exactly those files.

7. Bump the plugin version, add the CHANGELOG entry, and confirm `bash tests/run-all.sh` is green. Why: the repo ships per-plugin semver and CI checks it. Verify: `bash tests/run-all.sh` exits 0.

### Phase: 2 — review-plan panel

8. Extend `tests/review-plan-skill.test.mjs` for the post-conversion shape before touching SKILL.md: replace its two roster-line assertions, which match on the literal Step 4 line prefixes, with assertions against the workflow roster, and add assertions that the Agent Teams gate is gone and that a verification stage is documented. Run it and watch it fail. Why: those assertions parse Step 4's exact prefixes and break the moment Step 4 is deleted, so this is the one test guaranteed to go red and it leads. Verify: `node tests/review-plan-skill.test.mjs` exits non-zero naming the new assertions, while its existing walkthrough and background-mode checks still pass.

9. Define one shared findings schema in `references/role-prompts.md` — severity, the target selector from Step 7's mapping table, the proposed content, and the originating role — and delete the 10 per-role `SendMessage` blocks that duplicate it in prose. Why: `schema` forces a validated `StructuredOutput` call, so the format contract lives in one place instead of 10 hand-maintained copies that can drift. Verify: `grep -c SendMessage kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md` returns 0.

10. Replace each `## Report Back` section in the 10 `agents/plan-reviewer-*.md` files with the return-value contract, pointing at the shared schema. Why: a subagent under `schema` returns a validated object, so an instruction to call `SendMessage` is both wrong and a second contract to maintain. Verify: `grep -rl SendMessage kit/plugins/plan-agent/agents/` returns nothing.

11. Replace `review-plan` Steps 3, 4, 5 and 8 with a single Workflow invocation: `pipeline()` over the reviewer roster, stage 1 spawning `agent({agentType, schema, phase: 'Review'})` per role, stage 2 adversarially refuting that reviewer's findings as soon as they land. Keep Step 3b's UI-signal detection choosing 7 versus 10 roles. Why: `pipeline` has no barrier, so architecture findings verify while the security reviewer is still reading; the deleted steps were runtime mechanics the runtime now performs. Verify: `node tests/review-plan-skill.test.mjs` exits 0.

12. Bound the verify stage at the top 5 findings ranked by the Highest-Risk synthesis and `log()` what was dropped. Why: 10 reviewers times 3-5 findings each would put 30-50 verifiers in one workflow, and a silent bound reads as full coverage. Verify: a live run on a plan producing more than 5 findings prints the dropped count.

13. Replace the deleted respawn-once retry with explicit null handling: a failed reviewer resolves to `null`, so filter, then name each missing role in the synthesis as "Reviewer unavailable" exactly as Step 5 did. Why: the retry loop was the only thing distinguishing a failed reviewer from one with no findings, and `.filter(Boolean)` alone would erase that distinction. Verify: a run with one deliberately-broken `agentType` still synthesizes and names the unavailable role.

14. Rewrite Step 6 to consume the structured findings — the selector-to-spec-target mapping becomes a lookup on a typed field — and add the verdict to `references/output-template.md`'s Inline Edits table so triage shows whether a finding survived refutation. Leave Step 6b and Step 7 otherwise untouched. Why: the workflow's job ends at findings; triage and every file write stay in the skill, which is the only layer that can call `AskUserQuestion`. Verify: a live foreground run reaches the Step 6b triage prompt with verdicts populated.

15. Update the surviving Agent Teams references: `agents/agent-review-plan.md`, `commands/review-plan-bg.md`, the 11 mentions in `README.md`, and the now-dead handler at `skills/implementation-plan/SKILL.md:691-697`. Why: `implementation-plan` Step 8 still instructs the model to relay a hard-stop that can no longer fire, which sends users to fix a flag that no longer gates anything. Verify: `grep -rn 'AGENT_TEAMS\|2\.1\.32' kit/plugins/plan-agent/` returns nothing.

16. Run `/plan-agent:review-plan` end to end against a real plan in `docs/plans/`, then run it again with `--background`. Why: the background path is the one where verification actually matters, because it skips the human triage that currently catches bad findings. Verify: both runs complete; the foreground run reaches triage with verdicts; the background run applies edits and reports the applied/skipped tally.

17. Bump the plugin version, add the CHANGELOG entry, and confirm `bash tests/run-all.sh` is green. Why: same per-plugin semver gate as Phase 1, and this phase touches 17 files. Verify: `bash tests/run-all.sh` exits 0.

## Tests

Tier 1 — This plan changes application code

- Objective: a `review-plan` run produces schema-validated findings that survived adversarial refutation, with no Agent Teams gate anywhere in the path. File: `tests/review-plan-skill.test.mjs`; Type: smoke; Asserts: SKILL.md documents the Workflow roster and a bounded verify stage, no file under `kit/plugins/plan-agent/` references `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` or `2.1.32`, and no reviewer agent instructs a `SendMessage` call; Run: `node tests/review-plan-skill.test.mjs`
- Unit: the plan-documenter fan-out contract. File: `tests/plan-documenter-workflow.test.mjs`; Targets: `agents/plan-documenter.md`; Key cases: concurrent dispatch documented in Step 5, eligibility filter preserved, K=0 early exit preserved, dispatch tool granted in frontmatter, failure tally distinguishes attempted/succeeded/failed
- Integration: the whole suite still passes. File: `tests/run-all.sh`; Targets: every `tests/**/test-*.sh`, `tests/**/test-*.mjs`, `tests/**/*.test.mjs`; Key cases: `test-progressive-disclosure.sh` and `test-command-delegation.sh` stay green — both reference the `documenting-plans` skill and its command wrapper, neither of which this plan touches; Run: `bash tests/run-all.sh`

## Acceptance Criteria

- [ ] `grep -rn 'AGENT_TEAMS\|2\.1\.32' kit/plugins/plan-agent/` returns no matches
- [ ] `grep -rl SendMessage kit/plugins/plan-agent/agents/ kit/plugins/plan-agent/skills/review-plan/` returns no matches
- [ ] `bash tests/run-all.sh` exits 0
- [ ] A live `/plan-agent:review-plan` run on a real plan in `docs/plans/` reaches Step 6b triage with a refutation verdict on each of the top 5 findings
- [ ] A live `/plan-agent:review-plan <path> --background` run applies edits and reports the applied/skipped tally without any human prompt
- [ ] A live `plan-documenter` sweep documents every eligible plan concurrently and reports attempted / succeeded / failed as three distinct counts
- [ ] `review-plan/SKILL.md` no longer contains Steps 3, 4, 5 or 8, and its line count is below the current 255
- [ ] Both phases carry their own version bump and CHANGELOG entry

## Verification

Run the two converted surfaces the way a user would, on this repo's own plans.

For Phase 1: pick a window where `docs/plans/` holds at least two plans that are
`status: completed`, 30+ days old, and have no `docs/<slug>.md`. Run the
documenter sweep. Confirm the scope report's K matches the number of plans that
actually gained a doc, that every reported path exists on disk, and that
`git status` shows exactly those files and nothing else. Then re-run it — the
second run must report K of 0 and write nothing, proving the
already-documented skip survived the conversion.

For Phase 2: run `/plan-agent:review-plan` against a plan with UI signals, so
all ten reviewers spawn. Confirm the run never mentions a version or feature
flag, that the triage prompt shows a refutation verdict per finding, and that
the dropped-findings count is printed when more than five findings exist. Then
run the same plan with `--background` and confirm it applies edits unattended
and reports its tally. Finally run `bash tests/run-all.sh` and confirm the whole
suite is green, including the two shell tests that reference `documenting-plans`.

## Next Steps

- Schedule the documentation sweep instead of remembering to run it
  The `plan-documenter` description already names a "scheduled weekly documentation sweep" as its use case, but nothing schedules it. Once Phase 1 lands, a cron routine makes that real — and a routine, not `/loop`, because `/loop` dies with the session.

  ```text
  Create a weekly scheduled routine that runs the plan-agent plan-documenter sweep over docs/plans/ in the agentics repo, then runs /plan-agent:plan-maintenance --index to regenerate the plans README. Report what it documented.
  ```

- Reconsider build-fleet once the Workflow pattern is proven twice
  Deferred deliberately in this plan. `agent()` does support `isolation: 'worktree'`, so the conversion is possible — but each fleet agent runs 20+ minutes and the harness already notifies on completion, so the only gain is a deterministic report table. Revisit with two shipped conversions as evidence.
  ```text
  Assess whether plan-agent's build-fleet skill should move from background Agent dispatch to the Workflow tool, now that plan-documenter and review-plan have both been converted. Weigh the deterministic result collection against the loss of the current dispatch-and-forget behavior.
  ```

## Unresolved Questions

- Can the `Workflow` tool be called from inside a subagent? Step 1 settles this
  empirically before any conversion work. Both phases carry the same fallback —
  concurrent `Agent` dispatch — so a "no" changes the mechanism, not the plan.

## Resources

- `kit/plugins/plan-agent/skills/review-plan/SKILL.md` — the 255-line skill under
  conversion; Steps 3, 4, 5 and 8 are the 46 lines that go away.
- `kit/plugins/plan-agent/skills/build/references/phase-checkpoints.md` — already
  argues correctly that sequential plan steps must not be fanned out. The reason
  `build` is out of scope.
- `tests/run-all.sh` — auto-discovers `tests/**/*.test.mjs`, so the new Phase 1
  test needs no CI wiring. Its skip list documents why the behavioral
  `test-skill-behavior-baselines.sh` harness is run by hand.
