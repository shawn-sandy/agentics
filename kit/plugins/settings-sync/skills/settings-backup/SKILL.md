---
name: settings-backup
description: "Backs up Claude Code user settings to a git repo. Commits and pushes config files unattended; routine-compatible. Use when the user asks to back up or sync their Claude Code settings."
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
argument-hint: "[repo-path]"
---

# Settings Backup

Back up Claude Code user settings to a dedicated git repository. Copies
user-authored configuration files, commits, and pushes. Designed to run
unattended as a Claude routine when the repo path is configured.

## When not to use

- To restore settings from a backup — use `settings-restore` instead.
- To compare local vs backed-up settings without changing anything.

## Reference

Load `references/file-manifest.md` from the plugin root for the complete list
of files to back up, opt-in targets, and exclusions.

## Steps

### Step 1 — Resolve the backup repo path

Determine the target repo using this priority order:

1. **Argument**: if the user provided a path (via `$ARGUMENTS` or in their
   message), expand `~` and use it directly.
2. **Config file**: read `~/.claude/settings-sync.json`. If it exists and
   contains a `"repoPath"` key, use that value.
3. **Interactive prompt**: if neither is available, use `AskUserQuestion` to ask
   the user for the repo path. If `AskUserQuestion` is unavailable (routine /
   unattended context), output: "No repo path configured. Set `repoPath` in
   `~/.claude/settings-sync.json` or pass a path argument." and **STOP**.

Once resolved, expand `~` to the full home directory path and confirm the
directory exists. If it does not exist:

- **Interactive**: ask the user if they'd like to create it with `mkdir -p`.
- **Routine / unattended**: output: "Repo directory does not exist:
  `<repo-path>`. Create it manually or update `repoPath` in
  `~/.claude/settings-sync.json`." and **STOP**.

**Path safety:** always quote the resolved repo path in all shell commands
(git, rsync, cp, rm) to handle spaces and special characters.

After resolving, persist the path to `~/.claude/settings-sync.json`:

```json
{
  "repoPath": "/absolute/path/to/repo",
  "includeLocalSettings": false
}
```

If the file already exists, update `repoPath` only — preserve other keys.

### Step 2 — Validate and initialize the repo

Run `git -C <repo-path> rev-parse --is-inside-work-tree`.

- If it fails, ask the user if they want to initialize a new repo with
  `git init <repo-path>`. On confirmation, run `git init`.
- If the directory is already a git repo, continue.

Ensure the repo root `.gitignore` contains every rule below — create the file
if missing, and **append any individual rule it lacks** if it already exists:

```
.DS_Store
*.swp
*.swo
*~
.*.swp
__pycache__/
```

Checking only for the file's existence is not enough. Every repo created before
`hooks/` became a backup target already has a `.gitignore` without
`__pycache__/`, so those rules would never arrive and the `git add -A` in Step 7
would commit `hooks/__pycache__` on the next run.

### Step 3 — Read config and build the file list

Read `~/.claude/settings-sync.json` to check for `"includeLocalSettings"`.

Build the list of sources from the file manifest:

**Always included (skip silently if missing):**
- `~/.claude/settings.json`
- `~/.claude/CLAUDE.md`
- `~/.claude/keybindings.json`
- `~/.claude/rules/`
- `~/.claude/commands/`
- `~/.claude/skills/`
- `~/.claude/hooks/`

**Conditionally included:**
- `~/.claude/settings.local.json` — only if `"includeLocalSettings": true`

For each source, check if it exists before attempting to copy. Track which
sources were found and which were skipped.

### Step 4 — Secret scan (first backup only)

If the repo has no prior commits (`git -C <repo-path> log --oneline -1` fails),
this is the first backup. Read `~/.claude/settings.json` and scan its content
for common secret patterns:

- `sk-` (API keys)
- `ghp_` (GitHub tokens)
- `ghs_` (GitHub tokens)
- `AKIA` (AWS access keys)
- `xoxb-`, `xoxp-` (Slack tokens)
- Strings that look like base64-encoded secrets (40+ chars of `[A-Za-z0-9+/=]`)

If any matches are found, warn the user:

