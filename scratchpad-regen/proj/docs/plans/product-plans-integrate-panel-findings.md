---
status: todo
type: refactor
created: 2026-05-15
---

# Plan: product-plans skill integrates panel findings into the source plan

## Context

The `product-plans` skill (`kit/plugins/product-plans/skills/product-plans/SKILL.md`)
runs a six-reviewer panel and then, in Step 7, persists the revised plan.
Today Step 7 either:

- writes a sibling file `<original-stem>-revised.md`, or
- (if the user picks **Overwrite original** through `AskUserQuestion`)
  replaces the source file wholesale with section 15 of the synthesized
  output, or
- (if the user picks **Append**) appends a `## Revised Plan` section.

Background mode always picks the sibling-file path.

The user's intent is for the panel to **integrate** its recommendations
into the source plan the same way `plan-interview` integrates its
findings: append a clearly-labeled summary section to the source plan
(non-destructive to original content), apply any accepted in-line edits
(such as Step 0 additions, wording changes, verification updates) by
editing the relevant sections directly, and skip the separate-file or
ask-where-to-write flow entirely.

In other words: `product-plans` should leave behind a plan file that
*contains* the panel's review and *reflects* its recommendations, in
the same workflow shape that `plan-interview` already follows.

## Objective

Rewrite Step 7 of `SKILL.md` so the lead always integrates the panel's
findings into the **source plan file** in two ways:

1. **Apply revisions in place** — for each recommendation that maps to
   a specific section of the source plan, use `Edit` to update that
   section directly (Step 0 additions, verification additions, wording
   tightening, etc.).
2. **Append a `## Panel Review` summary section** to the end of the
   source plan, containing the synthesized 15-section report so the
   reasoning is preserved alongside the plan.

Both interactive and background modes share this single integration
path. There is no `AskUserQuestion`, no sibling file, no
`git status --porcelain` guard, and no overwrite-vs-append branching.

## Files to modify

- `kit/plugins/product-plans/skills/product-plans/SKILL.md` — Step 7
  ("Persist the revised plan") is rewritten end-to-end and renamed to
  "Integrate panel findings into the source plan."
- `kit/plugins/product-plans/skills/product-plans/references/output-template.md`
  — confirm section 15 is shaped as discrete edits (or add a new
  section listing in-line edits the lead should apply); shape it so
  the integration step is mechanical.
- `kit/plugins/product-plans/CHANGELOG.md` — add a `2.2.1` entry.
- `.claude-plugin/marketplace.json` — bump `product-plans` PATCH
  `2.2.0 → 2.2.1`.

## Steps

0. **Rename this plan file** — `git mv docs/plans/i-want-product-plan-velvety-koala.md docs/plans/product-plans-integrate-panel-findings.md`. The original suffix `velvety-koala` is a random adjective-noun unrelated to the plan content; the new name follows `verb-target` per `plan-mode.md` and reflects the now-clearer intent ("integrate panel findings").
   - *Why:* Plan filename hygiene per `plan-mode.md` and `plan-hygiene.md`. Rename was confirmed during interview but deferred because plan mode blocks filesystem operations.
   - *Verify:* `ls docs/plans/product-plans-integrate-panel-findings.md` succeeds and the original filename no longer exists. Run all subsequent steps against the renamed file.

1. **Inspect `references/output-template.md`** to confirm what shape
   the synthesized output takes today, particularly section 15 (the
   revised plan) and whether any section enumerates discrete in-line
   edits the lead should apply. If section 15 is currently a wholesale
   replacement of the plan, add a new sub-section listing
   *Inline edits to apply* — a numbered list of `(section heading,
   action: insert|edit|append, content)` entries the lead can mechanically
   apply with `Edit`.
   - *Why:* The integration step in Step 2 needs structured edits to
     apply. Today section 15 is shaped as a wholesale revised plan,
     which is fine for "overwrite" but not for "edit specific sections."
   - *Verify:* Re-read `references/output-template.md` and confirm
     section 15 (or a new sibling section) provides a numbered list of
     discrete edits with section heading + action + content. The
     wholesale revised-plan body may remain alongside, used only as
     context for the appended `## Panel Review` summary.

