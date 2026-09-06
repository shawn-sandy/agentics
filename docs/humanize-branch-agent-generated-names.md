# Make branch-agent generated names more descriptive and human-readable

> Rewrites the branch-agent description-inference rule to produce verb-led, whole-word phrases and raises length budgets so auto-generated names read like short commit subjects a human would write.

<!-- generated:start -->

**Status:** Shipped 2026-07-11 **Plan:** [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
**Type:** fix

## What shipped

- Rewrote Step 2a description inference in `branch-agent/SKILL.md` to require a verb-led 3–7 word phrase (imperative verb + what changed), explicitly prohibit abbreviations and keyword extraction, and include a good/bad examples table (replaces "2–5 extracted keywords" rule that produced terse names like `feat/src-login-form-valid`).
- Raised length budgets: pre-suffix name 49 → 60 chars, final date-suffixed name 60 → 72 chars (Step 2b), and Case B user-supplied slug 30 → 60 chars — all with word-boundary dropping instead of hard truncation at the limit.
- Synced `kit/plugins/git-agent/README.md`, added `CHANGELOG.md` v3.11.1 entry, and bumped `marketplace.json` from 3.11.0 to 3.11.1 (PATCH: refines existing rule, no component added or removed).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Naming rules — primary change | Modified |
| `kit/plugins/git-agent/README.md` | branch-agent feature description updated | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v3.11.1 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent bumped to 3.11.1 | Modified |

## How it works

The `branch-agent` skill auto-generates branch names from working-tree changes using the format `<type>/<scope>-<description>`. Before this fix, the description rule asked for "2–5 extracted keywords" under a 49-character pre-suffix budget. That produced names like `feat/src-login-form-valid` — abbreviated, scope-first, and hard to parse in branch lists or PR pages.

The rewrite changes the inference target from keywords to a short imperative phrase, modelled on good commit subjects. The rule now asks for an imperative verb followed by what changed — whole dictionary words only, no abbreviations — producing names like `feat/add-login-form-validation` instead. When a phrase would overflow the budget, trailing words are dropped at word boundaries rather than the last word being truncated mid-character.

The Case B path (where the user supplies a descriptive phrase argument) had its own 30-character hard truncation. Raising that to 60 and switching to word-boundary dropping means a phrase like `refactor-authentication-middleware-cleanup` is preserved whole rather than chopped at 30 to `refactor-authentication-mi`.

The length budget increases (49 → 60 pre-suffix, 60 → 72 final) give the phrase rule room to be descriptive without fighting the truncation rule. The date suffix appended in Step 2b already took chars from the final budget, so both limits had to rise together.

## How to use it

`/git-agent:branch-agent` — no invocation change. The improvement is in the quality of names generated when the skill infers a description from the working tree. Pass a descriptive phrase argument to use Case B, which now respects up to 60 characters before word-boundary dropping.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `7459add` | 2026-07-11 | fix(git-agent): make generated branch names more descriptive and human-readable (3.11.1) (#383) |

<!-- generated:end -->

## References

- Plan: [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
