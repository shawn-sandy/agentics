---
# Place in: (1) configured plansDirectory  (2) docs/plans/  (3) default Claude user plans folder
status: todo
type: <feature|fix|refactor|docs|chore>
created: YYYY-MM-DD
repo-name: <repo-name>
---

# Plan: <title>

## Context

<why this work is needed>

## Objective

<one or two sentences>

## Steps

1. <action> — *Why:* <reason>. *Verify:* <how to confirm>.
2. <action> — *Why:* <reason>. *Verify:* <how to confirm>.

## Acceptance Criteria

- [ ] <falsifiable condition that must be true for this plan to be done>
- [ ] <another condition>

## Verification

<end-to-end confirmation>

## Next Steps *(optional)*

- <label for the follow-up>:
  ```text
  <Self-contained prompt the user can paste into Claude to execute this
  follow-up. Include enough context that no prior plan reading is required.
  Example: "Scan every plan under docs/plans/ that has a Next Steps section
  with single-line bullets and rewrite them to the label + fenced-prompt
  shape. Skip completed plans. Report a list of files changed.">
  ```

## Unresolved Questions *(optional — omit if none)*

- <label for the open question>:
  ```text
  <Self-contained prompt asking Claude to investigate and recommend.
  Example: "Should the new requirement in plan-mode.md be advisory or
  enforced by a PostToolUse hook? Recommend one approach with reasoning,
  and if a hook is right, draft the minimum-viable check that avoids
  false-positives on completed plans or plans with no follow-ups.">
  ```
