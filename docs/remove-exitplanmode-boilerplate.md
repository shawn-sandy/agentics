# Teach the plan-mode guard once, keep it everywhere

> Reduced a four-line ExitPlanMode tutorial block duplicated verbatim across 43 plugin files to a single canonical 12-word guard line in write-heavy skills, removing ~1,125 words of duplicated explanation from instruction-file bodies while preserving the guard in every mutating workflow.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [remove-exitplanmode-boilerplate.md](plans/remove-exitplanmode-boilerplate.md)
**Type:** refactor

> **Note:** The plan's `status` field remains `in-progress` because the manual plan-mode behavioural test (entering plan mode interactively and confirming `git-agent:commit-agent` and `plan-agent:implementation-plan` exit it before writing) could not run in a non-interactive session. All code changes are complete and the static test gate passes 4/4.

## What shipped

- Inventoried all 52 `ExitPlanMode` mentions in `kit/plugins/`, classified 43 as boilerplate (40 write-heavy, 3 read-only), and excluded 9 as legitimate (CHANGELOG histories, a README, `hooks.json`, a lint rule, and the global plan-mode rule copy).
- Documented the canonical guard line — `**If in plan mode**, call \`ExitPlanMode\` first — this workflow mutates state.` (12 words) — in `.claude/rules/plugin-patterns.md` under a new `#### The plan-mode guard` heading, and fixed the `#### Deferred tools` section that had instructed authors to explain the `ToolSearch` mechanic, which caused the duplication.
- Replaced the long-form tutorial with the canonical line in 40 write-heavy files across eight plugins: `social-media-tools` (15 files), `git-agent` (10), `plan-agent` (9), `artifact-tools` (4), `product-plans` (2), `skill-reviewer` (1), `content-tools` (1), `code-testing-agent` (1).
- Deleted `ExitPlanMode` entirely from 3 read-only dispatcher files (`plan-agent/commands/review-plan-bg.md`, `product-plans/commands/product-plans-bg.md`, `social-media-tools/commands/digest.md`) and removed `ToolSearch`/`ExitPlanMode` from their `allowed-tools`.
- Bumped eight plugins at PATCH level with CHANGELOG entries: `artifact-tools` 1.7.3, `code-testing-agent` 3.4.5, `content-tools` 1.0.2, `git-agent` 4.7.1, `plan-agent` 5.0.2, `product-plans` 3.4.13, `skill-reviewer` 2.2.9, `social-media-tools` 2.19.2.
- Added `tests/plugins/test-exitplanmode-guard.sh` with four checks: no long-form tutorial text anywhere, non-guard prose under 200 words, every write-heavy skill contains the canonical guard, and every read-only dispatcher contains no guard.
- Wired the new test into `.github/workflows/check-plugin-versions.yml`.
- Retargeted `tests/plugins/test-build-skill.sh` check 4 and `tests/plugins/test-setup-sites.sh` check 5 to assert the canonical line rather than the old tutorial wording.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `.claude/rules/plugin-patterns.md` | Canonical guard wording and fix to the rule that mandated the long form | Modified |
| `kit/plugins/social-media-tools/**/*.md` | 15 files — long form replaced with canonical line | Modified |
| `kit/plugins/plan-agent/**/*.md` | 9 files — long form replaced with canonical line | Modified |
| `kit/plugins/git-agent/**/*.md` | 10 files — long form replaced with canonical line | Modified |
| `kit/plugins/artifact-tools/**/*.md` | 4 files — long form replaced with canonical line | Modified |
| `kit/plugins/product-plans/**/*.md` | 2 files — long form replaced / read-only cleared | Modified |
| `kit/plugins/skill-reviewer/**/*.md` | 1 file — long form replaced with canonical line | Modified |
| `kit/plugins/content-tools/**/*.md` | 1 file — long form replaced with canonical line | Modified |
| `kit/plugins/code-testing-agent/**/*.md` | 1 file — long form replaced with canonical line | Modified |
| `.claude-plugin/marketplace.json` | Eight PATCH version bumps | Modified |
| `tests/plugins/test-exitplanmode-guard.sh` | Four-check objective test | Created |
| `tests/plugins/test-build-skill.sh` | Check 4 retargeted to canonical line | Modified |
| `.github/workflows/check-plugin-versions.yml` | New step running test-exitplanmode-guard.sh | Modified |

## How it works

**The duplication had an authoring-rule cause.** The `#### Deferred tools` section in `.claude/rules/plugin-patterns.md` instructed skill authors to "include a note in the step body" explaining the `ToolSearch` mechanic. That instruction is why 43 files each carried a four-line block teaching the same ToolSearch deferral. Fixing the rule — removing the instruction to explain ToolSearch in every skill body — closes the source rather than just cleaning up the current instance. The same commit added the `#### The plan-mode guard` heading with the canonical wording and the principle: write-heavy skills carry one line, read-only skills carry nothing.

**The 52-file count was overcounted.** `grep -rl ExitPlanMode kit/plugins` matched 52 files, but 9 of them carry legitimate mentions: five CHANGELOG histories, `plan-agent/README.md`, `plan-agent/hooks.json` (a `PostToolUse` matcher on the tool name), `code-review/commands/fix-branch.md` (a lint rule asserting that any body mentioning `ExitPlanMode` also declares `ToolSearch`), and `team-defaults/skills/sync-rules/rules/plan-mode.md` (the shipped copy of the user's global plan-mode rule). None is duplication. The real target was the 43 files matching `select:ExitPlanMode` inside the body.

**The word-budget metric needed a scope.** The plan's stated goal of "under 600 words" was measured by `grep -rh 'ExitPlanMode' kit/plugins | wc -w`, which has a floor of 1,122 regardless of what is removed: 449 words in `allowed-tools:` frontmatter (the permission declaration — deleting it breaks the tool), 512 words in CHANGELOG history, and 161 words in the nine legitimate mentions. The budget was rescoped to instruction-file bodies only (skills, commands, agents, frontmatter excluded), where the sweep took 1,678 words to 553 — only 73 words of prose other than the canonical guard line itself.

**The objective test has four checks and a read-only negative assertion.** Check 1 asserts no file in the write-heavy or read-only sets contains the long-form `ToolSearch with select:ExitPlanMode` tutorial. Check 2 asserts non-guard prose under 200 words in the scoped measurement. Check 3 asserts every file in the WRITE_HEAVY array still contains the canonical guard line exactly. Check 4 asserts every file in the READ_ONLY array contains no `ExitPlanMode` mention — this is the only thing stopping Step 4's deletions from being quietly undone in a future edit. The test was mutation-tested in both directions: stripping the guard from one write-heavy skill makes Check 3 fail naming the file; re-adding a tutorial sentence to one file makes Check 1 fail quoting the line.

**Two existing tests had to be retargeted.** `test-build-skill.sh` check 4 and `test-setup-sites.sh` check 5 both proved a plan-mode guard existed by grepping for `select:ExitPlanMode`. They encoded the wording rather than the guarantee, so removing the tutorial failed them. Both now grep for the canonical 12-word line — they still assert the guard is present, now independent of the tutorial.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |
| `be304fd` | 2026-08-26 | feat(plan-agent): publish-hub — bundle a plan and its related HTML into one hub artifact (9.8.0) (#603) |
| `fd41fec` | 2026-08-22 | feat: prove merge readiness locally with a verify gate and verified-change skill (#594) |

<!-- generated:end -->

## References

- Plan: [remove-exitplanmode-boilerplate.md](plans/remove-exitplanmode-boilerplate.md)
