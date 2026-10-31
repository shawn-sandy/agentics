# Delete the six de-registered plugin directories and fix survivor frontmatter

> Six de-registered plugins that still loaded via --plugin-dir were deleted from disk, documentation corrected, and eight over-budget SKILL.md descriptions fixed using the repo's own skill-reviewer tooling.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
**Type:** chore

## What shipped

- Migrated `kit/plugins/code-review/commands/fix-branch.md` off `agent-reviewer:reviewing-agents` to `skill-reviewer:reviewing-skills` before deleting anything, and updated the companion delegation sentence in `kit/plugins/code-review/README.md`.
- Deleted six plugin directories via `git rm -r`: `agent-creator`, `agent-reviewer`, `agentic-plugin-dev`, `code-simplifier`, `marketplace-builder`, and `react-perf-analyzer` (5,454 lines across 40 files; all recoverable from git history).
- Corrected `README.md`: rewrote the breaking-change note to say the source was removed and is recoverable, deleted the six entries from the tree diagram, and unlinked (but kept) the plugin names in the removed-plugins migration table.
- Updated `.claude/rules/marketplace.md` so the `agentic-plugin-dev` and `code-simplifier` notes no longer promise retained directories — pointing to git history instead — while keeping the six-row do-not-re-add table intact.
- Replaced the `ls | xargs` loader one-liner in `CLAUDE.local.md` with a manifest-reading form so future de-registered plugins do not auto-load.
- Ran `/skill-reviewer:optimizing-skill-frontmatter` over all eight over-budget SKILL.md files (`team-defaults/sync-rules`, `plan-agent/prototype`, `plan-agent/finalize-plan`, `plan-agent/build-proposal`, `social-media-tools/save-artifact`, `social-media-tools/export-session`, `social-media-tools/share-code`, `git-agent/ship-autonomous`), letting the skill rewrite descriptions to the three-part 200/80-char format.
- Reconciled the two conflicting budget numbers in `kit/plugins/skill-reviewer/commands/check-description.md` to state 160 as a legacy conservative target and 200 as the real budget.
- Bumped `version` in `.claude-plugin/marketplace.json` for every plugin whose SKILL.md was touched (`team-defaults`, `plan-agent`, `social-media-tools`, `git-agent`, `skill-reviewer`) and added matching CHANGELOG entries (PATCH bumps).
- Created `tests/plugins/test-no-orphan-plugin-dirs.sh`: the objective-verification test asserting that the set of directory names under `kit/plugins/` equals the set of manifest name values.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/code-review/commands/fix-branch.md` | Command — agent-reviewer delegation migrated to skill-reviewer | Modified |
| `kit/plugins/code-review/README.md` | Plugin documentation — delegation description updated | Modified |
| `README.md` | Project README — breaking-change note, tree diagram, migration table | Modified |
| `.claude/rules/marketplace.md` | Removed Plugins rule — retained-for-reference promise removed | Modified |
| `.claude-plugin/marketplace.json` | Marketplace manifest — PATCH bumps for five plugins | Modified |
| `kit/plugins/skill-reviewer/commands/check-description.md` | Command — budget threshold reconciled to 200/80 | Modified |
| `tests/plugins/test-no-orphan-plugin-dirs.sh` | Smoke test — manifest/directory parity invariant | Created |

## How it works

The `.claude-plugin/marketplace.json` listed 13 plugins while `kit/plugins/` contained 19 directories. The six extras — `agent-creator`, `agent-reviewer`, `agentic-plugin-dev`, `code-simplifier`, `marketplace-builder`, and `react-perf-analyzer` — had been de-registered from the marketplace on 2026-05-29 but their directories were retained "for reference". De-registering stops distribution; it does not stop loading. The local-testing command documented in `CLAUDE.local.md` read `kit/plugins/` via `ls` rather than the manifest, so all 19 directories loaded. This was observed live in a session on 2026-07-16: the agent list contained duplicate `skill-reviewer` entries, `agent-creator` under two different versions, and `code-simplifier:code-simplifier` alongside live plugins, consuming description budget in every session.

Step 1 had to run before any deletion. `kit/plugins/code-review/commands/fix-branch.md` at line 119 delegated agent-file review to `agent-reviewer:reviewing-agents` — a live marketplace plugin invoking a dead one. The `fix-plugin-component-defects` plan (a companion plan) also modifies seven agent files, so deleting `agent-reviewer` first would have caused that plan's own reviewer to fail. The v4.0.0 removal note for `agent-reviewer` named `skill-reviewer` as its replacement, making the migration target unambiguous. Line 119 was updated to invoke `skill-reviewer:reviewing-skills`, and `kit/plugins/code-review/README.md` was updated to match.

Step 2 deleted all six directories with `git rm -r`. After deletion `ls kit/plugins | wc -l` returned 14 (13 plugins plus `README.md`). A repo-wide grep for the six names returns only `CHANGELOG.md` historical entries and the README migration table — no live references.

Step 3 corrected `README.md`. Line 9's breaking-change note had asserted the directories "are retained in the repository" — a now-false claim. It was rewritten to say the source was removed and is recoverable from git history at the commit prior to this change. The six entries in the tree diagram were deleted. The removed-plugins migration table at lines 779–781 retained the plugin names but removed the relative `./kit/plugins/...` links, since those paths no longer exist.

Step 4 updated `.claude/rules/marketplace.md`. The `agentic-plugin-dev` and `code-simplifier` rows previously noted the directories were retained for reference. Those notes were replaced with git-history pointers. The six-row do-not-re-add table and the gate rule both survived intact.

Step 5 fixed the loader locally. `CLAUDE.local.md` is gitignored, so this change applies only to the current developer's checkout and does not ship to other users. The fix replaced the `ls | xargs` one-liner with a Python one-liner that reads `marketplace.json` and emits exactly the registered plugin `--plugin-dir` flags. The durable, repo-wide protection against unregistered directories auto-loading is the new `tests/plugins/test-no-orphan-plugin-dirs.sh` test (Step 8), not the local loader change.

Step 6 ran `/skill-reviewer:optimizing-skill-frontmatter` over all eight SKILL.md files that failed the 200/80 rule. The skill rewrote each description to the three-part format (short trigger sentence ≤80 chars, capability statement, "Use when" activation trigger) and set `disable-model-invocation` correctly per file. `build-proposal` needed restructuring rather than trimming, as its 195-char description was one unbroken sentence with no three-part shape.

Step 7 reconciled the two budget numbers. `check-description.md` had warned at 160 characters, but `optimizing-skill-frontmatter/SKILL.md` documented 160 as a "legacy target" and set 200 total / 80 first-sentence as the real rule. Having two different numbers in one plugin caused reviewers to report failures that did not exist under the real rule (a first pass found 12 failures; the real count was 8). `check-description.md` was updated to state both numbers explicitly, framing 160 as conservative and 200 as the budget.

The new `tests/plugins/test-no-orphan-plugin-dirs.sh` asserts the parity invariant: every directory name under `kit/plugins/` (excluding `README.md`) must have a matching `name` entry in `.claude-plugin/marketplace.json`, and vice versa. This test runs in CI and guards against both re-added dead directories and registered-but-missing plugins.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |

<!-- generated:end -->

## References

- Plan: [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
- Related docs: [`.claude/rules/marketplace.md`](../.claude/rules/marketplace.md)
- Related test: [`tests/plugins/test-no-orphan-plugin-dirs.sh`](../tests/plugins/test-no-orphan-plugin-dirs.sh)
