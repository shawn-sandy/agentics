# Changelog

## v1.2.0 — 2026-09-04 — Back up what a restore needs, commit only real changes

### Added

- **Four new default targets: `agents/`, `output-styles/`, `scripts/`,
  `reference/`.** A coverage audit compared the manifest against a real
  `~/.claude/` and found the files already captured pointing at folders never
  copied: `settings.json` names an `outputStyle` that lives in
  `output-styles/`, its SessionEnd hook runs a script in `scripts/`,
  `CLAUDE.md` links files in `reference/`, and `agents/` holds the user's
  subagents. A restore from that backup looked complete and was not — the
  restored style did not exist and the restored hook pointed at a missing
  file. All four are now in `references/file-manifest.md`, the Step 3 list,
  the copy block, and the stray-entries detector, pinned to each other by
  `tests/plugins/test-settings-sync-manifest-targets.sh`. `settings-restore`
  needs no change: it restores every repo-root entry it finds.
- **Step 2 untracks files the ignore rules already cover.** An ignore rule
  never untracks a file that is already in git, so the four `.pyc` files
  committed before `__pycache__/` was ignored rode along in the real repo
  indefinitely. The new `**Ignore rules and already-tracked files.**` block
  appends any missing rule to `.gitignore`, then runs
  `git ls-files -ci --exclude-standard` through `git rm --cached`, which
  handles `__pycache__/`, `.sync-log`, and any rule added later in one line.
  Working files are untouched.

### Changed

- **A no-change run no longer commits.** Steps 6 and 7 wrote
  `.settings-sync-meta.json` with a fresh timestamp and only then asked
  whether anything had changed, so the answer was always yes: 4,477 of one
  real repo's 4,601 commits changed nothing but that timestamp, and the
  no-change branch committed a timestamped `.sync-log` line on top. The two
  steps are now one `**Commit only real changes.**` block that stages, tests
  `git diff --cached --quiet`, and writes the metadata only inside the
  real-change branch. `.sync-log` is gitignored and stays a local audit trail.
  Pinned by `tests/plugins/test-settings-backup-no-change-commit.sh` (the
  metadata timestamp survives a no-change run) and
  `tests/plugins/test-settings-backup-e2e.sh` (two runs against a fake home
  produce one commit).
- **The copy step is one bash block under `**Copy the targets.**`.** It
  detects rsync, copies the three single files and eight directories with the
  existing `-aL` / `--delete` semantics or the `cp` fallback, honours
  `includeLocalSettings`, quotes every path, and removes single-file targets
  that no longer exist locally — so the e2e test can run the skill's real
  commands instead of a paraphrase.

### Fixed

- **Manifest notes were wrong.** `agents/` was filed under task state, and
  `projects/` claimed memory "lives with each project" when auto-memory lives
  under `~/.claude/projects/*/memory/`. Both notes are corrected; `docs/`,
  `GITHUB_COMMANDS.md`, and the per-project `.claude/launch.json` are now
  listed as excluded with their reasons, and Copy behavior says that a
  symlinked skill folder comes back as a real folder the skills CLI must
  re-link.

---

## v1.1.5 — 2026-09-03 — Fresh-machine install steps and exec-bit false failures

### Fixed

- **README omitted the marketplace step.** The Installation section gave only
  `/plugin install settings-sync@agentics-kit`; on a machine that has never
  added the `agentics-kit` marketplace that command fails and tells you to
  update the marketplace, which is the wrong advice. The section now leads with
  `/plugin marketplace add shawn-sandy/agentics`, and the new-machine section
  says to install the plugin before asking for a restore — without it there is
  no skill to run and the request has nothing to act on.
- **Restore Step 7 reported false failures on interpreter-run hooks.** The
  execute-bit check was a blanket `find ~/.claude/hooks -type f ! -perm -u+x`,
  so a hook invoked as `python3 hook.py` — never executable, in the backup or
  anywhere — was a `FAILED` entry and a perfect restore was reported
  INCOMPLETE. The check now lists the files that are executable in the backup
  and reports only those that are not executable locally. Pinned by
  `tests/plugins/test-settings-restore-exec-bits.sh`, which runs the skill's
  own snippet against a fixture.
- **Backup never surfaced repo-root entries that are no longer targets.** A
  `plans/` directory left by an older version sat in a real backup for six
  weeks: nothing in the skill prunes or mentions root entries outside the
  Step 3 list, and `settings-restore` copies every root entry it finds, so the
  stale directory would have come back on every new machine. Step 5 now lists
  every root entry that is neither a target nor a control file, and Step 8
  reports them under `Not a backup target (left in repo):`. Nothing is deleted
  — a hand-added entry is deliberate; the user removes it or adds it to the
  manifest. Pinned by `tests/plugins/test-settings-backup-stale-entries.sh`.

---

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
