# Changelog

## v1.1.4 — 2026-08-17 — Plan-mode guard on backup and restore

### Changed

- **`settings-backup` and `settings-restore` carry the plan-mode guard.** Both
  skills run `rm -rf`/`rsync --delete` semantics but had no Step 0 exit from
  plan mode, so a plan-mode invocation could stall or narrate the mutation
  instead of performing it. Each now opens with the verbatim guard line
  required by `plugin-patterns.md`, lists `ToolSearch, ExitPlanMode` in
  `allowed-tools`, and is enforced by the WRITE_HEAVY manifest in
  `tests/plugins/test-exitplanmode-guard.sh`. Flagged in the 2026-08-17 audit.

---

## v1.1.3 — 2026-08-17 — Restore is verified, not assumed

### Changed

- **`settings-restore` gains Step 7 — Verify the restore.** The skill
  overwrites `~/.claude/` with `rm -rf`/`rsync --delete` semantics but
  reported "Restored: N files" from the planning step, never from
  re-comparison — a failed rsync entry, a `cp` error that scrolled past, or a
  hook script restored without its execute bit read as a complete restore.
  The new gate re-runs the Step 4 comparison for every restored entry
  (files via `diff -q`, directories via the same find-based classification),
  requires everything to compare identical, and explicitly checks
  `~/.claude/hooks` for lost execute bits (non-executable hooks are silently
  inert). The report is reachable only through the gate: failures lead with
  `Restore INCOMPLETE — verification failed for <n> of <total> entries.` and
  success says "restored and verified" with counts from verified results
  only.

---

## v1.1.2 — 2026-08-17 — Secret scan on every backup

### Security

- **The backup secret scan runs on every backup, not just the first.** It was
  gated on "repo has no prior commits", so a token added to `settings.json` (or
  a hook script) after the initial commit was pushed unattended on every
  subsequent routine run with no scan and no warning. The scan now covers every
  source in the Step 3 file list on every run, its pattern list is extended
  (GitHub fine-grained PATs, GitLab, Stripe, Google, Slack webhooks), and in
  routine mode the `.sync-log` entry records the matched pattern and file path
  so an exposure is discoverable rather than silent.

---

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
