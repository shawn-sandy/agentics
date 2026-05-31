---
status: todo
type: chore
created: 2026-05-29
repo-name: agentics
---

# Plan: Run Claude settings backup (settings-sync routine)

## Context

The `settings-sync:settings-backup` skill fired as a session-end (Stop hook)
routine. It is a deterministic write routine — copy user config → commit →
push — not an open-ended coding task. Per the global plan-mode rule (Step 0) and the
project memory note "Skill invocation must not use plan mode", write-operation
skills should execute directly rather than go through the multi-phase plan
workflow. Plan mode was nonetheless active, so this short plan documents the
fixed steps and then exits plan mode so the routine can run.

## Objective

Back up user-authored Claude Code settings to the configured git repo and push,
following the skill's defined steps with no deviation.

## Pre-resolved state (read-only checks already done)

- Repo path: `/Users/shawnsandy/claude-settings-backup` (from `~/.claude/settings-sync.json`)
- Directory exists; is a git repo; remote `origin` → `github.com/shawn-sandy/claude-settings-backup.git`
- Has prior commits (`1f8b317`) → **not** first backup, so the secret scan (Step 4) is skipped
- `includeLocalSettings: false` → `settings.local.json` excluded

## Steps

1. **Build file list** — Sources (skip silently if missing): `~/.claude/settings.json`,
   `CLAUDE.md`, `keybindings.json`, `rules/`, `commands/`, `skills/`.
   - *Why:* These are the user-authored config the manifest backs up. *Verify:* each source's existence is checked before copy.

2. **Copy into the repo** — rsync if available (`-aL` for single files, `-aL --delete` for the three dirs); cp fallback otherwise. Remove repo-side single-file targets that no longer exist locally.
   - *Why:* Mirror current local state into the backup. *Verify:* `git -C <repo> status --porcelain` reflects the copied files.

3. **Write metadata** — Write `.settings-sync-meta.json` (hostname, UTC timestamp, claude version, files included) to the repo root.
   - *Why:* Records provenance of each backup. *Verify:* file present with populated fields.

4. **Commit + push** — `git add -A`; if changes, commit via a short-lived `backup/<date-time>` branch fast-forwarded into the default branch, then `git push`. If no changes, append a `.sync-log` entry instead. On push conflict, stop and report (no auto-resolve).
   - *Why:* Versioned, conflict-safe backup. *Verify:* push succeeds, or clean "no changes" / clear conflict message.

5. **Report** — Print summary: repo, files backed up, skipped, commit hash + message, push status.
   - *Why:* Confirms outcome to the user. *Verify:* summary block emitted.

## Verification

- `git -C /Users/shawnsandy/claude-settings-backup log --oneline -1` shows the new backup commit (or `.sync-log` updated if nothing changed).
- `git -C /Users/shawnsandy/claude-settings-backup status` is clean afterward.
- Remote push reported as `yes` (or a clear conflict message if the remote moved).