2. **Rewrite Step 7 in `SKILL.md`** — Replace the entire body of
   "Step 7 — Persist the revised plan" with a single integration path.
   Rename the step heading to "Integrate panel findings into the source
   plan." The new body:

   ```markdown
   Skip entirely if `output_mode = review only`.

   Integrate the synthesized findings into the source plan file at the
   resolved path from Step 1. Two passes:

   1. **Apply inline edits** — for each entry in the
      "Inline edits to apply" sub-section of the synthesized output,
      use `Edit` against the resolved plan path: `insert` adds a new
      section, `edit` replaces a matched section's body, `append` adds
      content to the end of an existing section. Apply edits in order.
   2. **Append the panel review summary** — use `Edit` to append a new
      `## Panel Review` section at the end of the source plan
      containing the verbatim 15-section synthesized report. Do not
      re-generate; copy from synthesis.

   Both interactive and background modes share this path. There is no
   `AskUserQuestion`, no sibling file, no `git status --porcelain`
   guard. Announce:

   > `Plan updated in place: <resolved-path> (inline edits applied + Panel Review appended)`
   ```

   - *Why:* User intent is "the changes and recommendations are
     integrated into the plan as it currently happens with plan-interview."
     `plan-interview` integrates by appending a summary section AND by
     applying accepted edits inline (e.g., my Step 0 rename, my
     CHANGELOG wording). Mirroring that pattern keeps the workflows
     consistent across the two skills.
   - *Verify:* Re-read Step 7 and confirm: (a) heading renamed to
     "Integrate panel findings into the source plan," (b) the
     inline-edits pass runs before the append pass, (c) the words
     `AskUserQuestion`, `Sibling file`, `Append to original`,
     `Overwrite original`, `git status --porcelain`, and
     `<original-stem>-revised.md` no longer appear anywhere in Step 7,
     (d) the `Skip entirely if output_mode = review only` guard is
     preserved.
   - Also confirm `kit/plugins/product-plans/.claude-plugin/plugin.json`
     contains no `version` field — would silently override the
     marketplace bump in Step 4 (per `CLAUDE.md`).

3. **Add a CHANGELOG entry** under
   `kit/plugins/product-plans/CHANGELOG.md` for the new PATCH version
   `2.2.1`. Wording should call out both the integration model and the
   removed options:

   > **Behavior change (Step 7):** The skill now integrates panel
   > findings directly into the source plan: inline edits are applied
   > to the relevant sections via `Edit`, and a `## Panel Review`
   > section containing the full synthesized report is appended to
   > the end of the source plan. Both interactive and background
   > modes share this path. Removed: the `AskUserQuestion` prompt,
   > the **Sibling file**, **Overwrite original**, and **Append to
   > original** options, the `git status --porcelain` safety guard,
   > and the background-mode `<stem>-revised.md` sibling-write. This
   > mirrors how `plan-interview` integrates its findings into the
   > plans it reviews.

   - *Why:* `marketplace.md` requires a CHANGELOG entry on every
     version bump. This change removes user-visible options and
     introduces a new integration model, so the wording must flag both.
   - *Verify:* `head kit/plugins/product-plans/CHANGELOG.md` shows the
     `2.2.1` entry at the top with the wording above.

4. **Bump the version** in `.claude-plugin/marketplace.json` — change
   the `product-plans` entry's `version` from `2.2.0` to `2.2.1`.
   - *Why:* Per the user's interview confirmation, this stays a PATCH
     bump even though options were removed; semver category is the
     user's call. Version lives only in `marketplace.json` for
     relative-path plugins (per `CLAUDE.md`).
   - *Verify:* `jq '.plugins[] | select(.name=="product-plans") | .version' .claude-plugin/marketplace.json`
     prints `"2.2.1"`. The auto-validation hook on `marketplace.json`
     reports no errors.

## Verification

- Open `kit/plugins/product-plans/skills/product-plans/SKILL.md` and
  read the renamed Step 7 end-to-end:
  - Single integration path; two passes (inline edits, then append
    `## Panel Review`).
  - No `AskUserQuestion`, no sibling, no overwrite/append options, no
    git-clean guard, no background-mode branching.
  - The `Skip entirely if output_mode = review only` guard is preserved.
- Open `references/output-template.md` and confirm the
  "Inline edits to apply" sub-section exists and is shaped as
  `(section heading, action, content)` entries.
- Confirm `marketplace.json` validates and version reads `2.2.1`.
- Confirm `plugin.json` has no stray `version` field.
- Smoke-test by mentally walking through a realistic case:
  - A plan at `docs/plans/foo.md` with no Step 0 and a thin
    verification section.
  - Panel runs, synthesis lands. Section 15 lists three inline edits:
    insert a Step 0 (rename), edit the Verification section to add a
    `jq` check, append a Next Step entry.
  - Step 7 applies the three `Edit` calls in order, then appends a
    `## Panel Review` section to `foo.md`.
  - Result: `foo.md` now has the Step 0, the richer verification, the
    new Next Step, AND the full panel review at the bottom — all in
    one file. No sibling. No prompt.

