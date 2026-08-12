---
name: settings-restore
description: "Restores Claude Code settings from a backup repo or clone URL. Clones on a new machine, then confirms before overwriting ~/.claude/. Use when the user asks to restore settings or set up a new machine."
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion
argument-hint: "[repo-path-or-url]"
---

# Settings Restore

Restore Claude Code user settings from a dedicated backup git repository.
Accepts a local repo path or a clone URL — the URL form bootstraps a **new
machine**, where no local copy exists yet. Pulls latest changes, shows a diff
summary, and copies files back to `~/.claude/` after user confirmation.

## When not to use

- To back up settings to a repo — use `settings-backup` instead.
- To compare settings without making changes.

## Reference

Load `references/file-manifest.md` from the plugin root for the complete list
of files to restore, opt-in targets, and exclusions.

## Steps

### Step 1 — Resolve the backup source

The source may be a **local path** or a **remote URL**. On a new machine there
is no local repo yet — the URL form is the bootstrap path.

Determine the source using this priority order:

1. **Argument**: if the user provided a path or URL (via `$ARGUMENTS` or in
   their message), use it. Expand `~` for paths.
2. **Config file**: read `~/.claude/settings-sync.json`. If it exists and
   contains a `"repoPath"` key, use that value.
3. **Interactive prompt**: use `AskUserQuestion` to ask for the backup repo —
   accepting either a local path or a clone URL.

If nothing can be resolved, output an error and **STOP**.

**If the value is a URL** (starts with `https://`, `git@`, `ssh://`, or
`http://`), clone it to `~/.claude-settings-backup` and use that as the repo
path.

**First, derive `<safe-url>` — before anything is displayed or logged.** A clone
URL may carry credentials in its userinfo, and every branch below can emit a
diagnostic naming the URL. Redact once, here, and use `<safe-url>` in **all**
user-facing text and `.sync-log` entries; keep the original solely as the
argument to `git clone`.

Take the authority — the text after `//` up to the next `/`, `?`, or `#` — and
if it contains `@`, replace everything before its last `@` with `***`. Scope the
replacement to the authority so a later `@` in a path or query is untouched:

```text
https://alice:ghp_ABC123@github.com/you/backup.git  ->  https://***@github.com/you/backup.git
https://github.com/you/backup.git                   ->  unchanged (no userinfo)
https://github.com/you/repo.git?ref=a@b             ->  unchanged (@ is not in the authority)
```

Then clone:

```bash
git clone "<url>" "$HOME/.claude-settings-backup"
```

**Reject plaintext `http://` by default.** Restored `hooks/` scripts are
executed by Claude Code on next start, so an unencrypted clone is a
code-injection path, not merely an eavesdropping one. Warn and require explicit
confirmation via `AskUserQuestion` before cloning over `http://`; **STOP** if
the user declines.

If `~/.claude-settings-backup` already exists:

- It is a git repo whose `origin` matches the URL → reuse it; Step 2 pulls.
- It is a git repo with a **different** origin, or not a repo at all → output:
  "`~/.claude-settings-backup` already exists and is not a clone of
  `<safe-url>`. Remove it or pass a different local path." and **STOP**. Never
  overwrite it.

If the clone fails (auth, network, bad URL), report git's error and **STOP** —
but scrub it first. Git echoes the URL back inside its own error text,
credentials included, so apply the same redaction to that text before showing
or logging it.

**If the value is a local path**, verify it is a git repo:
`git -C "<repo-path>" rev-parse --is-inside-work-tree`. If it fails, output:

> "No backup repo at `<repo-path>`. Pass the clone URL of your backup repo
> instead (e.g. `https://github.com/you/claude-settings-backup.git`) and it
> will be cloned to `~/.claude-settings-backup`."

Then **STOP**. Do **not** suggest running `settings-backup` — on a machine with
no settings yet that would overwrite the backup with an empty config.

**Path safety:** always quote the resolved repo path in all shell commands
(git, rsync, cp, rm) to handle spaces and special characters.

### Step 2 — Pull latest from remote

Check if a remote exists: `git -C "<repo-path>" remote get-url origin 2>/dev/null`.

If a remote exists, run `git -C "<repo-path>" pull --ff-only`.

- If pull fails, warn: "Could not pull latest — remote may have diverged.
  Restoring from local copy. Run `git -C "<repo-path>" pull` manually to sync."
  Continue with the local state.

### Step 3 — Build the file list from the repo

Restore what the backup actually contains — not a fixed list. Backup captures
whatever the manifest resolved to on the source machine, and that set grows;
a hardcoded list here would silently strand the extras.

**List the repo root.** Restore every entry there except these control files,
which belong to the repo and never to `~/.claude/`:

- `.git/`
- `.gitignore`
- `.sync-log`
- `.settings-sync-meta.json`

Every entry maps to the same name under `~/.claude/`:
`<repo-path>/<entry>` → `~/.claude/<entry>`.

**Validate every entry before it is used as a path.** These names come from the
repo, and Step 6 feeds them to `rm -rf` and `rsync --delete`. Accept an entry
only if it is a plain relative name — no `/`, no `..`, not starting with `-`
(which `rsync` and `rm` would read as an option). Skip and report anything else
rather than expanding the destructive operation outside `~/.claude/`.