> "Found potential secrets in settings.json (patterns: sk-, ghp_). If this
> repo has a public remote, these could be exposed. Continue with backup?"

Use `AskUserQuestion` with options: "Continue", "Skip settings.json",
"Cancel backup". **In routine mode** (no interactive prompts), log the warning
to `.sync-log` but continue — the user accepted the risk by scheduling the
routine.

### Step 5 — Copy files to the repo

Determine the copy method:

```bash
command -v rsync >/dev/null 2>&1
```

**If rsync is available:**

For single files (no `--delete` — it would remove unrelated repo-root files):

```bash
rsync -aL ~/.claude/settings.json <repo-path>/settings.json
rsync -aL ~/.claude/CLAUDE.md <repo-path>/CLAUDE.md
rsync -aL ~/.claude/keybindings.json <repo-path>/keybindings.json
```

For directories (`--delete` is safe here — scoped to the target subdir):

```bash
rsync -aL --delete ~/.claude/rules/ <repo-path>/rules/
rsync -aL --delete ~/.claude/commands/ <repo-path>/commands/
rsync -aL --delete ~/.claude/skills/ <repo-path>/skills/
rsync -aL --delete ~/.claude/hooks/ <repo-path>/hooks/
```

**If rsync is not available (cp fallback):**

For each file target, use `cp -fL <source> <repo-path>/<filename>`.
For each directory target, use:

```bash
rm -rf <repo-path>/<dir> && cp -aL ~/.claude/<dir> <repo-path>/<dir>
```

The `rm -rf` before copy ensures deleted source files don't persist in the
backup (mirrors rsync `--delete` behavior).

**Cleanup for deleted sources:** for each file target that does **not** exist
locally but **does** exist in the repo, remove it from the repo so the backup
reflects the current local state:

```bash
[ ! -f ~/.claude/keybindings.json ] && [ -f <repo-path>/keybindings.json ] && rm <repo-path>/keybindings.json
```

Apply this check to every single-file target (settings.json, CLAUDE.md,
keybindings.json, and settings.local.json if opt-in is enabled).

Skip any source that does not exist — do not error on copy.

If `includeLocalSettings` is true, also copy `~/.claude/settings.local.json`.

### Step 6 — Write metadata

Write `.settings-sync-meta.json` to the repo root:

```bash
cat > <repo-path>/.settings-sync-meta.json << 'METAEOF'
{
  "hostname": "<output of hostname>",
  "timestamp": "<ISO 8601 UTC>",
  "claudeVersion": "<output of claude --version or 'unknown'>",
  "filesIncluded": [<list of files/dirs that were copied>]
}
METAEOF
```

Use `hostname` and `date -u +%Y-%m-%dT%H:%M:%SZ` for the values. For Claude
version, run `claude --version 2>/dev/null || echo 'unknown'`.

### Step 7 — Commit and push

Run `git -C <repo-path> add -A`.

Check `git -C <repo-path> status --porcelain`.

**If there are changes:**

```bash
git -C <repo-path> commit -m "backup: Claude settings $(date +%Y-%m-%d\ %H:%M)"
```

Check if a remote exists: `git -C <repo-path> remote get-url origin 2>/dev/null`.

If a remote exists, attempt `git -C <repo-path> push`.

- If push succeeds, report success.
- If push fails (conflict), output: "Push failed — another machine may have
  pushed since your last sync. Pull and resolve manually:
  `git -C <repo-path> pull --rebase && git push`" and **STOP**. Do not
  auto-resolve.

**If there are no changes:**

Append a timestamped entry to `<repo-path>/.sync-log`:

```
[YYYY-MM-DDTHH:MM:SSZ] no changes — backup skipped (hostname: <hostname>)
```

Commit the updated `.sync-log` if it changed, then push if remote exists.

Output: "No settings changes since last backup. Logged to .sync-log."

### Step 8 — Report

Output a summary:

```
Settings backup complete.
  Repo: <repo-path>
  Files backed up: <count> (<list of names>)
  Skipped (not found): <list or "none">
  Commit: <short hash> — <commit message>
  Pushed: yes/no/failed
```

**STOP after this step.**
