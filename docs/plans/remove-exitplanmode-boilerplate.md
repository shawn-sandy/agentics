---
status: todo
type: refactor
created: 2026-07-27
effort: high
workflow: true
glance: Fifty-two plugin files each re-teach Claude the same four-line dance about exiting plan mode before writing files, costing about 2,750 words spread across ten plugins. The guard itself matters and stays; only the explanation goes. We will know it worked when the long form appears nowhere and every write-heavy skill still carries a one-line guard.
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

Ten plugins change, so ten `marketplace.json` version bumps land in this
work. That wide blast radius is the reason this is its own plan rather than
part of a larger sweep: it must be revertible as one unit. The per-file change
is mechanical and repetitive across ten directories, so `workflow: true` is set
to allow parallel per-plugin execution with a final verification pass.

## Files

- kit/plugins/social-media-tools/**/*.md (modified) — 16 files, the largest group
- kit/plugins/plan-agent/**/*.md (modified) — 12 files
- kit/plugins/git-agent/**/*.md (modified) — 11 files
- kit/plugins/artifact-tools/**/*.md (modified) — 4 files
- kit/plugins/product-plans/**/*.md (modified) — 3 files
- kit/plugins/skill-reviewer/**/*.md (modified) — 2 files
- kit/plugins/team-defaults/**/*.md (modified) — 1 file
- kit/plugins/content-tools/**/*.md (modified) — 1 file
- kit/plugins/code-testing-agent/**/*.md (modified) — 1 file
- kit/plugins/code-review/**/*.md (modified) — 1 file
- .claude-plugin/marketplace.json (modified) — ten version bumps
- kit/plugins/*/CHANGELOG.md (modified) — one entry per touched plugin
- tests/plugins/test-exitplanmode-guard.sh (new) — objective test
- .github/workflows/check-plugin-versions.yml (modified) — wire the new test

## Steps

1. Inventory all 52 files and classify each as write-heavy (the skill or command mutates the filesystem, git state, or a remote) or read-only, recording the classification and the current `ExitPlanMode` wording per file. Why: read-only skills should lose the block entirely while write-heavy ones must keep a guard, and only reading each file's actual behavior distinguishes them. Verify: the inventory covers all 52 files with no "unclassified" entries, and the write-heavy count matches the set of skills that call Write, Edit, or mutating Bash.
2. Agree the canonical one-line guard wording and record it in `.claude/rules/plugin-patterns.md` as the pattern authors must follow. Why: a single documented form is what stops the next skill author from re-inventing a four-line version. Verify: `plugin-patterns.md` contains the canonical line, and it is under 20 words.
3. Replace the long form with the canonical line in every write-heavy file, one plugin at a time, starting with `code-review` (1 file) to validate the pattern before touching `social-media-tools` (16 files). Why: proving the change on the smallest plugin first means a wrong canonical wording costs one file to fix, not fifty-two. Verify: after each plugin, `grep -rc 'ExitPlanMode' kit/plugins/<name>` shows the expected reduced count and no file retains the `ToolSearch with select:ExitPlanMode` tutorial text.
4. Delete the block outright from every file classified read-only in Step 1. Why: a guard against a mutation the skill never performs is pure context cost with no protective value. Verify: `grep -rl 'ExitPlanMode'` returns no file on the read-only list.
5. Bump the version of all ten touched plugins in `.claude-plugin/marketplace.json` and add a `CHANGELOG.md` entry to each. Why: repo convention requires a bump higher than main for any edit under `kit/plugins/<name>/`, and ten plugins changed. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and reports ten bumped plugins.
6. Write `tests/plugins/test-exitplanmode-guard.sh` asserting the long-form tutorial text appears in zero files, that total `ExitPlanMode` word count across `kit/plugins/` is under 600, and that every skill on the Step 1 write-heavy list still contains the canonical guard line. Why: the third assertion is the one that matters — it fails if a future edit strips the guard along with the boilerplate. Verify: `bash tests/plugins/test-exitplanmode-guard.sh` exits 0; deleting the guard line from one write-heavy skill makes it exit 1.
7. Add the new test to `.github/workflows/check-plugin-versions.yml`. Why: local-only tests stop running. Verify: the workflow names `test-exitplanmode-guard.sh` and parses as valid YAML.

## Tests

Tier 1 — This plan changes application code
- Objective: the plan-mode guard survives in every write-heavy skill while the duplicated tutorial is gone. File: tests/plugins/test-exitplanmode-guard.sh; Type: smoke; Asserts: zero files contain the long-form `ToolSearch with select:ExitPlanMode` tutorial, total ExitPlanMode word count under 600, and every write-heavy skill on the manifest still carries the canonical guard line; Run: bash tests/plugins/test-exitplanmode-guard.sh
- Integration: a write-heavy skill still refuses to mutate inside plan mode. File: manual per Verification; Targets: git-agent:commit-agent, plan-agent:implementation-plan; Key cases: invoke each from inside plan mode and confirm it exits plan mode before its first write rather than erroring or writing regardless

## Acceptance Criteria

- [ ] Zero files under `kit/plugins/` contain the long-form `ExitPlanMode` tutorial text
- [ ] Total `ExitPlanMode` word count across `kit/plugins/` is under 600, down from 2,750
- [ ] Every skill classified write-heavy in Step 1 contains the canonical guard line
- [ ] Zero files classified read-only in Step 1 mention `ExitPlanMode`
- [ ] The canonical wording is documented in `.claude/rules/plugin-patterns.md`
- [ ] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with ten plugins bumped
- [ ] Each of the ten touched plugins has a new `CHANGELOG.md` entry
- [ ] `bash tests/plugins/test-exitplanmode-guard.sh` exits 0

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
