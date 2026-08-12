# Changelog

## v1.1.1 — 2026-08-12 — Fix 1.1.0 release defects and harden the clone path

### Fixed

- **Changelog structure.** The 1.1.0 entry absorbed v1.0.2's heading, leaving a
  duplicate `### Fixed` section and erasing the v1.0.2 release. Heading restored.
- **Root README plugin inventory** regenerated — it still advertised 1.0.2 after
  the 1.1.0 bump.
- **Restore's deletion warning is now built from the same dynamic list Step 6
  copies.** It named only `rules/`, `commands/`, and `skills/`, so `hooks/` —
  and any other directory in the backup — could be `--delete`d without ever
  appearing in the confirmation preview.

### Security

- `http://` clone URLs are rejected unless the user explicitly confirms.
  Restored `hooks/` scripts execute on next start, so plaintext transport is a
  code-injection path, not just an eavesdropping one.
- Clone URLs are redacted once at parse time and the redacted form is used in
  every diagnostic and `.sync-log` entry; the original reaches `git clone` only.
  A token embedded in the URL was otherwise echoed verbatim — not just by clone
  failures but by the "directory already exists" error, which fires before any
  clone is attempted. Redaction is scoped to the authority, so an `@` in a path
  or query is left alone.
- Repo entry names are validated as plain relative names before they reach
  `rm -rf` or `rsync --delete`.

---

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

---

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
