---
# Place in: configured plansDirectory (settings.local.json → settings.json → ~/.claude/settings.json), else ${PWD}/docs/plans/
status: todo
type: <feature|fix|refactor|docs|chore>
created: YYYY-MM-DD
repo-name: <repo-name>
---

# Plan: <title>

## Context

<why this work is needed>

## Objective

<one or two sentences — the one-line *what*>

## At a glance

<Two or three plain-language sentences for a reader who wasn't in the
planning session: why this work matters and how we'll know it worked.
Don't restate the objective — it covers the *what*; this covers the
*why* and the *proof*.>

## Resources *(optional — omit if none)*

<Images, screenshots, and links to material used to create the plan, so the
reader can illustrate and verify the implementation. Give every image
descriptive alt text and credit/link the source.>

- ![<descriptive alt text>](<https:// URL or relative asset path>) — <what it shows, source>
- [<reference title>](<https:// URL>) — <why it matters to this plan>

## Steps

1. <action> — *Why this matters:* <reason>. *How to check this worked:* <how to confirm>.
2. <action> — *Why this matters:* <reason>. *How to check this worked:* <how to confirm>.

## Definition of done

- [ ] <falsifiable condition that must be true for this plan to be done>
- [ ] <another condition>

## Final check

<end-to-end confirmation that the whole change achieved the goal>

## Next steps *(optional)*

- <label for the follow-up>:
  ```text
  <Self-contained prompt the user can paste into Claude to execute this
  follow-up. Include enough context that no prior plan reading is required.
  Example: "Scan every plan under docs/plans/ that has a Next Steps section
  with single-line bullets and rewrite them to the label + fenced-prompt
  shape. Skip completed plans. Report a list of files changed.">
  ```

## Unresolved questions *(optional — omit if none)*

- <label for the open question>:
  ```text
  <Self-contained prompt asking Claude to investigate and recommend.
  Example: "Should the new requirement in plan-mode.md be advisory or
  enforced by a PostToolUse hook? Recommend one approach with reasoning,
  and if a hook is right, draft the minimum-viable check that avoids
  false-positives on completed plans or plans with no follow-ups.">
  ```
