#!/usr/bin/env bash
set -euo pipefail

# settings-backup copies a fixed target list into the repo root, and
# settings-restore copies back every root entry it finds. Nothing in between
# ever mentioned a root entry that is no longer a target — a plans/ directory
# left behind by an older version sat in a real backup for six weeks and would
# have been restored onto every new machine. The skill now lists such entries
# and reports them, without deleting anything (a hand-added entry is
# deliberate).
#
# This test runs the skill's actual snippet — extracted from SKILL.md, not
# copied here — against a fixture repo holding targets, control files, and
# three strays, and asserts only the strays are printed.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/settings-sync/skills/settings-backup/SKILL.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/backup"
mkdir -p "$REPO/.git" "$REPO/rules" "$REPO/hooks" "$REPO/plans" "$REPO/vscode"
touch "$REPO/.gitignore" "$REPO/.sync-log" "$REPO/.settings-sync-meta.json" \
      "$REPO/settings.json" "$REPO/CLAUDE.md" "$REPO/notes.txt"
# targets + control files: never printed.   strays: plans/ vscode/ notes.txt

SNIPPET="$(awk '/^\*\*Entries that are not targets\.\*\*/{f=1} f&&/^```bash/{c=1;next} c&&/^```/{exit} c{print}' "$SKILL")"
if [ -z "$SNIPPET" ]; then
  echo "FAIL: no bash block after '**Entries that are not targets.**' in $SKILL"
  exit 1
fi
SNIPPET="${SNIPPET//<repo-path>/$REPO}"

set +e
OUT="$(bash -c "$SNIPPET" 2>&1)"
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
  grep -qx "$pattern" <<<"$OUT" && hit=1
  if { [ "$mode" = present ] && [ "$hit" -eq 1 ]; } || { [ "$mode" = absent ] && [ "$hit" -eq 0 ]; }; then
    echo "ok   $label"
  else
    echo "FAIL $label"
    FAILURES=$((FAILURES + 1))
  fi
}

expect present 'plans'          "a stale directory is reported"
expect present 'vscode'         "a second stale directory is reported"
expect present 'notes.txt'      "a stray root file is reported"
expect absent  'rules'          "a directory target is not reported"
expect absent  'hooks'          "a second directory target is not reported"
expect absent  'settings.json'  "a file target is not reported"
expect absent  'CLAUDE.md'      "a second file target is not reported"
expect absent  '.git'           "the .git directory is not reported"
expect absent  '.gitignore'     "a control file is not reported"
expect absent  '.sync-log'      "a second control file is not reported"

echo
echo "snippet output:"
printf '%s\n' "$OUT" | sed 's/^/  | /'

if [ "$FAILURES" -ne 0 ]; then
  echo "FAIL ($FAILURES)"
  exit 1
fi
echo "PASS"
