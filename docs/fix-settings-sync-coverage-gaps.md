# Make settings-sync back up what a restore actually needs, and stop committing when nothing changed

> Widens the settings-sync backup manifest to four missing folders (agents, output-styles, scripts, reference), fixes noise commits caused by writing metadata before checking for changes, and untracks already-ignored files.

<!-- generated:start -->

**Status:** Shipped 2026-09-04  **Plan:** [fix-settings-sync-coverage-gaps.md](plans/fix-settings-sync-coverage-gaps.md)
**Type:** fix

## What shipped

- Added four default backup targets to `references/file-manifest.md`: `~/.claude/agents/` (custom subagents), `~/.claude/output-styles/` (named styles), `~/.claude/scripts/` (hook scripts), and `~/.claude/reference/` (files linked from CLAUDE.md).
- Corrected the manifest's exclusion notes: removed the wrong `agents/` task-state label and the stale "lives with each project" note.
- Rewrote the `settings-backup` SKILL.md commit block so `.settings-sync-meta.json` is written only after a real change is staged (`git diff --cached --quiet` exits non-zero). The old pattern wrote the metadata timestamp unconditionally, causing 4,477 of 4,601 real-repo commits to be timestamp-only noise.
- Made `.sync-log` a local, gitignored audit trail — no-change runs append a timestamped line to it without committing.
- Added an untrack step using `git ls-files -ci --exclude-standard` to remove already-ignored files (e.g. `.pyc` files) from the index without deleting them from disk.
- Bumped settings-sync from 1.1.5 to 1.2.0 in `.claude-plugin/marketplace.json`.
- Shipped three new tests: `test-settings-backup-e2e.sh`, `test-settings-sync-manifest-targets.sh`, and `test-settings-backup-no-change-commit.sh`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/settings-sync/references/file-manifest.md` | Backup manifest | Modified |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Backup skill | Modified |
| `kit/plugins/settings-sync/README.md` | Plugin documentation | Modified |
| `kit/plugins/settings-sync/CHANGELOG.md` | 1.2.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Version bump | Modified |
| `tests/plugins/test-settings-backup-e2e.sh` | End-to-end objective test | Created |
| `tests/plugins/test-settings-sync-manifest-targets.sh` | Manifest consistency test | Created |
| `tests/plugins/test-settings-backup-no-change-commit.sh` | No-change commit test | Created |

## How it works

The four missing folders were discovered by comparing the plugin's file manifest against a real `~/.claude/` directory: `agents/` holds subagents the restored `settings.json` references, `output-styles/` holds styles named by the `outputStyle` key, `scripts/` holds scripts that hook and statusLine entries point at, and `reference/` holds files CLAUDE.md links by path. A restore from the old manifest would look complete but leave dangling references.

The commit-noise fix is the mechanism change: `.settings-sync-meta.json` is now written only inside the `git diff --cached --quiet` non-zero branch — meaning only when something else was already staged. Writing the timestamp before the check guaranteed a commit on every run regardless of actual content change. The `.sync-log` file stays local to give operators a timestamped trail without polluting git history.

The untrack step (`git ls-files -ci --exclude-standard | xargs git rm --cached`) generalizes to any current or future ignore rule. The four `.pyc` files tracked in the real backup repo persisted because an ignore rule added after the first commit never untracked them; this fix handles that on the next backup run.

The tests follow the `test-settings-backup-stale-entries.sh` pattern: extract bash blocks from SKILL.md by marker and run them against fixture repos. This means the tests exercise the skill's real commands, not a paraphrase.

The restore skill required no edits — it reads every entry in the repo root, so the four new folders restore for free on a new machine.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `2f8b101b` | 2026-10-28 | fix(settings-sync): back up each machine to its own branch (1.3.0) (#662) |
| `a63d0156` | 2026-09-04 | feat(settings-sync): back up what a restore needs and commit only on real change (1.2.0) (#624) |
| `28c3d704` | 2026-09-03 | fix(settings-sync): add marketplace step to install docs and stop false exec-bit failures (1.1.5) (#618) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [fix-settings-sync-coverage-gaps.md](plans/fix-settings-sync-coverage-gaps.md)
