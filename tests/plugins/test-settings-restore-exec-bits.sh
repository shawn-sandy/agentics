#!/usr/bin/env bash
set -euo pipefail

# Step 7 of settings-restore verifies that hooks/ scripts kept their execute
# bit after the copy. The first version of that check was a blanket
# `find ~/.claude/hooks -type f ! -perm -u+x` — every non-executable file was
# a FAILED entry, including hooks invoked through an interpreter
# (`python3 hook.py`) that were never executable in the backup either. A
# perfect restore of such a backup was reported INCOMPLETE.
#
# This test runs the skill's actual snippet — extracted from SKILL.md, not
# copied here, so the two cannot drift — against a fixture with three hooks:
# one that lost its bit (must be reported), one that never had it (must not
# be), and one that kept it (must not be).

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/settings-sync/skills/settings-restore/SKILL.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/backup"
HOME_DIR="$TMP/home"
mkdir -p "$REPO/hooks" "$HOME_DIR/.claude/hooks"

for name in lost.sh kept.sh check.py; do
  printf '#!/bin/sh\n' >"$REPO/hooks/$name"
  cp "$REPO/hooks/$name" "$HOME_DIR/.claude/hooks/$name"
done
# lost.sh  — executable in the backup, not locally -> must be reported
# kept.sh  — executable in both                    -> must not be
# check.py — executable in neither (python3 hook)  -> must not be
chmod +x "$REPO/hooks/lost.sh" "$REPO/hooks/kept.sh" "$HOME_DIR/.claude/hooks/kept.sh"
# linked.sh — a symlink in the backup to an executable script. Step 6 copies
#             with -L, so locally it is a regular file; here its bit is lost
#             -> must be reported (a find without -L never sees the symlink)
printf '#!/bin/sh\n' >"$TMP/target.sh"
chmod +x "$TMP/target.sh"
ln -s "$TMP/target.sh" "$REPO/hooks/linked.sh"
cp -L "$REPO/hooks/linked.sh" "$HOME_DIR/.claude/hooks/linked.sh"
chmod -x "$HOME_DIR/.claude/hooks/linked.sh"

# The fenced bash block that follows the "**Executable bits.**" paragraph.
SNIPPET="$(awk '/^\*\*Executable bits\.\*\*/{f=1} f&&/^```bash/{c=1;next} c&&/^```/{exit} c{print}' "$SKILL")"
if [ -z "$SNIPPET" ]; then
  echo "FAIL: no bash block after '**Executable bits.**' in $SKILL"
  exit 1
fi
SNIPPET="${SNIPPET//<repo-path>/$REPO}"

set +e
OUT="$(HOME="$HOME_DIR" bash -c "$SNIPPET" 2>&1)"
RC=$?
set -e
if [ "$RC" -ne 0 ]; then
  echo "FAIL: snippet exited $RC"
  printf '%s\n' "$OUT" | sed 's/^/  | /'
  exit 1
fi

FAILURES=0
expect() {
  local mode="$1" pattern="$2" label="$3" hit=0
  grep -q "$pattern" <<<"$OUT" && hit=1
  if { [ "$mode" = present ] && [ "$hit" -eq 1 ]; } || { [ "$mode" = absent ] && [ "$hit" -eq 0 ]; }; then
    echo "ok   $label"
  else
    echo "FAIL $label"
    FAILURES=$((FAILURES + 1))
  fi
}

expect present 'lost\.sh'  "a hook that lost its execute bit is reported"
expect absent  'check\.py' "a hook that was never executable (interpreter-run) is not reported"
expect absent  'kept\.sh'  "a hook that kept its execute bit is not reported"
expect present 'linked\.sh' "a hook stored as a symlink in the backup is still checked"

echo
echo "snippet output:"
printf '%s\n' "$OUT" | sed 's/^/  | /'

if [ "$FAILURES" -ne 0 ]; then
  echo "FAIL ($FAILURES)"
  exit 1
fi
echo "PASS"
