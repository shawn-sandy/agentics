# Make branch-agent generated names more descriptive and human-readable

> Auto-generated branch names switched from terse keyword abbreviations to verb-led, whole-word phrases with longer length budgets, making them read like short commit subjects.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
**Type:** fix

## What shipped

- Rewrote Step 2a description-inference rule in `branch-agent` to produce verb-led 3–7 word phrases (imperative verb + what changed) instead of 2–5 extracted keywords, with explicit prohibition on abbreviations and a good/bad examples table.
- Raised all three length budgets: pre-suffix name 49 → 60 chars, final date-suffixed name 60 → 72 chars, Case B (user-supplied slug) 30 → 60 chars — overflow now drops trailing whole words instead of hard-truncating mid-word.
- Updated `kit/plugins/git-agent/README.md` branch-agent feature description to document the new naming rules.
- Added `CHANGELOG.md` v3.11.1 entry and bumped `marketplace.json` git-agent version from 3.11.0 → 3.11.1 (PATCH: existing component refined, none added or removed).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | Skill instructions — naming rules primary | Modified |
| `kit/plugins/git-agent/README.md` | Plugin documentation — branch-agent feature description | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history — v3.11.1 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — git-agent version bump | Modified |

## How it works

The `branch-agent` skill in `kit/plugins/git-agent/skills/branch-agent/SKILL.md` auto-generates branch names from uncommitted working-tree changes when invoked without arguments. Before this fix, the Step 2a description-inference rule asked for "2–5 extracted keywords" under a 49-character pre-suffix budget, which produced terse, abbreviated names like `feat/src-login-form-valid`. This fix replaced that rule with a verb-led phrase approach.

Step 2a now instructs the model to form a 3–7 word imperative phrase describing what changed — for example, `feat/add-login-form-validation` instead of `feat/src-login-form-valid`. The rule explicitly prohibits abbreviations and requires whole dictionary words. A good/bad examples table in the skill body reinforces the distinction. When a phrase would overflow the budget, trailing words are dropped at word boundaries rather than chopping mid-word.

The three length budgets were all raised. The pre-suffix name limit went from 49 to 60 characters; the final date-suffixed name (Step 2b) from 60 to 72 characters; and the Case B path (where the user supplies a descriptive phrase as an argument) from 30 to 60 characters. Case B also adopted word-boundary dropping for overflow, matching Case A behaviour.

`kit/plugins/git-agent/README.md` was updated to describe the new behaviour in the branch-agent feature section. The plugin's `CHANGELOG.md` gained a v3.11.1 entry documenting the change, and `.claude-plugin/marketplace.json` was bumped from 3.11.0 to 3.11.1 to satisfy the CI version-bump gate.

## How to use it

Branch-agent is activated whenever the user asks to create or start a new branch.

```
/git-agent:branch-agent                        # auto-generates name from working-tree changes
/git-agent:branch-agent add-dark-mode-toggle   # uses the supplied phrase as the slug (Case B)
/git-agent:branch-agent fix/login-redirect     # pre-formed name passed through directly
```

Auto-generated names now read like commit subjects: `feat/add-login-form-validation-2026-07-11` instead of `feat/src-login-form-valid-2026-07-11`. The date suffix (`-YYYY-MM-DD`) is always appended regardless of path.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `324cc3c` | 2026-08-19 | feat(git-agent): adversarial pre-PR review in PR-opening flows (4.19.3) (#585) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `2fd715f` | 2026-08-17 | fix: redefine done as artifact + verification in five high-impact skills (#568) |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |
| `744f6e1` | 2026-08-14 | feat(git-agent): add scope guard PreToolUse hook (#560) |
| `c1e6e34` | 2026-08-14 | Run every ship pre-flight guard before reporting, not just the first (#555) |
| `a21acfb` | 2026-08-14 | Verify before asserting: merge guards, measured contrast ratios, review-finding reproduction (#552) |
| `58ae32d` | 2026-08-12 | refactor(git-agent): remove the lint gate from the merge skill (4.15.0) (#545) |
| `c071dac` | 2026-08-10 | fix(git-agent): make the commit lint gate trustworthy in every repo (4.14.0) (#544) |
| `dab833c` | 2026-08-05 | feat(git-agent): severity filter in Step 6c, mergeStateStatus in the merge gate (4.13.0) (#527) |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |

<!-- generated:end -->

## References

- Plan: [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
- Related docs: [`kit/plugins/git-agent/CHANGELOG.md`](../kit/plugins/git-agent/CHANGELOG.md)
