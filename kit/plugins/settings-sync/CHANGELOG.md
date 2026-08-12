# Changelog

## v1.1.0 — 2026-08-12 — Restore onto a new machine

### Added

- `settings-restore` accepts a **clone URL** as well as a local path. On a new
  machine — where no local backup repo exists — the URL is cloned to
  `~/.claude-settings-backup` and restored from there. Previously the skill
  hard-stopped, since all three resolution paths required an existing local repo.
- `~/.claude/hooks/` is now a default backup target. `settings.json` references
  hook scripts by path, so restoring settings without them left every hook
  pointing at a missing file.
- `__pycache__/` added to the `.gitignore` rules. Backup now appends missing
  rules to an existing `.gitignore` rather than only writing one when absent —
  every pre-`hooks/` repo already has the file, so a create-only check would
  have committed `hooks/__pycache__`.

### Changed

- `settings-restore` builds its file list from the repo root (minus `.git/`,
  `.gitignore`, `.sync-log`, and `.settings-sync-meta.json`) instead of a
  hardcoded six-target list. Whatever is in the backup now comes back, so the
  two skills can no longer drift apart. Verified against a real backup repo
  where the old list stranded four directories: `plans/`, `reference/`,
  `scripts/`, and `vscode/`.

### Fixed

- The "not a git repo" error no longer suggests running `settings-backup` to
  recover. On a new machine that would have overwritten the remote backup with
  an empty local config.

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/settings-sync` path instead of an author-specific home directory.

---

## v1.0.1 — README: sync usage documentation with current skill behavior

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## 1.0.0 (2026-05-18)

- Initial release
- `settings-backup` skill: back up Claude Code settings to a dedicated git repo
- `settings-restore` skill: restore settings from a backup repo
- Routine-compatible backup (no interactive prompts when repo path is configured)
- rsync with cp fallback for portability
- Secret scanning before first commit
- Sync log for no-change audit trail
- Metadata file (`.settings-sync-meta.json`) with hostname and timestamps
- `settings.local.json` excluded by default (opt-in via config)
