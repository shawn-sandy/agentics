#!/usr/bin/env bash
set -euo pipefail

# settings-backup writes each machine to its own branch, machines/<name>. The
# name is read from ~/.claude/settings-sync.json — a hand-editable file — and
# lands in a git ref and in shell commands, so the block that resolves it is a
# trust boundary: anything outside ^[a-z0-9][a-z0-9-]{0,62}$ must stop the
# backup before a git command runs. With no stored name it is derived once
# from `hostname -s`; macOS renames a Mac on a name clash ("Shawn's MacBook
# Pro (2)"), which is why a stored name always wins over the live hostname.
#
# The block is extracted from SKILL.md by marker and run against a fake home
# with `hostname` shimmed.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/settings-sync/skills/settings-backup/SKILL.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SNIPPET="$(awk 'index($0, "**Resolve the machine name.**") == 1 {f=1} f && /^```bash/ {c=1; next} c && /^```/ {exit} c {print}' "$SKILL")"
if [ -z "$SNIPPET" ]; then
  echo "FAIL: no bash block after '**Resolve the machine name.**' in $SKILL"
  exit 1
fi

mkdir -p "$TMP/bin" "$TMP/home/.claude"
CFG="$TMP/home/.claude/settings-sync.json"
HOSTNAME_OUT='Shawns-MacBook-Pro-2'
printf '#!/bin/sh\ncat "%s"\n' "$TMP/hostname.txt" > "$TMP/bin/hostname"   # prints the same name with or without -s
chmod +x "$TMP/bin/hostname"
shim_hostname() { printf '%s\n' "$1" > "$TMP/hostname.txt"; }

resolve() {  # stdout -> $TMP/out, stderr -> $TMP/err; returns the block's status
  HOME="$TMP/home" PATH="$TMP/bin:$PATH" bash -c "$SNIPPET" >"$TMP/out" 2>"$TMP/err"
}

FAILURES=0
check() {  # $1 label, rest: a command that succeeds when the behaviour holds
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "ok   $label"
  else
    echo "FAIL $label"
    FAILURES=$((FAILURES + 1))
  fi
}
prints()  { resolve && [ "$(cat "$TMP/out")" = "$1" ]; }
rejects() { ! resolve && [ ! -s "$TMP/out" ]; }  # non-zero, and no name to use
stored()  { printf '{\n  "repoPath": "/tmp/backup",\n  "machine": "%s"\n}\n' "$1" > "$CFG"; }

shim_hostname "$HOSTNAME_OUT"

rm -f "$CFG"
check "no config file: hostname slug"                    prints shawns-macbook-pro-2
printf '{\n  "repoPath": "/tmp/backup",\n  "includeLocalSettings": false\n}\n' > "$CFG"
check "no machine key: hostname slug"                    prints shawns-macbook-pro-2
stored studio
check "stored name wins over hostname"                   prints studio
printf '{"repoPath": "/tmp/backup", "machine": "studio-2", "includeLocalSettings": true}\n' > "$CFG"
check "stored name on a one-line config"                 prints studio-2
stored ../evil
check "rejects ../evil"                                  rejects
stored -x
check "rejects -x"                                       rejects
stored 'Has Space'
check "rejects Has Space"                                rejects
stored 'has space'
check "rejects has space"                                rejects
stored ''
check "rejects an empty value"                           rejects
stored Studio
check "rejects an uppercase stored name"                 rejects
stored "$(printf 'a%.0s' $(seq 63))"
check "accepts 63 characters"                            prints "$(printf 'a%.0s' $(seq 63))"
stored "$(printf 'a%.0s' $(seq 64))"
check "rejects 64 characters"                            rejects
printf '{"repoPath": "/tmp/backup", "machine": 7}\n' > "$CFG"
check "rejects a non-string machine"                     rejects
rm -f "$CFG"
shim_hostname "Shawn's MacBook Pro (2)"
check "slug collapses runs and trims hyphens"            prints shawn-s-macbook-pro-2
shim_hostname '!!!'
check "rejects a hostname with nothing usable"           rejects

echo
if [ "$FAILURES" -ne 0 ]; then
  echo "FAIL ($FAILURES)"
  exit 1
fi
echo "PASS"
