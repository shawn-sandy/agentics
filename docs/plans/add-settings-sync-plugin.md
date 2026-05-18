---
status: completed
type: feature
created: 2026-05-18
---

# Plan: Add settings-sync plugin with backup and restore skills

## Context

Claude Code user settings (`~/.claude/settings.json`, `CLAUDE.md`, `rules/`, `keybindings.json`, custom commands/skills) are local to each machine. There's no built-in way to back them up to a git repo or restore them on a new machine. A plugin with two skills — one for backup, one for restore — would let users version-control their settings and sync across machines. The backup skill must work unattended as a Claude routine (cron-scheduled).

## Objective

Create a `settings-sync` plugin with two skills (`settings-backup` and `settings-restore`) that copy user-authored Claude settings to/from a dedicated git repo, with full routine compatibility for automated backups.

## Files to back up

| Source | Type | Default |
|--------|------|---------|
| `~/.claude/settings.json` | Core config | Included |
| `~/.claude/CLAUDE.md` | Global instructions | Included |
| `~/.claude/keybindings.json` | Key bindings | Included |
| `~/.claude/rules/` | Rule files (recursive) | Included |
| `~/.claude/commands/` | Custom commands | Included |
| `~/.claude/skills/` | Custom skills | Included |
| `~/.claude/settings.local.json` | Local overrides | **Excluded** (opt-in via `"includeLocalSettings": true` in `settings-sync.json`) |

## Steps

1. **Create plugin scaffold** at `kit/plugins/settings-sync/` — plugin.json, README.md, CHANGELOG.md, and two skill directories. *Why:* establishes the standard plugin structure. *Verify:* `ls kit/plugins/settings-sync/.claude-plugin/plugin.json` succeeds and JSON is valid.

2. **Write `settings-backup` skill** at `kit/plugins/settings-sync/skills/settings-backup/SKILL.md`. *Why:* the primary skill — copies settings to a git repo, commits, and pushes. *Verify:* frontmatter has `name`, `description`, `allowed-tools`; body follows numbered-step pattern; skill is under 500 lines.

   Skill behavior:
   - Accepts optional argument: repo path (e.g., `~/dotfiles/claude-settings`)
   - If no argument, reads stored path from `~/.claude/settings-sync.json`
   - If neither exists, prompts user for path and saves it (interactive only)
   - Validates target is a git repo (or offers to `git init`); creates `.gitignore` (`.DS_Store`, `*.swp`) on first setup
   - Checks for `rsync`; falls back to `cp -rL` + `mkdir -p` when absent
   - Follows symlinks and copies resolved content (backups are self-contained)
   - Scans `settings.json` for common secret patterns (`sk-`, `ghp_`, `AKIA`) and warns before first commit
   - Writes `.settings-sync-meta.json` with machine hostname, backup timestamp, and Claude Code version
   - If no changes since last backup, writes a timestamped "no changes" entry to `.sync-log` (audit trail for routine runs)
   - Commits with message: `backup: Claude settings YYYY-MM-DD HH:MM`
   - Pushes to remote (if remote exists); on push conflict, fails and reports — does not auto-resolve
   - Routine-safe: no `AskUserQuestion` when repo path is known

3. **Write `settings-restore` skill** at `kit/plugins/settings-sync/skills/settings-restore/SKILL.md`. *Why:* the complement — pulls from repo and copies settings back to `~/.claude/`. *Verify:* frontmatter complete; includes confirmation step before overwriting; body under 500 lines.

   Skill behavior:
   - Accepts optional argument: repo path
   - Falls back to `~/.claude/settings-sync.json`, then prompts
   - Pulls latest from remote (if remote exists)
   - Shows file-level diff summary (added/modified/unchanged/deleted) — no content diffs unless requested
   - Asks user to confirm before overwriting (always interactive — restore is destructive)
   - Follows symlinks in source; copies resolved content
   - Copies files from repo to `~/.claude/`, creating directories as needed
   - Warns that restored settings take effect after restarting Claude Code
   - Reports what was restored

4. **Create shared reference file** `kit/plugins/settings-sync/references/file-manifest.md` listing the exact files/dirs to sync with copy include/exclude patterns. *Why:* keeps the manifest maintainable and separate from skill logic; both skills reference the same file at the plugin root. *Verify:* file lists all 6 default backup targets plus the opt-in `settings.local.json`.

5. **Register in marketplace.json** — add the `settings-sync` plugin entry to `.claude-plugin/marketplace.json` with version `1.0.0`, category `productivity`, and relevant tags. *Why:* makes the plugin installable via the marketplace. *Verify:* `cat .claude-plugin/marketplace.json | python3 -m json.tool` passes; plugin entry has all required fields.

6. **Bump marketplace version** from `3.4.0` to `3.5.0` in `.claude-plugin/marketplace.json`. *Why:* new plugin = minor version bump per versioning rules. *Verify:* top-level `"version"` field reads `"3.5.0"`.

## Acceptance Criteria

