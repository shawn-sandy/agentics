---
name: optimizing-skill-frontmatter
description: "Optimizes SKILL.md frontmatter fields. Rewrites descriptions to three-part format (≤200 chars) and tunes disable-model-invocation. Use when the user asks to optimize SKILL.md frontmatter."
allowed-tools: AskUserQuestion, Read, Edit, Bash, Glob, ToolSearch, ExitPlanMode
disable-model-invocation: true
---

## Overview

Optimizes two frontmatter fields in one pass: rewrites `description:` to the
**three-part format** — a short description (≤80 chars), a capability sentence,
then a "Use when…" trigger — and sets `disable-model-invocation` correctly for a
write-heavy workflow versus a read-only advisory tool.

The ≤200 total and ≤80 first-sentence limits are budget targets, not platform
limits; `references/budget-advisory.md` explains where they come from.

## When not to use

Does not review overall SKILL.md quality — use reviewing-skills for that. Does not change `allowed-tools` values — use auditing-allowed-tools for that. This skill only touches `description:` and `disable-model-invocation`.

## References

- `references/description-rules.md` — Rules 1–5 and 2b, worked examples A and B, the Step 4 edit order
- `references/invocation-control.md` — Step 4b's classification table, confirmation options, apply rules
- `references/measurement.md` — the measuring loops and the SKIP rule (Steps 2, 5, 6)
- `references/budget-advisory.md` — the `skillListingBudgetFraction` advisory and `/doctor` guidance

---

## Step 0: Exit plan mode, then discover project skills

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

Then enumerate all SKILL.md files in the current project:

```bash
find . -name "SKILL.md" | sort
```

If that returns nothing, `Glob` `kit/plugins/*/skills/*/SKILL.md`. Store the list as `$PROJECT_SKILLS` for Step 6.

Output one summary line: `Found N SKILL.md files in this project.`

---

## Step 1: Resolve target files

Determine which SKILL.md files to optimize using this priority order:

1. **Explicit path** — use it directly.
2. **Plugin scope** — `Glob` `**/plugins/<name>/skills/*/SKILL.md`, falling back to `kit/plugins/<name>/skills/*/SKILL.md`.
3. **All skills** ("all", "everything") — `Glob` `**/skills/*/SKILL.md`, falling back to `kit/plugins/*/skills/*/SKILL.md`.
4. **Still unclear** — ask: "Which SKILL.md should I optimize? Provide a path or say 'all'."

The resolved file(s) are this pass; `$PROJECT_SKILLS` is held for Step 6.

---

## Step 2: Measure current descriptions

Read `references/measurement.md` and run its Step 2 extraction against every
resolved file, then report the SKIP/REWRITE table it specifies before asking
about any SKIP candidate.

---

## Step 3: Rewrite each description

Read `references/description-rules.md` and apply all five rules in order. Draft
every rewrite before touching a file.

---

## Step 4: Apply edits

Follow the edit order in `references/description-rules.md` — body insertion
first (if Rule 4 applies), then the `description:` line, preserving the original
quoting style. Confirm each edit succeeded before moving to the next file.

---

## Step 4b: Tune invocation control

Read `references/invocation-control.md` and classify every file resolved in
Step 1 — including files SKIP'd in Step 2, which may still need the flag tuned.
Print its classification table, confirm via `AskUserQuestion`, then apply.

**Never write `disable-model-invocation: false`.** Write `true` for workflow
skills; omit the field entirely for advisory ones.

---

## Step 5: Verify results

Run the re-measurement loop in `references/measurement.md`. Confirm every total
is ≤200 and every short description ≤80, and report violations for a second
rewrite pass — separating total-only from short-only failures.

---

## Step 6: Offer to optimize the rest of the project

Re-measure every file in `$PROJECT_SKILLS` using the Step 6 loop in
`references/measurement.md`, print its `path | chars | status` table, and offer
the three follow-up options it lists.

Then output the advisory in `references/budget-advisory.md`, substituting the
installed-skill count. Skip it when the count is ≤40 and every description is
already ≤200 chars.
