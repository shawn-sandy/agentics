#!/usr/bin/env bash
# Install every agentics-kit marketplace plugin for this user, if missing.
#
#   bash scripts/ensure-plugins.sh
#
# Why this exists: a fresh container — Claude Code on the web, a codespace, a
# new machine — starts with an empty plugin store. The `enabledPlugins` block
# in `.claude/settings.json` only enables plugins that are already installed;
# it does not clone the marketplace or install anything. So a remote session
# comes up with none of the kit available, and every `/plan-agent:*`,
# `/git-agent:*`, and friend silently does not exist. This closes that gap.
#
# Called automatically by the Claude Code SessionStart hook, which runs it
# async so plugin provisioning never delays session startup. A copy lives at
# ~/.claude/hooks/ensure-agentics-plugins.sh for sessions outside this repo;
# this file is the canonical one, so edit here and re-copy.
#
# Restart required: a session already open when this runs loaded its skill
# registry at startup and will not see the new plugins until the next session.

set -uo pipefail

MARKETPLACE="agentics-kit"
SOURCE_REPO="shawn-sandy/agentics"
STATE="${HOME}/.claude/plugins/installed_plugins.json"
CACHE="${HOME}/.claude/plugins/marketplaces/${MARKETPLACE}"

command -v claude > /dev/null 2>&1 || exit 0
command -v python3 > /dev/null 2>&1 && HAVE_PYTHON=1 || HAVE_PYTHON=0

failures=0
installed=0

warn() {
  echo "WARNING: ensure-plugins: $1" >&2
  failures=$((failures + 1))
}

# Does a USER-scoped row exist for this plugin id? A project- or local-scoped
# row does not count. Those shadow the user row for one directory only, so a
# plugin present solely at project scope is still missing everywhere else —
# see scripts/update-worktree-plugins.sh for how that shadowing plays out.
# Without python3, fall back to an id-only match: coarser, but the ambiguity
# is rare and a false skip is better than a wrong reinstall loop.
has_user_scope() {
  if [ "$HAVE_PYTHON" = 1 ]; then
    python3 - "$STATE" "$1" << 'PY'
import json, sys
try:
    rows = json.load(open(sys.argv[1]))["plugins"].get(sys.argv[2], [])
except Exception:
    sys.exit(1)
sys.exit(0 if any(r.get("scope") == "user" for r in rows) else 1)
PY
  else
    grep -q "\"${1}\"" "$STATE" 2> /dev/null
  fi
}

# Clone the marketplace only when it is absent. `marketplace add` is a cheap
# no-op once added, but it still hits the network, and this runs every session.
if [ ! -d "$CACHE" ]; then
  claude plugin marketplace add "$SOURCE_REPO" > /dev/null 2>&1 \
    || warn "could not add marketplace ${SOURCE_REPO}"
fi

# Plugin ids come from the marketplace itself rather than a hardcoded list, so
# a plugin published later is picked up without touching this script. Both the
# installed and available sections of the JSON carry "<name>@<marketplace>"
# ids; grep unions them and the scope check below decides which are new.
# Removed plugins are not listed as available, so they are never resurrected.
raw="$(claude plugin list --available --json 2> /dev/null)"
if [ -z "$raw" ]; then
  warn "could not list plugins — leaving the store untouched"
  exit 0
fi

ids="$(printf '%s' "$raw" | grep -o "\"[a-z0-9-]*@${MARKETPLACE}\"" | tr -d '"' | sort -u)"
# An empty list here is not a failure: it means the marketplace declares no
# plugins, which is a real (if unlikely) state, not a broken query.
[ -n "$ids" ] || exit 0

for id in $ids; do
  has_user_scope "$id" && continue
  # --scope user is explicit on purpose. It is the CLI default today, and the
  # scope check above only recognises user rows, so an implicit default that
  # ever changed would make this loop reinstall on every single session.
  if claude plugin install "$id" --scope user > /dev/null 2>&1; then
    installed=$((installed + 1))
  else
    warn "failed to install ${id}"
  fi
done

if [ "$installed" -gt 0 ]; then
  echo "OK: installed ${installed} ${MARKETPLACE} plugin(s) — restart the session to load them"
fi
if [ "$failures" -gt 0 ]; then
  echo "WARNING: ensure-plugins: ${failures} operation(s) failed — run 'bash scripts/ensure-plugins.sh' by hand to see the errors" >&2
fi
exit 0
