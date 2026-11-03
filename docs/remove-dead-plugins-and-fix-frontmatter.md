# Delete the six de-registered plugin directories and fix survivor frontmatter

> Deletes six plugin directories de-registered in v4.0.0 but left on disk, migrates code-review off the deleted agent-reviewer, corrects docs, and uses skill-reviewer to fix eight over-budget SKILL.md descriptions.

<!-- generated:start -->

**Status:** Shipped 2026-07-16  **Plan:** [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
**Type:** chore

## What shipped

- Migrated `kit/plugins/code-review/commands/fix-branch.md` line 119 from delegating to `agent-reviewer:reviewing-agents` to `skill-reviewer`, and updated `kit/plugins/code-review/README.md` to match.
- Deleted with `git rm -r`: `kit/plugins/agent-creator/`, `kit/plugins/agent-reviewer/`, `kit/plugins/agentic-plugin-dev/`, `kit/plugins/code-simplifier/`, `kit/plugins/marketplace-builder/`, `kit/plugins/react-perf-analyzer/` (5,454 lines across 40 files; recoverable from git history).
- Updated `README.md` — rewrote the breaking-change note to say source was removed (recoverable from git), deleted six entries from the tree diagram, unlinked but kept the plugin names in the migration table.
- Updated `.claude/rules/marketplace.md` — removed the "retained for reference" promise; kept the six-row do-not-re-add table intact.
- Updated `CLAUDE.local.md` — replaced the `ls | xargs` plugin loader with a manifest-reading form.
- Updated `kit/plugins/skill-reviewer/commands/check-description.md` — reconciled the 160-char legacy threshold with the real 200/80 budget.
- Ran `/skill-reviewer:optimizing-skill-frontmatter` over the 8 failing files: `team-defaults/sync-rules`, `plan-agent/prototype`, `plan-agent/finalize-plan`, `plan-agent/build-proposal`, `social-media-tools/save-artifact`, `social-media-tools/export-session`, `social-media-tools/share-code`, `git-agent/ship-autonomous`.
- Bumped `team-defaults`, `plan-agent`, `social-media-tools`, `git-agent`, and `skill-reviewer` versions in `.claude-plugin/marketplace.json`; added matching CHANGELOG entries.
- Added `tests/plugins/test-no-orphan-plugin-dirs.sh` — asserts that every `kit/plugins/` directory name matches a manifest entry and vice versa.
- Added `tests/plugins/test-description-budget.sh` — unit test for the 200/80 description rule.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/code-review/commands/fix-branch.md` | Command instructions | Modified |
| `kit/plugins/code-review/README.md` | Plugin documentation | Modified |
| `kit/plugins/agent-creator/` | Dead plugin | Deleted |
| `kit/plugins/agent-reviewer/` | Dead plugin | Deleted |
| `kit/plugins/agentic-plugin-dev/` | Dead plugin | Deleted |
| `kit/plugins/code-simplifier/` | Dead plugin | Deleted |
| `kit/plugins/marketplace-builder/` | Dead plugin | Deleted |
| `kit/plugins/react-perf-analyzer/` | Dead plugin | Deleted |
| `README.md` | Root documentation | Modified |
| `.claude/rules/marketplace.md` | Marketplace rules | Modified |
| `CLAUDE.local.md` | Local loader | Modified |
| `kit/plugins/skill-reviewer/commands/check-description.md` | Check command | Modified |
| `.claude-plugin/marketplace.json` | Marketplace versions | Modified |
| `tests/plugins/test-no-orphan-plugin-dirs.sh` | Orphan guard test | Created |
| `tests/plugins/test-description-budget.sh` | Description budget test | Created |

## How it works

`.claude-plugin/marketplace.json` listed 13 plugins while `kit/plugins/` contained 19 directories. The six extras were de-registered in v4.0.0 on 2026-05-29, but de-registering stops distribution without stopping loading: the local `--plugin-dir` loader reads directories, not the manifest, so all 19 loaded. The result was observed live as duplicate skill names (`0.1.0:agent-creator` competing with the real plugin) consuming description budget in every session.

The migration of `code-review:fix-branch` was done before any deletion: `code-review` was the one live plugin still invoking a dead one (`agent-reviewer:reviewing-agents`). After migration, the deletions went through cleanly.

The dead directories are removed from disk but fully recoverable from git history, matching the six prior plugin removals in `.claude/rules/marketplace.md`. The local loader was fixed at its source (manifest-reading) rather than as a one-time symptom fix.

Eight SKILL.md descriptions exceeded the real 200/80 budget (200 total chars, first sentence under 80). The repair used `skill-reviewer:optimizing-skill-frontmatter` to rewrite each description and set `disable-model-invocation` correctly — the same judgment the skill exists to make, applied to the repo's own plugins.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|

<!-- generated:end -->

## References

- Plan: [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
