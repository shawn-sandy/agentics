---
status: completed
modified: 2026-09-13
type: feature
created: 2026-09-13
repo-name: agentics
glance: build-proposal researches an idea, synthesizes one core finding, and goes straight to per-decision questions, so the proposal it authors is written around an approach the human never chose from a menu. This adds a Step 4b gate that lays out two to four candidate solutions, records the pick as the first locked decision, and authors only the chosen one.
---

# Plan: Add the approach gate to build-proposal

## Objective

Insert a `Step 4b — Choose the approach` gate into `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` so that, once research has settled the facts, the skill presents candidate solutions for selection and writes the proposal around the selected one.

## Context

`build-proposal` (plan-agent 9.17.2) runs an 8-step loop: Frame, Confirm the ask (Step 1b gate), Fan out research, Synthesize the core finding, Separate facts from decisions, Resolve decisions, Author, Deepen, Converge. Step 3 collapses the research into a single core finding and an idea-versus-ours Side-by-side table; Step 5 then asks per-decision questions. Nowhere does the human pick between whole approaches, so the proposal that Step 6 authors is built around whichever solution the synthesis happened to favour. The requester's rule is the reverse: present multiple solutions for selection first, then write the proposal from the pick.

Constraints found in the repo:

- `tests/plugins/test-build-proposal.sh` check 6 asserts exactly eight `### Step [1-8] —` headings, so the gate is a lettered sub-step, following the `Step 1b` precedent, not a ninth step.
- The saved prompt's slots are pinned by `tests/plugins/test-write-prompt-proposal-type.sh` and `tests/plugins/test-proposal-prompt-pipeline.sh`. The chosen design (selected by the requester from three alternatives) adds no slot: the pick rides in the existing `{{LOCKED_DECISIONS}}` and `{{COMPARISON_TABLE}}` slots, and at Tier 1, which omits both, as the closing line of `{{CONTEXT}}`. The rejected alternatives were a dedicated `OPTIONS_CONSIDERED` slot (touches the `prompt` skill and two slot tests) and folding the menu into Step 5 (buries the approach choice among per-decision questions).
- The baseline *keep the current approach* is always one candidate, so the menu never collapses to a single option and needs no escape hatch.
- `build-feature` shares the loop shape but writes feature docs, not proposals. It is out of scope.
- Any edit under `kit/plugins/plan-agent/` needs a `marketplace.json` bump; a new workflow gate is a MINOR bump to 9.18.0.

## Files

- kit/plugins/plan-agent/skills/build-proposal/SKILL.md (modified) — Step 4b inserted; Step 3, Step 5, the tier table note, and the guardrail count adjusted
- kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md (modified) — Side-by-side compares candidates; Locked decisions opens with the pick; Tier 1 note
- kit/plugins/plan-agent/skills/build-proposal/references/operating-principles.md (modified) — eleventh principle; AskUserQuestion row names Step 4b
- kit/plugins/plan-agent/README.md (modified) — build-proposal section: loop bullet and a Step 4b bullet
- README.md (modified) — build-proposal row in the plan-agent skill table; generated Plugin Reference Table regenerated for the version
- docs/guides/how-to/plan-agent.md (modified) — build-proposal "What happens" bullet
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 9.18.0 entry
- .claude-plugin/marketplace.json (modified) — plan-agent 9.17.2 to 9.18.0
- tests/plugins/test-build-proposal.sh (modified) — check 16 pins the gate

## Steps

