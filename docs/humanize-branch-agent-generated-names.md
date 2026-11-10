# Make branch-agent generated names more descriptive and human-readable

> `branch-agent` auto-generated terse, abbreviated branch names like `feat/src-login-form-valid`; the naming rules were rewritten to produce verb-led, whole-word phrases within wider length budgets.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [humanize-branch-agent-generated-names](plans/humanize-branch-agent-generated-names.md)
**Type:** fix

## What shipped

- Rewrote the `branch-agent` Step 2a description-inference rule from "extract 2–5 keywords" to a verb-led 3–7 word phrase rule with explicit prohibition on abbreviations.
- Raised the pre-suffix name budget from 49 to 60 characters and the final date-suffixed budget from 60 to 72 characters.
- Raised the Case B (user-supplied phrase) slug budget from 30 to 60 characters with word-boundary dropping instead of hard truncation.
- Added a good/bad examples table to the skill.
- Updated the `git-agent` README, added a CHANGELOG v3.11.1 entry, and bumped the marketplace version from 3.11.0 to 3.11.1.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Branch naming rules (primary) | Modified |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Version manifest | Modified |

## How it works

**Naming rule rewrite.** `branch-agent/SKILL.md` Step 2a previously asked for "2–5 extracted keywords", which encouraged the model to abbreviate individual words to stay within budget. The rule was replaced with an instruction to produce an imperative-verb-led phrase of 3–7 whole dictionary words describing what changed. Abbreviation is now explicitly prohibited; the overflow handling drops trailing whole words rather than shortening any word.

**Wider length budgets.** The pre-suffix segment ceiling moved from 49 to 60 characters and the final date-suffixed ceiling from 60 to 72. These numbers give the model room to write `fix-login-redirect-after-oauth-callback` rather than `fix-login-redir-oauth-cb`. Case B slugs (where the caller supplies a descriptive phrase) gained the same 60-character ceiling with word-boundary dropping, eliminating the previous hard-truncation that could chop a phrase mid-word.

**Examples table.** A good/bad examples table was added to the skill so the model has concrete anchors rather than inferring the quality bar from the prose alone.

**Version sync.** The change refines an existing naming rule without adding or removing any component, making it a patch release. `git-agent` shipped as 3.11.1 in `marketplace.json`, with the README branch-agent bullet and the CHANGELOG updated to match.

## How to use it

Branch names are generated automatically when `branch-agent` reads the working-tree diff. No invocation change is needed. Generated names will now read like short commit subjects (`feat/add-dark-mode-toggle-to-settings-panel`) rather than abbreviated keyword strings (`feat/settings-dark-toggle`).

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `7459add` | 2026-07-11 | fix(git-agent): make generated branch names more descriptive and human-readable (3.11.1) (#383) |

<!-- generated:end -->

## References

- Plan: [humanize-branch-agent-generated-names](plans/humanize-branch-agent-generated-names.md)
- Changelog: `kit/plugins/git-agent/CHANGELOG.md` — v3.11.1 entry
