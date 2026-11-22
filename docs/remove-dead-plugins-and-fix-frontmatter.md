# Remove dead plugins and fix frontmatter

> Six plugins were dropped from the marketplace in v4.0.0 but their directories stayed on disk. Because the local loader reads directories instead of the manifest, they were still loading and colliding by name with the real plugins. This deletes them, corrects the docs, and fixes over-budget SKILL.md descriptions.

<!-- generated:start -->

**Status:** Shipped 2026-07-16 **Plan:** [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
**Type:** chore

## What shipped

- Migrated `code-review/commands/fix-branch.md` and `code-review/README.md` off `agent-reviewer` to `skill-reviewer` before deleting anything.
- Deleted six de-registered plugin directories: `kit/plugins/agent-creator/`, `agent-reviewer/`, `agentic-plugin-dev/`, `code-simplifier/`, `marketplace-builder/`, `react-perf-analyzer/` (5,454 lines across 40 files; recoverable from git history).
- Updated `README.md`: breaking-change note now says directories were removed and are recoverable from git history; six entries removed from the tree diagram; migration-table names kept as text without links.
- Updated `.claude/rules/marketplace.md`: the "retained for reference" promise removed; do-not-re-add table kept intact.
- Updated `CLAUDE.local.md` (gitignored): replaced the `ls | xargs` loader one-liner with a form that reads `marketplace.json`, so only registered plugins load.
- Ran `/skill-reviewer:optimizing-skill-frontmatter` over the eight over-budget SKILL.md files and applied rewrites.
- Reconciled `check-description.md`'s threshold text to state 160 as a legacy conservative target and 200 as the real budget.
- Added `tests/plugins/test-no-orphan-plugin-dirs.sh`: asserts every directory under `kit/plugins/` has a matching manifest entry and vice versa.
- Added `tests/plugins/test-description-budget.sh`: applies the 200-total / 80-first-sentence rule across every SKILL.md.
- Bumped PATCH versions for all plugins with touched SKILL.md files.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/code-review/commands/fix-branch.md` | Delegated to skill-reviewer | Modified |
| `kit/plugins/code-review/README.md` | Delegation sentence updated | Modified |
| `kit/plugins/agent-creator/` | Deleted | Deleted |
| `kit/plugins/agent-reviewer/` | Deleted | Deleted |
| `kit/plugins/agentic-plugin-dev/` | Deleted | Deleted |
| `kit/plugins/code-simplifier/` | Deleted | Deleted |
| `kit/plugins/marketplace-builder/` | Deleted | Deleted |
| `kit/plugins/react-perf-analyzer/` | Deleted | Deleted |
| `README.md` | Breaking-change note, tree diagram, migration table | Modified |
| `.claude/rules/marketplace.md` | Retained-for-reference promise removed | Modified |
| `kit/plugins/skill-reviewer/commands/check-description.md` | 160/200 reconciliation | Modified |
| `tests/plugins/test-no-orphan-plugin-dirs.sh` | Plugin-manifest parity test | Created |
| `tests/plugins/test-description-budget.sh` | 200-char budget rule test | Created |
| `.claude-plugin/marketplace.json` | PATCH bumps for touched plugins | Modified |

## How it works

**Loading collision**: The `ls | xargs` loader loaded every directory in `kit/plugins/`, including the six de-registered ones. That put `0.1.0:agent-creator` alongside the real `agent-creator`-based skills and `code-simplifier:code-simplifier` into the agent list in every session. The manifest-reading loader only loads the 13 registered plugins.

**Live dependency**: `code-review:fix-branch` called `agent-reviewer:reviewing-agents` for changed agent files. `agent-reviewer` was de-registered because it overlaps with `skill-reviewer` — so `fix-branch` now delegates to `skill-reviewer` instead, which is what the v4.0.0 removal note implied.

**Description budget**: The real budget is 200 total / 80 first sentence (from `optimizing-skill-frontmatter/SKILL.md`), not the 160-char warning number in `check-description.md`. Eight files were over budget. All eight belonged to surviving plugins; none was in a deleted directory.

## How to use it

The changes are automatic for anyone installing from the marketplace. For local development, update `CLAUDE.local.md` to use the manifest-reading loader to avoid loading any future de-registered directories.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-07-16 | chore: delete six de-registered plugin dirs, fix frontmatter budgets, manifest-reading loader |

<!-- generated:end -->

## References

- Plan: [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
