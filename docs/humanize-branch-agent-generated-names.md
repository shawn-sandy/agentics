# Make branch-agent generated names more descriptive and human-readable

> Replace keyword extraction with verb-led phrase inference and raise all length budgets so generated branch names read like short commit subjects rather than abbreviated keyword strings.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
**Type:** fix

## What shipped

- Rewrote `branch-agent/SKILL.md` Step 2a to infer a verb-led 3–7 word phrase (imperative verb + what changed) instead of extracting 2–5 keywords, with explicit readability rules: whole dictionary words only, no abbreviations, drop trailing words to fit rather than shortening words, plus a good/bad examples table.
- Raised length budgets: pre-suffix name 49 → 60 chars; date-suffixed name 60 → 72 chars (Step 2b); Case B slug 30 → 60 chars with word-boundary dropping instead of hard truncation.
- Updated the `git-agent` README branch-agent bullet, added a CHANGELOG v3.11.1 entry, and bumped `marketplace.json` to `3.11.1`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Branch-name inference and budgeting rules | Modified |
| `kit/plugins/git-agent/README.md` | Branch-agent feature description | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v3.11.1 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent version bump 3.11.0 → 3.11.1 | Modified |

## How it works

The original rule at Step 2a asked for "2–5 extracted keywords" under a 49-char pre-suffix budget. The result was terse, abbreviated names like `feat/src-login-form-valid` that were hard to read in branch lists and PR pages.

The rewrite replaces keyword extraction with phrase inference. Step 2a now asks for a 3–7 word verb-led phrase where the first word is an imperative verb and the remaining words describe what changed. Explicit constraints forbid abbreviations and require whole dictionary words; when the phrase would overflow, trailing words are dropped at word boundaries rather than truncating mid-word.

Length budgets were raised in Step 2b: the pre-suffix portion grows from 49 to 60 chars, the final date-suffixed name from 60 to 72 chars. Case B (user-supplied descriptive phrase) previously hard-truncated at 30 chars; it now allows up to 60 chars with the same word-boundary drop rule.

A good/bad examples table in the SKILL.md illustrates the difference: `feat/add-login-form-email-validation` (good) vs `feat/src-login-form-valid` (bad).

The bump to 3.11.1 reflects a PATCH: the existing rule is refined, no component was added or removed.

## How to use it

`branch-agent` auto-activates on working-tree change description. Invoke it via `/git-agent:branch-agent` or as part of the `ship` workflow.

Generated names will now read like: `feat/extract-user-auth-to-separate-service-2026-07-11` instead of `feat/usr-auth-sep-svc`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |
| `eab3545` | 2026-09-03 | fix(git-agent,code-review): stop the pre-PR reviewer from stalling the ship (4.20.2, 3.3.6) (#619) |
| `9277c9f` | 2026-09-18 | feat(git-agent): commit and ship paths handle lint-gate blocks (4.21.0) (#635) |
| `5e1b3c2` | 2026-09-26 | feat(git-agent): sync with the base branch before pushing (4.22.0) (#639) |
| `3056b57` | 2026-09-28 | fix: retire dated prompt patterns in plan-agent and git-agent (#641) |
| `052d88c` | 2026-10-08 | refactor(git-agent): commit-agent pushes without asking (4.23.0) (#646) |
| `86412c3` | 2026-10-26 | fix(git-agent): finish post-merge-cleanup inside an app session's worktree (4.23.1) (#657) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `174d0ef` | 2026-10-27 | fix(marketplace): resolve claude.ai plugin validation issues (#660) |
| `8a8a392` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |

<!-- generated:end -->

## References

- Plan: [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
