#!/usr/bin/env bash
set -euo pipefail

# Restore used to copy settings.json whole. Restoring the primary Mac's branch
# onto the secondary then replaced the secondary's permission rules with ones
# naming the primary's home directory. Restore now keeps this machine's
# `permissions` and `autoMode` and takes every other key from the backup.
#
# This test runs the skill's own `**Keep this machine's permissions.**` block —
# extracted from SKILL.md, not copied here, so the two cannot drift — against a
# fake HOME. The block prints the merged settings.json; Step 6 moves that
# output into place, Step 4 previews against it, and Step 7 verifies with it.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/settings-sync/skills/settings-restore/SKILL.md"
MARK="**Keep this machine's permissions.**"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SNIPPET="$(awk -v m="$MARK" 'index($0, m) == 1 {f=1} f && /^```bash/ {c=1; next} c && /^```/ {exit} c {print}' "$SKILL")"
if [ -z "$SNIPPET" ]; then
  echo "FAIL: no bash block after '$MARK' in $SKILL"
  exit 1
fi

REPO="$TMP/backup"
HOME_DIR="$TMP/home"
LOCAL="$HOME_DIR/.claude/settings.json"
mkdir -p "$REPO" "$HOME_DIR/.claude"
SNIPPET="${SNIPPET//<repo-path>/$REPO}"
BASH_BIN="$(command -v bash)"

# The primary Mac's backup: compact and without a trailing newline, so a block
# that reformats it instead of passing it through byte for byte is caught.
BACKUP_JSON='{"theme":"dark","enabledPlugins":{"a@kit":true,"b@kit":true},"hooks":{"Stop":[]},"permissions":{"allow":["Read(/Users/primary/**)"]},"autoMode":"primary repo text"}'
LOCAL_JSON='{
  "theme": "light",
  "enabledPlugins": {"a@kit": false},
  "localOnly": 1,
  "permissions": {"allow": ["Read(/Users/secondary/**)"], "deny": ["Bash(rm *)"]},
  "autoMode": "secondary repo text"
}'

run_block() {  # $1 output file; extra env via the caller. Status in $RC.
  RC=0
  HOME="$HOME_DIR" "$BASH_BIN" -c "$SNIPPET" >"$1" 2>"$TMP/err" || RC=$?
}
run_block_without_jq() {  # $1 output file — PATH holds only cat, so no jq
  mkdir -p "$TMP/nojq"
  ln -sf "$(command -v cat)" "$TMP/nojq/cat"
  RC=0
  HOME="$HOME_DIR" PATH="$TMP/nojq" "$BASH_BIN" -c "$SNIPPET" >"$1" 2>"$TMP/err" || RC=$?
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
# jq_true <filter> — evaluates with $out, $backup, $local bound to the files'
# parsed values; succeeds only when the filter yields true.
jq_true() {
  jq -e -n --slurpfile out "$TMP/out" --slurpfile backup "$REPO/settings.json" \
    --slurpfile local "$TMP/local.saved" "$1"
}

printf '%s' "$BACKUP_JSON" >"$REPO/settings.json"

# --- this machine has its own permissions and autoMode -----------------------
printf '%s\n' "$LOCAL_JSON" >"$LOCAL"
cp "$LOCAL" "$TMP/local.saved"
run_block "$TMP/out"
check "both kept: exits 0"                               test "$RC" -eq 0
check "both kept: output is one JSON object"             jq_true '($out | length) == 1 and ($out[0] | type) == "object"'
check "both kept: theme comes from the backup"           jq_true '$out[0].theme == $backup[0].theme'
check "both kept: enabledPlugins come from the backup"   jq_true '$out[0].enabledPlugins == $backup[0].enabledPlugins'
check "both kept: permissions are this machine's"        jq_true '$out[0].permissions == $local[0].permissions'
check "both kept: autoMode is this machine's"            jq_true '$out[0].autoMode == $local[0].autoMode'
check "both kept: every other key is the backup's, nothing local leaks in" \
  jq_true '($out[0] | del(.permissions, .autoMode)) == ($backup[0] | del(.permissions, .autoMode))'
check "both kept: block did not touch the local file"    cmp -s "$LOCAL" "$TMP/local.saved"

# A second run over its own result changes nothing.
cp "$TMP/out" "$LOCAL"
run_block "$TMP/out2"
check "second run: exits 0"                              test "$RC" -eq 0
check "second run: byte-identical output"                cmp -s "$TMP/out" "$TMP/out2"

# --- this machine has permissions but no autoMode ----------------------------
printf '%s\n' '{"theme":"light","permissions":{"allow":["Read(/Users/secondary/**)"]}}' >"$LOCAL"
cp "$LOCAL" "$TMP/local.saved"
run_block "$TMP/out"
check "no local autoMode: exits 0"                       test "$RC" -eq 0
check "no local autoMode: the backup's autoMode is dropped" jq_true '$out[0] | has("autoMode") | not'
check "no local autoMode: permissions are this machine's"   jq_true '$out[0].permissions == $local[0].permissions'
check "no local autoMode: theme comes from the backup"      jq_true '$out[0].theme == $backup[0].theme'

# --- no settings.json on this machine ----------------------------------------
rm "$LOCAL"
run_block "$TMP/out"
check "no local file: exits 0"                           test "$RC" -eq 0
check "no local file: output is the backup byte for byte" cmp -s "$TMP/out" "$REPO/settings.json"

# --- invalid JSON on either side ---------------------------------------------
printf '%s\n' '{"permissions": {"allow": [' >"$LOCAL"
cp "$LOCAL" "$TMP/local.saved"
run_block "$TMP/out"
check "invalid local JSON: exits non-zero"               test "$RC" -ne 0
check "invalid local JSON: local file unchanged"         cmp -s "$LOCAL" "$TMP/local.saved"

printf '%s\n' "$LOCAL_JSON" >"$LOCAL"
cp "$LOCAL" "$TMP/local.saved"
printf '%s' '{"theme": "dark",' >"$REPO/settings.json"
run_block "$TMP/out"
check "invalid backup JSON: exits non-zero"              test "$RC" -ne 0
check "invalid backup JSON: local file unchanged"        cmp -s "$LOCAL" "$TMP/local.saved"

# jq reads whitespace as zero values and exits 0 with no output — an empty
# file that Step 6 would move over this machine's settings.json.
printf ' \n' >"$REPO/settings.json"
run_block "$TMP/out"
check "blank backup: exits non-zero"                     test "$RC" -ne 0
printf '%s' "$BACKUP_JSON" >"$REPO/settings.json"

# --- jq missing --------------------------------------------------------------
run_block_without_jq "$TMP/out"
check "jq missing: exits non-zero"                       test "$RC" -ne 0
check "jq missing: local file unchanged"                 cmp -s "$LOCAL" "$TMP/local.saved"

echo
if [ "$FAILURES" -ne 0 ]; then
  echo "last block stderr:"
  sed 's/^/  | /' "$TMP/err"
  echo "FAIL ($FAILURES)"
  exit 1
fi
echo "PASS"
