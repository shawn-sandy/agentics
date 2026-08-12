# Settings Sync — File Manifest

Files and directories to include in backup/restore operations. Both
`settings-backup` and `settings-restore` skills reference this manifest.

## Default targets (always included)

| Source path | Type | Notes |
|-------------|------|-------|
| `~/.claude/settings.json` | File | Core configuration (env vars, permissions, hooks, plugins) |
| `~/.claude/CLAUDE.md` | File | Global AI assistant instructions |
| `~/.claude/keybindings.json` | File | Custom keyboard shortcuts |
| `~/.claude/rules/` | Directory | Rule files with path-scoped instructions (recursive) |
| `~/.claude/commands/` | Directory | User-created custom commands (recursive) |
| `~/.claude/skills/` | Directory | User-created custom skills (recursive) |
| `~/.claude/hooks/` | Directory | Hook scripts referenced by `settings.json` — without these, restored hooks point at missing files |

## Opt-in targets

| Source path | Type | Opt-in flag | Notes |
|-------------|------|-------------|-------|
| `~/.claude/settings.local.json` | File | `"includeLocalSettings": true` in `settings-sync.json` | Machine-specific overrides — excluded by default |

## Excluded (never backed up)

These are auto-generated, machine-specific, or reinstallable:

- `~/.claude/sessions/` — session transcripts and metadata
- `~/.claude/history.jsonl` — command history
- `~/.claude/cache/`, `~/.claude/paste-cache/` — transient caches
- `~/.claude/daemon.*` — daemon process state
- `~/.claude/plugins/` — installed plugins (reinstallable from marketplaces)
- `~/.claude/projects/` — project-specific memory (lives with each project)
- `~/.claude/usage-data/`, `telemetry/`, `stats/` — analytics
- `~/.claude/tasks/`, `plans/`, `teams/`, `agents/`, `todos/`, `jobs/` — task state
- `~/.claude/ide/`, `debug/`, `backups/`, `downloads/` — system directories
- `~/.claude/security_warnings_state_*.json` — per-session security state

## Copy behavior

- **Symlinks**: follow and copy resolved content (`cp -aL` / `rsync -aL`)
- **Missing sources**: skip silently — not every user has all targets
- **Permissions**: preserve source permissions (`-a` flag on both cp and rsync)
- **Path safety**: always quote paths in shell commands
