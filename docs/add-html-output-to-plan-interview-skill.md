# Add HTML output to the plan-interview skill (rename + save findings)

> Extends the `plan-interview` skill to offer HTML generation at two key moments — after a confirmed rename (Step 2) and after a confirmed interview-summary append (Step 6) — keeping the `.html` artifact in sync with the plan file (v1.19.0).

<!-- generated:start -->

**Status:** Shipped 2026-05-13  **Plan:** [add-html-output-to-plan-interview-skill.md](plans/add-html-output-to-plan-interview-skill.md)
**Type:** artifact

## What shipped

- Added `Skill` to the `allowed-tools` frontmatter of `kit/plugins/plan-interview/skills/plan-interview/SKILL.md` so `plan-to-html` can be invoked mid-skill without triggering a mid-interview permission prompt.
- Inserted an HTML-generation offer at the end of Step 2's "If the user confirms" block (after the rename is applied): prompts via `AskUserQuestion` ("Yes, generate HTML" / "Skip"), then invokes `plan-to-html` with the new file path and `--no-open` if accepted; notes that `plan-to-html` will prompt for a theme.
- Inserted a parallel HTML-(re)generation offer at the end of Step 6's "If they confirm" block (after the interview summary is appended via `Edit`): same `AskUserQuestion` pattern, notes "regenerate" when an `.html` already exists, invokes `plan-to-html` with the current resolved plan path and `--no-open`.
- Renamed the placeholder plan file from `implements-this-plan-expressive-valiant.md` to `add-html-output-to-plan-interview-skill.md` via `git mv`.
- Bumped `plan-interview` version from `1.18.0` to `1.19.0` (MINOR — new behaviour added to an existing skill) in `.claude-plugin/marketplace.json`.
- Added `## [1.19.0] - 2026-05-13` entry to `kit/plugins/plan-interview/CHANGELOG.md` above `[1.18.0]`.

> CHANGELOG citation — `kit/plugins/plan-interview/CHANGELOG.md`, `## [1.19.0] - 2026-05-13`: "Step 2: after a user-confirmed rename, offers to generate HTML for the renamed plan via `plan-to-html --no-open`; Step 6: after a user-confirmed summary append, offers to generate or regenerate HTML so the artifact reflects the appended `## Interview Summary`; `Skill` added to `allowed-tools`."

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/skills/plan-interview/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-interview/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `docs/plans/add-html-output-to-plan-interview-skill.md` | Plan file (renamed) | Modified |
| `kit/plugins/plan-interview/skills/plan-to-html/SKILL.md` | Skill instructions | Not modified (reused) |

## How it works

The `plan-interview` skill has two natural moments where the on-disk plan file changes: Step 2 (rename, when the filename is mismatched) and Step 6 (save findings, when an `## Interview Summary` section is appended). Before v1.19.0, neither moment generated or refreshed the HTML view of the plan, so any previously-generated `.html` would become stale.

This change adds a lightweight offer branch after each of those two confirmed-action points. In Step 2, once the rename has been applied (the file has moved to its new path, the H1 has been updated, and internal references to the new path are set up), an `AskUserQuestion` prompt surfaces. If the user accepts, the skill calls `Skill("plan-interview:plan-to-html", "<new-path> --no-open")`. The `--no-open` flag suppresses the browser-launch prompt that would normally interrupt the in-progress interview session. The `plan-to-html` skill's own theme prompt is allowed to fire — a single extra question per rename is acceptable.

In Step 6, the offer fires inside the "If they confirm" branch, after `Edit` has appended the summary. If the plan was renamed in Step 2, the resolved path already reflects the new name; the HTML is generated (or regenerated) from this final state. The wording explicitly notes "regenerate" when an `.html` sibling already exists so the user understands that `plan-to-html`'s overwrite prompt may follow.

The `plan-to-html` skill itself was not modified for this plan — it already accepted a file path argument and the `--no-open` flag from the v1.18.0 work that added the same behaviour to the rename commands. This plan extends the same pattern to the skill surface.

Decline paths are preserved: declining the rename in Step 2 skips both the rename and the HTML offer; declining the summary append in Step 6 skips both the append and the HTML offer.

## How to use it

The HTML offers are embedded in the normal `plan-interview` skill flow. They activate automatically:

**After a rename (Step 2):** When the skill detects a mismatched filename and the user confirms the rename, a new prompt appears:
> "Would you like to generate an HTML view of the renamed plan? (plan-to-html will ask for a theme)"
> Options: `Yes, generate HTML` / `Skip`

**After saving the interview summary (Step 6):** After the `## Interview Summary` is appended and the user confirms, a second prompt appears:
> "Would you like to generate (or regenerate) HTML for the updated plan? [Notes if .html already exists: plan-to-html will prompt to overwrite it]"
> Options: `Yes, generate HTML` / `Skip`

Both invocations pass `--no-open`, so no browser tab launches during the interview.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `1631f5d` | 2026-05-13 | feat(plugins/plan-interview): add html generation offers to skill step 2 and step 6, bump to v1.19.0 |
| `3dee2c2` | 2026-05-13 | chore(docs/plans): add status frontmatter to two plan files per coderabbit review |

<!-- generated:end -->

## References

- Plan: [add-html-output-to-plan-interview-skill.md](plans/add-html-output-to-plan-interview-skill.md)
- Related docs: [add-plan-to-html-skill-to-plan-interview.md](add-plan-to-html-skill-to-plan-interview.md), [add-review-rename-plans-command.md](add-review-rename-plans-command.md), [add-html-output-to-rename-workflow.md](add-html-output-to-rename-workflow.md)
