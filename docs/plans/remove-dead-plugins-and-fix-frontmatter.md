---
status: completed
type: chore
created: 2026-07-16
modified: 2026-07-16
repo-name: agentics
effort: low
glance: Six plugins were dropped from the marketplace in v4.0.0 but their directories stayed on disk, and because the local loader reads directories instead of the manifest, they still load and now collide by name with the real plugins. This deletes them, corrects the docs that promise they are retained, and runs skill-reviewer over the survivors instead of hand-editing frontmatter.
---

# Plan: Delete the six de-registered plugin directories and fix survivor frontmatter

## Objective

Remove the six plugin directories that v4.0.0 de-registered from the marketplace but left on disk, correct the three documentation sites that assert those directories are retained, and bring the surviving 13 plugins' SKILL.md frontmatter back inside the 200-char description budget by running the repo's own `skill-reviewer` tooling over itself.

## Context

`.claude-plugin/marketplace.json` lists 13 plugins. `kit/plugins/` contains 19 directories. The six extras — `agent-creator`, `agent-reviewer`, `agentic-plugin-dev`, `code-simplifier`, `marketplace-builder`, `react-perf-analyzer` — were removed from the marketplace on 2026-05-29 (see the removed-plugins table in `.claude/rules/marketplace.md`) and their source was retained "for reference".

Retention has a cost that was not visible when the decision was made. De-registering a plugin stops *distribution*; it does not stop *loading*. `CLAUDE.local.md` documents the local-testing command as `claude $(ls ~/devbox/agentics/kit/plugins/ | xargs -I{} echo --plugin-dir ~/devbox/agentics/kit/plugins/{})`, which reads directories, not the manifest, so all 19 load. The result was observed live in a session on 2026-07-16: the agent list contained both `0.1.0:agent-creator` and `plugin-dev:agent-creator`, both `0.1.0:skill-reviewer` and the real `skill-reviewer`, plus `code-simplifier:code-simplifier`. The dead plugins are loading under duplicate names and competing with the live ones for skill-description budget in every session.

Git history is the reference these directories were kept to be. The six total 5,454 lines across 40 files.

One surviving plugin does depend on a dead one, and it must be migrated before anything is deleted. `kit/plugins/code-review/commands/fix-branch.md:119` reads "If `$CHANGED_FILES` contains any `**/agents/*.md`, invoke `agent-reviewer:reviewing-agents` for each and merge findings", and `kit/plugins/code-review/README.md:89` advertises that delegation. `code-review` is a live marketplace plugin. Deleting `agent-reviewer` without migrating it means `/code-review:fix-branch` hits a missing skill on any branch that touches an agent file — and the companion plan `fix-plugin-component-defects` modifies seven agent files, so this deletion would remove the tool that reviews that plan's own work. `agent-reviewer` was removed in v4.0.0 on the grounds that it overlaps with `skill-reviewer`, which makes `skill-reviewer` the migration target the removal note itself implies.

Aside from that one live caller, the remaining references are documentation: `README.md:9` (a v4.0.0 note asserting the directories "are retained in the repository" — deletion makes this false), `README.md:134-146` (the tree diagram), `README.md:779-781` (the removed-plugins migration table, which must survive because it tells users what to install instead), and `CHANGELOG.md` (historical entries, left untouched — changelogs record what happened).

