---
status: completed
type: feature
created: 2026-08-12
issue: https://github.com/shawn-sandy/agentics/issues/546
glance: Teams get a /plan-agent:build-feature command that turns a feature idea into a committed feature doc plus a recommended split into smaller, dependency-ordered plans — without touching the proven build-proposal loop. Done means plan-agent loads at 9.2.0 and the new skill's smoke test passes.
effort: medium
workflow: never
---

# Plan: Create the build-feature skill — feature docs that split into plans

## Objective

Add a new `build-feature` skill to the plan-agent plugin that turns a feature idea into a team-readable feature doc at `docs/features/<slug>.md` — covering context, users, goals, scope, and risks — ending in a recommended breakdown into smaller sub-feature plans, each with a paste-ready `/plan-agent:implementation-plan` prompt and a saved prompt for the planning layer.

## Context

The request started as "refactor build-proposal to create a feature rather than a proposal," with the adapt-vs-new decision explicitly left open. Exploration settled it: `build-proposal` is load-bearing for three other skills — `build` Step 1b falls through to direct plan authoring only when the proposal stage writes nothing, `implementation-plan` ships a dedicated `--from-prompt` mode for its output, and `prompt` owns a caller-driven `proposal` type with sha-guarded in-place rewrites. Repurposing it would be a MAJOR bump and would break the should-we loop those skills depend on.

Decisions resolved with the owner on 2026-08-12: create a new sibling skill named `build-feature` (MINOR bump to 9.2.0); deliver both a markdown feature doc (the team deliverable) and per-sub-feature saved prompts (the planning-layer input); the sub-plan breakdown is recommend-only — generating the actual plans stays a separate user-initiated step. The interview added four more: the skill is model-invocable with trigger phrases disjoint from both siblings; prompts go through the prompt skill's standard path (no prompt-skill edits — the `proposal` type stays exclusive to build-proposal); prompts are written only at convergence, never per round; and a Tier 0 scale-down gate routes small, already-clear features straight to `implementation-plan` with no artifact written. `build-proposal` ships unchanged.

The new skill reuses build-proposal's proven loop shape — tier triage, frame-and-confirm gate, parallel research fan-out, facts-vs-decisions separation, recommendation-first questions — but converges on a different deliverable: a proposal answers "should we?"; a feature doc answers "what are we building, and how does it split into plans?"

## Files

- kit/plugins/plan-agent/skills/build-feature/SKILL.md (new) — the skill: frontmatter contract, workflow, dual-deliverable convergence
- kit/plugins/plan-agent/skills/build-feature/references/feature-doc-shape.md (new) — canonical feature-doc section order and the sub-feature breakdown format
- .claude-plugin/marketplace.json (modified) — bump plan-agent 9.1.1 → 9.2.0; add build-feature to the description's skill list
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 9.2.0 entry
- kit/plugins/plan-agent/README.md (modified) — components-table row and a build-feature section mirroring build-proposal's
- tests/plugins/test-build-feature.sh (new) — structural smoke test mirroring test-build-proposal.sh
- tests/plugins/test-exitplanmode-guard.sh (modified) — add the new SKILL.md to the guard whitelist

## Steps

