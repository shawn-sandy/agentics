# How do I... settings-sync

Back up and restore your Claude Code user settings through a dedicated git repo.

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install settings-sync@agentics-kit`

## settings-backup

Copies your `~/.claude/` config into a backup git repo, then commits and pushes it.

- **Command** — `/settings-sync:settings-backup [repo-path]`
- **Say it instead** — "back up my Claude Code settings"
- **What happens** — Resolves the repo path from the argument, `~/.claude/settings-sync.json`, or a prompt, then scans `settings.json`, `CLAUDE.md`, `keybindings.json`, `rules/`, `commands/`, `skills/`, and `hooks/` for secrets before copying them in. Commits, writes `.settings-sync-meta.json`, and pushes when a remote exists. Any repo-root entry that is neither a backup target nor a control file — a `plans/` directory left by an older version, say — is listed in the report under `Not a backup target (left in repo)`; nothing is deleted, since a hand-added entry is deliberate.
- **Watch out** — Directory copies use `--delete`, so anything removed locally disappears from the backup; in unattended routine mode a secret-scan hit is only logged to `.sync-log` and the backup proceeds. `settings.local.json` is excluded unless `includeLocalSettings` is `true`.

## settings-restore

Pulls a backup repo and copies the saved settings back into `~/.claude/`.

- **Command** — `/settings-sync:settings-restore [repo-path-or-url]`
- **Say it instead** — "restore my Claude Code settings on this new machine"
- **What happens** — Accepts a local repo path or a clone URL (cloned to `~/.claude-settings-backup`, the bootstrap path for a fresh machine), pulls, and shows an added / modified / unchanged / deleted preview. After you confirm, it copies into `~/.claude/`, verifies every entry, and reports any that failed. The `hooks/` execute-bit check is measured against the backup: only a hook that is executable there and not locally is a `FAILED` entry, so an interpreter-run `python3 hook.py` no longer marks a correct restore INCOMPLETE.
- **Watch out** — Confirmation is mandatory, so it stops rather than run unattended. The restore overwrites `~/.claude/` and deletes local files missing from the backup, plaintext `http://` clone URLs require explicit approval, and restored settings only take effect after restarting Claude Code.
