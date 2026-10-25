# Make settings-sync back up what a restore actually needs, and stop committing when nothing changed

> Widens the settings-sync manifest to include `agents/`, `output-styles/`, `scripts/`, and `reference/` — four folders that restored configs reference but were never backed up — and stops the backup skill from committing on no-change runs.

<!-- generated:start -->

**Status:** Shipped 2026-09-09  **Plan:** [fix-settings-sync-coverage-gaps](plans/fix-settings-sync-coverage-gaps.md)
**Type:** fix

## What shipped

- Added four Default targets to `references/file-manifest.md`: `~/.claude/agents/` (user-defined subagents), `~/.claude/output-styles/` (custom styles named by `outputStyle`), `~/.claude/scripts/` (scripts referenced by hooks and statusLine), and `~/.claude/reference/` (files linked from CLAUDE.md)
- Corrected the manifest's wrong exclusion note that labelled `agents/` as task state
- Rewrote the `settings-backup` commit logic so `.settings-sync-meta.json` is written only after a real change is staged; no-change runs log locally to `.sync-log` (gitignored) and commit nothing
- Added a Step 2 snippet to untrack files that are already in git but covered by ignore rules (cleans up tracked `.pyc` files and `.sync-log` entries from earlier runs)
- Bumped settings-sync to 1.2.0
- Created three new test files: `test-settings-backup-e2e.sh`, `test-settings-sync-manifest-targets.sh`, and `test-settings-backup-no-change-commit.sh`

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/settings-sync/references/file-manifest.md` | Reference — four new targets, corrected exclusion notes | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Skill — copy targets, untrack snippet, commit-only-on-change | Modified |
| `kit/plugins/settings-sync/README.md` | Plugin docs — new targets table rows, no-change wording | Modified |
| `kit/plugins/settings-sync/CHANGELOG.md` | Release history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry — settings-sync 1.2.0 | Modified |
| `tests/plugins/test-settings-backup-e2e.sh` | Smoke test — end-to-end backup behaviour | Created |
| `tests/plugins/test-settings-sync-manifest-targets.sh` | Smoke test — four-copy target list consistency | Created |
| `tests/plugins/test-settings-backup-no-change-commit.sh` | Smoke test — commit-only-on-change logic | Created |

## How it works

A coverage audit on 2026-09-04 compared the plugin's file manifest against a real `~/.claude/` directory and found the backup missed four user-authored folders that restored configs depend on: `agents/` holds custom subagents, `output-styles/` holds the style `settings.json` names, `scripts/` holds scripts that hooks and the status line call, and `reference/` holds files that `CLAUDE.md` links by path. A new-machine restore would look complete but would silently fail the moment any of these was accessed.

The manifest's exclusion list also labelled `agents/` as task state (it is not) and `projects/*/memory/` as "lives with each project" (that phrasing confused it with the project-scoped plans directory).

The noise-commit problem was separate but measured at the same time: 4,477 of the real backup repo's 4,601 commits changed only `.settings-sync-meta.json` because the timestamp was written before the change check. Moving the metadata write to after `git diff --cached --quiet` confirms a real change eliminates those commits. The no-change branch now appends one timestamped line to a gitignored `.sync-log` and exits without committing.

The three new tests follow the same extract-a-marked-snippet-and-run-it pattern as `test-settings-backup-stale-entries.sh`: they pull bash blocks from SKILL.md by marker and run them against fixture repos, so the tests exercise the skill's actual commands rather than grepping for prose. The manifest-targets test additionally pins the four copies of the target list (manifest, SKILL.md Step 3, the copy block, and the stray-entries case list) to each other so they cannot drift.

The restore skill was not changed — it restores every entry it finds in the repo root, so the four new folders come back for free on a new machine.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d7a4be2` | 2026-09-09 | feat(plan-agent): workflow engine escalation pilot (9.17.0) |

<!-- generated:end -->

## References

- Plan: [fix-settings-sync-coverage-gaps](plans/fix-settings-sync-coverage-gaps.md)