1. [x] Scaffold kit/plugins/plan-agent/skills/build-feature/SKILL.md with the frontmatter contract: `name: build-feature`, `model: claude-fable-5`, a three-part description (≤200 chars total, first sentence ≤80) whose trigger — "feature doc", "break this feature into plans" — shares no phrase with build-proposal's should-we trigger, `allowed-tools` mirroring build-proposal (Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, ToolSearch, ExitPlanMode, WebSearch, WebFetch, Skill, Agent, Artifact), and `argument-hint: "<feature idea> [--dir <path>] [--tier 0|1|2]"` Why: the frontmatter is the installed contract — the skill stays model-invocable like its sibling (no disable-model-invocation), the description drives that activation without colliding with build-proposal or implementation-plan, and a complete allowed-tools list keeps the skill from prompting mid-run Verify: `grep -q "^name: build-feature$"` on the file passes and the description line measures ≤200 chars with a ≤80-char first sentence.
2. [x] Author the SKILL.md workflow body: the verbatim plan-mode guard as the first step, then a right-sizing triage with a Tier 0 scale-down gate — a single-surface, already-clear feature routes straight to `/plan-agent:implementation-plan` with no artifact written — then frame-and-confirm (restate the feature in one line, confirm via AskUserQuestion before research), tiered parallel research fan-out (codebase Agent in flight before the first web fetch, never blocking), facts-vs-decisions separation with recommendation-first questions, then convergence on the feature doc written to the resolved features directory (`planAgent.featuresDirectory` via settings precedence, falling back to `${PWD}/docs/features/`) Why: reusing build-proposal's loop shape — including its Tier 0 answer-and-route gate — keeps the siblings consistent and stops a one-plan feature from getting a 10-section doc, while the features-directory resolution mirrors how the plans and prompts directories already resolve Verify: the body is under 500 lines, names Tier 0 routing to implementation-plan, and the guard line "**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state." appears verbatim exactly once.
3. [x] Specify the dual-deliverable convergence in the SKILL.md body: the feature doc ends with a Sub-feature breakdown section — each sub-feature carries a rationale, an S/M/L size, its dependency order, and a paste-ready `/plan-agent:implementation-plan` prompt — and, only once the breakdown is settled at convergence (never per round), each sub-feature also gets a saved prompt at `<prompts-dir>/feature-<slug>-<sub-slug>.md` authored by delegating to `plan-agent:prompt` through its standard authoring path with an explicit `--out` and `--answers-gathered` (no edits to the prompt skill; the `proposal` type stays exclusive to build-proposal); the skill never invokes implementation-plan itself on Tier 1/2 runs Why: recommend-only was the resolved decision — the skill's seam is "what and how it splits", plan generation stays user-initiated, and convergence-only prompt writes avoid churning N files per round and stale prompts when sub-features merge or split mid-loop Verify: the body names `docs/features/`, the `feature-<slug>-<sub-slug>.md` prompt path, and states prompts are written at convergence; outside the Tier 0 routing line it contains no `Skill(skill: "plan-agent:implementation-plan"` call.
4. [x] Write references/feature-doc-shape.md: the canonical feature-doc section order (frontmatter, title and framing note, context, problem and users, goals and success metrics, scope in/out, UX and accessibility notes, risks, sub-feature breakdown, next step) with the breakdown-entry format and the paste-ready prompt template, scaled by tier Why: build-proposal keeps its artifact shape in a reference file so the SKILL.md body stays under the 500-line budget — the sibling follows the same split Verify: the SKILL.md link to references/feature-doc-shape.md resolves to an existing file.
5. [x] Register and document the skill: bump plan-agent to 9.2.0 in .claude-plugin/marketplace.json and add build-feature to the description's skill list; add a 9.2.0 CHANGELOG entry; add the components-table row and a build-feature section to README.md Why: the marketplace entry is what installs; the version guard CI fails any plugin edit without a bump above main Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` passes and `grep -c build-feature kit/plugins/plan-agent/README.md` is ≥2.
6. [x] Add tests/plugins/test-build-feature.sh mirroring test-build-proposal.sh — assert the SKILL.md frontmatter contract, the allowed-tools set, the three-part description budget, the references file, marketplace registration above origin/main, the dual-deliverable paths, and the Tier 0 routing line — and append the new SKILL.md path to the whitelist in tests/plugins/test-exitplanmode-guard.sh Why: every plan-agent skill ships with a structural smoke test, and the guard test greps a fixed file list that must name every mutating skill Verify: `bash tests/plugins/test-build-feature.sh` and `bash tests/plugins/test-exitplanmode-guard.sh` both exit 0.

## Acceptance Criteria

