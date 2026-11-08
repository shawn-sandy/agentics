# Make settings-sync back up what a restore actually needs, and stop committing when nothing changed

> Widens the settings-sync manifest to four missing folders (`agents`, `output-styles`, `scripts`, `reference`), corrects two wrong exclusion notes, and reworks the backup skill to commit only when something actually changed — eliminating 97% of timestamp-only noise commits.

<!-- generated:start -->

**Status:** Shipped 2026-09-04  **Plan:** [fix-settings-sync-coverage-gaps.md](plans/fix-settings-sync-coverage-gaps.md)
**Type:** fix

## What shipped

- Added four folders to the backup manifest: `~/.claude/agents/` (custom subagents), `output-styles/` (the style `outputStyle` in `settings.json` names), `scripts/` (scripts referenced by hooks and `statusLine`), and `reference/` (files linked from `CLAUDE.md`). A fresh-machine restore now delivers every folder the restored config references.
- Corrected the exclusion notes: `agents/` was mislabeled as "task state" (it is not); `projects/` note updated to explain that auto-memory lives there and is excluded intentionally.
- Rewrote backup Steps 6–7 into a single `**Commit only real changes.**` block: `git add -A` → `git diff --cached --quiet`; on no change, appends a timestamped no-change line to `.sync-log` (gitignored, local audit trail) and prints `no-change`; on change, writes `.settings-sync-meta.json` after staging, commits, and pushes. This eliminates the timestamp-first-then-check pattern that produced 4,477 of 4,601 commits in the real backup repo changing only the metadata file.
- Added a `**Ignore rules and already-tracked files.**` step (Step 2) that uses `git ls-files -ci --exclude-standard` to untrack any file already in git that the current ignore rules cover — fixing four tracked `.pyc` files in the real backup repo.
- Added `.sync-log` to the ignore-rule list; existing repos untrack it on the next run via the same Step 2 snippet.
- Bumped settings-sync to 1.2.0.
- Added three new test files: `test-settings-backup-e2e.sh` (objective test with a fake home), `test-settings-sync-manifest-targets.sh` (pins the four copies of the target list to each other), and `test-settings-backup-no-change-commit.sh` (pins the commit block's both branches).

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/settings-sync/references/file-manifest.md` | Four new default targets; corrected exclusion notes | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Steps 2, 3, 5, 6–7 rewrite | Modified |
| `kit/plugins/settings-sync/README.md` | Four rows in What gets backed up table | Modified |
| `kit/plugins/settings-sync/CHANGELOG.md` | 1.2.0 entry | Modified |
| `.claude-plugin/marketplace.json` | settings-sync 1.1.5 → 1.2.0 | Modified |
| `tests/plugins/test-settings-backup-e2e.sh` | End-to-end objective test | Created |
| `tests/plugins/test-settings-sync-manifest-targets.sh` | Four-copy target-list consistency check | Created |
| `tests/plugins/test-settings-backup-no-change-commit.sh` | Commit-block both-branches unit test | Created |

## How it works

The plan was structured as red-green-verify because the existing settings-sync tests already extract bash blocks from `SKILL.md` by marker and run them against fixture repos — so failing tests exist before any edit, and the behaviours are real rather than grep theatre.

**Coverage gap**: the manifest's `agents/` exclusion note misclassified user-defined subagents as task state. The four folders were confirmed missing by comparing the manifest against a real `~/.claude/` and an actual backup repo. The restore skill needs no edit — it restores every entry it finds in the repo root, so the four new folders come back for free on a new machine.

**Noise commits**: writing `.settings-sync-meta.json` with a fresh timestamp *before* the change check means every run stages a change and commits it. The fix moves the write to the real-change branch, after `git add -A` and `git diff --cached --quiet` confirm something is staged. `.sync-log` becomes a gitignored local audit trail — appending a timestamped no-change line to it is not a commit.

**Untrack step**: `git ls-files -ci --exclude-standard` lists every tracked file the current ignore rules cover. Piping to `xargs git rm --cached --quiet --` removes the index entries while leaving the working files. This handles both the four tracked `.pyc` files in the real repo and the `.sync-log` file that prior versions committed.

The three test files were written in RED phase (each exits non-zero with a specific assertion failure) before the GREEN edits, following the pattern in `test-settings-backup-stale-entries.sh`. `test-settings-sync-manifest-targets.sh` pins the four copies of the target list (manifest, SKILL.md Step 3, `**Copy the targets.**` block, stray-entries `case` list) to each other so they cannot drift apart.

> See [CHANGELOG v1.2.0](../kit/plugins/settings-sync/CHANGELOG.md) for the authoritative feature list.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `2f8b101` | 2026-10-28 | fix(settings-sync): back up each machine to its own branch (1.3.0) (#662) |
| `a63d015` | 2026-09-04 | feat(settings-sync): back up what a restore needs and commit only on real change (1.2.0) (#624) |
| `28c3d70` | 2026-09-03 | fix(settings-sync): add marketplace step to install docs and stop false exec-bit failures (1.1.5) (#618) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [fix-settings-sync-coverage-gaps.md](plans/fix-settings-sync-coverage-gaps.md)
- Related: [kit/plugins/settings-sync/CHANGELOG.md](../kit/plugins/settings-sync/CHANGELOG.md)
- Related: [kit/plugins/settings-sync/references/file-manifest.md](../kit/plugins/settings-sync/references/file-manifest.md)
