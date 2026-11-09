# Make branch-agent generated names more descriptive and human-readable

> Branch names generated from working-tree changes now use verb-led phrases with whole words instead of terse keyword extracts, with raised length budgets throughout.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
**Type:** fix

## What shipped

- Rewrote the Step 2a description-inference rule in `branch-agent/SKILL.md` to require a verb-led 3–7 word phrase (imperative verb + what changed) with whole dictionary words only — abbreviations are explicitly prohibited.
- Added a good/bad examples table illustrating the contrast between the old keyword extract style and the new phrase style.
- Raised length budgets: pre-suffix name 49 → 60 chars, final date-suffixed name 60 → 72 chars (Step 2b), Case B slug 30 → 60 chars.
- Changed overflow handling from hard truncation (which chopped words mid-thought) to word-boundary dropping throughout.
- Synced README, CHANGELOG, and bumped `marketplace.json` to 3.11.1 (PATCH bump).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Branch-agent skill — naming rules (primary change) | Modified |
| `kit/plugins/git-agent/README.md` | Branch-agent feature description | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v3.11.1 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent version 3.11.0 → 3.11.1 | Modified |

## How it works

`branch-agent` auto-generates branch names from working-tree changes. Before this fix, Step 2a asked for "2–5 extracted keywords" under a 49-char pre-suffix budget, producing names like `feat/src-login-form-valid` — terse, abbreviated, and hard to read in branch lists or PR pages. The Case B slug path (user-supplied descriptive phrases) hard-truncated at 30 characters, chopping input mid-thought.

The updated Step 2a now requires a verb-led 3–7 word phrase in the imperative: what was changed, in natural words, with no abbreviations. The examples table makes the contrast explicit: `feat/add-auth-token-refresh-endpoint` (good) vs `feat/auth-tok-rfsh` (bad). When a phrase exceeds the budget, trailing words are dropped at word boundaries rather than characters — `add-user-preference-notification` becomes `add-user-preference`, never `add-user-prefer`.

The three length budgets were raised to give the new phrase style room to work without truncation becoming the norm. The 72-char final cap still fits comfortably in GitHub's branch selector UI while accommodating a date suffix.

## How to use it

`branch-agent` is activated when you invoke `/git-agent:branch-agent` or when `git-agent` auto-branches during a ship flow. The naming changes are transparent — generated names simply read better.

```
/git-agent:branch-agent   # generates a branch name from working-tree changes
```

Example output before: `feat/src-comp-btn-valid`
Example output after: `feat/add-form-validation-to-submit-button`

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8a8a392f` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `174d0efc` | 2026-10-27 | fix(marketplace): resolve claude.ai plugin validation issues (#660) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
