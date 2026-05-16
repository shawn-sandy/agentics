---
status: todo
type: feature
created: 2026-05-16
---

# Plan: Add vertical-slice decomposition to plan-review-agents

> **Filename note:** This plan should be renamed before commit (the current
> filename does not match its content). Proposed name:
> `add-vertical-slice-decomposition-to-plan-review-agents.md`. Per
> `~/.claude/rules/plan-mode.md`, a stale filename is a plan defect — rename
> as part of Step 1 of execution.

## Context

The `plan-review-agents` skill (in `kit/plugins/product-plans/`) currently
runs a six-reviewer panel and either (a) writes a review report only or (b)
applies inline edits to the source plan and appends a `## Panel Review`
block. It does **not** decompose work into independently shippable units —
even though the project's canonical step shape (`action / why / verify`,
defined in `~/.claude/rules/plan-mode.md` and enforced by the sibling
`plan-interview` skill) is built for exactly that.

The user pain point: a panel-reviewed plan still leaves a developer staring
at one long task. The user wants the skill to additionally emit
**independent vertical slices** — each shippable on its own, each carrying
enough context that a fresh Claude session (or a different developer) can
execute the slice without re-reading the whole plan.

The Explore pass confirmed no plugin in this marketplace currently does
this; the natural seam is to add a third integration pass to the existing
skill, gated by a new opt-in mode at Step 2.

## Objective

Add an opt-in **decomposition** mode to `plan-review-agents` that (1)
rewrites the source plan's `## Steps` section into vertical slices
conforming to the plan-mode skeleton (action / why / verify), and (2)
emits a sibling `<plan>.steps.md` file where each slice is a self-contained,
paste-ready execution prompt the developer can run one at a time.

## Steps

1. **Bump version & changelog skeleton** — Update
   `.claude-plugin/marketplace.json` to `"version": "3.2.0"` for the
   `product-plans` entry, and add a `## 3.2.0 — 2026-05-16` entry at the
   top of `kit/plugins/product-plans/CHANGELOG.md` describing the new
   decomposition mode. *Why:* MINOR bump per `.claude/rules/marketplace.md`
   (new feature added, no breaking change). *Verify:* `grep -n '"version":'`
   on the marketplace JSON shows `3.2.0` for `product-plans`, and `head -8
   kit/plugins/product-plans/CHANGELOG.md` shows the new 3.2.0 entry above
   the existing 3.1.0 entry.

2. **Add a third option to Step 2 of `SKILL.md`** — In
   `kit/plugins/product-plans/skills/plan-review-agents/SKILL.md`, extend
   the Step 2 `AskUserQuestion` options from two to three:
   `Review + update plan in place`,
   `Review + update + decompose into vertical slices` (new — preselected
   when the plan frontmatter `type` is `feature`),
   `Review only`. Record the choice as `output_mode` with values
   `update`, `decompose`, or `review-only`. Background mode: parse a new
   `--decompose` flag in `$ARGUMENTS` (Step 1) — when present and a path is
   given, set `output_mode = decompose`; otherwise keep current behaviour
   (`update`).
   **Non-feature guard:** immediately after the user selects (or
   background sets) `decompose`, read the plan frontmatter `type`. If it
   is not `feature`, announce: `Decomposition mode requires plan type:
   feature; this plan is type: <type>. Falling back to update mode.` and
   set `output_mode = update`. This gates decompose mode to feature plans
   and keeps "vertical slice" semantics honest.
   *Why:* gates the new behaviour behind explicit consent, keeps the
   default safe, matches user choice "opt-in via Step 2", and prevents
   the "vertical slice" framing from leaking into refactor / chore / docs
   plans where it doesn't apply.
   *Verify:* re-read the updated `## Step 2 — Choose output mode` and
   confirm three options exist with the values listed above, the
   `--background` parser in Step 1 also detects `--decompose`, and the
   non-feature guard text matches the wording above verbatim.

3. **Update Step 6 synthesis instructions** — Add a bullet to Step 6 that
   reads (verbatim):
   > "When `output_mode = decompose`, the lead also fills sections 16a and
   > 16b of the output template (see `output-template.md`). Each slice
   > must be a **vertical slice**: shippable on its own, delivers
   > user-visible value end-to-end, and carries action / why / verify per
   > `~/.claude/rules/plan-mode.md`. Decompose mode is gated to
   > `type: feature` plans at Step 2; non-feature plans never reach this
   > branch."

   *Why:* the lead is the only role with full panel context — it owns
   slice boundaries; keeping a single, honest definition of "vertical
   slice" (rather than a dual-semantics fallback for non-feature plans)
   prevents inconsistent output and preserves room for a future
   commit-chunk mode if that's ever needed. *Verify:* re-read Step 6 and
   confirm the new bullet appears verbatim and references sections
   16a/16b.

4. **Add Pass 3 to Step 7** — In the same `SKILL.md`, add a new
   *"Pass 3 — Decompose into independent vertical slices"* block under
   Step 7, executed only when `output_mode = decompose`:
   - **Pass 3a:** use `Edit` to replace the `## Steps` section body in the
     resolved plan path with section 16a content (the normalized slice
     list). If the plan has no `## Steps` heading, `insert after` the
     `## Objective` heading.
   - **Pass 3b:** use `Write` to create `<resolved-path-without-.md>.steps.md`
     containing section 16b verbatim. Overwrite if it exists (regenerated
     every run). Announce both file paths in the final summary line.
   *Why:* mirrors the existing two-pass integration model so reviewers and
   future maintainers see decomposition as "one more pass", not a new
   subsystem. *Verify:* re-read Step 7 and confirm Pass 3a, Pass 3b, the
   skip-when-not-decompose guard, and the updated announcement are all
   present; confirm `Write` is already in `allowed-tools` (line 8–10) so
   no frontmatter change is needed.

