---
status: in-progress
type: refactor
created: 2026-07-27
modified: 2026-07-28
effort: high
workflow: true
glance: Forty-three plugin files each re-teach Claude the same four-line dance about exiting plan mode before writing files, spread across eight plugins. The guard itself matters and stays; only the explanation goes. We will know it worked when the long form appears nowhere and every write-heavy skill still carries a one-line guard.
---

# Plan: Teach the plan-mode guard once, keep it everywhere

## Objective

Reduce the repeated `ExitPlanMode` preamble across 52 plugin files to a single
canonical line in the skills that actually mutate the filesystem, preserving
the guard while removing roughly 2,750 words of duplicated explanation.

## Context

Measured across `kit/plugins/`: 52 files mention `ExitPlanMode`, and the lines
containing it total about 2,750 words. The same four-line block — exit plan
mode, here is why mutations cannot proceed inside it, `ExitPlanMode` is
deferred, call `ToolSearch` with `select:ExitPlanMode` first — is repeated
verbatim 19 times in one phrasing and 7 more in a near-identical variant.

Distribution: `social-media-tools` 16 files, `plan-agent` 12, `git-agent` 11,
`artifact-tools` 4, `product-plans` 3, `skill-reviewer` 2, and one each in
`team-defaults`, `content-tools`, `code-testing-agent`, and `code-review`.

Two of the Claude 5 context-engineering rules apply at once. Rule 4 says state
a thing once rather than repeating it across layers. Rule 1 says prefer
judgment over rules — a current model asked to commit while in plan mode does
not need forty words explaining that writes are mutations.

**This plan reduces the guard, it does not remove it.** A skill that starts
writing files inside plan mode violates a standing user preference, and that
failure is silent — the write either fails confusingly or escapes a mode the
user deliberately entered. The distinction Step 2 draws is between the *guard*
(one line, keep in every write-heavy skill) and the *tutorial* (the deferred
tool mechanics and rationale, delete everywhere). Read-only skills that carry
the block at all should lose it entirely, since they never mutate.

Eight plugins change, so eight `marketplace.json` version bumps land in this
work. That wide blast radius is the reason this is its own plan rather than
part of a larger sweep: it must be revertible as one unit. The per-file change
is mechanical and repetitive across eight directories, so `workflow: true` is set
to allow parallel per-plugin execution with a final verification pass.

**Corrections made during execution.** Three of the numbers above were
measured against the wrong scope. They were corrected rather than worked
around, and each correction is recorded here so the diff can be read against
the spec.

