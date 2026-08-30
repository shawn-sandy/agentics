---
status: completed
modified: 2026-08-30
type: feature
created: 2026-08-30
repo: agentics
glance: finalize-plan only ever asked whether each planned thing was built, so a plan that grew scope during implementation was marked completed while its published artifact still described the original scope. Step 3d asks the other direction and routes the answer into sections the renderer already handles; done means unplanned work and changed approaches reach the shared page.
---

# Plan: Reconcile a plan against what actually shipped

## Objective

Add a reconcile step to `finalize-plan` that compares a plan against the
commits that actually shipped it, then records work that was **shipped but
unplanned** and work that was **built differently** into the plan spec, so a
published plan artifact describes what was built rather than only what was
imagined before the work started.

## Context

`plan-agent` already keeps a published plan's todo and status state current.
`finalize-plan` ticks criteria from codebase evidence, writes a
`## Completion Report`, re-renders, and republishes to the spec's
`artifact-url:` (9.9.0); `plan-status` Step 8 republishes after a status write.

All of that answers one direction of one question: *was each planned thing
built?* Nothing ever asked *what got built that the plan never mentions.* A
plan whose implementation grew a new file, a new flag, or a different approach
was marked completed with its shared claude.ai page still describing the
original scope. The under-reporting is silent and public — the page is what
everyone else reads.

The obvious shape, a new `## What Shipped` section, was rejected: the spec
parser in `plan-spec.mjs` recognises a fixed set of headings and silently drops
anything else on the next rebuild, so a new section costs parse, render,
`buildDigest` round-trip, `extractSections`, and CSS. Reusing the existing
`## Completion Report` was also rejected — every entry there renders with a red
dot (`.report-list dt::before`), which reads as a defect, and work that shipped
fine is not a defect. Routing the four buckets into sections the renderer
already handles costs no renderer change at all.

## Decisions

- Reconcile extends `finalize-plan` rather than becoming its own skill — that skill already resolves the plan, scores evidence, writes the spec, re-renders, and republishes to the artifact URL; a separate skill would duplicate all five.
- Evidence comes from git, not `gh` — the spec's own commit history is precise because this repo commits the plan file alongside the change it describes, and it needs no auth.
- Unplanned work is written as a `[x]` step rather than a prose note — the step list is what a reader treats as the record of what was built.

## Files

- `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` (modified) — Step 3d, the commit range and the bucketing table
- `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` (modified) — 5c2, 5d2, and the scoped 5d removal
- `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` (modified) — names 3d and 5c2/5d2 so the model reaches them
- `kit/plugins/plan-agent/README.md` (modified) — user-facing description
- `kit/plugins/plan-agent/CHANGELOG.md` (modified) — 9.11.0
- `.claude-plugin/marketplace.json` (modified) — version 9.10.1 to 9.11.0
- `tests/plugins/test-plan-reconcile.sh` (new) — the objective test

## Steps

1. [x] Write the objective test `tests/plugins/test-plan-reconcile.sh` and confirm it fails. Why: the rules being added are prose, so the only thing that can hold them in place is a test that greps for each one; written after the fact it would assert whatever was written rather than what was required. Verify: `bash tests/plugins/test-plan-reconcile.sh` exits non-zero, reporting 11 failures.
2. [x] Add `### 3d — Reconcile against what shipped` to `references/evidence-analysis.md`, between 3c and Step 4. Why: 3d is an observation step and belongs with the other evidence steps, ahead of the Step 4 confirmation the user answers. Verify: checks 2, 2a, 2b, and 2c pass.
3. [x] Add `5c2` and `5d2` to `references/write-completions.md`, and scope 5d's removal rule to its own section. Why: 5d's "remove the report and add nothing" describes exactly the state a clean run with extra scope lands in, so unscoped it discards reconcile output on the happy path. Verify: checks 3, 3a, 4, 4a, and 5 pass.
4. [x] Name Step 3d and 5c2/5d2 in `finalize-plan/SKILL.md`. Why: a reference step the core never names is a step the model never reaches, since references are only fetched because the core points at them. Verify: check 1 passes.
5. [x] Document the reconcile in the plugin README and add the 9.11.0 CHANGELOG entry. Why: the behaviour changes what a completed plan contains, which users need to be able to anticipate. Verify: check 6 passes.
6. [x] Bump `plan-agent` to 9.11.0 in `.claude-plugin/marketplace.json`. Why: a CI guard fails any PR touching a plugin whose marketplace version does not exceed the base branch. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.
7. [x] Run the full suite. Why: the skill files are covered by description-budget, progressive-disclosure, and frontmatter tests that a prose addition can trip. Verify: `bash scripts/verify.sh` exits 0.

## Tests

Tier 1 — This plan modifies plugin runtime instruction files and adds a test
- Objective: `finalize-plan` carries a rule for every reconcile bucket, so unplanned and differently-built work reaches the spec. File: tests/plugins/test-plan-reconcile.sh; Type: smoke; Asserts: the core names Step 3d, 3d derives its range from `git log --follow` with an `...HEAD` fallback and names both new buckets, 5c2 writes an `Unplanned:` step under a trailing `### Phase: Unplanned` in phased specs, 5d2 routes a changed approach to `## Decisions`, and 5d's removal is scoped so it cannot discard either write; Run: bash tests/plugins/test-plan-reconcile.sh

## Acceptance Criteria

- [x] `finalize-plan` derives the shipped commit range from the spec's own git history, falling back to the default-branch range when the spec commit has not landed yet
- [x] Work shipped but never planned is written into `## Steps` as an already-done `Unplanned:` step
- [x] In a phased spec those steps land under a trailing `### Phase: Unplanned`, so 5a0's phase gate does not count them as unfinished
- [x] A changed approach is written to `## Decisions`, never to the red-dotted `## Completion Report`
- [x] A fully verified plan keeps its reconcile findings — 5d's removal rule cannot discard them
- [x] No change to `build-plan-html.mjs`, `plan-spec.mjs`, or `plan-shell.mjs` is required
- [x] `bash scripts/verify.sh` exits 0

## Verification

Run `bash tests/plugins/test-plan-reconcile.sh` — 11 checks, all passing.
Then run `bash scripts/verify.sh` and confirm it exits 0, which covers the
skill-frontmatter, description-budget, and progressive-disclosure tests that a
prose addition to a SKILL.md can trip. Confirm `git diff --stat` touches no
file under `kit/plugins/plan-agent/scripts/`, which is the claim that the
feature needed no renderer change.
