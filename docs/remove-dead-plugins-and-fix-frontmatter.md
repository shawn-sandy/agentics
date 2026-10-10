# Delete the six de-registered plugin directories and fix survivor frontmatter

> Removed six plugin directories that v4.0.0 de-registered but left on disk (causing name collisions), corrected documentation, and brought all surviving SKILL.md descriptions within the 200-character budget.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
**Type:** chore

## What shipped

- Migrated `code-review:fix-branch` off the deleted `agent-reviewer` skill by pointing changed `**/agents/*.md` review delegation at `skill-reviewer` instead (the replacement named in v4.0.0's removal note).
- Deleted the six de-registered plugin directories — `agent-creator`, `agent-reviewer`, `agentic-plugin-dev`, `code-simplifier`, `marketplace-builder`, `react-perf-analyzer` — via `git rm -r`, leaving them recoverable from git history.
- Corrected `README.md`: rewrote the v4.0.0 breaking-change note, removed the six entries from the tree diagram, and unlinked (but kept) the plugin names in the removed-plugins migration table.
- Updated `.claude/rules/marketplace.md` to point to git history rather than the now-deleted directories, while keeping the six-row do-not-re-add table intact.
- Replaced the `ls | xargs` local loader one-liner in `CLAUDE.local.md` with a manifest-reading form that loads only registered plugins.
- Ran `skill-reviewer:optimizing-skill-frontmatter` over all eight over-budget SKILL.md files (none in the deleted directories); reconciled `check-description.md`'s 160-character threshold with the real 200-character budget.
- Bumped versions in `.claude-plugin/marketplace.json` for every plugin whose SKILL.md changed and added matching CHANGELOG entries.
- Added `tests/plugins/test-no-orphan-plugin-dirs.sh` and `tests/plugins/test-description-budget.sh` as new objective-verification tests.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/code-review/commands/fix-branch.md` | Command — delegates agent review to `skill-reviewer`, not the deleted `agent-reviewer` | Modified |
| `kit/plugins/code-review/README.md` | Plugin docs — updated delegation description | Modified |
| `kit/plugins/agent-creator/` | Deleted plugin directory (5 files, 613 lines) | Deleted |
| `kit/plugins/agent-reviewer/` | Deleted plugin directory (6 files, 1,208 lines) | Deleted |
| `kit/plugins/agentic-plugin-dev/` | Deleted plugin directory (10 files, 1,026 lines) | Deleted |
| `kit/plugins/code-simplifier/` | Deleted plugin directory (7 files, 798 lines) | Deleted |
| `kit/plugins/marketplace-builder/` | Deleted plugin directory (7 files, 860 lines) | Deleted |
| `kit/plugins/react-perf-analyzer/` | Deleted plugin directory (5 files, 949 lines) | Deleted |
| `README.md` | Repo root docs — breaking-change note, tree diagram, migration-table links | Modified |
| `.claude/rules/marketplace.md` | Rule — drop retained-for-reference promise, keep do-not-re-add table | Modified |
| `tests/plugins/test-no-orphan-plugin-dirs.sh` | New test — every directory in `kit/plugins/` has a matching manifest entry | Created |
| `tests/plugins/test-description-budget.sh` | New test — 200-total and 80-first-sentence description rule across all SKILL.md files | Created |
| `.claude-plugin/marketplace.json` | Version bumps for every plugin whose SKILL.md was modified | Modified |

## How it works

The root cause was that de-registering a plugin from `marketplace.json` stops distribution but does not stop loading. The local-testing command used `ls kit/plugins/ | xargs` — loading everything by directory scan — so all 19 directories loaded, producing collisions like `0.1.0:agent-creator` alongside `plugin-dev:agent-creator` and a duplicate `skill-reviewer`. The fix addresses both the symptom (the six directories) and the underlying defect (the loader reads directories, not the manifest).

Step 1 handled the only live dependency on a deleted plugin before any directory was removed. `kit/plugins/code-review/commands/fix-branch.md` line 119 delegated review of changed agent files to `agent-reviewer:reviewing-agents`. Because `code-review` is a live marketplace plugin and `fix-plugin-component-defects` (a concurrent plan) modifies agent files, deleting `agent-reviewer` first would have broken that plan's own review step. The delegation was repointed at `skill-reviewer`, which is the replacement the v4.0.0 removal note names.

Step 2 performed the deletion: `git rm -r kit/plugins/{agent-creator,agent-reviewer,agentic-plugin-dev,code-simplifier,marketplace-builder,react-perf-analyzer}`. After deletion `ls kit/plugins | wc -l` returns 14 (13 plugins plus `README.md`), and every remaining directory name appears in `marketplace.json`. The six total 5,454 lines across 40 files; all are recoverable from git history.

Step 3 updated `README.md`. The v4.0.0 breaking-change note at line 9 had asserted the directories "are retained in the repository" — a claim that became false after step 2. The note was rewritten to say source was removed and is recoverable from the commit prior to this change. Six entries were removed from the tree diagram, and the removed-plugins migration table kept the plugin names but removed the relative `./kit/plugins/...` links.

Step 4 updated `.claude/rules/marketplace.md`. The notes for `agentic-plugin-dev` and `code-simplifier` previously promised retained directories; those were updated to point at git history instead, while the six-row do-not-re-add table and its rule survived intact.

Step 5 replaced the `CLAUDE.local.md` loader with a manifest-reading form: `python3 -c "import json;print(' '.join('--plugin-dir kit/plugins/'+p['name'] for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']))"`. This closes the class of defect rather than just the instance — any future directory not in the manifest will not load.

Step 6 ran `skill-reviewer:optimizing-skill-frontmatter` over the eight SKILL.md files that failed the real 200-character budget (200 total characters, first sentence under 80). All eight belong to surviving plugins; none was in a deleted directory. The tool rewrote descriptions to the three-part format and set `disable-model-invocation` correctly per file.

Steps 7 and 8 reconciled the two budget numbers (the 160-character warning in `check-description.md` versus the real 200-character rule in `optimizing-skill-frontmatter/SKILL.md:18`), bumped versions for every changed plugin, and added CHANGELOG entries. The new objective tests assert the invariant this plan established: every directory under `kit/plugins/` has a matching manifest entry and vice versa, and every SKILL.md passes the 200/80 description rule.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |

<!-- generated:end -->

## References

- Plan: [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
