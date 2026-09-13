# Delete de-registered plugin directories and fix survivor frontmatter

> Six plugin directories de-registered in v4.0.0 but left on disk were still loading through `--plugin-dir`, colliding with live plugins. This removes them, corrects the docs, and brings all surviving SKILL.md descriptions inside the 200-char budget.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
**Type:** chore

## What shipped

- Migrated `code-review`'s `fix-branch.md` off the deleted `agent-reviewer` skill to `skill-reviewer` before any deletion, closing the one live caller of a dead plugin (step 1 must precede deletions or `/code-review:fix-branch` errors on branches touching agent files).
- Deleted six plugin directories via `git rm -r`: `agent-creator`, `agent-reviewer`, `agentic-plugin-dev`, `code-simplifier`, `marketplace-builder`, `react-perf-analyzer` — 5,454 lines across 40 files reclaimed from disk.
- Corrected `README.md` so it no longer claims the removed directories are retained; updated the tree diagram and migration-table links.
- Updated `.claude/rules/marketplace.md` to remove the "retained for reference" promises for `agentic-plugin-dev` and `code-simplifier`, pointing to git history instead; the do-not-re-add table survives.
- Updated `CLAUDE.local.md` (gitignored) to read plugin dirs from `marketplace.json` rather than `ls kit/plugins/`, closing the class of defect rather than just the instance.
- Ran `/skill-reviewer:optimizing-skill-frontmatter` over all eight over-budget SKILL.md files (`team-defaults/sync-rules`, `plan-agent/prototype`, `plan-agent/finalize-plan`, `plan-agent/build-proposal`, `social-media-tools/save-artifact`, `social-media-tools/export-session`, `social-media-tools/share-code`, `git-agent/ship-autonomous`) to rewrite descriptions to three-part form within the real 200/80 budget.
- Reconciled `kit/plugins/skill-reviewer/commands/check-description.md` to state the real 200-char budget instead of the legacy 160 target.
- Added `tests/plugins/test-no-orphan-plugin-dirs.sh` — asserts the set of `kit/plugins/` directory names equals the set of names in `marketplace.json`.
- Added `tests/plugins/test-description-budget.sh` — asserts every SKILL.md description stays within the 200-total and 80-first-sentence limits.
- Bumped version in `.claude-plugin/marketplace.json` for every plugin whose SKILL.md was touched.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/code-review/commands/fix-branch.md` | Delegates agent-file review to `skill-reviewer` instead of deleted `agent-reviewer` | Modified |
| `kit/plugins/code-review/README.md` | Updated delegation sentence at line 89 | Modified |
| `kit/plugins/agent-creator/` | De-registered plugin directory (613 lines) | Deleted |
| `kit/plugins/agent-reviewer/` | De-registered plugin directory (1,208 lines) | Deleted |
| `kit/plugins/agentic-plugin-dev/` | De-registered plugin directory (1,026 lines) | Deleted |
| `kit/plugins/code-simplifier/` | De-registered plugin directory (798 lines) | Deleted |
| `kit/plugins/marketplace-builder/` | De-registered plugin directory (860 lines) | Deleted |
| `kit/plugins/react-perf-analyzer/` | De-registered plugin directory (949 lines) | Deleted |
| `README.md` | Removed false "retained" claim, updated tree diagram and migration table | Modified |
| `.claude/rules/marketplace.md` | Removed retained-for-reference promise; kept do-not-re-add table | Modified |
| `tests/plugins/test-no-orphan-plugin-dirs.sh` | Smoke test: plugin dirs must equal manifest names | Created |
| `tests/plugins/test-description-budget.sh` | Unit test: 200-total and 80-first-sentence description rule | Created |
| `.claude-plugin/marketplace.json` | PATCH bumps for all plugins with rewritten SKILL.md descriptions | Modified |

## How it works

De-registering a plugin from `marketplace.json` stops distribution but does not stop loading when the local test command passes `--plugin-dir` for every directory under `kit/plugins/`. This produced duplicate skill names (`0.1.0:agent-creator` and `plugin-dev:agent-creator`, two copies of `skill-reviewer`, `code-simplifier:code-simplifier`) competing for description budget in every session.

The migration order was safety-critical. `code-review:fix-branch` at line 119 delegated to `agent-reviewer:reviewing-agents` for any branch touching `**/agents/*.md`. Deleting `agent-reviewer` without first migrating that call would break `/code-review:fix-branch` on exactly the kind of branch the companion `fix-plugin-component-defects` plan was creating. Step 1 rewired the call to `skill-reviewer` (the stated replacement in v4.0.0's own removal note) before any `git rm` ran.

The description-budget work was separate from but coincident with the deletion. The real budget rule lives in `optimizing-skill-frontmatter/SKILL.md:18`: 200 total chars, first sentence under 80. Eight files failed this rule; none was in a deleted directory, so no deletion shrank the set. The plan ran the repo's own `skill-reviewer:optimizing-skill-frontmatter` over all eight rather than hand-editing, both to exercise the tool against its own repo and to get the `disable-model-invocation` judgment right per file.

The `check-description.md` file in `skill-reviewer` previously stated 160 chars as the budget, which is how a reviewer miscounted 12 failures when there were only 8. Step 7 reconciled the two numbers so the warning no longer contradicts the rule it enforces.

`CLAUDE.local.md` (gitignored) carried a `ls kit/plugins/ | xargs` loader that would re-load any directory dropped into `kit/plugins/`, making the class of defect persistent. Replacing it with a `marketplace.json`-driven form (`python3 -c "..."`) closes the class; the file being gitignored makes this local-only with no commit required.

The two new test scripts assert the invariant the plan establishes. `test-no-orphan-plugin-dirs.sh` fails if a directory exists without a matching manifest entry or vice versa. `test-description-budget.sh` fails if any SKILL.md description exceeds the 200/80 rule. Both are wired into CI.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