Do **not** drive this list from `filesIncluded` in `.settings-sync-meta.json`.
That array records what the last backup run copied, which is a subset of the
repo whenever anything was added by hand or by an older version — those entries
would never come back. Read the meta file only for provenance (hostname,
timestamp, Claude version) to show in the preview.

**Conditional target.** `settings.local.json` is restored **only** if
`~/.claude/settings-sync.json` exists and sets `"includeLocalSettings": true` —
even when it appears in `filesIncluded` or the repo root. On a new machine that
config file does not exist yet, so the default is to skip it.

Track which entries exist in the repo and which are missing.

### Step 4 — Generate diff summary

For each file/directory that exists in the repo, compare against the local
`~/.claude/` target:

**Files** — compare each file:
- **New**: exists in repo but not locally → label as `+ added`
- **Modified**: exists in both, content differs (`diff -q`) → label as `~ modified`
- **Unchanged**: exists in both, content matches → label as `= unchanged`
- **Deleted**: exists locally but **not** in backup → label as `- deleted`

**Directories** — list local and repo files, then classify each:
- Use `find` on both the repo subdir and the local `~/.claude/` subdir to get
  complete file lists, then compare to derive added/modified/unchanged/deleted
  counts. (`diff -rq` alone misses unchanged files and local-only deletions.)
- Summarize as: `rules/ — 5 files (1 new, 1 modified, 2 unchanged, 1 deleted)`

Present the summary:

```
Restore preview:
  + settings.json (new)
  ~ CLAUDE.md (modified)
  = keybindings.json (unchanged)
  ~ rules/ — 5 files (1 new, 1 modified, 2 unchanged, 1 deleted)
  + commands/ — 2 files (2 new)
  skills/ — not in backup (skipped)
```

**Important:** the `--delete` flag (rsync) and `rm -rf` (cp fallback) mean that
for **every directory in the Step 3 list**, local files not present in the
backup are removed. Derive the deleted entries from that same list — never from
a fixed set of directory names, or a directory added to the backup later
(`hooks/` among them) would be wiped without ever appearing in the preview.
Always surface these as `- deleted` so the user knows what will be lost.

### Step 5 — Confirm with user

Use `AskUserQuestion`:

> "Restore these settings to `~/.claude/`? This will overwrite existing files
> and delete local files not present in the backup (see deleted items above)."

Options:
- "Restore all" — proceed with full restore
- "Restore new and modified only" — skip files marked as `unchanged`
- "Cancel" — abort without changes

**This step is always interactive.** If running in a context where prompting is
not possible, output: "Restore requires interactive confirmation. Run this
skill manually." and **STOP**.

### Step 6 — Copy files from repo to ~/.claude/

Ensure `~/.claude/` exists: `mkdir -p ~/.claude`.

Determine the copy method:

```bash
command -v rsync >/dev/null 2>&1
```

Work through the list built in Step 3, treating each entry as a file or a
directory.

**If rsync is available:**

```bash
# file entry
rsync -aL "<repo-path>/<file>" "$HOME/.claude/<file>"
# directory entry — trailing slashes and --delete mirror the backup exactly
rsync -aL --delete "<repo-path>/<dir>/" "$HOME/.claude/<dir>/"
```

**If rsync is not available (cp fallback):**

For each file target: `cp -fL "<repo-path>/<file>" "$HOME/.claude/<file>"`.
For each directory target, remove then replace to mirror rsync `--delete`:

```bash
rm -rf "$HOME/.claude/<dir>" && cp -aL "<repo-path>/<dir>" "$HOME/.claude/<dir>"
```

Quote both sides. `~` does not expand inside quotes, so use `$HOME` for the
destination.

Restore executable bits as stored — `hooks/` scripts are invoked directly by
Claude Code and are inert without them (`-a` preserves this on both paths).

If the `cp` fails after `rm -rf`, report the error immediately — the user can
re-run restore to recover from the backup repo.

Skip any source that does not exist in the repo — do not error.

If `includeLocalSettings` is true and `settings.local.json` exists in the repo,
copy it as well.

If the user chose "Restore new and modified only", skip files/directories where
the diff status was `unchanged`.

### Step 7 — Save config

If `~/.claude/settings-sync.json` does not exist or `repoPath` differs, write
it:

```json
{
  "repoPath": "/absolute/path/to/repo",
  "includeLocalSettings": false
}
```

Preserve any existing keys.

### Step 8 — Report

Output a summary:

```
Settings restored from <repo-path>.
  Restored: <count> files (<list>)
  Skipped (not in backup): <list or "none">
  Skipped (unchanged): <list or "none">

NOTE: Restored settings take effect after restarting Claude Code.
Restart your session or run `claude` again to pick up the changes.
```

If the repo was cloned in Step 1, name the clone location so the user knows
where it landed.

On a **new machine**, add:

```
Plugins are not part of the backup — settings.json carries `enabledPlugins`
and `extraKnownMarketplaces`, so Claude Code reinstalls them on next start.
```

**STOP after this step.**
