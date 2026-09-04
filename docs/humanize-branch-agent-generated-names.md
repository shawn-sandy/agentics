# Make branch-agent generated names more descriptive and human-readable

> Rewrites the `branch-agent` skill's auto-name generation to produce verb-led, whole-word phrases that read like commit subjects, and raises length budgets so names are no longer truncated mid-word.

<!-- generated:start -->

**Status:** Shipped 2026-07-11 **Plan:** [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
**Type:** fix

## What shipped

- Rewrote Step 2a description inference in `branch-agent/SKILL.md`: the rule changed from "extract 2–5 keywords" to a verb-led 3–7 word phrase (imperative verb + what changed), with explicit readability guards: whole dictionary words only, no abbreviations, drop trailing words to fit the budget rather than shortening words.
- Added a good/bad examples table to SKILL.md to make the expected output concrete for the model.
- Raised length budgets: pre-suffix branch name 49 → 60 chars; final date-suffixed name 60 → 72 chars; Case B descriptive-phrase slugs 30 → 60 chars with word-boundary dropping instead of hard truncation.
- Updated `git-agent` README branch-agent feature description, added a `v3.11.1` CHANGELOG entry, and bumped `marketplace.json` to 3.11.1 (PATCH — refines an existing rule, no component added or removed).

> See [CHANGELOG v3.11.1](../kit/plugins/git-agent/CHANGELOG.md#v3111--2026-07-11--more-descriptive-human-readable-generated-branch-names) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Skill instructions — Step 2a description inference rule, length budgets, examples table | Modified |
| `kit/plugins/git-agent/README.md` | Plugin docs — branch-agent feature description | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release history — v3.11.1 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — `git-agent` version to 3.11.1 | Modified |

## How it works

The `branch-agent` skill generates branch names in the format `<type>/[<scope>-]<description>[-YYYY-MM-DD]` (scope is optional). Before this change, the description segment was derived by extracting 2–5 keywords from the working tree diff, producing terse names like `feat/src-login-form-valid`. These were hard to read in branch lists, PR pages, and `git log --oneline` output.

Step 2a now instructs the model to synthesize a short phrase rather than extract keywords. The phrase must start with an imperative verb (matching the git commit subject convention), describe what changed in plain language, and use only whole dictionary words — abbreviations like `auth`, `impl`, or `val` are explicitly forbidden. When the phrase exceeds the budget, trailing words are dropped at the nearest word boundary; the phrase is never shortened by truncating a word mid-character.

Length budgets were raised to give the new phrasing room to breathe. The pre-suffix segment was the most constrained at 49 chars; raising it to 60 allows 3–4 meaningful words in most cases. The 11-character date suffix (`-YYYY-MM-DD`) is accounted for in the final 72-char cap. Case B (when the user supplies a descriptive phrase as the argument) now slugifies at up to 60 chars with the same word-boundary dropping rule, preventing the previous behaviour where a user's carefully chosen phrase might be cut mid-word.

The good/bad examples table in SKILL.md serves as a concrete calibration signal for the model. Generating branch names is a judgment call that varies with diff content; examples like `feat/add-user-authentication-flow` (good) versus `feat/src-auth-flow-impl` (bad — abbreviated) make the constraint unambiguous.

## How to use it

The `branch-agent` skill activates automatically when the user asks to create or start a new branch (description trigger). It can also be invoked explicitly:

```
/git-agent:branch-agent                   # auto-generate name from working tree changes
/git-agent:branch-agent fix/my-bug-title  # use supplied name (Case B — still date-suffixed)
```

Generated names now read like: `feat/add-export-session-skill-2026-07-02` or `fix/make-branch-names-readable-2026-07-11` instead of the previous terse keyword style. The date suffix is always appended to the final branch name regardless of which path generated the description.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `7459add` | 2026-07-11 | fix(git-agent): make generated branch names more descriptive and human-readable (3.11.1) (#383) |

<!-- generated:end -->

## References

- Plan: [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
- Changelog: [kit/plugins/git-agent/CHANGELOG.md](../kit/plugins/git-agent/CHANGELOG.md)