5. **Extend the output template with sections 16a/16b** — In
   `kit/plugins/product-plans/skills/plan-review-agents/references/output-template.md`,
   add two new conditional sections after section 15b:
   - **16a. Normalized `## Steps` (for in-plan rewrite)** — verbatim
     markdown to write into the source plan's `## Steps` section, each
     numbered item following `<action> — *Why:* <reason>. *Verify:* <how
     to confirm>.` per the plan-mode skeleton.
   - **16b. Sibling steps file body (for `<plan>.steps.md`)** — full
     markdown body for the sibling file: a short header that names the
     parent plan, then one `### Slice N — <title>` block per slice
     containing **Action**, **Why**, **Verify**, **Acceptance** (what
     "shipped" looks like), and a fenced ` ```text ` paste-ready prompt
     for a fresh Claude session.
   Add a top-of-template note that both 16a and 16b are omitted unless
   `output_mode = decompose`, and that any step-related recommendations
   from section 12 must route through 16a (not 15a) in decompose mode to
   avoid double-writing the `## Steps` section. *Why:* makes the
   contract between synthesis (lead output) and integration (Step 7
   Pass 3) explicit, matching how 15a already drives Pass 1. *Verify:*
   re-read the template end-to-end and confirm both new sections exist,
   the conditional rules are stated, and the 15a/16a routing rule is
   spelled out.

6. **Document `--decompose` in the background command** — Update
   `kit/plugins/product-plans/commands/product-plans-bg.md` so its usage
   line and example show `--decompose` as an optional flag. Update
   `kit/plugins/product-plans/agents/agent-product-plans.md` to pass
   `$ARGUMENTS` through unchanged (it likely already does — verify).
   *Why:* background users have no `AskUserQuestion` prompt; the flag is
   their only entry point to the new mode. *Verify:* `grep -n
   'decompose' kit/plugins/product-plans/commands/product-plans-bg.md
   kit/plugins/product-plans/agents/agent-product-plans.md` returns at
   least one match in the command file (and any required mention in the
   agent file).

7. **Update the plugin README** — Add a short section under "Components" or
   "Usage" in `kit/plugins/product-plans/README.md` describing the new
   decomposition mode, the sibling steps file, and the `--decompose` flag.
   Keep it under ~15 lines; link to the SKILL for full detail. *Why:*
   discoverability — most users find features here, not in the SKILL.md.
   *Verify:* `grep -n 'decompose\|vertical slice\|.steps.md' kit/plugins/product-plans/README.md`
   shows the new mentions.

8. **Finalize changelog entry** — Flesh out the `## 3.2.0` entry created in
   Step 1 with the concrete changes from Steps 2–7 (one bullet per file
   touched). *Why:* the version-bump rule in
   `.claude/rules/marketplace.md` requires both the manifest bump and a
   changelog entry; doing it last captures the actual final list. *Verify:*
   the 3.2.0 entry names every file modified in Steps 2–7 and includes a
   one-paragraph "How to use" snippet showing the interactive prompt and
   the `--decompose` flag.

## Verification

End-to-end test, performed manually after Step 8:

1. Create a throwaway plan file under `docs/plans/test-decompose.md` with
   the skeleton (frontmatter `type: feature`, plus Context / Objective /
   Steps / Verification).
2. Confirm Agent Teams is on (`echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
   returns `1`) and Claude Code is `≥ 2.1.32` (`claude --version`).
3. Invoke the skill interactively on that plan; at the Step 2 question,
   pick **Review + update + decompose into vertical slices**.
4. Confirm after the run:
   - The plan's `## Steps` section now contains numbered items each
     matching `<action> — *Why:* <reason>. *Verify:* <how to confirm>.`
   - A sibling file `docs/plans/test-decompose.steps.md` exists, with one
     `### Slice` block per item, each containing Action / Why / Verify /
     Acceptance / a fenced ` ```text ` paste-ready prompt.
   - The `## Panel Review` section is still appended at the bottom (Pass 2
     unchanged).
5. Re-run with **Review only**; confirm no sibling file is created and the
   plan is unchanged on disk.
6. Re-run via `/product-plans:product-plans-bg docs/plans/test-decompose.md
   --decompose`; confirm same outputs as step 4 above without any
   interactive prompts.
7. Delete the test plan and its sibling steps file when done.

## Next Steps *(optional)*

- Backfill decomposition for completed plans:
  ```text
  Scan kit/plugins/product-plans/ and the wider docs/plans/ tree for
  feature plans whose ## Steps section does not follow the
  `<action> — *Why:* ... *Verify:* ...` shape. For each, propose (do not
  apply) a normalized rewrite plus a sibling `.steps.md` file using the
  vertical-slice format described in
  kit/plugins/product-plans/skills/plan-review-agents/references/output-template.md
  sections 16a and 16b. Report findings as a checklist; ask before
  writing any files.
  ```

- Cross-link from plan-interview:
  ```text
  Open kit/plugins/plan-interview/skills/plan-interview/SKILL.md and add
  a short "Related skills" note pointing to
  product-plans:plan-review-agents with --decompose for users who want
  panel review plus vertical-slice decomposition as a single flow.
  Keep it under 5 lines and do not change activation behaviour.
  ```

