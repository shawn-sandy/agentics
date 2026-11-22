# Fix settings-sync coverage gaps

> A restore from a settings-sync backup handed you a settings.json, CLAUDE.md, and hook set that pointed at four folders the backup never copied — and the backup repo's history was 97 percent timestamp-only commits. This widens the manifest to include the four missing folders and reworks the backup to commit only on real change.

<!-- generated:start -->

**Status:** Shipped 2026-09-04 **Plan:** [fix-settings-sync-coverage-gaps.md](plans/fix-settings-sync-coverage-gaps.md)
**Type:** fix

## What shipped

- Updated `references/file-manifest.md`: added four new default backup targets (`agents/`, `output-styles/`, `scripts/`, `reference/`); corrected the two wrong exclusion notes; added a Copy behavior bullet noting that symlinked skill folders are copied as real directories and the skills CLI must re-link them on a new machine.
- Updated `skills/settings-backup/SKILL.md`: Step 2 gains an untrack snippet (`git ls-files -ci --exclude-standard`) that removes already-tracked files the current ignore rules cover (e.g. `.pyc` files, `.sync-log`); Step 3 and Step 5 name the four new folders; Steps 6 and 7 collapsed into one `**Commit only real changes.**` block that writes `.settings-sync-meta.json` only after a real change is staged, keeping `.sync-log` local and gitignored.
- Updated `README.md`: four new rows in the What gets backed up table; Components paragraph updated to note that no-change runs are logged locally and never committed.
- Added `tests/plugins/test-settings-backup-e2e.sh`: builds a fake home, runs the three SKILL.md blocks twice, asserts the four new folders land in the scratch repo, no `.pyc` or `.sync-log` are tracked, commit count is 2 after first run and still 2 after an unchanged second run, and `.sync-log` has one line.
- Added `tests/plugins/test-settings-sync-manifest-targets.sh`: pins the four copies of the target list (manifest Default targets, SKILL.md Step 3, Copy block, stray-entries `case` list) to each other so they cannot drift.
- Added `tests/plugins/test-settings-backup-no-change-commit.sh`: tests the commit block in isolation — no change leaves count and meta timestamp untouched; a changed file adds one commit and refreshes the timestamp.
- Bumped settings-sync to 1.2.0; updated CHANGELOG.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/settings-sync/references/file-manifest.md` | Four targets + corrected notes | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Untrack + four folders + commit-only-on-change | Modified |
| `kit/plugins/settings-sync/README.md` | Four table rows + no-change wording | Modified |
| `kit/plugins/settings-sync/CHANGELOG.md` | 1.2.0 entry | Modified |
| `tests/plugins/test-settings-backup-e2e.sh` | End-to-end backup smoke test | Created |
| `tests/plugins/test-settings-sync-manifest-targets.sh` | Target list drift check | Created |
| `tests/plugins/test-settings-backup-no-change-commit.sh` | Commit-only-on-change unit test | Created |
| `.claude-plugin/marketplace.json` | settings-sync → 1.2.0 | Modified |

## How it works

**Missing folders**: `agents/`, `output-styles/`, `scripts/`, and `reference/` are referenced by the files a backup already copies (settings.json, CLAUDE.md, hooks), so a restore without them is incomplete. The manifest's exclusion list incorrectly labelled `agents/` as task state; it now correctly lists it as user-defined subagents.

**Noise commits**: The backup wrote `.settings-sync-meta.json` with a fresh timestamp before checking whether anything changed, guaranteeing a commit on every run regardless of content. The new commit block runs `git add -A` first, checks `git diff --cached --quiet`, and only writes the metadata file (and commits) when something is actually staged.

**Tracked junk**: `.pyc` files and `.sync-log` entries that were already in the index are removed by `git ls-files -ci --exclude-standard | xargs git rm --cached --quiet --`. Working files are not deleted; only the git index entries are removed.

**Restore unchanged**: The restore skill reads the repo root and restores everything it finds, so the four new folders come back on a new machine for free — no edit to restore was needed.

## How to use it

No invocation change needed. The improvements apply automatically on the next backup run after updating to 1.2.0.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-09-04 | fix(settings-sync): widen manifest to four missing folders, commit only on real change (1.2.0) (#622) |

<!-- generated:end -->

## References

- Plan: [fix-settings-sync-coverage-gaps.md](plans/fix-settings-sync-coverage-gaps.md)
