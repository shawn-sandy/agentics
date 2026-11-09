# Make branch-agent generated names more descriptive and human-readable

> Rewrites branch-agent's naming rules to produce verb-led, whole-word phrases instead of abbreviated keyword extractions, and raises the length budgets so names stay readable in branch lists and PR pages.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [humanize-branch-agent-generated-names](plans/humanize-branch-agent-generated-names.md)
**Type:** fix

## What shipped

- Rewrote Step 2a in `branch-agent/SKILL.md` to require a verb-led 3–7 word phrase (imperative verb + what changed), explicitly prohibit abbreviations, and mandate whole dictionary words only
- Added a good/bad examples table showing the contrast between old keyword extraction and new phrase generation
- Raised the pre-suffix budget from 49 to 60 characters, the final date-suffixed budget from 60 to 72 characters, and the Case B slug from 30 to 60 characters with word-boundary dropping instead of hard truncation
- Bumped git-agent to 3.11.1

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Skill — naming rules rewrite | Modified |
| `kit/plugins/git-agent/README.md` | Plugin docs | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — git-agent 3.11.1 | Modified |

## How it works

The old Step 2a asked for "2–5 extracted keywords" under a tight 49-char budget, which produced terse branch names like `feat/src-login-form-valid` — abbreviated to the point of being hard to parse in branch lists and PR pages. The description rule also allowed mid-word truncation via hard truncation at 30 characters in the Case B (user-supplied phrase) path.

The new rule asks for a verb-led phrase — an imperative verb followed by what changed — with a floor of three and ceiling of seven whole words. Abbreviations are explicitly prohibited; if a phrase exceeds the budget, trailing words are dropped at word boundaries rather than words being shortened. This mirrors how a human would name the branch from a commit subject.

Length budget increases reflect the observation that 49 characters is too short to express a two-part phrase clearly while leaving room for a type prefix and date suffix. 60 characters pre-suffix and 72 final gives enough space for a readable phrase while staying well under GitHub's branch name limits.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [humanize-branch-agent-generated-names](plans/humanize-branch-agent-generated-names.md)
