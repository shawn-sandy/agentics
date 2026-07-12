---
status: todo
type: <feature|fix|refactor|docs|chore>
created: YYYY-MM-DD
glance: <2–3 plain-language sentences on ONE line — why this matters and how we'll know it worked; never restates the objective>
---

# Plan: <title — a rallying statement, not a ticket summary>

## Objective

<one or two sentences — the one-line *what*>

## Context

<why this work is needed; risks with mitigations; issue link when seeded
from one. Omit the whole section for self-evident chores.>

## Files

- <path> (new) — <short note on what happens in this file>
- <path> (modified) — <short note>

## Steps

1. <action naming real files/commands> Why: <reason a newcomer understands> Verify: <command or state that confirms this step worked>.
2. <action> Why: <reason> Verify: <how to confirm>.

## Tests

Tier <1 — This plan changes application code|2 — This plan doesn't change application code>
- Objective: <what the hero test proves>. File: <test path>; Type: <mock|smoke>; Asserts: <the plan's objective is accomplished in the running app>; Run: <test runner command>
- Unit: <what it covers>. File: <test path>; Targets: <function/module>; Key cases: <scenarios>

## Acceptance Criteria

- [ ] <falsifiable condition that must be true for this plan to be done>
- [ ] <another condition — flip to [x] only when verified during implementation>

## Verification

<end-to-end confirmation that the whole change achieved the objective —
walk it as a user or caller would>

## Next Steps

<markdown-only (not rendered into the HTML yet): follow-ups with
self-contained paste-ready prompts; label blue-sky items as wish list>

## Unresolved Questions

<markdown-only: open questions needing user input — omit if none>

## Resources

<markdown-only: links/screenshots consulted while planning, each with a
descriptive title and why it matters — omit if none>
