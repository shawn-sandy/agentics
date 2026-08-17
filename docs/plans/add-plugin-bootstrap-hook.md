---
status: completed
type: fix
created: 2026-08-17
modified: 2026-08-17
repo-name: agentics
---

# Add Plugin Bootstrap Hook

## context

A Claude Code on the web session in this repo came up with none of the
agentics-kit plugins available — no `/plan-agent:*`, no `/git-agent:*`, no
skills from any of the twelve. Inspection of the container showed
`~/.claude/plugins/installed_plugins.json` at `{"plugins": {}}` and no
`marketplaces/` cache at all.

The cause is a misreading of what `.claude/settings.json` does. It declares
`extraKnownMarketplaces` and lists all twelve under `enabledPlugins`, which
looks like it should install them. It does not: `enabledPlugins` only *enables*
plugins already present in the store, and remote session bootstrap never clones
the marketplace. Every fresh container — web session, codespace, new machine —
therefore starts empty, and nothing in the repo ever fixes it.

Network was never the problem: `claude plugin marketplace add
shawn-sandy/agentics` succeeded on the first try in the affected container.

## objective

Make a fresh container self-heal at session start: clone the marketplace if
absent, install any marketplace plugin missing from the user's store, and stay
silent once there is nothing to do.

## steps

1. **`scripts/ensure-plugins.sh`** — the bootstrap itself. Clones the
   marketplace only when `~/.claude/plugins/marketplaces/agentics-kit` is
   absent, then installs every id from `claude plugin list --available --json`
   that `installed_plugins.json` does not already carry.
   *Why the marketplace and not a hardcoded list:* a plugin published later is
   picked up without editing the script, and plugins in the manifest's
   `removed` array are never listed as available, so the removal decisions in
   `.claude/rules/removed-plugins.md` cannot be undone by accident.
   *Why default user scope:* a project-scoped row shadows the user row and pins
   a version per directory — the failure mode documented at length in
   `scripts/update-worktree-plugins.sh`.
   *Verify:* `bash -n` passes; a no-op run is silent and exits 0; after
   `claude plugin uninstall content-tools@agentics-kit` a run reinstalls
   exactly one and says so.
2. **Repo SessionStart hook** (`.claude/settings.json`): a third entry running
   the script through `git rev-parse --show-toplevel`, matching the existing
   `setup-merge-driver.sh` entry's shape and its `|| true` tail so a failure
   never blocks session start. *Why:* covers anyone working in this repo,
   including future web sessions, without per-machine setup.
   *Verify:* the JSON edit is an 8-line addition with no reformatting
   elsewhere; the marketplace-validation PostToolUse hook reports valid.
3. **Global copy** for sessions outside this repo:
   `~/.claude/hooks/ensure-agentics-plugins.sh` (byte-identical to the
   canonical script) plus a SessionStart entry in `~/.claude/settings.json`.
   *Why `~/.claude/hooks/`:* it is a default backup target in
   `settings-sync`'s file manifest, so the script and the settings entry both
   travel to other machines through an existing backup/restore path.
   *Verify:* `diff -q` against the canonical copy; running it from `/tmp` is a
   silent exit 0.

## verification

- No-op path: 0.8s, no output, exit 0.
- Install path: uninstalling one plugin and re-running reinstalled it and
  printed `OK: installed 1 agentics-kit plugin(s)`.
- All twelve present in `installed_plugins.json` at user scope.

## notes

Restart required. A session already open when the hook fires has already built
its skill registry, so the plugins load on the *next* session, not the current
one.

The installed copies come from `origin/main`, not the working tree. Testing a
local plugin edit still means `claude --plugin-dir ./kit/plugins/<name>`.

Updating the global copy after editing the canonical script is a manual
`cp scripts/ensure-plugins.sh ~/.claude/hooks/ensure-agentics-plugins.sh`.
