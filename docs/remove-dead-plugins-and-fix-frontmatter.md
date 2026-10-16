# Delete the Six De-Registered Plugin Directories and Fix Survivor Frontmatter

> Six plugins were dropped from the marketplace in v4.0.0 but their directories stayed on disk, and because the local loader reads directories instead of the manifest, they still load and now collide by name with the real plugins. This deletes them, corrects the docs that promise they are retained, and runs skill-reviewer over the survivors instead of hand-editing frontmatter.

<!-- generated:start -->

**Status:** Shipped 2026-07-16  **Plan:** [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
**Type:** chore

## What shipped

- Migrated `code-review`'s `fix-branch` skill off the deleted `agent-reviewer` plugin to `skill-reviewer` (the stated replacement), eliminating a live caller of a dead skill before any deletion occurred.
- Deleted six de-registered plugin directories (`agent-creator`, `agent-reviewer`, `agentic-plugin-dev`, `code-simplifier`, `marketplace-builder`, `react-perf-analyzer`) — 5,454 lines across 40 files — from `kit/plugins/`, reducing the directory count from 19 to 13.
- Corrected `README.md` to remove false claims about retained directories, updated the tree diagram, and preserved migration-table rows as plain text without dead links.
- Updated `.claude/rules/marketplace.md` to drop the retained-for-reference promise while keeping the do-not-re-add table intact.
- Replaced the `ls | xargs` loader in `CLAUDE.local.md` with a manifest-reading form, closing the class of re-loading any future de-registered plugin.
- Ran `skill-reviewer:optimizing-skill-frontmatter` over all eight SKILL.md files that exceeded the real 200-char/80-char-first-sentence description budget.
- Reconciled the two budget numbers in `check-description.md` (160 legacy vs. 200 real) to a single authoritative value.
- Bumped versions for every plugin whose SKILL.md changed and added matching CHANGELOG entries.
- Added two new tests: `test-no-orphan-plugin-dirs.sh` (manifest-vs-directory invariant) and `test-description-budget.sh` (200/80 description rule).

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/code-review/commands/fix-branch.md` | Command — delegates agent-file review to `skill-reviewer` | Modified |
| `kit/plugins/code-review/README.md` | Plugin docs — updated delegation description | Modified |
| `kit/plugins/agent-creator/` | Dead plugin directory — 5 files, 613 lines | Deleted (was present) |
| `kit/plugins/agent-reviewer/` | Dead plugin directory — 6 files, 1,208 lines | Deleted (was present) |
| `kit/plugins/agentic-plugin-dev/` | Dead plugin directory — 10 files, 1,026 lines | Deleted (was present) |
| `kit/plugins/code-simplifier/` | Dead plugin directory — 7 files, 798 lines | Deleted (was present) |
| `kit/plugins/marketplace-builder/` | Dead plugin directory — 7 files, 860 lines | Deleted (was present) |
| `kit/plugins/react-perf-analyzer/` | Dead plugin directory — 5 files, 949 lines | Deleted (was present) |
| `README.md` | Repo docs — breaking-change note, tree diagram, migration table | Modified |
| `.claude/rules/marketplace.md` | Authoring rule — dropped retained-for-reference promise | Modified |
| `kit/plugins/skill-reviewer/commands/check-description.md` | Description checker — reconciled 160 vs. 200 budget | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — PATCH bumps for touched plugins | Modified |
| `tests/plugins/test-no-orphan-plugin-dirs.sh` | Test — asserts manifest directories match plugin dirs | Created |
| `tests/plugins/test-description-budget.sh` | Test — asserts 200-char total, 80-char first-sentence rule | Created |

## How it works

The root defect was a mismatch between how plugins are distributed and how they are loaded locally. `.claude-plugin/marketplace.json` is the distribution manifest: de-registering a plugin there stops users from installing it via `/plugin install`. But the documented local-testing command loaded plugins by reading the `kit/plugins/` directory with `ls`, not by reading the manifest. When six plugins were de-registered in v4.0.0 their source directories were left on disk "for reference," which meant they continued loading in every local session — appearing as duplicate entries like `0.1.0:agent-creator` alongside `plugin-dev:agent-creator` and competing with live plugins for skill-description budget.

Before any directory was deleted, the one live caller of a dead plugin was migrated. `kit/plugins/code-review/commands/fix-branch.md` delegated agent-file review to `agent-reviewer:reviewing-agents` — the v4.0.0 removal note named `skill-reviewer` as the replacement, and the migration simply rewires that one line. Without this step, deleting `agent-reviewer` would break `/code-review:fix-branch` on any branch touching an agent file, including the companion `fix-plugin-component-defects` plan.

The six directories were then removed with `git rm -r`. Git history preserves every file for recovery, so nothing was actually lost. The README's claims that directories are "retained in the repository" became false claims and were corrected: the breaking-change note was rewritten, the six entries were removed from the tree diagram, and the migration-table rows (which tell users what to install instead) were kept as plain text without live links to the now-deleted paths.

The description-budget problem existed independently of the deletion. Eight SKILL.md files exceeded the real 200-char/80-char-first-sentence budget, but the checker in `check-description.md` warned at 160 chars (a legacy target), causing a reviewer to count 12 failing files instead of 8. Rather than hand-editing descriptions, `skill-reviewer:optimizing-skill-frontmatter` was run over all eight files, letting the tool apply its own three-part judgment. The checker was then updated to state a single budget number, with 160 referenced only as a conservative historical target.

The `CLAUDE.local.md` loader was replaced with a Python one-liner that reads `.claude-plugin/marketplace.json` directly, so future de-registrations cannot re-introduce the symptom. Two new tests lock in the outcome: `test-no-orphan-plugin-dirs.sh` asserts that every directory under `kit/plugins/` has a matching manifest entry and vice versa, and `test-description-budget.sh` enforces the 200/80 rule across all shipped SKILL.md files.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
