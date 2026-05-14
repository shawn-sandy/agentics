---
status: todo
type: feature
created: 2026-05-14
---

# Plan: Update Plan-Generating Skills to Emit Three-Part Steps and Verb-Led Filenames

## Context

`/Users/shawnsandy/.claude/rules/plan-mode.md` was recently updated to require every `<li>` in a plan's `steps` section to have three parts: **action**, **why**, and **verify**. It also implies filenames should be imperative-verb-led (e.g., `add-`, `fix-`, `create-`). However, the plan-interview plugin's skills and commands still only enforce two-part steps (action + why) and do not require or generate verb-led filenames. `plan-to-html` already has full three-part rendering support in its HTML spec — the gap is entirely upstream in the validation and suggestion logic.

## Objective

Update the three plan-interview skills/commands that validate or generate plan filenames and step content — `plan-interview/SKILL.md`, `commands/review-rename-plans.md`, and `commands/plan-hygiene.md` — so they (a) flag non-verb-led filenames and suggest verb-led replacements, and (b) validate that steps carry all three parts and emit three-part format when generating example steps. Bump the plugin to v1.21.0.

## Files to Modify

- `kit/plugins/plan-interview/skills/plan-interview/SKILL.md` — Step 2 filename criteria, Step 2 plan-analysis extraction, Step 5 summary template, Step 6 save note
- `kit/plugins/plan-interview/commands/review-rename-plans.md` — Step 2 filename criteria, suggested-name format
- `kit/plugins/plan-interview/commands/plan-hygiene.md` — Name generation section
- `kit/plugins/plan-interview/CHANGELOG.md` — v1.21.0 entry
- `.claude-plugin/marketplace.json` — version `1.20.0` → `1.21.0`

**No changes needed:**
- `plan-status/SKILL.md` — writes frontmatter only; no filenames or step content generated
- `plan-to-html/SKILL.md` — already parses and renders all three parts
- `deep-grill/SKILL.md` — review-only; generates no step content

## Steps

<ol>

<li>

**Add verb-led criterion to `plan-interview/SKILL.md` Step 2 filename validation.**

In the "Evaluate the filename" block (currently three criteria: Descriptive, Not random, Not too generic), insert a fourth bullet:

```
- **Verb-led**: Starts with an imperative verb (e.g., `add-`, `fix-`, `create-`, `build-`,
  `implement-`, `update-`, `refactor-`, `migrate-`, `configure-`, `remove-`, `enable-`,
  `disable-`, `move-`, `rename-`, `extract-`, `deploy-`, `document-`, `integrate-`).
  Good: `add-dark-mode-toggle`, `fix-auth-redirect`. Bad: `branch-agent-append-date-suffix`
  (noun-led), `auth-module-changes` (noun-led).
```

Also update the "suggested filename" guidance in the "Record the result" block to say the suggestion must be verb-led.

*Why:* the updated `plan-mode.md` rule implies verb-led names; surfacing this during plan-interview closes the loop without requiring a separate hygiene pass.

*Verify:* re-read the "Evaluate the filename" block and confirm four criteria are listed and "Verb-led" is one of them; confirm the suggested-filename note says the suggestion must be verb-led.

</li>

<li>

**Add step-structure check to `plan-interview/SKILL.md` Step 2 plan analysis extraction.**

In the "Extract the following to guide question generation" block, append a new bullet after "Open questions":

```
- **Step structure**: Does the `## Steps` section exist? For each numbered step, check
  whether it includes both a `*Why:*` line and a `*Verify:*` (or `- Verify:`) line.
  Record the count of steps missing a verify line (e.g., "3 of 5 steps lack a verify").
```

*Why:* the plan-mode.md rule now mandates three-part steps; surfacing the gap here lets the interviewer flag it during the same review pass rather than leaving it for a separate hygiene tool.

*Verify:* re-read the extraction block and confirm the "Step structure" bullet appears after "Open questions" and describes checking for both `*Why:*` and `*Verify:*`.

</li>

<li>

**Expose step-structure findings in `plan-interview/SKILL.md` Step 5 summary template.**

In the "Compile and present the review summary" section, add an optional section after "Open Risks & Concerns":

```markdown
### Step Structure

