# Teach the plan-mode guard once, keep it everywhere

> Forty-three plugin files each re-teach Claude the same four-line dance about exiting plan mode before writing files, spread across eight plugins. The guard i...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [remove-exitplanmode-boilerplate.md](plans/remove-exitplanmode-boilerplate.md)
**Type:** refactor

## What shipped

- Inventory all 52 files and classify each as write-heavy (the skill or command mutates the filesystem, git state, or a...
- Agree the canonical one-line guard wording and record it in `.claude/rules/plugin-patterns.md` as the pattern authors...
- Replace the long form with the canonical line in every write-heavy file, one plugin at a time, starting with `code-re...
- Delete the block outright from every file classified read-only in Step 1.
- Bump the version of all ten touched plugins in `.claude-plugin/marketplace.json` and add a `CHANGELOG.md` entry to each.
- Write `tests/plugins/test-exitplanmode-guard.sh` asserting the long-form tutorial text appears in zero files, that to...
- Add the new test to `.github/workflows/check-plugin-versions.yml`.
- *(added during execution)* Retarget two existing tests that asserted on the boilerplate itself.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/social-media-tools/**/*.md` | 15 files, the largest group | Modified |
| `kit/plugins/plan-agent/**/*.md` | 9 files | Modified |
| `kit/plugins/git-agent/**/*.md` | 10 files | Modified |
| `kit/plugins/artifact-tools/**/*.md` | 4 files | Modified |
| `kit/plugins/product-plans/**/*.md` | 2 files | Modified |
| `kit/plugins/skill-reviewer/**/*.md` | 1 file | Modified |
| `kit/plugins/content-tools/**/*.md` | 1 file | Modified |
| `kit/plugins/code-testing-agent/**/*.md` | 1 file | Modified |
| `.claude/rules/plugin-patterns.md` | the canonical wording, and the fix to the rule that manda... | Modified |
| `.claude-plugin/marketplace.json` | eight version bumps | Modified |
| `kit/plugins/*/CHANGELOG.md` | one entry per touched plugin | Modified |
| `tests/plugins/test-exitplanmode-guard.sh` | objective test | Created |
| `tests/plugins/test-build-skill.sh` | check 4 asserted on the boilerplate wording | Modified |
| `tests/plugins/test-setup-sites.sh` | check 5 asserted on the boilerplate wording | Modified |
| `.github/workflows/check-plugin-versions.yml` | wire the new test | Modified |

## How it works

Reduce the repeated `ExitPlanMode` preamble across 52 plugin files to a single canonical line in the skills that actually mutate the filesystem, preserving the guard while removing roughly 2,750 words of duplicated explanation.

Measured across `kit/plugins/`: 52 files mention `ExitPlanMode`, and the lines containing it total about 2,750 words. The same four-line block — exit plan mode, here is why mutations cannot proceed inside it, `ExitPlanMode` is deferred, call `ToolSearch` with `select:ExitPlanMode` first — is repeated

The implementation proceeded through these steps: Inventory all 52 files and classify each as write-heavy (the skill or command mutates the filesystem, git state, or a...; Agree the canonical one-line guard wording and record it in `.claude/rules/plugin-patterns.md` as the pattern authors...; Replace the long form with the canonical line in every write-heavy file, one plugin at a time, starting with `code-re...; Delete the block outright from every file classified read-only in Step 1. Why: a guard against a mutation the skill n...; Bump the version of all ten touched plugins in `.claude-plugin/marketplace.json` and add a `CHANGELOG.md` entry to ea....

- Manual plan-mode behavioural test not run — EnterPlanMode requires user approval and ExitPlanMode requests it, so neither works in a non-interactive session. The guard's runtime behaviour is unverified; everything asserted about it is static. This is why status stays in-progress. - Fifty-two files

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [remove-exitplanmode-boilerplate.md](plans/remove-exitplanmode-boilerplate.md)
