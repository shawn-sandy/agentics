# Fix settings-sync coverage gaps

> Closes four coverage gaps found in the settings-sync backup audit: missing folders, 4,477-commit noise from no-change runs, and tracked `.pyc` files; promotes from 1.1.5 to 1.2.0.

<!-- generated:start -->

**Status:** Shipped 2026-09-04  **Plan:** [fix-settings-sync-coverage-gaps.md](plans/fix-settings-sync-coverage-gaps.md)
**Type:** fix

## What shipped

- Updated `kit/plugins/settings-sync/references/file-manifest.md` — added the four previously missing backup targets: `agents/`, `output-styles/`, `scripts/`, and `reference/`.
- Updated `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` — added `.settings-sync-meta.json` write-only-on-real-change guard (the metadata file is written and staged only when at least one other file changed); moved `.sync-log` to local-only and `.gitignore`-listed; added `git ls-files -ci --exclude-standard` step to untrack `.pyc` files before staging.
- Updated `kit/plugins/settings-sync/README.md` with the new folder list and no-change behavior.
- Updated `kit/plugins/settings-sync/CHANGELOG.md` with the 1.2.0 entry.
- Added three new test files written before the edits (red-green-verify structure):
  - `tests/plugins/test-settings-sync-e2e.sh` — end-to-end backup and restore cycle.
  - `tests/plugins/test-settings-sync-manifest-targets.sh` — asserts each manifest-listed folder is copied.
  - `tests/plugins/test-settings-sync-no-change-commit.sh` — asserts a no-change run produces zero new commits.
- Bumped `settings-sync` to `1.2.0` in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/settings-sync/references/file-manifest.md` | Backup file manifest | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/settings-sync/README.md` | Plugin documentation | Modified |
| `kit/plugins/settings-sync/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |
| `tests/plugins/test-settings-sync-e2e.sh` | End-to-end test | Created |
| `tests/plugins/test-settings-sync-manifest-targets.sh` | Manifest targets test | Created |
| `tests/plugins/test-settings-sync-no-change-commit.sh` | No-change-commit test | Created |

## How it works

The coverage audit found that four folders written by Claude Code (`agents/`, `output-styles/`, `scripts/`, `reference/`) were omitted from the manifest, meaning a restore after a fresh install would lose them silently. Adding them to `file-manifest.md` makes `settings-backup` copy them into the backup repo and `settings-restore` pull them back out — no skill logic changes were needed because restore reads the manifest at runtime.

The 4,477-commit noise came from `.settings-sync-meta.json` being written unconditionally on every run. The fix stages the metadata file only when `git diff --cached --name-only` lists at least one non-metadata file, making no-change runs produce zero commits.

`.pyc` files accumulated because Python bytecode appears under `scripts/` and the gitignore in the backup repo only covered the primary repo. The `git ls-files -ci --exclude-standard` step removes any currently-tracked files that match `.gitignore` patterns before the commit, keeping the backup repo clean.

The restore skill was not edited: it reads the backup repo's HEAD and copies whatever files are present, so the new folders appear automatically on the next restore after a backup that included them.

Tests were written before edits, following the red-green-verify structure: each test was confirmed to fail against the unpatched skill before the edits were applied.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `a63d015` | 2026-09-04 | feat(settings-sync): back up what a restore needs and commit only on real change (1.2.0) (#624) |

<!-- generated:end -->

## References

- Plan: [fix-settings-sync-coverage-gaps.md](plans/fix-settings-sync-coverage-gaps.md)
