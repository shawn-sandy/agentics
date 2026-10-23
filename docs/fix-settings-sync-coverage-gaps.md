# Fix settings-sync coverage gaps

> Adds four new sync targets (agents/, output-styles/, scripts/, reference/), fixes no-change commits writing meta without staging, gitignores .sync-log, and adds untrack logic for files excluded from sync.

<!-- generated:start -->

**Status:** Shipped 2026-09-04 **Plan:** [fix-settings-sync-coverage-gaps.md](plans/fix-settings-sync-coverage-gaps.md)
**Type:** fix

## What shipped

- Added four new sync targets: `agents/`, `output-styles/`, `scripts/`, `reference/`.
- Fixed no-change commits: `meta` is now written only after a staged change exists, not unconditionally.
- Added `.sync-log` to `.gitignore`.
- Added untrack logic via `git ls-files -ci`: files that match `.gitignore` patterns but were previously tracked are now untracked on sync.
- Added three new tests.
- Bumped settings-sync to 1.2.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Backup skill | Modified |
| `kit/plugins/settings-sync/skills/settings-restore/SKILL.md` | Restore skill | Modified |
| `.gitignore` | Ignore sync log | Modified |
| `tests/test-settings-sync-agents.sh` | agents/ target test | Created |
| `tests/test-settings-sync-output-styles.sh` | output-styles/ target test | Created |
| `tests/test-settings-sync-no-change.sh` | No-change commit test | Created |
| `kit/plugins/settings-sync/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

The four new targets (`agents/`, `output-styles/`, `scripts/`, `reference/`) fill gaps in settings-sync coverage. Previously, custom agents, output style configurations, utility scripts, and reference files under `~/.claude/` were not backed up. These directories can contain months of accumulated customization that would be lost on a machine wipe.

The no-change commit fix prevents spurious commits: before this fix, `meta` (last-sync timestamp, file count) was written and staged regardless of whether any settings file changed. This produced empty commits with only the meta file changed. Now `meta` is written only after at least one settings file is staged.

The `.sync-log` gitignore addition prevents the sync log (which records every sync operation with timestamps and file counts) from being committed to the repo. The log is a local operational record, not project state.

The untrack logic handles files that were synced in a previous version of settings-sync but are now excluded by a `.gitignore` pattern. Without this, the file stays tracked even after being added to `.gitignore`, which defeats the ignore rule.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [fix-settings-sync-coverage-gaps.md](plans/fix-settings-sync-coverage-gaps.md)
