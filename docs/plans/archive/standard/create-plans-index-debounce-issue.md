---
status: in-progress
type: chore
created: 2026-05-31
repo-name: agentics
---

# Plan: Create GitHub issue for plans-index title-search debounce

## Context

The user invoked `/issue-agent:create-issue` (source: `feature`) to file a feature
request: a live, debounced title-search input on `docs/plans/index.html` that composes
with the existing status/type filters.

Investigation showed the feature is ~90% already shipped — the search input, filter-as-you-type
handler, three-way filter composition, and the `data-title` data shape all already exist in the
source template `kit/plugins/plan-agent/templates/plans-gallery.html` (and its generated output
`docs/plans/index.html`). The only outstanding gap vs. the spec is the **150ms debounce**.

The user reviewed the drafted issue at the skill's confirmation gate and chose **Create** (full
feature as described, with an honest "current state" note). This plan exists only to leave plan
mode so the approved outward write (`gh issue create`) can run — no source code changes are part
of this task.

## Objective

Create one GitHub issue on `shawn-sandy/agentics` capturing the feature, accurately noting that
input + filtering already exist and only the 150ms debounce remains.

## Steps

1. **Run `gh issue create`** with the approved title, body, and labels (`enhancement`,
   `good first issue`). — *Why:* This is the single outward action the user approved at the
   confirmation gate. — *Verify:* the command prints a new issue URL and number.

## Acceptance Criteria

- [ ] A new GitHub issue exists on `shawn-sandy/agentics` titled
      `[FEATURE] Live title search for the plans index gallery (add 150ms debounce)`.
- [ ] Labels `enhancement` and `good first issue` are applied.
- [ ] The body matches the draft reviewed at the confirmation gate (Summary, Current State,
      Acceptance Criteria, Related Files, etc.).

## Verification

- Open the printed issue URL (or run `gh issue view <number>`) and confirm the title, labels, and
  body render as drafted.
- Confirm no source files were modified — this task creates an issue only.

## Next Steps (out of scope)

- Implement the debounce itself:
  ```text
  In kit/plugins/plan-agent/templates/plans-gallery.html, wrap the #searchBox input handler in a
  150ms debounce (inline JS, no library): on each input event set searchText from the field then
  clear+reschedule a 150ms timer that calls applyFilters(). Then regenerate docs/plans/index.html
  via docs/plans/build-index.sh and confirm the committed output matches. No build-index.sh data
  change is needed — data-title already exists. Verify by typing a partial plan title and
  confirming only matching cards remain, alongside the status/type chip filters.
  ```
