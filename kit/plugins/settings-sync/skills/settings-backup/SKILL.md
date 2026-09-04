---
name: settings-backup
description: "Backs up Claude Code user settings to a git repo. Commits and pushes config files unattended; routine-compatible. Use when the user asks to back up or sync their Claude Code settings."
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, ToolSearch, ExitPlanMode
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

### Step 0 — Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

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
  "includeLocalSettings": false,
  "includeMcpServers": false
}
```

If the file already exists, update `repoPath` only — preserve other keys.

### Step 2 — Validate and initialize the repo

Run `git -C <repo-path> rev-parse --is-inside-work-tree`.

- If it fails, ask the user if they want to initialize a new repo with
  `git init <repo-path>`. On confirmation, run `git init`.
- If the directory is already a git repo, continue.

**Ignore rules and already-tracked files.** The block below makes sure the
repo root `.gitignore` carries every rule in its list — creating the file if
missing, appending any individual rule it lacks — and then untracks whatever
those rules already cover. Checking only that `.gitignore` exists is not
enough: every repo created before `hooks/` became a target has one without
`__pycache__/`, and an ignore rule never untracks a file that is already in
git, so the `.pyc` files committed before the rule arrived kept riding along on
every run. `git rm --cached` drops only the index entry; the working file
stays on disk, and `--force` only skips the up-to-date check so a file someone
hand-staged in the backup repo is untracked too.

```bash
repo="<repo-path>"
touch "$repo/.gitignore"
[ -n "$(tail -c1 "$repo/.gitignore")" ] && echo >> "$repo/.gitignore"
for rule in .DS_Store '*.swp' '*.swo' '*~' '.*.swp' __pycache__/ .sync-log; do
  grep -qxF -- "$rule" "$repo/.gitignore" || echo "$rule" >> "$repo/.gitignore"
done
if git -C "$repo" ls-files -ci --exclude-standard | grep -q .; then
  git -C "$repo" ls-files -ci --exclude-standard -z | xargs -0 git -C "$repo" rm --cached --force --quiet --
fi
```

`.sync-log` is ignored because it is a local audit trail: Step 6 appends a
line to it on every no-change run, and committing that line would turn each of
those runs into a commit of its own.

### Step 3 — Read config and build the file list

Read `~/.claude/settings-sync.json` to check for `"includeLocalSettings"`
and `"includeMcpServers"`.

Build the list of sources from the file manifest:

**Always included (skip silently if missing):**
- `~/.claude/settings.json`
- `~/.claude/CLAUDE.md`
- `~/.claude/keybindings.json`
- `~/.claude/rules/`
- `~/.claude/commands/`
- `~/.claude/skills/`
- `~/.claude/hooks/`
- `~/.claude/agents/`
- `~/.claude/output-styles/`
- `~/.claude/scripts/`
- `~/.claude/reference/`

**Conditionally included:**
- `~/.claude/settings.local.json` — only if `"includeLocalSettings": true`
- `<repo-path>/mcp-servers.json` — only if `"includeMcpServers": true`
  and top-level `mcpServers` exists in `~/.claude.json`; this is a generated
  control file, not a direct copy of `~/.claude.json`

**Extract MCP servers.** If `"includeMcpServers": true`, extract only the
top-level `mcpServers` object from `~/.claude.json` and write that object
itself to `<repo-path>/mcp-servers.json`. Do not copy any other key from
`~/.claude.json`. If the file or top-level object is absent, remove a stale
`mcp-servers.json` from the repo so an opt-in backup reflects the current
source state. If `~/.claude.json` exists but is not valid JSON, stop rather
than committing a stale MCP export.

```bash
repo="<repo-path>"
if grep -q '"includeMcpServers"[[:space:]]*:[[:space:]]*true' "$HOME/.claude/settings-sync.json" 2>/dev/null; then
  if [ -f "$HOME/.claude.json" ]; then
    node -e '
