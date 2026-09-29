# Delete the six de-registered plugin directories and fix survivor frontmatter

> Removed six plugin directories that v4.0.0 de-registered but left on disk, preventing them from loading and colliding with live plugins via the directory-based loader, migrated the one live caller, corrected documentation, and fixed all over-budget skill descriptions.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
**Type:** chore

## What shipped

- Migrated `kit/plugins/code-review/commands/fix-branch.md` and its README off `agent-reviewer:reviewing-agents` to `skill-reviewer` before any deletion, eliminating the live-caller dependency.
- Deleted six plugin directories with `git rm -r`: `agent-creator`, `agent-reviewer`, `agentic-plugin-dev`, `code-simplifier`, `marketplace-builder`, `react-perf-analyzer` — 5,454 lines across 40 files, all recoverable from git history.
- Corrected `README.md`: rewrote the breaking-change note at line 9 to say source was removed (recoverable from git), removed the six entries from the tree diagram, and unlinked (but kept) the plugin names in the migration table.
- Updated `.claude/rules/marketplace.md`: dropped the retained-for-reference promise for `agentic-plugin-dev` and `code-simplifier`, kept the six-row do-not-re-add table intact.
- Updated `CLAUDE.local.md` (gitignored) to load plugins from the manifest instead of `ls kit/plugins/`, closing the class of defect rather than just the instance.
- Ran `skill-reviewer:optimizing-skill-frontmatter` over all eight over-budget SKILL.md files; reconciled the 160-char warning threshold in `check-description.md` against the real 200/80 budget.
- Added `tests/plugins/test-no-orphan-plugin-dirs.sh` asserting that the set of directory names under `kit/plugins/` equals the set of manifest `name` values.
- Added `tests/plugins/test-description-budget.sh` asserting the 200-total and 80-first-sentence rule across every SKILL.md.
- Bumped team-defaults, plan-agent, social-media-tools, git-agent, and skill-reviewer with CHANGELOG entries.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/code-review/commands/fix-branch.md` | Migrated agent review delegation from agent-reviewer to skill-reviewer | Modified |
| `kit/plugins/code-review/README.md` | Updated delegation description | Modified |
| `tests/plugins/test-no-orphan-plugin-dirs.sh` | Invariant: every kit/plugins/ directory has a manifest entry | Created |
| `tests/plugins/test-description-budget.sh` | Unit test for the 200-total / 80-first-sentence description rule | Created |
| `.claude-plugin/marketplace.json` | PATCH bumps for five touched plugins | Modified |
| `README.md` | Breaking-change note, tree diagram, migration table | Modified |

## How it works

**De-registering a plugin does not stop it loading.** The local testing command in `CLAUDE.local.md` used `ls kit/plugins/ | xargs -I{} echo --plugin-dir ...`, which reads directories, not the manifest. With 19 directories and 13 registered plugins, all 19 loaded — producing observed name collisions like `0.1.0:agent-creator` alongside the live `agent-creator`, and a duplicate `skill-reviewer`. The fix changes the loader to iterate the manifest: `python3 -c "import json; print(' '.join('--plugin-dir kit/plugins/'+p['name'] for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']))"`, so only registered plugins load regardless of what is in the directory.

**One live caller had to migrate first.** `kit/plugins/code-review/commands/fix-branch.md:119` delegated agent-file review to `agent-reviewer:reviewing-agents` — a dead plugin. The removal note for `agent-reviewer` (v4.0.0) named `skill-reviewer` as the replacement. `fix-branch.md` was updated to call `skill-reviewer` instead before any deletion, so the command never has a missing skill on any branch that touches an agent file.

**Git history is the real retention mechanism.** The six directories totalled 5,454 lines across 40 files. None is lost: `git log` and `git show <sha>:<path>` reach every file at the commit preceding this change. `README.md` and `.claude/rules/marketplace.md` previously asserted the directories were retained on disk "for reference"; those claims became false after deletion and were corrected to point to git history instead, while the do-not-re-add table was left fully intact.

**The description budget had two numbers.** `skill-reviewer/commands/check-description.md` warned at 160 characters, but `optimizing-skill-frontmatter/SKILL.md` documented the real budget as 200 total with the first sentence under 80. This discrepancy caused reviewers to count 12 failures when only 8 existed. The reconciliation raised the warning threshold to 200 and reworded the message to state 160 as a conservative legacy target. All eight genuinely over-budget files were fixed by running the repo's own `skill-reviewer:optimizing-skill-frontmatter` skill rather than hand-editing, preserving its judgment about the `disable-model-invocation` value alongside the description rewrite.

**Two new tests guard the invariant going forward.** `test-no-orphan-plugin-dirs.sh` asserts that the set of directory names under `kit/plugins/` (excluding `README.md`) equals the set of `name` values in the manifest — failing on both a re-added dead directory and a plugin registered without source. `test-description-budget.sh` applies the 200-total / 80-first-sentence rule across every SKILL.md, with fixture cases for pass and fail at each boundary.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
