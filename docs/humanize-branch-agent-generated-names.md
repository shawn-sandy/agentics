# Make branch-agent generated names more descriptive and human-readable

> Rewrites branch-agent naming rules to produce verb-led, whole-word branch names instead of terse keyword abbreviations, with raised length budgets to match.

<!-- generated:start -->

**Status:** Shipped 2026-07-11 **Plan:** [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
**Type:** fix

## What shipped

- Rewrote Step 2a of `branch-agent/SKILL.md` to require a verb-led 3–7 word phrase (imperative verb + what changed) instead of "extract 2–5 keywords", with explicit rules prohibiting abbreviations and a good/bad examples table.
- Raised length budgets: pre-suffix name 49→60 chars, final date-suffixed name 60→72 chars, Case B slug 30→60 chars; overflow now drops trailing words at word boundaries instead of hard-truncating.
- Updated `kit/plugins/git-agent/README.md` branch-agent bullet, added CHANGELOG v3.11.1 entry, bumped `git-agent` to `3.11.1` in `.claude-plugin/marketplace.json` (PATCH).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

The old naming rule told the model to "extract 2–5 keywords," producing names like `feat/src-login-form-valid` — abbreviated to the point of being opaque in branch lists. The new rule asks for a verb-led phrase using whole dictionary words, which is how a human would write a commit subject: `feat/add-login-form-validation` rather than `feat/login-form-valid`.

The budget raise (49→60 pre-suffix, 30→60 for user-supplied Case B slugs) gives enough room for a readable multi-word phrase before the date suffix pushes the total over GitHub's 255-char branch-name limit. Word-boundary dropping ensures no branch name ends mid-word when the budget is reached.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
- Changelog: [git-agent CHANGELOG v3.11.1](../kit/plugins/git-agent/CHANGELOG.md)