Separately, the description-budget picture is smaller than a first pass suggests, and the budget itself is easy to get wrong. `check-description.md` warns at 160 chars, but `optimizing-skill-frontmatter/SKILL.md:18` calls 160 a "legacy target" and sets the real budget at 200 total with the first sentence under 80. Measured against the real rule, 8 files fail: `team-defaults/sync-rules` (258 total, 87 first), `plan-agent/prototype` (246, 85), `social-media-tools/save-artifact` (231), `plan-agent/finalize-plan` (224), `git-agent/ship-autonomous` (214), `social-media-tools/export-session` (207), `social-media-tools/share-code` (first sentence 81), and `plan-agent/build-proposal` (195 chars in one unbroken sentence with no three-part structure). All eight belong to surviving plugins — none is in a directory this plan deletes, so the deletion does not shrink this set. (`marketplace-builder`'s `building-marketplaces` description appeared to fail under the earlier, wrong 160-char reading; at the real 200/80 rule it passes, and the plugin is deleted for unrelated reasons.)

These must not be hand-edited. `skill-reviewer:optimizing-skill-frontmatter` exists to rewrite `description:` to the three-part format and set `disable-model-invocation` correctly in the same pass, judging write-heavy workflow against read-only advisory per file. Hand-editing would reproduce that judgment worse and leave the tool unexercised against its own repo.

## Files

- `kit/plugins/code-review/commands/fix-branch.md` (modified) — line 119 delegates agent review to skill-reviewer, not the deleted agent-reviewer
- `kit/plugins/code-review/README.md` (modified) — line 89 advertises the same delegation
- `kit/plugins/agent-creator/` (deleted) — 5 files, 613 lines
- `kit/plugins/agent-reviewer/` (deleted) — 6 files, 1,208 lines
- `kit/plugins/agentic-plugin-dev/` (deleted) — 10 files, 1,026 lines
- `kit/plugins/code-simplifier/` (deleted) — 7 files, 798 lines
- `kit/plugins/marketplace-builder/` (deleted) — 7 files, 860 lines
- `kit/plugins/react-perf-analyzer/` (deleted) — 5 files, 949 lines
- `README.md` (modified) — breaking-change note, tree diagram, migration-table links
- `.claude/rules/marketplace.md` (modified) — drop the retained-for-reference promise, keep the do-not-re-add table
- `CLAUDE.local.md` (modified) — gitignored; loader reads marketplace.json instead of ls
- `kit/plugins/skill-reviewer/commands/check-description.md` (modified) — reconcile 160 against the real 200 budget
- `.claude-plugin/marketplace.json` (modified) — PATCH bumps for every plugin whose SKILL.md changes
- `tests/plugins/test-no-orphan-plugin-dirs.sh` (new) — the objective-verification test
- `tests/plugins/test-description-budget.sh` (new) — unit test for the 200/80 rule

## Steps

1. Migrate `code-review` off `agent-reviewer` before deleting anything: change `kit/plugins/code-review/commands/fix-branch.md:119` so that changed `**/agents/*.md` files are reviewed by `skill-reviewer` rather than `agent-reviewer:reviewing-agents`, and update the delegation sentence at `kit/plugins/code-review/README.md:89` to match. Why: `code-review` is a live marketplace plugin invoking a dead one, so deleting `agent-reviewer` first makes `/code-review:fix-branch` hit a missing skill on any branch touching an agent file — including the `fix-plugin-component-defects` plan, which modifies seven — and `skill-reviewer` is the stated replacement in v4.0.0's own removal note. Verify: `grep -rn 'agent-reviewer' kit/plugins/code-review/` returns nothing, and running `/code-review:fix-branch` on a branch with a modified agent file completes and reports findings rather than erroring on a missing skill.
2. Delete the six directories with `git rm -r kit/plugins/{agent-creator,agent-reviewer,agentic-plugin-dev,code-simplifier,marketplace-builder,react-perf-analyzer}`. Why: de-registered plugins still load through `--plugin-dir`, colliding by name with live plugins and consuming description budget in every session, and git history preserves them so nothing is actually lost — but only after step 1, since until then a live plugin still calls one of them. Verify: `ls kit/plugins | wc -l` returns 14 (13 plugins plus `README.md`), every remaining directory name appears in `.claude-plugin/marketplace.json`, and a repo-wide grep for the six names returns only `CHANGELOG.md` and the README migration table.
3. Correct `README.md` by rewriting line 9's breaking-change note to say the source was removed and is recoverable from git history at the commit prior to this change, deleting the six entries from the tree diagram at lines 134-146, and unlinking but keeping the plugin names in the removed-plugins table at lines 779-781. Why: line 9 becomes an outright false claim after step 1, and dead relative links degrade the migration guidance users rely on to find replacements. Verify: `grep -nE 'agent-creator|agent-reviewer|agentic-plugin-dev|code-simplifier|marketplace-builder|react-perf-analyzer' README.md` returns only migration-table rows, none of them as markdown links to `./kit/plugins/...`.
4. Update the Removed Plugins section of `.claude/rules/marketplace.md` so the notes for `agentic-plugin-dev` and `code-simplifier` no longer say the directories are retained for reference, pointing to git history instead, while keeping the six-row table and the do-not-re-add rule intact. Why: this rule is the written authority that currently contradicts step 1, and leaving it stale invites a future session to restore the directories on the grounds that the rule promised them. Verify: `grep -n 'retained' .claude/rules/marketplace.md` returns nothing, and the six-row table plus the do-not-re-add instruction both survive.
5. Replace the `ls | xargs` loader one-liner in `CLAUDE.local.md` with a form that reads the manifest, such as `claude $(python3 -c "import json;print(' '.join('--plugin-dir kit/plugins/'+p['name'] for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']))")`. Why: step 1 removes today's symptom but the loader is the underlying defect, since it will re-load anything dropped into `kit/plugins/` including a future de-registered plugin, so this closes the class rather than the instance; the file is gitignored, making this step local-only and absent from the commit. Verify: running the new command's inner substitution alone prints exactly 13 `--plugin-dir` flags whose names match `marketplace.json`.
6. Run `/skill-reviewer:optimizing-skill-frontmatter` over all eight failing files — `team-defaults/sync-rules`, `plan-agent/prototype`, `plan-agent/finalize-plan`, `plan-agent/build-proposal`, `social-media-tools/save-artifact`, `social-media-tools/export-session`, `social-media-tools/share-code`, and `git-agent/ship-autonomous` — letting the skill decide both the rewritten description and the `disable-model-invocation` value per file rather than pre-deciding either. Why: all eight belong to surviving plugins, so the deletion in step 2 does not reduce this set and treating any as already-handled would leave a real failure in place and make the acceptance criterion unreachable; the repo ships this tool precisely for this judgment, and `build-proposal` needs restructuring rather than trimming since it is one 195-char sentence with no three-part shape. Verify: `/skill-reviewer:check-description` across all remaining SKILL.md files reports no file above 200 total or 80 for its first sentence.
7. Reconcile the two budget numbers by either raising `check-description.md`'s threshold to 200 or rewording its message to state that 160 is a conservative legacy target while 200 is the budget. Why: two numbers in one plugin is how a reviewer concludes 12 files fail when only 8 do, and a warning should not disagree with the rule it enforces. Verify: `grep -rn '160' kit/plugins/skill-reviewer/` returns only text that explicitly frames 160 as a legacy or conservative target alongside 200.
8. Bump `version` in `.claude-plugin/marketplace.json` for every plugin whose SKILL.md step 5 touched (`team-defaults`, `plan-agent`, `social-media-tools`, `git-agent`, `skill-reviewer`) and add a matching `kit/plugins/<name>/CHANGELOG.md` entry for each, treating a description rewrite and step 6's threshold change as PATCH bumps. Why: `scripts/check-plugin-versions.mjs` fails any PR that changes a plugin without raising its marketplace version, so skipping this blocks the merge. Verify: `node scripts/check-plugin-versions.mjs` exits 0.

## Tests

Tier 1 — This plan changes application code (it deletes plugin source directories and modifies SKILL.md frontmatter)
- Objective: every directory under `kit/plugins/` has a matching entry in the marketplace manifest and vice versa, the exact invariant this plan establishes, guarding against both a re-added dead directory and a plugin registered without source. File: `tests/plugins/test-no-orphan-plugin-dirs.sh`; Type: smoke; Asserts: the set of directory names equals the set of manifest name values, excluding `README.md`; Run: `bash tests/plugins/test-no-orphan-plugin-dirs.sh`
- Unit: the 200-total and 80-first-sentence description rule applied across every SKILL.md. File: `tests/plugins/test-description-budget.sh`; Targets: `kit/plugins/skill-reviewer/skills/*/measure-description.sh`; Key cases: a fixture with a 258-char description fails, a fixture at exactly 200 passes, a fixture whose first sentence is 81 chars fails
- Integration: the surviving 13 plugins still work after the deletion. File: the existing 19 suites in `tests/plugins/`; Targets: cross-plugin references; Key cases: the full suite passes unchanged after step 1, proving nothing depended on the deleted six

## Acceptance Criteria

- [x] `/code-review:fix-branch` reviews changed agent files without invoking the deleted `agent-reviewer`
- [x] `kit/plugins/` contains exactly 13 plugin directories plus `README.md`
- [x] No file outside `CHANGELOG.md` and the README migration table references any of the six deleted plugins
- [x] All eight over-budget descriptions are fixed — none was in a deleted directory, so none is skipped
- [x] `README.md` no longer claims the removed directories are retained
- [x] `.claude/rules/marketplace.md` keeps its do-not-re-add table but no longer promises retained directories
- [x] Every remaining SKILL.md passes the 200-total and 80-first-sentence description rule
- [x] `skill-reviewer` states one budget number, not two
- [x] `node scripts/check-plugin-versions.mjs` exits 0
- [x] `tests/plugins/test-no-orphan-plugin-dirs.sh` exists and passes

## Verification

Run `bash tests/plugins/test-no-orphan-plugin-dirs.sh` and confirm it passes. Run every suite in `tests/plugins/` and confirm all pass, proving no surviving plugin depended on the deleted six. Run `/skill-reviewer:check-description` across `kit/plugins/**/SKILL.md` and confirm no warnings. Then start a session using the corrected loader from step 4 and confirm the agent and skill lists contain no `agent-creator`, no `code-simplifier`, and no duplicate `skill-reviewer` entries — this was the original observed symptom and is the real end-to-end proof that the objective is met. Finally confirm `node scripts/check-plugin-versions.mjs` exits 0.

## Next Steps

- Decide the two deferred consolidations: the plan-agent/plan-interview merge and the social-media-tools split
  Both were deferred pending this cleanup, because the dead-plugin name collisions muddied the picture. Both are MAJOR bumps affecting installed users.
  ```text
  In the agentics repo, evaluate two MAJOR-bump consolidations that were deferred
  pending the dead-plugin cleanup. (1) plan-agent (9 skills) and plan-interview
  (6 skills, 10 commands) total 11,476 lines and overlap on plan-to-HTML conversion,
  plan review, plan status, and gallery building — plan-interview:plan-to-html is
  already a deprecated alias delegating to markdown-to-html. (2) social-media-tools
  ships 17 skills and 6,381 lines, a quarter of the repo's skill-description budget,
  and its own social-share router exists to dispatch among the other 16 — the
  share-* family (blog, video, github, react, selection, session, code, explanation)
  may collapse into one skill with a source argument. Both remove and rename skills
  users have installed. For each: assess whether the consolidation is worth the
  breaking change, and if so write an implementation plan including a migration
  note for installed users. Recommend one, both, or neither with reasoning.
  ```

- Consider enforcing the loader invariant with a hook
  The test suite added by this plan already asserts it; a hook may or may not add enough to justify the maintenance.
  ```text
  In the agentics repo, draft a minimum-viable PostToolUse or PreCommit hook that
  fails when a directory exists under kit/plugins/ with no matching `name` entry in
  .claude-plugin/marketplace.json, or vice versa. The repo already has
  tests/plugins/test-no-orphan-plugin-dirs.sh asserting this invariant — decide
  whether a hook adds enough over the test suite to be worth the maintenance, given
  that tests/plugins/ is being wired into PR CI by the wire-plugin-tests-into-ci
  plan. Recommend hook, test-only, or both, with reasoning.
  ```