const fs = require("node:fs");
const [src, dest] = process.argv.slice(1);
let doc;
try {
  doc = JSON.parse(fs.readFileSync(src, "utf8"));
} catch (error) {
  console.error("Unable to parse ~/.claude.json: " + error.message);
  process.exit(1);
}
const servers = doc && typeof doc === "object" && !Array.isArray(doc) ? doc.mcpServers : undefined;
if (servers && typeof servers === "object" && !Array.isArray(servers)) {
  fs.writeFileSync(dest, JSON.stringify(servers, null, 2) + "\n");
} else {
  try {
    fs.unlinkSync(dest);
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
}
' "$HOME/.claude.json" "$repo/mcp-servers.json"
  else
    rm -f "$repo/mcp-servers.json"
  fi
else
  rm -f "$repo/mcp-servers.json"
fi
```

For each source, check if it exists before attempting to copy or scan. Track
which sources were found and which were skipped.

### Step 4 — Secret scan (every backup)

Run this scan on **every** backup, not just the first. A token added to
`settings.json` (or a hook script) after the initial commit would otherwise be
pushed unattended on every subsequent routine run with no scan and no warning.
The scan is a fast grep over a handful of text files — the cost is negligible.

Scan every source in the Step 3 file list (files directly, directories
recursively) for common secret patterns:

- `sk-` (API keys — covers `sk-ant-…` Anthropic and OpenAI-style keys)
- `sk_live_` (Stripe live keys)
- `ghp_`, `ghs_`, `gho_`, `github_pat_` (GitHub tokens)
- `glpat-` (GitLab tokens)
- `AKIA` (AWS access keys)
- `AIza` (Google API keys)
- `xoxb-`, `xoxp-` (Slack tokens)
- `hooks.slack.com/services/` (Slack webhook URLs)
- Strings that look like base64-encoded secrets (40+ chars of `[A-Za-z0-9+/=]`)

**Scan the backup sources.** Include the generated
`<repo-path>/mcp-servers.json` control file when it exists, because MCP server
environment blocks commonly hold API keys. Use this output to drive the
interactive warning or routine `.sync-log` entry described below.

```bash
repo="<repo-path>"
secret_patterns='sk-[A-Za-z0-9-]{20,}|sk_live_[A-Za-z0-9]{24,}|ghp_[A-Za-z0-9]{36}|ghs_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{22,}|glpat-[A-Za-z0-9_-]{20,}|AKIA[A-Z0-9]{16}|AIza[A-Za-z0-9_-]{35}|xox[bp]-[A-Za-z0-9-]{10,}|hooks\.slack\.com/services/|[A-Za-z0-9+/=]{40,}'
scan_one() {
  if [ -d "$1" ]; then
    grep -RHInE "$secret_patterns" "$1" 2>/dev/null || true
  elif [ -f "$1" ]; then
    grep -HInE "$secret_patterns" "$1" 2>/dev/null || true
  fi
}
scan_one "$HOME/.claude/settings.json"
scan_one "$HOME/.claude/CLAUDE.md"
scan_one "$HOME/.claude/keybindings.json"
scan_one "$HOME/.claude/rules"
scan_one "$HOME/.claude/commands"
scan_one "$HOME/.claude/skills"
scan_one "$HOME/.claude/hooks"
scan_one "$HOME/.claude/agents"
scan_one "$HOME/.claude/output-styles"
scan_one "$HOME/.claude/scripts"
scan_one "$HOME/.claude/reference"
if grep -q '"includeLocalSettings"[[:space:]]*:[[:space:]]*true' "$HOME/.claude/settings-sync.json" 2>/dev/null; then
  scan_one "$HOME/.claude/settings.local.json"
fi
[ -f "$repo/mcp-servers.json" ] && scan_one "$repo/mcp-servers.json"
```

If any matches are found, warn the user:

> "Found potential secrets in <file> (patterns: sk-, ghp_). If this
> repo has a public remote, these could be exposed. Continue with backup?"

Use `AskUserQuestion` with options: "Continue", "Skip the flagged files",
"Cancel backup". **In routine mode** (no interactive prompts), log the warning
to `.sync-log` **with the matched pattern and file path** so the exposure is
discoverable later, then continue — the user accepted the risk by scheduling
the routine.

### Step 5 — Copy files to the repo

**Copy the targets.** One block copies every Step 3 source that exists. With
rsync, `-aL` follows symlinks and `--delete` is scoped to each target
subdirectory, never the repo root; without it, `cp` runs after an `rm -rf` of
the target subdirectory so deleted source files do not linger. A single-file
target that no longer exists locally is removed from the repo so the backup
reflects the current local state. Every path is quoted.

```bash
repo="<repo-path>"
files="settings.json CLAUDE.md keybindings.json"
if grep -q '"includeLocalSettings"[[:space:]]*:[[:space:]]*true' "$HOME/.claude/settings-sync.json" 2>/dev/null; then
  files="$files settings.local.json"
fi
dirs="rules commands skills hooks agents output-styles scripts reference"
if command -v rsync >/dev/null 2>&1; then
  for f in $files; do
    if [ -f "$HOME/.claude/$f" ]; then rsync -aL "$HOME/.claude/$f" "$repo/$f"; fi
  done
  for d in $dirs; do
    if [ -d "$HOME/.claude/$d" ]; then rsync -aL --delete "$HOME/.claude/$d/" "$repo/$d/"; fi
  done
else
  for f in $files; do
    if [ -f "$HOME/.claude/$f" ]; then cp -fL "$HOME/.claude/$f" "$repo/$f"; fi
  done
  for d in $dirs; do
    if [ -d "$HOME/.claude/$d" ]; then rm -rf "$repo/$d" && cp -aL "$HOME/.claude/$d" "$repo/$d"; fi
  done
fi
for f in $files; do
  if [ ! -f "$HOME/.claude/$f" ] && [ -f "$repo/$f" ]; then rm "$repo/$f"; fi
done
```

A symlinked skill folder (one the skills CLI installed elsewhere and linked
into `~/.claude/skills/`) is copied as a real folder. It still works after a
restore; only the CLI's link to it is lost.

**Entries that are not targets.** The repo root may hold entries that no
Step 3 source produced — left behind by an older version of this skill, or
added by hand. Nothing above removes them, and `settings-restore` copies every
root entry it finds, so a stale `plans/` comes back on every new machine until
someone notices. List them:

```bash
for p in "<repo-path>"/* "<repo-path>"/.*; do
  [ -e "$p" ] || continue
  e="$(basename "$p")"
  case " . .. .git .gitignore .sync-log .settings-sync-meta.json mcp-servers.json settings.json CLAUDE.md keybindings.json settings.local.json rules commands skills hooks agents output-styles scripts reference " in
    *" $e "*) ;;
    *) echo "$e" ;;
  esac
done
```

Do **not** delete them — a hand-added entry is deliberate. Carry the list to
Step 7 so the user can remove each one from the repo or add it to the
manifest.

### Step 6 — Commit only real changes

**Commit only real changes.** Stage everything, then ask git whether anything
is actually staged before writing a single byte of metadata. The old order —
write a fresh timestamp into `.settings-sync-meta.json`, then check for
changes — made every run a commit: 4,477 of one real repo's 4,601 commits
changed nothing but that timestamp, and `git log` could no longer show when a
setting changed. Now a no-change run appends one line to the local, gitignored
`.sync-log` and touches nothing git tracks. A real change writes the metadata
(hostname, UTC timestamp, `claude --version`, and the top-level entries the
backup holds, each JSON-escaped so a stray root entry with a quote in its name
cannot corrupt the file) and commits it together with the copied files.

```bash
repo="<repo-path>"
json_escape() { sed 's/\\/\\\\/g; s/"/\\"/g'; }
git -C "$repo" add -A
if git -C "$repo" diff --cached --quiet; then
  printf '[%s] no changes — backup skipped (hostname: %s)\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(hostname)" >> "$repo/.sync-log"
  echo no-change
else
  {
    printf '{\n  "hostname": "%s",\n  "timestamp": "%s",\n  "claudeVersion": "%s",\n  "filesIncluded": [\n' \
      "$(hostname | json_escape)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$({ claude --version 2>/dev/null || echo unknown; } | json_escape)"
    git -C "$repo" ls-files -z | tr '\0' '\n' | cut -d/ -f1 | grep -vx -e .gitignore -e .settings-sync-meta.json | sort -u \
      | json_escape | awk 'NR > 1 { printf ",\n" } { printf "    \"%s\"", $0 } END { print "" }'
    printf '  ]\n}\n'
  } > "$repo/.settings-sync-meta.json"
  git -C "$repo" add .settings-sync-meta.json \
    && git -C "$repo" commit -q -m "backup: Claude settings $(date +%Y-%m-%d\ %H:%M)" \
    && echo committed
fi
```

**After `committed`:** check for a remote with
`git -C <repo-path> remote get-url origin 2>/dev/null`. If one exists, run
`git -C <repo-path> push`.

- If push succeeds, report success.
- If push fails (conflict), output: "Push failed — another machine may have
  pushed since your last sync. Pull and resolve manually:
  `git -C <repo-path> pull --rebase && git push`" and **STOP**. Do not
  auto-resolve.

**After `no-change`:** there is nothing to push. Output: "No settings changes
since last backup. Logged locally to .sync-log (not committed)."

### Step 7 — Report

Output a summary:

```
Settings backup complete.
  Repo: <repo-path>
  Files backed up: <count> (<list of names>)
  Skipped (not found): <list or "none">
  Not a backup target (left in repo): <list or "none">
  Commit: <short hash> — <commit message>, or "none — no changes"
  Pushed: yes/no/failed/not needed
```

**STOP after this step.**
