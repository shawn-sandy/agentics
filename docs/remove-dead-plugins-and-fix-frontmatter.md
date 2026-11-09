# Delete the six de-registered plugin directories and fix survivor frontmatter

> Six de-registered plugins were left on disk after the v4.0.0 marketplace update, causing name collisions in every local session and eating description budget.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
**Type:** chore

## What shipped

- Deleted six plugin directories (`agent-creator`, `agent-reviewer`, `agentic-plugin-dev`, `code-simplifier`, `marketplace-builder`, `react-perf-analyzer`) that were de-registered in v4.0.0 but kept on disk, causing duplicate skill names when loading via `--plugin-dir` on a directory glob.
- Migrated `code-review:fix-branch` to delegate changed agent files to `skill-reviewer` instead of the deleted `agent-reviewer`, removing the live dependency before deleting the dead plugin.
- Corrected `README.md` and `.claude/rules/marketplace.md` to remove the claim that removed plugin directories are retained, pointing to git history instead.
- Fixed eight over-budget `SKILL.md` descriptions by running `/skill-reviewer:optimizing-skill-frontmatter` across the affected files (none were in the deleted directories).
- Reconciled the conflicting 160-char vs 200-char description thresholds in `skill-reviewer`.
- Added `tests/plugins/test-no-orphan-plugin-dirs.sh` to assert every directory under `kit/plugins/` has a matching marketplace manifest entry, and `tests/plugins/test-description-budget.sh` to enforce the 200/80 rule across all SKILL.md files.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/code-review/commands/fix-branch.md` | Command — delegates agent-file review to skill-reviewer | Modified |
| `tests/plugins/test-no-orphan-plugin-dirs.sh` | Smoke test — orphan directory guard | Created |
| `tests/plugins/test-description-budget.sh` | Smoke test — 200-char description budget | Created |
| `README.md` | Repo landing page — removes stale retention promise | Modified |
| `.claude/rules/marketplace.md` | Rule — updates removed-plugins table notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — version bumps for touched plugins | Modified |

## How it works

The core defect was that de-registering a plugin from `.claude-plugin/marketplace.json` stops distribution but does not stop loading. The local testing command `claude $(ls ~/devbox/agentics/kit/plugins/ | xargs -I{} echo --plugin-dir ...)` reads directories, not the manifest, so all 19 directories loaded. This caused live-observed name collisions: `0.1.0:agent-creator` competing with `plugin-dev:agent-creator`, and `code-simplifier:code-simplifier` alongside the real `skill-reviewer`.

Before deleting `agent-reviewer`, `code-review:fix-branch` was migrated to invoke `skill-reviewer:reviewing-agents` instead, since `agent-reviewer` was explicitly removed on the grounds that it overlaps with `skill-reviewer`. This migration was verified by grepping for `agent-reviewer` references in the live code-review plugin.

The six directories were then deleted with `git rm -r`, preserving all history. The README tree diagram and the breaking-change note were updated, and `.claude/rules/marketplace.md` now points to git history rather than asserting the directories are still on disk.

The description-budget cleanup ran `skill-reviewer:optimizing-skill-frontmatter` over eight SKILL.md files that exceeded the 200-char total / 80-char first-sentence rule. The threshold discrepancy in `skill-reviewer/commands/check-description.md` (which warned at 160 chars) was reconciled by framing 160 as a legacy conservative target.

## How to use it

```bash
# Verify no orphan plugin directories exist
bash tests/plugins/test-no-orphan-plugin-dirs.sh

# Verify all SKILL.md descriptions are within budget
bash tests/plugins/test-description-budget.sh
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
