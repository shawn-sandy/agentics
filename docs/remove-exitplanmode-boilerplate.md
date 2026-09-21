# Teach the plan-mode guard once, keep it everywhere

> Forty-three plugin files each re-teach Claude the same four-line dance about exiting plan mode before writing files, spread across eight plugins. The guard i...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [remove-exitplanmode-boilerplate.md](plans/remove-exitplanmode-boilerplate.md)
**Type:** refactor

## What shipped

- Inventory all 52 files and classify each as write-heavy (the skill or command mutates the filesystem, git state, or a remote) or read-only, recording the classification and the current `ExitPlanMode` wording per file.
- Agree the canonical one-line guard wording and record it in `.claude/rules/plugin-patterns.md` as the pattern authors must follow.
- Replace the long form with the canonical line in every write-heavy file, one plugin at a time, starting with `code-review` (1 file) to validate the pattern before touching `social-media-tools` (16 files).
- Delete the block outright from every file classified read-only in Step 1.
- Bump the version of all ten touched plugins in `.claude-plugin/marketplace.json` and add a `CHANGELOG.md` entry to each.
- Write `tests/plugins/test-exitplanmode-guard.sh` asserting the long-form tutorial text appears in zero files, that total `ExitPlanMode` word count across `kit/plugins/` is under 600, and that every skill on the Step 1 write-heavy list still contains the canonical guard line.
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
| `.claude/rules/plugin-patterns.md` | the canonical wording, and the fix to the rule that mandated the long form | Modified |
| `.claude-plugin/marketplace.json` | eight version bumps | Modified |
| `kit/plugins/*/CHANGELOG.md` | one entry per touched plugin | Modified |
| `tests/plugins/test-exitplanmode-guard.sh` | objective test | Created |
| `tests/plugins/test-build-skill.sh` | check 4 asserted on the boilerplate wording | Modified |
| `tests/plugins/test-setup-sites.sh` | check 5 asserted on the boilerplate wording | Modified |
| `.github/workflows/check-plugin-versions.yml` | wire the new test | Modified |

## How it works

Reduce the repeated `ExitPlanMode` preamble across 52 plugin files to a single canonical line in the skills that actually mutate the filesystem, preserving the guard while removing roughly 2,750 words of duplicated explanation.

