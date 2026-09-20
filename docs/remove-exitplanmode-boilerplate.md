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

Measured across `kit/plugins/`: 52 files mention `ExitPlanMode`, and the lines containing it total about 2,750 words. The same four-line block — exit plan mode, here is why mutations cannot proceed inside it, `ExitPlanMode` is deferred, call `ToolSearch` with `select:ExitPlanMode` first — is repeated verbatim 19 times in one phrasing and 7 more in a near-identical variant.

The implementation proceeded through the following steps: Inventory all 52 files and classify each as write-heavy (the skill or command mutates the filesystem, git state, or a remote) or read-only, recording the classification and the current `ExitPlanMode` wording per file. Why: read-only skills should lose the block entirely while write-heavy ones must keep a guard, and only reading each file's actual behavior distinguishes them. Verify: the inventory covers all 52 files with no "unclassified" entries, and the write-heavy count matches the set of skills that call Write, Edit, or mutating Bash. — *Done:* 52 files inventoried, 9 excluded as legitimate mentions (see Context), leaving 43 boilerplate-bearing files: **40 write-heavy**, **3 read-only**. The classification is recorded as the `WRITE_HEAVY` and `READ_ONLY` arrays in `tests/plugins/test-exitplanmode-guard.sh`, where it is executable rather than prose. The 3 read-only files are the pure dispatchers `plan-agent/commands/review-plan-bg.md`, `product-plans/commands/product-plans-bg.md`, and `social-media-tools/commands/digest.md` — each only spawns an agent or skill that carries its own guard.; Agree the canonical one-line guard wording and record it in `.claude/rules/plugin-patterns.md` as the pattern authors must follow. Why: a single documented form is what stops the next skill author from re-inventing a four-line version. Verify: `plugin-patterns.md` contains the canonical line, and it is under 20 words. — *Done:* the canonical line is ``**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.`` (12 words). Recorded under a new `#### The plan-mode guard` heading. The same edit fixes the rule that *caused* the duplication: the `#### Deferred tools` section previously instructed authors to "include a note in the step body" explaining the `ToolSearch` mechanic, which is why 43 files each carried one.; Replace the long form with the canonical line in every write-heavy file, one plugin at a time, starting with `code-review` (1 file) to validate the pattern before touching `social-media-tools` (16 files). Why: proving the change on the smallest plugin first means a wrong canonical wording costs one file to fix, not fifty-two. Verify: after each plugin, `grep -rc 'ExitPlanMode' kit/plugins/<name>` shows the expected reduced count and no file retains the `ToolSearch with select:ExitPlanMode` tutorial text. — *Done:* 40 files carry the canonical line. The pilot ran on `code-testing-agent` (1 file) rather than `code-review`, which turned out to have no boilerplate to pilot on. Three files keep a genuinely distinct instruction in the paragraph after the guard — `build` / `prototype` / `setup-sites` their "produce no plan document" clause. `build-proposal`'s `WebSearch`/`WebFetch` bootstrap note was dropped in review: it explained the same `ToolSearch` mechanic the new rule forbids, so keeping it contradicted the rule this plan added.; Delete the block outright from every file classified read-only in Step 1. Why: a guard against a mutation the skill never performs is pure context cost with no protective value. Verify: `grep -rl 'ExitPlanMode'` returns no file on the read-only list. — *Done:* all 3 dispatchers are clean, and `ToolSearch`/`ExitPlanMode` were dropped from their `allowed-tools` since they no longer call either. Asserted by Check 4 of the objective test.; Bump the version of all ten touched plugins in `.claude-plugin/marketplace.json` and add a `CHANGELOG.md` entry to each. Why: repo convention requires a bump higher than main for any edit under `kit/plugins/<name>/`, and ten plugins changed. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and reports ten bumped plugins. — *Done:* **eight** plugins bumped (patch — refactor, no behavior change), each with a CHANGELOG entry in that file's own established style: `artifact-tools` 1.7.3, `code-testing-agent` 3.4.5, `content-tools` 1.0.2, `git-agent` 4.7.1, `plan-agent` 5.0.2, `product-plans` 3.4.13, `skill-reviewer` 2.2.9, `social-media-tools` 2.19.2.; Write `tests/plugins/test-exitplanmode-guard.sh` asserting the long-form tutorial text appears in zero files, that total `ExitPlanMode` word count across `kit/plugins/` is under 600, and that every skill on the Step 1 write-heavy list still contains the canonical guard line. Why: the third assertion is the one that matters — it fails if a future edit strips the guard along with the boilerplate. Verify: `bash tests/plugins/test-exitplanmode-guard.sh` exits 0; deleting the guard line from one write-heavy skill makes it exit 1. — *Done:* four checks, all passing. A fourth check was added beyond the spec: the read-only dispatchers must *not* carry a guard, which is the only thing stopping Step 4's deletions from being quietly undone. Mutation-tested both ways (see Verification)..

- Manual plan-mode behavioural test not run — EnterPlanMode requires user approval and ExitPlanMode requests it, so neither works in a non-interactive session. The guard's runtime behaviour is unverified; everything asserted about it is static. This is why status stays in-progress. - Fifty-two files became forty-three — nine of the 52 mention ExitPlanMode legitimately (five CHANGELOG histories, a README, a hooks.json matcher, a code-review lint rule, and the team-defaults copy of the global plan-mode rule). None was duplication. - Ten plugins became eight — code-review and team-defaults carry no boilerplate. Bumping them to reach ten would have been a fabricated change. - The under-600 word budget was rescoped, not relaxed — the plan's own command has a 1,122-word floor of frontmatter, changelog history, and legitimate content. Measured over instruction-file bodies, the sweep took 1,678 words to 553, only 73 of it non-guard prose.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [remove-exitplanmode-boilerplate.md](plans/remove-exitplanmode-boilerplate.md)
