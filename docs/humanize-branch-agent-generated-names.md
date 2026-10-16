# Make branch-agent generated names more descriptive and human-readable

> Replace terse keyword-extracted branch names with verb-led, whole-word phrases, and raise length budgets so slugs read like short commit subjects a human would write.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
**Type:** fix

## What shipped

- Rewrote the `branch-agent` description-inference rule (Step 2a) to require a verb-led 3–7 word phrase using whole dictionary words, with abbreviations explicitly prohibited and a good/bad examples table added.
- Raised length budgets: pre-suffix name 49 → 60 chars, date-suffixed final name 60 → 72 chars, Case B user-supplied slug 30 → 60 chars; overflow drops trailing words at word boundaries rather than hard-truncating mid-word.
- Updated `git-agent` README branch-agent feature description to reflect the new naming guidance (no abbreviations, imperative verb lead).
- Added CHANGELOG entry for v3.11.1 and bumped `marketplace.json` from 3.11.0 → 3.11.1 (PATCH: rule refinement, no component added or removed).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Naming rules for auto-generated branch names | Modified |
| `kit/plugins/git-agent/README.md` | Branch-agent feature description | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v3.11.1 release entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent version bump 3.11.0 → 3.11.1 | Modified |

## How it works

The `branch-agent` skill auto-generates branch names from a diff of the working tree. Before this change, Step 2a asked for "2–5 extracted keywords" under a 49-character pre-suffix budget, producing compact but unreadable slugs like `feat/src-login-form-valid`. The Case B path (user supplies a descriptive phrase) hard-truncated at 30 characters, sometimes chopping mid-word.

The fix rewrites Step 2a to request a verb-led 3–7 word phrase in the imperative mood (e.g. `add-email-validation-to-checkout-form`). The rule explicitly bans abbreviations and lists a table of good versus bad examples so the model has concrete guidance rather than a character count to optimize against.

Length budgets were raised in three places. The pre-suffix name grows from 49 to 60 characters, giving room for two to three extra words. The full date-suffixed name (used for uniqueness disambiguation) grows from 60 to 72 characters. The Case B slug limit grows from 30 to 60 characters. In all three cases, the overflow strategy changes from hard truncation to dropping the last whole word — so the name always ends at a word boundary.

The CHANGELOG entry records this as a PATCH bump because the change refines an existing rule without adding or removing any skill, command, or hook.

## How to use it

`branch-agent` is invoked automatically by git-agent's `ship` and `ship-autonomous` flows, or directly via `/git-agent:branch-agent`. No new arguments were added; the improved names appear wherever a branch name was generated before.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
