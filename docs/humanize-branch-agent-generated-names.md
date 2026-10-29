# Make branch-agent generated names more descriptive and human-readable

> Rewrites branch-agent's description inference rule from "extract 2–5 keywords" to a verb-led 3–7 word phrase, raises all length budgets, and adds a good/bad examples table.

<!-- generated:start -->

**Status:** Shipped 2026-07-11  **Plan:** [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
**Type:** fix

## What shipped

- Updated `kit/plugins/git-agent/skills/branch-agent/SKILL.md` Step 2a — replaced "extract 2–5 keywords" with a verb-led 3–7 word phrase rule (imperative verb + what changed), added explicit readability rules (whole dictionary words only, no abbreviations, drop trailing words at word boundaries to fit rather than shortening), and a good/bad examples table.
- Raised length budgets: pre-suffix name 49 → 60 chars; final date-suffixed name 60 → 72 chars (Step 2b); Case B slug 30 → 60 chars with word-boundary dropping instead of hard truncation.
- Updated `kit/plugins/git-agent/README.md` branch-agent feature description.
- Added `kit/plugins/git-agent/CHANGELOG.md` v3.11.1 entry.
- Bumped `git-agent` to `3.11.1` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |

## How it works

The previous naming rule asked for "2–5 extracted keywords" under a 49-character budget, producing terse abbreviated names like `feat/src-login-form-valid` that were difficult to scan in branch lists and PR pages.

The replacement rule asks for a **verb-led phrase** — an imperative verb followed by 2–6 words naming what changed. Abbreviation is explicitly prohibited: the skill must use whole dictionary words and drop trailing words at word boundaries if the phrase would exceed the budget, rather than shortening existing words. The budget itself was raised (49 → 60 chars pre-suffix, 60 → 72 chars final) to give the phrase enough room to stay readable while still fitting typical branch-list columns.

The Case B path (user supplies a descriptive phrase argument) previously hard-truncated at 30 characters, chopping user-supplied phrases mid-thought. The 60-character budget with word-boundary dropping means the user's intent survives at its natural phrasing up to the new limit.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
