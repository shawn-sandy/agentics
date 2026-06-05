# Changelog

## v1.0.2 — 2026-06-05 — Use portable plugin-dir path in README

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
