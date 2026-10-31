# Make branch-agent generated names more descriptive and human-readable

> Generated branch names should read like short commit subjects a human would write — verb-led, whole words, no abbreviations — with enough length budget to stay readable.

<!-- generated:start -->

**Status:** Shipped 2026-07-11  **Plan:** [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
**Type:** fix

## What shipped

- Rewrote `branch-agent/SKILL.md` Step 2a description-inference rule from "extract 2–5 keywords" to a verb-led 3–7 word phrase rule (imperative verb + what changed), with explicit readability requirements: whole dictionary words only, no abbreviations, drop trailing words to fit rather than shortening them, plus a good/bad examples table.
- Raised the pre-suffix name budget from 49 to 60 characters and the final date-suffixed budget from 60 to 72 characters (Step 2b).
- Raised the Case B slug budget (user-supplied descriptive phrase) from 30 to 60 characters and replaced hard truncation with word-boundary dropping.
- Synced `git-agent/README.md`, `git-agent/CHANGELOG.md` (v3.11.1 entry), and `.claude-plugin/marketplace.json` (3.11.0 → 3.11.1).

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Branch agent skill — naming rules, length budgets, examples table | Modified |
| `kit/plugins/git-agent/README.md` | Plugin README — branch-agent feature description | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Changelog — v3.11.1 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — git-agent 3.11.0 → 3.11.1 | Modified |

## How it works

The `branch-agent` skill in git-agent auto-generates branch names from the working-tree diff using the format `<type>/<scope>-<description>`. Before this fix, the description rule asked for "2–5 extracted keywords" under a 49-character budget, which produced terse, abbreviated names like `feat/src-login-form-valid` — unreadable in branch lists and PR pages.

The rewrite changes the core inference rule in Step 2a from keyword extraction to phrase synthesis. The model is now asked to produce a verb-led imperative phrase (3–7 words) that reads like a commit subject — for example `add-login-form-validation` instead of `src-login-form-valid`. The good/bad examples table in the updated SKILL.md anchors this with concrete comparisons so the rule is applied consistently.

The length budget increase (49 → 60 pre-suffix, 60 → 72 final) gives the verb-led phrase room to stay whole. The previous budget was tight enough that even a 5-word phrase risked truncation, which was the primary pressure pushing the model toward abbreviation. Overflow handling now drops trailing words at word boundaries everywhere — so a phrase that is too long loses its last word rather than having its last word chopped mid-character.

Case B (user-supplied phrase slug) raised its budget from 30 to 60 characters for the same reason: a user who typed a 40-character descriptive phrase was getting it cut in half.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
