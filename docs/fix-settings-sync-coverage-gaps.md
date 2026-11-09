# Make settings-sync back up what a restore actually needs, and stop committing when nothing changed

> A restore from today's settings-sync backup hands you a settings.json, a CLAUDE.md, and a hook set that point at four folders the backup never copied; this adds those folders and stops committing when nothing changed.

<!-- generated:start -->

**Status:** Shipped 2026-09-04  **Plan:** [fix-settings-sync-coverage-gaps.md](plans/fix-settings-sync-coverage-gaps.md)
**Type:** fix

## What shipped

- Added four missing backup targets to `settings-backup/SKILL.md` and `references/file-manifest.md`: `~/.claude/agents/` (custom subagents), `output-styles/` (styles named by `settings.json outputStyle`), `scripts/` (scripts referenced by hooks), and `reference/` (files linked from CLAUDE.md) — so a fresh-machine restore gets every folder its restored config references.
- Rewrote the commit logic so `.settings-sync-meta.json` is written only after a real change is staged; no-change runs append a timestamped line to `.sync-log` (gitignored) and commit nothing (eliminating the 97% timestamp-only noise in real backup repos).
- Added an untrack snippet (`git ls-files -ci --exclude-standard`) that removes already-tracked files covered by ignore rules (fixing previously tracked `.pyc` and `.sync-log` entries) without deleting working files.
- Corrected the `agents/` exclusion note (it was wrongly labelled task state), updated the `projects/` exclusion note, and expanded the Excluded list with reasons for `docs/`, `GITHUB_COMMANDS.md`, and `.claude/launch.json`.
- Shipped three new shell tests pinning the behaviour: `test-settings-backup-e2e.sh`, `test-settings-sync-manifest-targets.sh`, and `test-settings-backup-no-change-commit.sh`.
- Bumped settings-sync from 1.1.5 to 1.2.0 (minor, because the backup set grew).

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/settings-sync/references/file-manifest.md` | Backup manifest — four new targets, corrected exclusion notes | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Backup skill — untrack snippet, four new folders, commit-only-on-change | Modified |
| `kit/plugins/settings-sync/README.md` | Plugin README — four new rows, no-change wording | Modified |
| `kit/plugins/settings-sync/CHANGELOG.md` | Changelog — 1.2.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — settings-sync 1.1.5 → 1.2.0 | Modified |
| `tests/plugins/test-settings-backup-e2e.sh` | E2E objective test — fake home backed up twice | Created |
| `tests/plugins/test-settings-sync-manifest-targets.sh` | Unit test — pins four copies of the target list | Created |
| `tests/plugins/test-settings-backup-no-change-commit.sh` | Unit test — commit block, both branches | Created |

## How it works

The coverage audit compared the plugin's file manifest against a real `~/.claude/` directory and found the restore skill was functionally incomplete: captured files in `settings.json` and `CLAUDE.md` referenced `agents/`, `output-styles/`, `scripts/`, and `reference/` — but none of those directories were in the backup manifest. A restored machine would have working config pointing at directories that did not exist.

The fix adds all four to the Default targets table in `references/file-manifest.md` and to the `**Copy the targets.**` bash block in `settings-backup/SKILL.md`. The restore skill needed no change because it reads the repo root and restores whatever it finds there.

The noise-commit problem was structural. The old skill wrote `.settings-sync-meta.json` with a fresh timestamp before checking whether anything had changed, so every run staged that file and committed. The rewrite moves the metadata write to inside the real-change branch: only after `git add -A` and `git diff --cached --quiet` confirm something is staged does the skill write the timestamp and commit. No-change runs append one line to `.sync-log`, which is gitignored, so a repo that ran the skill 4,000 times can recover a meaningful `git log`.

The untrack snippet (`git ls-files -ci --exclude-standard -z | xargs -0 git rm --cached --quiet --`) is added to Step 2 and runs on every backup. It removes index entries for files that current ignore rules cover — the mechanism that caused `.pyc` and `.sync-log` files to accumulate in real backup repos. Working files are not deleted; only the index entry is removed.

Three tests use the established pattern from `test-settings-backup-stale-entries.sh`: extract a marked bash block from `SKILL.md` by keyword and execute it against a fixture directory. `test-settings-backup-e2e.sh` builds a throwaway home with all seven original targets plus the four new ones, runs the full backup sequence twice, and asserts the commit count is 2 after run one and still 2 after run two. `test-settings-backup-no-change-commit.sh` isolates the commit block specifically to prove the metadata timestamp is unchanged on a no-change run.

## How to use it

Install or update `settings-sync` from the marketplace:
```text
/plugin install settings-sync@agentics-kit
```

The backup skill picks up the four new directories automatically on the next run. The settings-restore skill already restores everything it finds in the repo root, so no change to the restore workflow is needed.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| a63d015 | 2026-09-04 | feat(settings-sync): back up what a restore needs and commit only on real change (1.2.0) (#624) |

<!-- generated:end -->

## References

- Plan: [fix-settings-sync-coverage-gaps.md](plans/fix-settings-sync-coverage-gaps.md)
