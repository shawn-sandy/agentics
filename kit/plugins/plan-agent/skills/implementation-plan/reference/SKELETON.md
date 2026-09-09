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
from one. State what a reader with no prior context needs to judge the
plan — no follow-up question required. Omit the whole section for
self-evident chores.>

## Files

- <path> (new) — <short note on what happens in this file>
- <path> (modified) — <short note>

## Steps

<optional lanes — `### Lane:` headings group independent runs of steps that
one worktree worker owns end to end; omit every heading for a chain, which
runs sequentially. Numbering stays flat and global across lanes. The
example below is two worker lanes plus the reserved `lead` lane that holds
the shared files and runs last in the main session.>

### Lane: <name-a> (owns: <path-or-glob>, <path-or-glob>)

1. <action naming real files/commands> Why: <reason a newcomer understands> Verify: <command or state that confirms this step worked>.
2. <action> Why: <reason> Verify: <how to confirm — the lane's last Verify proves the lane on its own>.

### Lane: <name-b> (owns: <path-or-glob>; after: <name-a>)

3. <action> Why: <reason> Verify: <how to confirm>.

### Lane: lead (after: <name-a>, <name-b>)

4. <bump the version, write the CHANGELOG entry, regenerate indexes> Why: <reason> Verify: <how to confirm>.

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

<optional — renders as collapsible follow-up cards with Copy-prompt buttons.
Each top-level bullet is one card: first line = summary, indented fenced
block = self-contained paste-ready prompt, other indented lines =
description. Bullet-less prose renders as paragraphs. Label blue-sky items
as wish list.>

- <follow-up summary — one line>
  <optional description of the follow-up>
  ```text
  <self-contained paste-ready prompt for this follow-up>
  ```

## Unresolved Questions

<markdown-only: open questions needing user input — omit if none>

## Resources

<markdown-only: links/screenshots consulted while planning, each with a
descriptive title and why it matters — omit if none>