- [ ] `settings-backup` copies all 6 default file targets to a git repo, commits, and pushes without user interaction when repo path is configured
- [ ] `settings.local.json` is excluded by default; included only when `"includeLocalSettings": true` is set in `settings-sync.json`
- [ ] `settings-restore` pulls from repo, shows a file-level diff summary, confirms with user, then copies files to `~/.claude/`
- [ ] `settings-restore` warns that changes take effect after restarting Claude Code
- [ ] Both skills handle missing files gracefully (e.g., no `keybindings.json` doesn't error)
- [ ] Both skills follow symlinks and copy resolved content
- [ ] Backup skill checks for rsync and falls back to cp when absent
- [ ] Backup skill warns about potential secrets in `settings.json` before first commit
- [ ] Backup skill writes `.settings-sync-meta.json` and logs no-change runs to `.sync-log`
- [ ] Push conflicts fail and report rather than auto-resolving
- [ ] Repo path persists in `~/.claude/settings-sync.json` after first use
- [ ] `settings-backup` is routine-compatible: works with zero interactive prompts when path is configured
- [ ] Plugin installs cleanly via `/plugin marketplace add shawn-sandy/agentics` then `/plugin install settings-sync@agentics-kit`
- [ ] Both skills are under 500 lines each
- [ ] marketplace.json is valid JSON after changes

## Verification

1. Load plugin locally: `claude --plugin-dir ./kit/plugins/settings-sync`
2. Create a temp git repo: `git init /tmp/test-claude-backup`
3. Run backup: trigger "backup my claude settings to /tmp/test-claude-backup"
4. Verify files appear in repo: `ls /tmp/test-claude-backup/` shows settings.json, CLAUDE.md, rules/, etc.
5. Verify commit exists: `git -C /tmp/test-claude-backup log --oneline -1` shows backup commit
6. Modify a setting, re-run backup, verify new commit
7. Delete a local file (e.g., keybindings.json), run restore, verify it's restored
8. Validate marketplace: `python3 -m json.tool .claude-plugin/marketplace.json`

## Key Design Decisions

- **rsync with cp fallback**: prefer rsync for cleaner handling, but fall back to `cp -rL` + `mkdir -p` when rsync isn't installed — keeps the skill portable across minimal Linux installs and WSL
- **Exclude `settings.local.json` by default**: machine-specific overrides are not backed up unless explicitly opted in via `"includeLocalSettings": true` in `settings-sync.json`
- **Config file only**: `~/.claude/settings-sync.json` is the single source for the repo path — no environment variable support, no ambiguity about precedence
- **Push conflicts fail and report**: don't auto-resolve with rebase or force push — report the conflict and let the user handle it manually
- **Follow symlinks**: resolve and copy symlink targets so backups are self-contained and portable across machines
- **Sync log for no-change runs**: write a timestamped entry to `.sync-log` in the backup repo when nothing changed, providing an audit trail that routines actually ran
- **Minimal metadata**: `.settings-sync-meta.json` with hostname, timestamp, and Claude Code version — enough for debugging without bloating the repo
- **File-level diff on restore**: show added/modified/unchanged/deleted list, not content diffs — quick to scan, sufficient for a confirm/deny decision
- **Two skills, not one**: backup can be scheduled as a routine without pulling in restore logic; restore always requires human confirmation
- **No backup of auto-generated files**: sessions, caches, daemon state, telemetry, and installed plugins are excluded — they're machine-specific or reinstallable

## Files to create/modify

| Path | Action |
|------|--------|
| `kit/plugins/settings-sync/.claude-plugin/plugin.json` | Create |
| `kit/plugins/settings-sync/README.md` | Create |
| `kit/plugins/settings-sync/CHANGELOG.md` | Create |
| `kit/plugins/settings-sync/skills/settings-backup/SKILL.md` | Create |
| `kit/plugins/settings-sync/skills/settings-restore/SKILL.md` | Create |
| `kit/plugins/settings-sync/references/file-manifest.md` | Create (shared by both skills) |
| `.claude-plugin/marketplace.json` | Modify (add plugin, bump version) |

## Next Steps *(optional)*

- Add a `settings-diff` skill to compare local vs backed-up settings:
  ```text
  Create a third skill in the settings-sync plugin at
  kit/plugins/settings-sync/skills/settings-diff/SKILL.md that compares
  the current ~/.claude/ settings against the backup repo and reports
  differences without making changes. Use diff or rsync --dry-run.
  ```

- Schedule automated backup routine:
  ```text
  Set up a Claude routine that runs settings-backup daily. The routine
  prompt should be: "Back up my Claude settings to <repo-path>". Use
  /schedule to create it with a daily cron expression.
  ```

## Interview Summary

*Conducted 2026-05-18 — 2 rounds (Technical & Trade-offs, Edge Cases)*

### Key Decisions Confirmed

- **rsync with cp fallback**: check for rsync availability; fall back to `cp -rL` + `mkdir -p` when absent
- **Exclude `settings.local.json` by default**: machine-specific overrides not backed up unless user sets `"includeLocalSettings": true` in `settings-sync.json`
- **Config file only**: `~/.claude/settings-sync.json` is the single source for repo path — no env var support
- **Push conflicts fail and report**: don't auto-resolve — report the conflict and let the user handle it
- **No-change runs log to `.sync-log`**: timestamped entry in backup repo provides audit trail for routine runs
- **Follow symlinks**: resolve and copy targets so backups are self-contained and portable
- **File-level diff on restore**: show added/modified/unchanged/deleted list — no content diffs unless requested
- **Minimal metadata**: `.settings-sync-meta.json` with machine hostname, backup timestamp, Claude Code version

### Open Risks & Concerns

- **Secret exposure**: `settings.json` env vars may contain API keys — skill should scan for common secret patterns (`sk-`, `ghp_`, `AKIA`) and warn before first commit
- **Active session**: restored settings won't take effect until Claude Code is restarted — restore skill must warn the user
- **Shared reference file**: file manifest moved to plugin root (`references/file-manifest.md`) so both skills reference the same source

### Recommended Next Steps

1. Rename plan file from random name to `add-settings-sync-plugin.md`
2. Implement per the updated plan

### Simplification Opportunities

None identified — scope and abstractions are well-matched to the problem.
