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
| `~/.claude/agents/` | Directory | User-defined subagents (recursive) |
| `~/.claude/output-styles/` | Directory | Custom output styles — `settings.json` names one via `outputStyle`, so a restore without this folder points at a style that does not exist |
| `~/.claude/scripts/` | Directory | Scripts referenced by `settings.json` hooks and `statusLine` — without these, a restored hook runs a missing file |
| `~/.claude/reference/` | Directory | Files linked by path from `CLAUDE.md` and hooks |

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
- `~/.claude/projects/` — auto-memory lives here, not in the project repo; excluded for now, an opt-in copy is planned
- `~/.claude/usage-data/`, `telemetry/`, `stats/` — analytics
- `~/.claude/tasks/`, `plans/`, `teams/`, `todos/`, `jobs/` — task state
- `~/.claude/docs/` — user content (plans, notes), not configuration; `plansDirectory` is project-scoped
- `~/.claude/GITHUB_COMMANDS.md` — a personal notes file that Claude Code never reads
- `.claude/launch.json` (per project) — Browser-pane dev-server config, project-scoped, lives in each repo
- `~/.claude/ide/`, `debug/`, `backups/`, `downloads/` — system directories
- `~/.claude/security_warnings_state_*.json` — per-session security state

## Copy behavior

- **Symlinks**: follow and copy resolved content (`cp -aL` / `rsync -aL`)
- **Symlinked skill folders**: a skill the skills CLI installed elsewhere and linked into `~/.claude/skills/` is copied as a real folder; it works after restore, but the CLI no longer tracks it, so re-link it on a new machine
- **Missing sources**: skip silently — not every user has all targets
- **Permissions**: preserve source permissions (`-a` flag on both cp and rsync)
- **Path safety**: always quote paths in shell commands