Measured across `kit/plugins/`: 52 files mention `ExitPlanMode`, and the lines containing it total about 2,750 words. The same four-line block — exit plan mode, here is why mutations cannot proceed inside it, `ExitPlanMode` is deferred, call `ToolSearch` with `select:ExitPlanMode` first — is repeated verbatim 19 times in one phrasing and 7 more in a near-identical variant. Distribution: `social-media-tools` 16 files, `plan-agent` 12, `git-agent` 11, `artifact-tools` 4, `product-plans` 3, `skill-reviewer` 2, and one each in `team-defaults`, `content-tools`, `code-testing-agent`, and `code-review`. Two of the Claude 5 context-engineering rules apply at once. Rule 4 says state a thing once rather than repeating it across layers. Rule 1 says prefer judgment over rules — a current model asked to commit while in plan mode does not need forty words explaining that writes are mutations. **This plan reduces the guard, it does not remove it.** A skill that starts writing files inside plan mode violates a standing user preference, and that failure is silent — the write either fails confusingly or escapes a mode the user deliberately entered. The distinction Step 2 draws is between the *guard* (one line, keep in every write-heavy skill) and the *tutorial* (the deferred tool mechanics and rationale, delete everywhere). Read-only skills that carry the block at all should lose it entirely, since they never mutate. Eight plugins change, so eight `marketplace.json` version bumps land in this work. That wide blast radius is the reason this is its own plan rather than part of a larger sweep: it must be revertible as one unit. The per-file change is mechanical and repetitive across eight directories, so `workflow: true` is set to allow parallel per-plugin execution with a final verification pass. **Corrections made during execution.** Three of the numbers above were measured against the wrong scope. They were corrected rather than worked around, and each correction is recorded here so the diff can be read against the spec. **Fifty-two files, but forty-three carry boilerplate.** The 52 came from `grep -rl ExitPlanMode kit/plugins`, which also matches nine files where the mention is legitimate: five `CHANGELOG.md` histories, `plan-agent/README.md`, `plan-agent/hooks.json` (a `PostToolUse` matcher), `code-review/commands/fix-branch.md` (a lint rule asserting that any body mentioning `ExitPlanMode` also declares `ToolSearch`), and `team-defaults/skills/sync-rules/rules/plan-mode.md` (the shipped copy of the user's global plan-mode rule). None is duplication. The real target was the 43 files matching `select:ExitPlanMode` in a body. **Eight plugins, not ten.** The two dropped are `code-review` and `team-defaults`, whose only mentions are the two legitimate files above. Bumping them to reach ten would have been a fabricated change. **The under-600 word budget needed a scope, not a smaller number.** Measured with the plan's own command, `grep -rh 'ExitPlanMode' kit/plugins | wc -w`, 600 is unreachable: 449 words are `allowed-tools:` frontmatter (the permission declaration — deleting it breaks the tool rather than saving context), 512 are CHANGELOG history, and 161 are the legitimate content above. The floor is 1,122 before a single guard line exists. The budget now measures what it meant to measure — the bodies of `skills/*/SKILL.md`, `commands/*.md`, and `agents/*.md`, frontmatter excluded — where the sweep took 1,678 words down to 553, of which only 73 is prose other than the canonical guard itself.

The implementation proceeded through the following steps: Inventory all 52 files and classify each as write-heavy (the skill or command mutates the filesystem, git state, or a remote) or read-only, recording the classification and the current `ExitPlanMode` wording per file.; Agree the canonical one-line guard wording and record it in `.claude/rules/plugin-patterns.md` as the pattern authors must follow.; Replace the long form with the canonical line in every write-heavy file, one plugin at a time, starting with `code-review` (1 file) to validate the pattern before touching `social-media-tools` (16 files).; Delete the block outright from every file classified read-only in Step 1.; Bump the version of all ten touched plugins in `.claude-plugin/marketplace.json` and add a `CHANGELOG.md` entry to each.; Write `tests/plugins/test-exitplanmode-guard.sh` asserting the long-form tutorial text appears in zero files, that total `ExitPlanMode` word count across `kit/plugins/` is under 600, and that every skill on the Step 1 write-heavy list still contains the canonical guard line.; Add the new test to `.github/workflows/check-plugin-versions.yml`.; *(added during execution)* Retarget two existing tests that asserted on the boilerplate itself..

- Manual plan-mode behavioural test not run — EnterPlanMode requires user approval and ExitPlanMode requests it, so neither works in a non-interactive session. The guard's runtime behaviour is unverified; everything asserted about it is static. This is why status stays in-progress. - Fifty-two files became forty-three — nine of the 52 mention ExitPlanMode legitimately (five CHANGELOG histories, a README, a hooks.json matcher, a code-review lint rule, and the team-defaults copy of the global plan-mode rule). None was duplication. - Ten plugins became eight — code-review and team-defaults carry no boilerplate. Bumping them to reach ten would have been a fabricated change. - The under-600 word budget was rescoped, not relaxed — the plan's own command has a 1,122-word floor of frontmatter, changelog history, and legitimate content. Measured over instruction-file bodies, the sweep took 1,678 words to 553, only 73 of it non-guard prose. - Two existing tests had to be retargeted — test-build-skill.sh and test-setup-sites.sh both proved a guard existed by grepping for the tutorial wording, so removing it failed them. Both now assert the canonical line. - Two guards were mis-positioned and are now fixed — social-share wrote a temp file in Phase 2 but called the guard in Phase 4, and plan-review-agents ran background-flag detection before its guard. Both predate this plan; a guard after the mutation protects nothing. - Repo-wide guard coverage is out of scope and tracked as a follow-up — about 20 instruction files declare Write/Edit and have never carried a guard. Adding them is new behaviour across more plugins, not preservation of what existed. - A fourth check was added beyond the spec — read-only dispatchers must not carry a guard, which is the only thing stopping Step 4's deletions from being quietly undone.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [remove-exitplanmode-boilerplate.md](plans/remove-exitplanmode-boilerplate.md)