- [x] kit/plugins/plan-agent/skills/build-feature/SKILL.md exists with `name: build-feature` and loads via `claude --plugin-dir kit/plugins/plan-agent`
- [x] The SKILL.md body directs both deliverables: a feature doc under the resolved features directory and per-sub-feature saved prompts authored via plan-agent:prompt with explicit --out paths
- [x] The sub-feature breakdown is recommend-only: on Tier 1/2 runs SKILL.md invokes no plan generation on the user's behalf; every sub-feature carries a paste-ready prompt instead
- [x] The skill carries a Tier 0 gate: a small, already-clear feature routes to /plan-agent:implementation-plan with no feature doc or prompt written
- [x] Saved prompts are written only at convergence, via the prompt skill's standard path — `git diff origin/main -- kit/plugins/plan-agent/skills/prompt/` is empty
- [x] build-proposal is byte-identical to main: `git diff origin/main -- kit/plugins/plan-agent/skills/build-proposal/` is empty
- [x] .claude-plugin/marketplace.json carries plan-agent 9.2.0 and `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0
- [x] `bash tests/plugins/test-build-feature.sh` exits 0
- [x] `bash tests/plugins/test-exitplanmode-guard.sh` exits 0 with the new skill in its whitelist

## Tests

Tier 1 — This plan creates plugin source files (skills are this marketplace's application code)
- Objective: build-feature ships installed, dual-deliverable, and recommend-only. File: tests/plugins/test-build-feature.sh; Type: smoke; Asserts: SKILL.md frontmatter contract (name, model, no disable-model-invocation), allowed-tools set, three-part ≤200-char description, references/feature-doc-shape.md present, marketplace registers plan-agent above origin/main, body names docs/features/ and feature-<slug>-<sub-slug>.md, and the Tier 0 routing to implementation-plan is present; Run: bash tests/plugins/test-build-feature.sh
- Integration: the plan-mode guard whitelist covers the new skill. File: tests/plugins/test-exitplanmode-guard.sh; Targets: build-feature/SKILL.md guard line; Key cases: guard present verbatim, file listed in the test's FILES array; Run: bash tests/plugins/test-exitplanmode-guard.sh

## Verification

From the repo root: `bash tests/plugins/test-build-feature.sh && bash tests/plugins/test-exitplanmode-guard.sh && git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` — all three exit 0. Then load the plugin end-to-end: `claude --plugin-dir kit/plugins/plan-agent` and confirm `/plan-agent:build-feature` appears in the command list and its help echoes the `<feature idea> [--dir <path>] [--tier 1|2]` argument hint. Finally, `git diff origin/main --stat -- kit/plugins/plan-agent/skills/build-proposal/` prints nothing, proving the sibling shipped untouched.

## Next Steps

- Route feature-shaped ideas from build-proposal's triage to build-feature
  A one-line addition to build-proposal's Tier table so "we're definitely building this, help me shape it" routes to the sibling instead of spinning up a should-we loop. Deliberately out of scope here to keep build-proposal byte-identical.
  ```text
  In the agentics repo (kit/plugins/plan-agent), add a routing line to the
  build-proposal skill's right-sizing triage: when the idea is already a
  committed feature (no should-we question), route to
  /plan-agent:build-feature instead of running the proposal loop. Bump the
  plan-agent version in .claude-plugin/marketplace.json (PATCH) and add a
  CHANGELOG entry. Verify: bash tests/plugins/test-build-proposal.sh exits 0
  and the triage table names build-feature.
  ```
- Wish list: a features gallery mirroring the plans library
  A `features-library` skill scanning docs/features/ into a filterable index page, following plans-library's pattern.
  ```text
  In the agentics repo (kit/plugins/plan-agent), add a features-library skill
  that scans docs/features/*.md and builds a filterable HTML index, following
  the existing plans-library skill's structure and generator-script pattern.
  Bump the plan-agent minor version in .claude-plugin/marketplace.json and add
  a CHANGELOG entry. Verify: the generated index lists every file in
  docs/features/ and the plan-agent test scripts still exit 0.
  ```

## Resources

- kit/plugins/plan-agent/skills/build-proposal/SKILL.md — the loop shape, tier triage, and artifact-resolution pattern the sibling reuses
- kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md — the canonical-shape reference-file pattern feature-doc-shape.md mirrors
- tests/plugins/test-build-proposal.sh — the smoke-test template for test-build-feature.sh
- .claude/rules/plugin-patterns.md — frontmatter contract, three-part description budget, and the verbatim plan-mode guard
- kit/plugins/plan-agent/skills/build/references/author-plan-chain.md — why build-proposal's no-artifact Tier 0 contract must stay untouched
