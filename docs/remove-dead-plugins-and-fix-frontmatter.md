# Delete the six de-registered plugin directories and fix survivor frontmatter

> Removes the six plugin directories that v4.0.0 de-registered from the marketplace but left on disk, corrects documentation that claimed they were retained, and brings all surviving SKILL.md descriptions inside the 200-char budget.

<!-- generated:start -->

**Status:** Shipped 2026-07-16 **Plan:** [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
**Type:** chore

## What shipped

- Migrated `code-review/fix-branch.md` off `agent-reviewer:reviewing-agents` → `skill-reviewer`, and updated `code-review/README.md`.
- Deleted `kit/plugins/{agent-creator,agent-reviewer,agentic-plugin-dev,code-simplifier,marketplace-builder,react-perf-analyzer}/` (6 directories, 5,454 lines).
- Corrected `README.md` breaking-change note, removed the six entries from the tree diagram, updated the migration table.
- Updated `.claude/rules/marketplace.md` to point to git history instead of claiming retained directories.
- Fixed the `ls | xargs` loader one-liner in `CLAUDE.local.md` to read from `marketplace.json` instead.
- Ran `/skill-reviewer:optimizing-skill-frontmatter` over the eight files exceeding the 200-char description budget.
- Reconciled `check-description.md`'s 160-char threshold to the real 200-char budget.
- Bumped `team-defaults`, `plan-agent`, `social-media-tools`, `git-agent`, and `skill-reviewer` versions.
- Added `tests/plugins/test-no-orphan-plugin-dirs.sh` and `tests/plugins/test-description-budget.sh`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/agent-creator/` | Removed plugin | Deleted |
| `kit/plugins/agent-reviewer/` | Removed plugin | Deleted |
| `kit/plugins/agentic-plugin-dev/` | Removed plugin | Deleted |
| `kit/plugins/code-simplifier/` | Removed plugin | Deleted |
| `kit/plugins/marketplace-builder/` | Removed plugin | Deleted |
| `kit/plugins/react-perf-analyzer/` | Removed plugin | Deleted |
| `kit/plugins/code-review/commands/fix-branch.md` | Command | Modified |
| `README.md` | Documentation | Modified |
| `.claude/rules/marketplace.md` | Rules | Modified |
| `tests/plugins/test-no-orphan-plugin-dirs.sh` | Invariant test | Created |
| `tests/plugins/test-description-budget.sh` | Budget test | Created |

## How it works

De-registering a plugin from `marketplace.json` stops distribution but not local loading: the `--plugin-dir` flag reads directories, not the manifest. With six extra directories under `kit/plugins/`, the local loader was surfacing duplicate names — both `0.1.0:agent-creator` and `plugin-dev:agent-creator`, both `0.1.0:skill-reviewer` and the real `skill-reviewer` — competing for the 8,000-char skill-description budget in every session.

The deletion required one migration first: `code-review/fix-branch.md` delegated agent-file review to `agent-reviewer:reviewing-agents`, which was deleted in v4.0.0 with `skill-reviewer` as the stated replacement. That delegation was repointed before anything was deleted.

The `test-no-orphan-plugin-dirs.sh` test asserts the set of directory names under `kit/plugins/` equals the set of `name` values in `marketplace.json`, guarding against both re-added dead directories and plugins registered without source.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