1. [x] Add check 16 to tests/plugins/test-build-proposal.sh asserting a `### Step 4b —` heading between Step 4 and Step 5 whose body names `AskUserQuestion`, `(Recommended)`, the *keep the current approach* baseline, and Locked decisions, and that artifact-shape.md and operating-principles.md carry the candidate comparison and the new principle. Why: the gate is a contract, and an unpinned contract drifts on the next edit. Verify: `bash tests/plugins/test-build-proposal.sh` fails on check 16 and only check 16 before the skill is edited.
2. [x] Insert `### Step 4b — Choose the approach (the second gate)` into SKILL.md after Step 4: one recommendation-first `AskUserQuestion` with two to four candidates including the baseline, the pick recorded as the first Locked decision naming what it was chosen over, rejected candidates kept in the Side-by-side, Steps 5 and 6 scoped to the pick, the Tier 1 placement rule, and the Other-answer rule. Why: this is the behaviour the requester asked for, at the point where facts are settled and decisions begin. Verify: check 16 passes and check 6 still counts eight numbered steps.
3. [x] Adjust Step 3 to draft the candidate solutions alongside the core finding, Step 5 to ask only the questions the chosen approach raises, the tier section to say Step 4b fires at Tier 1 and Tier 2, and the guardrail sentence to count eleven. Why: the gate needs candidates to present and a narrowed Step 5 to hand off to, or it is a menu with nothing behind it. Verify: `grep -n "candidate" kit/plugins/plan-agent/skills/build-proposal/SKILL.md` hits Step 3, Step 4b, and Step 5, and `grep -c "eleven guardrails"` returns 1.
4. [x] Update references/artifact-shape.md (Side-by-side is dimension by candidate with the baseline column, Locked decisions opens with the pick, skeleton and Tier 1 note updated) and references/operating-principles.md (principle 11 *Choose the approach before authoring*, heading count, AskUserQuestion row). Why: the artifact shape is what Step 6 assembles from, so the pick has to have a documented home in every tier. Verify: check 16's shape and principle greps pass; `bash tests/plugins/test-build-proposal.sh` check 14 still passes.
5. [x] Update the plugin README build-proposal section (loop bullet gains the Step 4b gate; new bullet describing it), the root README build-proposal row, and the how-to guide's "What happens" bullet. Why: the README is the reference surface CLAUDE.md points at, and the loop description there would otherwise contradict the skill. Verify: `grep -n "Step 4b" kit/plugins/plan-agent/README.md` hits at least twice; `grep -n "candidate" README.md docs/guides/how-to/plan-agent.md` hits once each.
6. [x] Bump plan-agent to 9.18.0 in .claude-plugin/marketplace.json, add the 9.18.0 CHANGELOG entry, and regenerate the root README Plugin Reference Table with `node scripts/build-readme-table.mjs`. Why: the version guard fails any plugin edit without a bump above origin/main, and the reference table is generated from the marketplace file. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0; `node scripts/build-readme-table.mjs --check` exits 0; `jq empty .claude-plugin/marketplace.json` exits 0.
7. [x] Render this plan with `kit/plugins/plan-agent/bin/plan-agent-render docs/plans/add-proposal-approach-gate.md -o docs/plans/add-proposal-approach-gate.html` and rebuild the index with `bash docs/plans/build-index.sh`. Why: plan HTML is generated, never hand-written, and the index is what the gallery reads. Verify: the HTML file exists and `docs/plans/index.html` names the plan.

## Tests

Tier 1 — This plan changes plugin source (SKILL.md and its references are what ships)

### Objective-Verification Test

- **File:** `tests/plugins/test-build-proposal.sh` (check 16)
- **Type:** structural smoke test
- **Asserts:** a `### Step 4b —` heading sits between Step 4 and Step 5; its body names `AskUserQuestion`, `(Recommended)`, *keep the current approach*, and Locked decisions; `references/artifact-shape.md` compares candidates including the baseline; `references/operating-principles.md` carries *Choose the approach*
- **Run:** `bash tests/plugins/test-build-proposal.sh`

### Unit Tests

- **File:** `tests/plugins/test-build-proposal.sh` (checks 1 to 15), `tests/plugins/test-exitplanmode-guard.sh`, `tests/plugins/test-description-budget.sh`
- **Targets:** the existing build-proposal contract, the plan-mode guard line, the frontmatter description budget
- **Key cases:** eight numbered steps still counted; the Step 6 dual-write and Step 8 handoff contracts unchanged; the description is byte-identical

### Integration Tests

- **File:** `tests/plugins/test-write-prompt-proposal-type.sh`, `tests/plugins/test-proposal-prompt-pipeline.sh`
- **Targets:** the proposal prompt template and the build-proposal to prompt pipeline
- **Key cases:** the slot list is unchanged, so both suites pass without edits

## Acceptance Criteria

- [x] Running `/plan-agent:build-proposal` at Tier 1 or Tier 2 presents two to four candidate solutions, the baseline among them, in one recommendation-first question before any proposal content is authored
- [x] The saved prompt's Locked decisions open with the chosen approach and name what it was chosen over; the Side-by-side table shows the rejected candidates beside it
- [x] A Tier 1 prompt records the pick as the closing line of Context
- [x] Step 5 asks no question that only matters for a rejected candidate
- [x] `tests/plugins/test-build-proposal.sh` passes all 16 checks and check 6 still reports eight numbered steps
- [x] plan-agent is 9.18.0 in marketplace.json with a matching CHANGELOG entry; `build-feature` is untouched

## Verification

`bash tests/run-all.sh` passes on this machine, `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0, and `bash scripts/verify.sh` exits 0 with no stage reported as a silent skip. A read of the edited SKILL.md from Step 3 through Step 6 reads as one flow: candidates drafted, one chosen, remaining decisions resolved, the pick authored.

## Next Steps

- Give build-feature the same gate:
  ```text
  kit/plugins/plan-agent/skills/build-feature/SKILL.md shares build-proposal's loop (Frame, Confirm, Research, Synthesize, Separate facts from decisions, Resolve, Author). build-proposal 9.18.0 added a Step 4b gate that presents two to four candidate solutions (the baseline "keep the current approach" always among them) in one recommendation-first AskUserQuestion and authors only the pick. Decide whether build-feature should present candidate feature shapes or seam splits the same way before Step 5, and if so add the equivalent Step 4b, a check to tests/plugins/test-build-feature.sh, and a CHANGELOG entry with a MINOR bump.
  ```