**Fifty-two files, but forty-three carry boilerplate.** The 52 came from
`grep -rl ExitPlanMode kit/plugins`, which also matches nine files where the
mention is legitimate: five `CHANGELOG.md` histories, `plan-agent/README.md`,
`plan-agent/hooks.json` (a `PostToolUse` matcher), `code-review/commands/fix-branch.md`
(a lint rule asserting that any body mentioning `ExitPlanMode` also declares
`ToolSearch`), and `team-defaults/skills/sync-rules/rules/plan-mode.md` (the
shipped copy of the user's global plan-mode rule). None is duplication. The
real target was the 43 files matching `select:ExitPlanMode` in a body.

**Eight plugins, not ten.** The two dropped are `code-review` and
`team-defaults`, whose only mentions are the two legitimate files above.
Bumping them to reach ten would have been a fabricated change.

**The under-600 word budget needed a scope, not a smaller number.** Measured
with the plan's own command, `grep -rh 'ExitPlanMode' kit/plugins | wc -w`,
600 is unreachable: 449 words are `allowed-tools:` frontmatter (the permission
declaration — deleting it breaks the tool rather than saving context), 512 are
CHANGELOG history, and 161 are the legitimate content above. The floor is 1,122
before a single guard line exists. The budget now measures what it meant to
measure — the bodies of `skills/*/SKILL.md`, `commands/*.md`, and `agents/*.md`,
frontmatter excluded — where the sweep took 1,678 words down to 583.

## Files

Counts below are the files actually rewritten — the boilerplate-bearing subset,
not every file that mentions `ExitPlanMode`. See the Context section.

- kit/plugins/social-media-tools/**/*.md (modified) — 15 files, the largest group
- kit/plugins/plan-agent/**/*.md (modified) — 9 files
- kit/plugins/git-agent/**/*.md (modified) — 10 files
- kit/plugins/artifact-tools/**/*.md (modified) — 4 files
- kit/plugins/product-plans/**/*.md (modified) — 2 files
- kit/plugins/skill-reviewer/**/*.md (modified) — 1 file
- kit/plugins/content-tools/**/*.md (modified) — 1 file
- kit/plugins/code-testing-agent/**/*.md (modified) — 1 file
- .claude/rules/plugin-patterns.md (modified) — the canonical wording, and the fix to the rule that mandated the long form
- .claude-plugin/marketplace.json (modified) — eight version bumps
- kit/plugins/*/CHANGELOG.md (modified) — one entry per touched plugin
- tests/plugins/test-exitplanmode-guard.sh (new) — objective test
- tests/plugins/test-build-skill.sh (modified) — check 4 asserted on the boilerplate wording
- tests/plugins/test-setup-sites.sh (modified) — check 5 asserted on the boilerplate wording
- .github/workflows/check-plugin-versions.yml (modified) — wire the new test

Not modified, though the original spec listed them: `kit/plugins/code-review/`
and `kit/plugins/team-defaults/`. Neither carries boilerplate.

## Steps

1. [x] Inventory all 52 files and classify each as write-heavy (the skill or command mutates the filesystem, git state, or a remote) or read-only, recording the classification and the current `ExitPlanMode` wording per file. Why: read-only skills should lose the block entirely while write-heavy ones must keep a guard, and only reading each file's actual behavior distinguishes them. Verify: the inventory covers all 52 files with no "unclassified" entries, and the write-heavy count matches the set of skills that call Write, Edit, or mutating Bash. — *Done:* 52 files inventoried, 9 excluded as legitimate mentions (see Context), leaving 43 boilerplate-bearing files: **40 write-heavy**, **3 read-only**. The classification is recorded as the `WRITE_HEAVY` and `READ_ONLY` arrays in `tests/plugins/test-exitplanmode-guard.sh`, where it is executable rather than prose. The 3 read-only files are the pure dispatchers `plan-agent/commands/review-plan-bg.md`, `product-plans/commands/product-plans-bg.md`, and `social-media-tools/commands/digest.md` — each only spawns an agent or skill that carries its own guard.
2. [x] Agree the canonical one-line guard wording and record it in `.claude/rules/plugin-patterns.md` as the pattern authors must follow. Why: a single documented form is what stops the next skill author from re-inventing a four-line version. Verify: `plugin-patterns.md` contains the canonical line, and it is under 20 words. — *Done:* the canonical line is ``**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.`` (12 words). Recorded under a new `#### The plan-mode guard` heading. The same edit fixes the rule that *caused* the duplication: the `#### Deferred tools` section previously instructed authors to "include a note in the step body" explaining the `ToolSearch` mechanic, which is why 43 files each carried one.
3. [x] Replace the long form with the canonical line in every write-heavy file, one plugin at a time, starting with `code-review` (1 file) to validate the pattern before touching `social-media-tools` (16 files). Why: proving the change on the smallest plugin first means a wrong canonical wording costs one file to fix, not fifty-two. Verify: after each plugin, `grep -rc 'ExitPlanMode' kit/plugins/<name>` shows the expected reduced count and no file retains the `ToolSearch with select:ExitPlanMode` tutorial text. — *Done:* 40 files carry the canonical line. The pilot ran on `code-testing-agent` (1 file) rather than `code-review`, which turned out to have no boilerplate to pilot on. Four files keep a genuinely distinct instruction alongside the guard: `build-proposal` its `WebSearch`/`WebFetch` bootstrap, and `build` / `prototype` / `setup-sites` their "produce no plan document" clause.
4. [x] Delete the block outright from every file classified read-only in Step 1. Why: a guard against a mutation the skill never performs is pure context cost with no protective value. Verify: `grep -rl 'ExitPlanMode'` returns no file on the read-only list. — *Done:* all 3 dispatchers are clean, and `ToolSearch`/`ExitPlanMode` were dropped from their `allowed-tools` since they no longer call either. Asserted by Check 4 of the objective test.
5. [x] Bump the version of all ten touched plugins in `.claude-plugin/marketplace.json` and add a `CHANGELOG.md` entry to each. Why: repo convention requires a bump higher than main for any edit under `kit/plugins/<name>/`, and ten plugins changed. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and reports ten bumped plugins. — *Done:* **eight** plugins bumped (patch — refactor, no behavior change), each with a CHANGELOG entry in that file's own established style: `artifact-tools` 1.7.3, `code-testing-agent` 3.4.5, `content-tools` 1.0.2, `git-agent` 4.7.1, `plan-agent` 5.0.2, `product-plans` 3.4.13, `skill-reviewer` 2.2.9, `social-media-tools` 2.19.2.
6. [x] Write `tests/plugins/test-exitplanmode-guard.sh` asserting the long-form tutorial text appears in zero files, that total `ExitPlanMode` word count across `kit/plugins/` is under 600, and that every skill on the Step 1 write-heavy list still contains the canonical guard line. Why: the third assertion is the one that matters — it fails if a future edit strips the guard along with the boilerplate. Verify: `bash tests/plugins/test-exitplanmode-guard.sh` exits 0; deleting the guard line from one write-heavy skill makes it exit 1. — *Done:* four checks, all passing. A fourth check was added beyond the spec: the read-only dispatchers must *not* carry a guard, which is the only thing stopping Step 4's deletions from being quietly undone. Mutation-tested both ways (see Verification).
7. [x] Add the new test to `.github/workflows/check-plugin-versions.yml`. Why: local-only tests stop running. Verify: the workflow names `test-exitplanmode-guard.sh` and parses as valid YAML. — *Done:* added as the final step; the file parses and the step is present.
8. [x] *(added during execution)* Retarget two existing tests that asserted on the boilerplate itself. Why: `test-build-skill.sh` check 4 and `test-setup-sites.sh` check 5 both grepped for `select:ExitPlanMode` as their proof that a guard existed, so removing the tutorial failed them — they encoded the wording rather than the guarantee. Verify: both now grep for the canonical line, and the full suite is green.

## Tests

Tier 1 — This plan changes application code
- Objective: the plan-mode guard survives in every write-heavy skill while the duplicated tutorial is gone. File: tests/plugins/test-exitplanmode-guard.sh; Type: smoke; Asserts: zero files contain the long-form `ToolSearch with select:ExitPlanMode` tutorial, total ExitPlanMode word count under 600, and every write-heavy skill on the manifest still carries the canonical guard line; Run: bash tests/plugins/test-exitplanmode-guard.sh
- Integration: a write-heavy skill still refuses to mutate inside plan mode. File: manual per Verification; Targets: git-agent:commit-agent, plan-agent:implementation-plan; Key cases: invoke each from inside plan mode and confirm it exits plan mode before its first write rather than erroring or writing regardless

## Acceptance Criteria

- [x] Zero files under `kit/plugins/` contain the long-form `ExitPlanMode` tutorial text — Check 1 of the objective test; CHANGELOG history is out of scope
- [x] Total `ExitPlanMode` word count across `kit/plugins/` is under 600, down from 2,750 — **583**, measured over instruction-file bodies (see Context for why the plan's raw command has a 1,122-word floor); down from 1,678 in the same scope, and 2,750 → 1,641 by the raw command
- [x] Every skill classified write-heavy in Step 1 contains the canonical guard line — all 40, Check 3
- [x] Zero files classified read-only in Step 1 mention `ExitPlanMode` — all 3, Check 4
- [x] The canonical wording is documented in `.claude/rules/plugin-patterns.md` — under `#### The plan-mode guard`, together with the fix to the rule that generated the duplication
- [x] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with ten plugins bumped — exits 0 with **eight**; see Context
- [x] Each of the ten touched plugins has a new `CHANGELOG.md` entry — each of the **eight**
- [x] `bash tests/plugins/test-exitplanmode-guard.sh` exits 0 — 4 of 4 checks pass

## Verification

Run `grep -rh 'ExitPlanMode' kit/plugins | wc -w` and confirm the result is
under 600, down from 2,750. Run
`BASE_REF=main node scripts/check-plugin-versions.mjs` and confirm exit 0.

Then prove the guard still works, which is the whole point of keeping it.
Enter plan mode, invoke `git-agent:commit-agent` on a dirty working tree, and
confirm it exits plan mode and commits rather than either erroring or writing
from inside plan mode. Repeat with `plan-agent:implementation-plan`, confirming
it writes its spec to the plans directory. Both are skills whose guard this
plan deliberately preserved.

Finally, prove the test is not a tautology: delete the canonical guard line
from one write-heavy skill, run `bash tests/plugins/test-exitplanmode-guard.sh`,
confirm exit 1, and revert.

### Verification status — 2026-07-28

**Passed — word count and version guard.** 583 words against a 600 budget
(scope corrected per the Context section; the raw command reads 2,750 → 1,641).
`BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with eight
plugins bumped.

**Passed — the test is not a tautology.** Mutated in both directions, each
reverted afterwards and the baseline re-confirmed green:

- Stripped the guard from `git-agent/skills/commit-agent/SKILL.md` → Check 3
  fails, exit 1, naming the file.
- Re-added a tutorial sentence to `social-media-tools/skills/share-code/SKILL.md`
  → Check 1 fails, exit 1, quoting the line.

That second mutation is why the test does not rest on the word budget alone: it
moved the count only 583 → 593, well inside the 600 ceiling. A sum-based budget
is a slow-creep backstop that trips after roughly ten files regress, not a
detector. Checks 1 and 3 fail on the first file.

**Not run — the manual plan-mode behavioural test.** `EnterPlanMode` states it
"REQUIRES user approval" and `ExitPlanMode` "requests user approval", so both
gate on an interactive prompt. The session that executed this plan was
non-interactive and could not enter plan mode, so the guard's runtime behaviour
is unverified. Everything asserted about it here is static: the line is present,
first in each workflow, and worded identically across all 40 files.

This is the only outstanding item, and it is why `status` remains
`in-progress`. To close it, from an interactive session on a dirty working tree:

1. Enter plan mode, invoke `git-agent:commit-agent`, and confirm it exits plan
   mode and commits rather than erroring or committing from inside plan mode.
2. Enter plan mode, invoke `plan-agent:implementation-plan`, and confirm it
   writes its spec to the plans directory.

Then set `status: completed` and re-render.

## Completion Report

- Manual plan-mode behavioural test not run — EnterPlanMode requires user approval and ExitPlanMode requests it, so neither works in a non-interactive session. The guard's runtime behaviour is unverified; everything asserted about it is static. This is why status stays in-progress.
- Fifty-two files became forty-three — nine of the 52 mention ExitPlanMode legitimately (five CHANGELOG histories, a README, a hooks.json matcher, a code-review lint rule, and the team-defaults copy of the global plan-mode rule). None was duplication.
- Ten plugins became eight — code-review and team-defaults carry no boilerplate. Bumping them to reach ten would have been a fabricated change.
- The under-600 word budget was rescoped, not relaxed — the plan's own command has a 1,122-word floor of frontmatter, changelog history, and legitimate content. Measured over instruction-file bodies, the sweep took 1,678 words to 583.
- Two existing tests had to be retargeted — test-build-skill.sh and test-setup-sites.sh both proved a guard existed by grepping for the tutorial wording, so removing it failed them. Both now assert the canonical line.
- A fourth check was added beyond the spec — read-only dispatchers must not carry a guard, which is the only thing stopping Step 4's deletions from being quietly undone.

## Next Steps

- Audit the remaining cross-plugin duplicated lines
  The same measurement that found this block also found a README boilerplate line repeated in ten plugins and a template-locating shell block repeated eleven times inside social-media-tools.
  ```text
  In the agentics repo, find instruction lines of eight or more words that
  appear in three or more different plugins under kit/plugins/, excluding the
  ExitPlanMode guard. For each cluster, decide whether it should become a
  shared reference file or be deleted as model-obvious, and report the list
  with a recommendation per cluster. Do not change any files — this is a
  report. Verify by including the measured word count saved per cluster.
  ```

## Resources

- The new rules of context engineering for Claude 5 generation models — https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models — Rules 1 and 4, both of which this sweep applies
- ~/.claude/rules/plan-mode.md — the standing user rule this guard protects; the reason the guard is reduced rather than removed
