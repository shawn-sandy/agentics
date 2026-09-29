# Make branch-agent generated names more descriptive and human-readable

> Rewrites the branch-agent naming rules to produce verb-led, whole-word branch names up to 72 characters, replacing the terse keyword slugs that the previous 49-character budget encouraged.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
**Type:** fix

## What shipped

- Replaced the "extract 2–5 keywords" description rule with a verb-led 3–7 word phrase rule (imperative verb + what changed)
- Added explicit readability constraints: whole dictionary words only, no abbreviations, trailing words dropped at word boundaries when over budget
- Added a good-vs-bad examples table to `SKILL.md`
- Raised the pre-suffix name budget from 49 to 60 characters
- Raised the final date-suffixed name budget from 60 to 72 characters
- Raised the Case B (user-supplied phrase) slug budget from 30 to 60 characters, with word-boundary dropping instead of hard truncation
- Updated the `README.md` branch-agent feature description
- Added a `CHANGELOG.md` v3.11.1 entry
- Bumped `marketplace.json` from git-agent 3.11.0 to 3.11.1

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Naming rules — primary change | Modified |
| `kit/plugins/git-agent/README.md` | Branch-agent feature description | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v3.11.1 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent version bump 3.11.0 → 3.11.1 | Modified |

## How it works

The `branch-agent` skill generates branch names from working-tree changes using the format `<type>/<scope>-<description>`. Before this fix, the description rule asked for "2–5 extracted keywords" within a tight 49-character pre-suffix budget, which produced terse, abbreviated names such as `feat/src-login-form-valid` — names that are difficult to read in branch lists and PR pages.

The fix rewrites Step 2a of the skill's name inference. Instead of extracting raw keywords, the skill now forms an imperative verb phrase of 3–7 whole words describing what changed — for example, `add-user-login-form-validation` instead of `src-login-form-valid`. Abbreviation is explicitly prohibited by the updated rule text, and a good/bad examples table in `SKILL.md` illustrates the contrast.

Length budgets were raised across the board. The pre-suffix name limit moved from 49 to 60 characters, the final date-suffixed name limit from 60 to 72 characters, and the Case B slug limit (for user-supplied descriptive phrase arguments) from 30 to 60 characters. All three overflow handlers now drop trailing whole words at word boundaries rather than hard-truncating mid-word, preserving readability at any length.

The change is a PATCH bump (3.11.0 → 3.11.1) because it refines an existing rule — no component was added or removed. The README and CHANGELOG entries document the new defaults for users who reference them.

## How to use it

After loading the plugin, invoke `/git-agent:branch-agent` as usual. The generated branch name will now read like a short commit subject: verb-led, whole words, up to 60 characters before the date suffix. To supply your own phrase, pass it as an argument; the skill will slug-ify it at word boundaries up to 60 characters rather than chopping at 30.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
