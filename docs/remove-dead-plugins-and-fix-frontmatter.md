# Delete the six de-registered plugin directories and fix survivor frontmatter

> Remove the six plugin directories that v4.0.0 de-registered from the marketplace but left on disk, correct the documentation that promises their retention, and fix over-budget SKILL.md descriptions.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [remove-dead-plugins-and-fix-frontmatter](plans/remove-dead-plugins-and-fix-frontmatter.md)
**Type:** chore

## What shipped

- Migrated `code-review:fix-branch` off the deleted `agent-reviewer` plugin, routing changed agent files to `skill-reviewer` instead.
- Deleted all six de-registered plugin directories (`agent-creator`, `agent-reviewer`, `agentic-plugin-dev`, `code-simplifier`, `marketplace-builder`, `react-perf-analyzer`) — 5,454 lines across 40 files.
- Corrected `README.md` to remove the false claim that deleted directories are retained, updated the tree diagram, and de-linked removed plugins from the migration table.
- Updated `.claude/rules/marketplace.md` to point at git history instead of retained directories, while preserving the do-not-re-add table and rule.
- Fixed `CLAUDE.local.md`'s local loader to read `marketplace.json` instead of `ls kit/plugins/`, closing the entire class of dead-plugin re-load.
- Fixed eight over-budget SKILL.md descriptions across four surviving plugins by running `skill-reviewer:optimizing-skill-frontmatter` over each.
- Reconciled `skill-reviewer`'s two conflicting description budget numbers (160-char legacy vs. 200-char real).
- Added `tests/plugins/test-no-orphan-plugin-dirs.sh` and `tests/plugins/test-description-budget.sh` to guard the new invariants.
- Bumped all touched plugins in `.claude-plugin/marketplace.json` with matching CHANGELOG entries.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/code-review/commands/fix-branch.md` | Agent-review delegation rerouted to `skill-reviewer` | Modified |
| `kit/plugins/code-review/README.md` | Delegation description updated | Modified |
| `kit/plugins/agent-creator/` | De-registered plugin directory (5 files, 613 lines) | Deleted |
| `kit/plugins/agent-reviewer/` | De-registered plugin directory (6 files, 1,208 lines) | Deleted |
| `kit/plugins/agentic-plugin-dev/` | De-registered plugin directory (10 files, 1,026 lines) | Deleted |
| `kit/plugins/code-simplifier/` | De-registered plugin directory (7 files, 798 lines) | Deleted |
| `kit/plugins/marketplace-builder/` | De-registered plugin directory (7 files, 860 lines) | Deleted |
| `kit/plugins/react-perf-analyzer/` | De-registered plugin directory (5 files, 949 lines) | Deleted |
| `README.md` | Breaking-change note, tree diagram, migration-table links corrected | Modified |
| `.claude/rules/marketplace.md` | Retained-for-reference promise removed; do-not-re-add table preserved | Modified |
| `kit/plugins/skill-reviewer/commands/check-description.md` | 160/200 budget discrepancy reconciled | Modified |
| `.claude-plugin/marketplace.json` | PATCH bumps for every plugin whose SKILL.md changed | Modified |
| `tests/plugins/test-no-orphan-plugin-dirs.sh` | New smoke test: plugin dirs must match manifest entries | Created |
| `tests/plugins/test-description-budget.sh` | New unit test: 200-total and 80-first-sentence rule across all SKILL.md files | Created |

## How it works

**Migrating the live caller first.** Before any directory was deleted, `kit/plugins/code-review/commands/fix-branch.md` line 119 was updated to delegate changed `**/agents/*.md` files to `skill-reviewer` rather than the removed `agent-reviewer:reviewing-agents`. The companion sentence in `kit/plugins/code-review/README.md` was updated to match. This step was required because deleting `agent-reviewer` before migrating it would have caused `/code-review:fix-branch` to error on any branch touching an agent file — including the concurrent `fix-plugin-component-defects` plan.

**Deleting the six directories.** After the migration, all six de-registered directories were removed with `git rm -r`. Git history preserves their contents exactly. The local loader (`CLAUDE.local.md`'s `--plugin-dir` one-liner) was also replaced: instead of `ls kit/plugins/ | xargs`, it now reads `marketplace.json` directly via a short Python substitution, so any future de-registered directory dropped into `kit/plugins/` will not silently load.

**Correcting the documentation.** `README.md`'s line 9 breaking-change note no longer claims the directories are retained — it says the source was removed and is recoverable from git history at the commit prior to this change. The tree diagram entries for the six plugins were removed. The removed-plugins migration table entries remain but were de-linked from `./kit/plugins/...` paths. The do-not-re-add table and rule in `.claude/rules/marketplace.md` survived intact; only the retained-for-reference promise was removed.

**Fixing over-budget descriptions.** Eight SKILL.md files failed the real 200-total / 80-first-sentence budget rule: `team-defaults/sync-rules`, `plan-agent/prototype`, `plan-agent/finalize-plan`, `plan-agent/build-proposal`, `social-media-tools/save-artifact`, `social-media-tools/export-session`, `social-media-tools/share-code`, and `git-agent/ship-autonomous`. Each was processed through `skill-reviewer:optimizing-skill-frontmatter`, which rewrote the `description:` to three-part format and set `disable-model-invocation` correctly in the same pass. `check-description.md`'s 160-char threshold was reconciled with the real 200-char rule to eliminate the two-number discrepancy.

**Adding the guard tests.** `tests/plugins/test-no-orphan-plugin-dirs.sh` asserts that the set of directory names under `kit/plugins/` equals the set of `name` values in `marketplace.json` (excluding `README.md`). `tests/plugins/test-description-budget.sh` asserts the 200-total and 80-first-sentence rule across every remaining SKILL.md. Both are designed to fail the precise scenarios this plan guards against.

**Version bumps.** Every plugin whose SKILL.md was changed (`team-defaults`, `plan-agent`, `social-media-tools`, `git-agent`, `skill-reviewer`) received a PATCH bump in `.claude-plugin/marketplace.json` with a matching CHANGELOG entry.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `ebba701` | 2026-07-16 | chore: delete six de-registered plugin directories and fix survivor frontmatter (#418) |

<!-- generated:end -->

## References

- Plan: [remove-dead-plugins-and-fix-frontmatter](plans/remove-dead-plugins-and-fix-frontmatter.md)
- Removed plugins registry: `.claude/rules/marketplace.md` (do-not-re-add table)
