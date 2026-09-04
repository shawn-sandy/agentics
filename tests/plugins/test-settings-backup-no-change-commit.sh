#!/usr/bin/env bash
set -euo pipefail

# settings-backup used to write .settings-sync-meta.json with a fresh
# timestamp and only then ask git whether anything had changed — so the answer
# was always yes. 4,477 of one real backup repo's 4,601 commits changed only
# that file, and `git log` could no longer show when a setting changed. The
# commit block now stages first, checks second, and writes the metadata only
# inside the real-change branch. A no-change run appends one line to the
# local, gitignored .sync-log and touches nothing git tracks.
#
# The e2e test proves the commit count; this one isolates the metadata file,
# which the e2e fixture cannot: it starts from a repo that already carries an
# old timestamp and asserts that only a real change replaces it.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/settings-sync/skills/settings-backup/SKILL.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/bin"
printf '#!/bin/sh\necho 9.9.9-test\n' > "$TMP/bin/claude"
chmod +x "$TMP/bin/claude"

OLD_TS='2026-01-01T00:00:00Z'
REPO="$TMP/backup"
git -c init.defaultBranch=main init -q "$REPO"
git -C "$REPO" config user.name test
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config commit.gpgsign false
printf '.sync-log\n' > "$REPO/.gitignore"
echo '{"a":1}' > "$REPO/settings.json"
cat > "$REPO/.settings-sync-meta.json" <<META
{
  "hostname": "old-host",
  "timestamp": "$OLD_TS",
  "claudeVersion": "unknown",
  "filesIncluded": ["settings.json"]
}
META
git -C "$REPO" add -A
git -C "$REPO" commit -q -m "initial"

SNIPPET="$(awk 'index($0, "**Commit only real changes.**") == 1 {f=1} f && /^```bash/ {c=1; next} c && /^```/ {exit} c {print}' "$SKILL")"
if [ -z "$SNIPPET" ]; then
  echo "FAIL: no bash block after '**Commit only real changes.**' in $SKILL"
  exit 1
fi
SNIPPET="${SNIPPET//<repo-path>/$REPO}"

run_block() {  # $1 label — output lands in $TMP/out
  local rc=0
  PATH="$TMP/bin:$PATH" bash -c "$SNIPPET" >"$TMP/out" 2>&1 || rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "FAIL: $1 exited $rc"
    sed 's/^/  | /' "$TMP/out"
    exit 1
  fi
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
commits()    { git -C "$REPO" rev-list --count HEAD; }
meta_ts()    { sed -n 's/.*"timestamp": "\([^"]*\)".*/\1/p' "$REPO/.settings-sync-meta.json"; }
clean_tree() { [ -z "$(git -C "$REPO" status --porcelain)" ]; }
meta_in_head() { ! git -C "$REPO" diff --quiet HEAD~1 HEAD -- .settings-sync-meta.json; }

# --- no change ---------------------------------------------------------------
run_block "commit block (no change)"
check "no change: commit count unchanged"        test "$(commits)" = 1
check "no change: prints no-change"              grep -qx no-change "$TMP/out"
check "no change: .sync-log gained one line"     test "$(wc -l < "$REPO/.sync-log" | tr -d ' ')" = 1
check "no change: git status is clean"           clean_tree
check "no change: metadata timestamp untouched"  test "$(meta_ts)" = "$OLD_TS"

# --- a real change -----------------------------------------------------------
echo '{"a":2}' >> "$REPO/settings.json"
run_block "commit block (real change)"
check "change: commit count rose by one"         test "$(commits)" = 2
check "change: prints committed"                 grep -qx committed "$TMP/out"
check "change: metadata timestamp refreshed"     test "$(meta_ts)" != "$OLD_TS"
check "change: metadata is in the commit"        meta_in_head
check "change: git status is clean"              clean_tree
check "change: .sync-log did not grow"           test "$(wc -l < "$REPO/.sync-log" | tr -d ' ')" = 1

echo
if [ "$FAILURES" -ne 0 ]; then
  echo "FAIL ($FAILURES)"
  exit 1
fi
echo "PASS"