## Next Steps *(optional)*

- Update the `product-plans` README:

  ```text
  Re-read kit/plugins/product-plans/README.md. Remove every reference
  to the Sibling file option, Overwrite original option, Append to
  original option, the AskUserQuestion prompt, the git-clean guard,
  and the background-mode <stem>-revised.md sibling file. Replace
  with a section explaining the new integration model: inline edits
  applied to the source plan via Edit, plus a ## Panel Review summary
  appended at the end. Note explicitly that this mirrors the
  plan-interview integration pattern. Do not bump the version again
  for a docs-only sync unless the README is materially out of sync.
  ```

- Consider a `--dry-run` flag for the panel:

  ```text
  Evaluate whether to add a --dry-run (or --no-write) flag to the
  product-plans skill so users can run the panel and see the
  synthesized review without modifying the source plan. Today this is
  achievable by selecting output_mode = review only in Step 2, but
  only if Step 2's AskUserQuestion still runs. Confirm that Step 2
  still asks the question after this plan ships, and if not,
  recommend either restoring the Step 2 question or adding a flag.
  Output: a 1-paragraph recommendation, and if a flag is right, the
  exact SKILL.md edit needed.
  ```

- Mirror the integration pattern in any future review-style skills:

  ```text
  Audit other "review/stress-test the plan"-shaped skills in the
  agentics marketplace (plan-interview, code-review, deep-grill, etc.)
  and confirm they all follow the same integration pattern: apply
  accepted edits inline to the source file, then append a clearly
  labeled summary section. Surface any skill that still writes to a
  sibling file or asks where to write, and propose a small plan to
  align it.
  ```

## Interview Summary

Captured from `/plan-interview:plan-interview` on 2026-05-15.

### Key Decisions Confirmed

- **Integration model, not overwrite.** Final answer (supersedes the
  earlier "always overwrite" framing): the panel applies inline edits
  to the source plan AND appends a `## Panel Review` section,
  mirroring how `plan-interview` integrates its findings.
- **Both interactive and background modes** use this single path.
- **No AskUserQuestion, no sibling, no overwrite/append options, no
  git-clean guard.**
- **Rename plan file** to `product-plans-integrate-panel-findings.md`
  (Step 0 in this plan).
- **Semver bump**: PATCH `2.2.0 → 2.2.1`. User's call; CHANGELOG
  wording carries the "loud" signal that user-visible options were
  removed and a new integration model added.

### Plan Naming

| Element | Current | Issue | Suggested | User decision |
|---------|---------|-------|-----------|---------------|
| Filename | `i-want-product-plan-velvety-koala.md` | Random `velvety-koala` suffix | `product-plans-integrate-panel-findings.md` | Accepted — applied at implementation Step 0 |
| H1 Heading | `# Plan: product-plans skill integrates panel findings into the source plan` | Updated to match the integration framing | _(no further change)_ | _(n/a)_ |

### Open Risks & Concerns

- **`output-template.md` may need shape changes**: the integration
  step depends on section 15 (or a new sibling section) listing
  discrete inline edits. If the template only emits a wholesale
  revised plan, Step 7 has nothing structured to apply. Step 1 of
  this plan exists to shore that up.
- **Loss of opt-out**: users who relied on **Sibling file** or
  **Overwrite original** workflows will be surprised. CHANGELOG
  wording is the only signal; `--dry-run` follow-up captured in
  Next Steps.
- **README drift** for `product-plans` (covered in `next-steps`).
- **Semver under-call**: PATCH for option removal + new integration
  model is below industry norm. User explicitly chose PATCH.
- **`plugin.json` stray `version` field** would silently override the
  marketplace bump (verify in Step 2 and Step 4).

### Recommended Next Steps Applied

- Step 0 added: rename the plan file before the rest of the edits.
- Step 1 added: shore up `output-template.md` to emit discrete inline
  edits the lead can mechanically apply.
- Step 2 fully rewritten: single integration path replaces both
  branches and all three options.
- Step 3 CHANGELOG wording strengthened to call out the integration
  model AND the option removal.
- Unresolved-questions section dropped (background-mode question is
  answered: it now integrates too).
- New Next Steps added: README sync, `--dry-run` flag follow-up, and
  a marketplace audit of other review-style skills.

### Simplification Opportunities

- Step 7 collapses from a 25-line, 3-option, branching block into a
  ~10-line two-pass procedure with no branching.
- Background and interactive modes converge on a single path,
  eliminating the entire `mode = background` branching in Step 7.