[Include only if Step 2 found steps missing a verify line. State the count
(e.g., "3 of 5 steps lack a *Verify:* line") and show a corrected example:

**Corrected example:**
1. **[Action]** — [description]. *Why:* [rationale]. *Verify:* [how to confirm this step
   succeeded].

Omit this section entirely if all steps already carry action + why + verify.]
```

*Why:* the summary is where the interviewer consolidates all findings for the user; a dedicated section makes the gap visible and provides an inline template.

*Verify:* re-read the Step 5 template and confirm the "Step Structure" section appears after "Open Risks & Concerns", includes a corrected example, and has a conditional-omit rule.

</li>

<li>

**Add three-part format note to `plan-interview/SKILL.md` Step 6 save.**

In the "If they confirm, update the plan with suggested changes" paragraph, insert a note:

```
When writing or amending steps, use the three-part format required by plan-mode.md:
`**[Action]** — [description]. *Why:* [rationale]. *Verify:* [confirmation criteria].`
```

*Why:* Step 6 is the only place in plan-interview that writes step content to the file; the format must be specified here so the model doesn't revert to two-part format on save.

*Verify:* re-read Step 6 and confirm the three-part format string appears in the "update the plan" block.

</li>

<li>

**Add verb-led criterion to `commands/review-rename-plans.md` Step 2 filename evaluation.**

In "Evaluate the filename" (currently three criteria), append a fourth bullet matching the wording added in step 1 above. In the "Record the result" block, also update the suggested-filename note to say the suggestion must be verb-led.

*Why:* `review-rename-plans` is the batch sibling of plan-interview's name validation; keeping the criteria in sync prevents inconsistent enforcement between single-file and batch modes.

*Verify:* re-read the Step 2 evaluation criteria and confirm four criteria are listed with "Verb-led" as the fourth; confirm the suggested-filename note says verb-led.

</li>

<li>

**Update `commands/plan-hygiene.md` name generation to produce verb-led output.**

In the "Name Generation" section, replace the current step 3:

> Convert to kebab-case: lowercase, spaces to hyphens, strip special chars, collapse hyphens, max 60 chars at word boundary, append `.md`

with:

> Convert to kebab-case: lowercase, spaces to hyphens, strip special chars, collapse hyphens, max 60 chars at word boundary, append `.md`. Then apply a **verb-led check**: if the first word of the result is not an imperative verb, extract the dominant action from the heading and prepend it. Examples: heading `Auth Module Refactor` → `refactor-auth-module.md`; heading `User Dashboard` → `add-user-dashboard.md`; heading `Plugin Settings Screen` → `add-plugin-settings-screen.md`. Common verbs: `add`, `fix`, `create`, `build`, `implement`, `update`, `refactor`, `migrate`, `configure`, `remove`, `enable`, `disable`, `move`, `rename`, `extract`, `deploy`, `document`, `integrate`.

*Why:* plan-hygiene auto-generates names from H1 headings; without a verb-led check, a heading like "User Dashboard" would produce `user-dashboard.md`, which passes all current criteria but violates the new convention.

*Verify:* re-read the Name Generation section and confirm step 3 now includes a verb-led check with examples for both verb-present and noun-only headings.

</li>

<li>

**Add v1.21.0 entry to `kit/plugins/plan-interview/CHANGELOG.md`.**

Insert a new section at the top (above the existing `[1.20.0]` entry):

```markdown
## [1.21.0] - 2026-05-14

### Added

- `skills/plan-interview/SKILL.md` Step 2: fourth filename criterion "Verb-led" — flags
  filenames that don't start with an imperative verb and requires suggested names to be
  verb-led
- `skills/plan-interview/SKILL.md` Step 2: "Step structure" extraction point — counts
  steps missing a `*Verify:*` line
- `skills/plan-interview/SKILL.md` Step 5: optional "Step Structure" summary section
  showing count of incomplete steps and a corrected three-part example
- `skills/plan-interview/SKILL.md` Step 6: three-part format string required when writing
  or amending steps (`action — description. *Why:* rationale. *Verify:* criteria.`)
- `commands/review-rename-plans.md` Step 2: fourth filename criterion "Verb-led" — same
  rule as plan-interview, applied to batch filename review
- `commands/plan-hygiene.md` Name Generation: verb-led output check — if generated name is
  noun-led, the dominant action verb is extracted from the heading and prepended
```

*Why:* changelog tracks what changed and when; required by repo convention (every plugin version bump needs a CHANGELOG entry).

*Verify:* re-read CHANGELOG.md and confirm `[1.21.0]` is the topmost entry, dated 2026-05-14, listing all six changed items.

</li>

<li>

**Bump `plan-interview` version to `1.21.0` in `.claude-plugin/marketplace.json`.**

Locate the `plan-interview` plugin entry and change `"version": "1.20.0"` to `"version": "1.21.0"`.

*Why:* minor version bump is correct here — new validation criteria and output behavior added without removing existing functionality; per `marketplace.md` conventions, new features are MINOR bumps.

*Verify:* run `python3 -c "import json; d=json.load(open('.claude-plugin/marketplace.json')); [print(p['version']) for p in d['plugins'] if p['name']=='plan-interview']"` and confirm output is `1.21.0`.

</li>

</ol>

## Verification

1. Load the updated plugin: `claude --plugin-dir ./kit/plugins/plan-interview`
2. Run `/plan-interview:plan-interview` on a plan file whose filename is noun-led (e.g., `branch-agent-append-date-suffix.md`) — confirm the "Plan Name Review" table now includes a "Verb-led" issue row with a verb-led suggested name.
3. Run `/plan-interview:plan-interview` on a plan file whose steps lack `*Verify:*` lines — confirm the Step 5 summary includes a "Step Structure" section showing the count of incomplete steps and the corrected example format.
4. Run `/plan-interview:review-rename-plans` on a directory containing a noun-led plan — confirm the Needs Attention table flags it with "Not verb-led" in the Issue column.
5. Run `/plan-interview:plan-hygiene` on a directory containing plans with noun-only headings — confirm generated name proposals start with a verb.
6. Confirm `.claude-plugin/marketplace.json` reports `1.21.0` for `plan-interview`.

## Next Steps

- Backfill `*Verify:*` lines into existing plan files under `docs/plans/` that predate this rule (out of scope; tracked as separate hygiene pass).
