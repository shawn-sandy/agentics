# Plan: Harden plan-documenter completion guard

## Context

The plan-documenter agent and documenting-plans skill should only process completed plans. Both components already have status-checking gates, but the instructions have minor ambiguities around frontmatter parsing, casing, and read window size that should be tightened.

## Objective

Ensure the plan-documenter agent and documenting-plans skill reject non-completed plans in all edge cases, with no behavioral regressions.

## Current State

Both components already gate on `status: completed`:

- **plan-documenter agent** (batch): reads first 10 lines, checks `status: completed` exact match, skips everything else
- **documenting-plans skill** (single): checks frontmatter, runs `plan-status` if ambiguous, stops if still not completed

The double-gate design is sound. No completed-plan-only violations exist today.

## Steps

1. **Switch to delimiter-based frontmatter reading in plan-documenter agent**
   - File: `kit/plugins/plan-interview/agents/plan-documenter.md`, Step 2
   - Replace "Read the first 10 lines" with "Read until the closing `---` delimiter"
   - *Why:* A fixed line count is fragile — delimiter-based reading handles any frontmatter length

2. **Add explicit frontmatter-boundary and casing rules to plan-documenter agent**
   - File: `kit/plugins/plan-interview/agents/plan-documenter.md`, Step 2
   - Add: parse between `---` delimiters only; require lowercase `status: completed`; skip files without frontmatter delimiters
   - *Why:* Makes implicit behavior explicit — prevents matching `status: completed` in body text or accepting non-canonical casing

3. **Add edge cases to plan-documenter agent**
   - File: `kit/plugins/plan-interview/agents/plan-documenter.md`, Edge Cases section
   - Add: no YAML frontmatter (skip), non-standard casing (skip), status in body not frontmatter (ignore)
   - *Why:* Documents expected behavior for ambiguous inputs

4. **Add frontmatter-boundary clarification to documenting-plans skill**
   - File: `kit/plugins/plan-interview/skills/documenting-plans/SKILL.md`, Step 2
   - Add: "Extract the YAML block between `---` delimiters. If no frontmatter delimiters, treat status as absent."
   - *Why:* Aligns with plan-documenter's explicit rules

5. **Clean up `--overwrite` flag mismatch in plan-documenter agent**
   - File: `kit/plugins/plan-interview/agents/plan-documenter.md`, Step 5
   - Remove `--overwrite` from the skill invocation args since the skill has no such argument
   - *Why:* The agent already pre-filters existing docs in Step 3, so `--overwrite` is unnecessary and undocumented

6. **Manual verification**
   - Run plan-documenter and confirm the sweep summary correctly counts completed vs non-completed plans
   - Verify plans with `status: draft`, `todo`, `in-progress`, and no frontmatter are all skipped
   - Run documenting-plans on a non-completed plan (e.g., `fix-code-review-agent-skill-audit.md` with `status: draft`) and confirm it stops

## Files to Modify

- `kit/plugins/plan-interview/agents/plan-documenter.md` — Steps 1-3
- `kit/plugins/plan-interview/skills/documenting-plans/SKILL.md` — Step 4

## Verification

1. Run the plan-documenter agent and check the "Plan Documentation Sweep" summary shows correct counts
2. Confirm these are skipped: `fix-code-review-agent-skill-audit.md` (draft), `plan-status-skill-audit-fixes.md` (todo), `move-claude-plugin-to-kit.md` (no frontmatter)
3. Run `documenting-plans` on a `status: draft` plan and confirm it refuses or stops after plan-status check

## Interview Summary

### Key Decisions Confirmed
- **Silently skip** plans without frontmatter — no plan-status fallback in the batch agent
- **Read until closing `---` delimiter** instead of a fixed line count — more robust than widening to 20 lines
- **Document the casing rule** — one sentence, prevents future ambiguity
- **Manual verification only** — no test fixtures for markdown-instruction agents

### Open Risks & Concerns
- The `--overwrite` flag passed by the plan-documenter agent to the documenting-plans skill is not a documented argument. The skill may ignore it, which is fine for the batch flow (existing docs are pre-filtered), but it's a documentation mismatch worth cleaning up.
- Plans without frontmatter that are actually completed will remain undocumented until someone manually runs `plan-status` on them. This is accepted as the correct trade-off.

### Recommended Next Steps
1. Update Step 2 of `plan-documenter.md` to use delimiter-based reading instead of a line count
2. Add the casing rule and frontmatter-boundary parsing instructions
3. Add edge cases for no-frontmatter and body-text false positives
4. Add frontmatter-boundary clarification to `documenting-plans/SKILL.md` Step 2
5. Remove or document the `--overwrite` flag mismatch in the agent's Step 5
