---
status: completed
type: fix
created: 2026-05-15
modified: 2026-05-15
---

# Plan: Restore HTML generation in the `/plan-interview` command

## Context

The user reported that the `plan-interview` skill is not converting plans to HTML "as required."

Investigation shows the HTML-generation offer was added to the skill in v1.19.0 (commit `1631f5d`) and fixed in v1.22.1 (commit `cfaf70e`) — but those changes only landed in `skills/plan-interview/SKILL.md`. The parallel slash-command file `commands/plan-interview.md` has not been touched since the `kit/` rename (commit `e15fba2`), so it is three feature releases behind.

Effect:

- Natural-language activation ("stress-test this plan") runs the SKILL.md and offers HTML — works correctly.
- The slash command `/plan-interview:plan-interview` reads the command file directly and never offers HTML — this is the reported bug.

The fix scope (user-confirmed: **Minimal sync**) is to backport the two HTML-offer blocks and the required `Skill` permission into the command file, leaving other drift (verb-led rule, Step 2.6, Step 5 sections) for a separate pass.

## Objective

Add the missing HTML-generation prompts to `commands/plan-interview.md` so the slash-command path matches the skill path for HTML conversion. Update `allowed-tools` so the embedded `Skill(...)` call does not trigger a mid-flow permission prompt.

## Files to modify

- `kit/plugins/plan-interview/commands/plan-interview.md` — add HTML offers in Steps 2 and 6; add `Skill` to `allowed-tools` in frontmatter.
- `kit/plugins/plan-interview/CHANGELOG.md` — record the fix.
- `.claude-plugin/marketplace.json` — bump the `plan-interview` plugin patch version.

No changes to `skills/plan-interview/SKILL.md` (already correct) or to `skills/plan-to-html/SKILL.md` (already correct).

## Steps

1. **Add `Skill` to the command's `allowed-tools` line.** — *Why:* Steps 2 and 6 will issue `Skill(skill: "plan-interview:plan-to-html", ...)`; without `Skill` in `allowed-tools`, the user is prompted for permission mid-run. *Verify:* re-read line 4 of `commands/plan-interview.md` and confirm `Skill` appears in the comma-separated list alongside the existing tools.

2. **Insert the post-rename HTML offer in Step 2 of the command.** — *Why:* SKILL.md asks this immediately after a confirmed rename so the renamed plan gets a corresponding `.html` file. The command should do the same. The text and `Skill(...)` call should mirror `skills/plan-interview/SKILL.md` lines ~170–174 verbatim (offer wording, options, and `--no-open` arg). *Verify:* re-read the command around its "If the user confirms: rename the file…" block and confirm an `AskUserQuestion` step asking _"Generate HTML for the renamed plan?"_ now follows, with the matching `Skill(...)` invocation when the user picks `Yes, generate HTML`.

3. **Insert the post-summary HTML offer in Step 6 of the command, gated to plan-review mode.** — *Why:* SKILL.md (post v1.22.1) asks this after the save decision is handled, regardless of whether the user accepted the summary append, and skips it for skill-review mode. The wording, gating, and `Skill(...)` invocation should mirror `skills/plan-interview/SKILL.md` lines ~504–512. *Verify:* re-read Step 6 of the command and confirm an `AskUserQuestion` step asking _"Generate (or regenerate) HTML for this plan?"_ runs after the existing save-decision block, only when `mode = plan-review`, and that it calls `Skill(skill: "plan-interview:plan-to-html", args: "<resolved-plan-path> --no-open")` on confirm.

4. **Bump `plan-interview` patch version in `.claude-plugin/marketplace.json`.** — *Why:* This is a bug fix per `marketplace.md` (patch = bug fix). Current `marketplace.json` version for `plan-interview` should be incremented by one patch (e.g., `1.22.1` → `1.22.2`). *Verify:* `git diff .claude-plugin/marketplace.json` shows only the `plan-interview` entry's `version` field changing, by exactly one patch level.

5. **Add a CHANGELOG entry under the new version.** — *Why:* Project convention (`CLAUDE.md`) requires changelog updates for plugin changes. *Verify:* the top of `kit/plugins/plan-interview/CHANGELOG.md` has a new `## [X.Y.Z]` section that names: (a) the bug — HTML offer missing from the slash-command flow, (b) the fix — backported HTML prompts in Steps 2 and 6, and (c) the `allowed-tools` update.

## Verification

End-to-end check (after the steps above):

- Run `/plan-interview:plan-interview docs/plans/the-plan-interview-skill-is-logical-teacup.md` (this plan or any other plan). Walk through the rounds and answer through to Step 6. Confirm that after the save-decision question, a new question appears: _"Generate (or regenerate) HTML for this plan?"_ Selecting `Yes, generate HTML` invokes `plan-to-html` and writes `docs/plans/the-plan-interview-skill-is-logical-teacup.html`.
- Repeat with a misnamed plan to exercise the rename path: confirm the rename, then confirm the post-rename HTML offer appears and produces an `.html` next to the renamed `.md`.
- Confirm no permission prompt for `Skill` appears during the run (verifies Step 1 of this plan).
- Run the same flow with natural-language activation ("stress-test this plan against ...") to confirm SKILL.md behavior is unchanged.
- `grep -n 'plan-to-html' kit/plugins/plan-interview/commands/plan-interview.md` should now return two matches (one per added offer); previously it returns zero.

## Next Steps *(out of scope)*

- Full command/skill parity sweep:
  ```text
  In kit/plugins/plan-interview/commands/plan-interview.md, finish syncing the remaining drift versus skills/plan-interview/SKILL.md: (a) add the verb-led filename criterion (v1.21.0), (b) add Step 2.6 skill quality checklist, (c) add the "Skill Quality Checklist Results" and "Step Structure" sections to the Step 5 summary template, (d) update Step 6 to say "update the plan with suggested changes and append this interview summary." Bump the plan-interview patch version, update CHANGELOG, and verify by diffing the two files for remaining substantive differences.
  ```

- Eliminate the parallel-file drift class permanently:
  ```text
  Refactor kit/plugins/plan-interview/commands/plan-interview.md from a 352-line duplicate of SKILL.md into a thin wrapper that just invokes the skill on $ARGUMENTS (preserving frontmatter description, argument-hint, and a minimal allowed-tools). Verify by running /plan-interview:plan-interview with and without an argument and confirming behavior matches the natural-language activation path. Apply the same pattern to deep-grill, documenting-plans, plan-status, plan-to-html, plan-hygiene, review-rename-plans, and update-plan-status if drift exists between their command files and SKILL.md files.
  ```

## Unresolved Questions *(none)*
