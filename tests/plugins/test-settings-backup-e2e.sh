#!/usr/bin/env bash
set -euo pipefail

# The settings-backup file list stopped at hooks/, yet the files it already
# captured point past it: settings.json names a style in output-styles/, its
# SessionEnd hook runs a script in scripts/, CLAUDE.md links files in
# reference/, and agents/ holds the user's subagents. A restore from that
# backup looked complete and was not. Separately, every run wrote a fresh
# timestamp into .settings-sync-meta.json before asking whether anything had
# changed, so 4,477 of one real repo's 4,601 commits changed only that file —
# and an ignore rule added after the fact never untracked the .pyc files
# already committed.
#
# This test runs the skill's own snippets — extracted from SKILL.md by marker,
# never paraphrased — against a throwaway home and a scratch repo, twice: once
# with new content, once with nothing changed.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/settings-sync/skills/settings-backup/SKILL.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- a fake home holding every target, including the four new folders -------
HOME_DIR="$TMP/home"
SRC="$HOME_DIR/.claude"
mkdir -p "$SRC/rules" "$SRC/commands" "$SRC/skills/demo" "$SRC/hooks" "$SRC/agents" \
         "$SRC/output-styles" "$SRC/scripts/__pycache__" "$SRC/reference"
echo '{"outputStyle":"s"}' > "$SRC/settings.json"
echo '# global'            > "$SRC/CLAUDE.md"
echo 'rule'                > "$SRC/rules/r.md"
echo 'cmd'                 > "$SRC/commands/c.md"
echo 'skill'               > "$SRC/skills/demo/SKILL.md"
echo 'hook'                > "$SRC/hooks/h.sh"
echo 'agent'               > "$SRC/agents/a.md"
echo 'style'               > "$SRC/output-styles/s.md"
echo 'script'              > "$SRC/scripts/x.sh"
printf 'bytecode'          > "$SRC/scripts/__pycache__/x.pyc"
echo 'ref'                 > "$SRC/reference/r.md"

# --- a fake `claude` so the version in the metadata is deterministic --------
mkdir -p "$TMP/bin"
printf '#!/bin/sh\necho 9.9.9-test\n' > "$TMP/bin/claude"
chmod +x "$TMP/bin/claude"

# --- a scratch repo whose one commit already tracks a .pyc and a .sync-log,
#     behind a .gitignore written before either rule existed (the real repo) ---
REPO="$TMP/backup"
git -c init.defaultBranch=main init -q "$REPO"
git -C "$REPO" config user.name test
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config commit.gpgsign false
printf '.DS_Store\n' > "$REPO/.gitignore"
mkdir -p "$REPO/scripts/__pycache__"
printf 'stale' > "$REPO/scripts/__pycache__/x.pyc"
: > "$REPO/.sync-log"
echo '{}' > "$REPO/settings.json"
printf 'stray' > "$REPO/weird\"name.txt"   # a hand-added root entry with a quote in its name
git -C "$REPO" add -A
git -C "$REPO" commit -q -m "initial"

# --- extract the three marked blocks, in the order the skill runs them ------
extract() {
  SNIPPET="$(awk -v m="$1" 'index($0, m) == 1 {f=1} f && /^```bash/ {c=1; next} c && /^```/ {exit} c {print}' "$SKILL")"
  if [ -z "$SNIPPET" ]; then
    echo "FAIL: no bash block after '$1' in $SKILL"
    exit 1
  fi
  SNIPPET="${SNIPPET//<repo-path>/$REPO}"
}
extract '**Ignore rules and already-tracked files.**'; STEP2="$SNIPPET"
extract '**Copy the targets.**';                       COPY="$SNIPPET"
extract '**Commit only real changes.**';               COMMIT="$SNIPPET"

run_block() {  # $1 label, $2 snippet — output lands in $TMP/out
  local rc=0
  HOME="$HOME_DIR" PATH="$TMP/bin:$PATH" bash -c "$2" >"$TMP/out" 2>&1 || rc=$?
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
tracked()     { git -C "$REPO" ls-files | grep -q -- "$1"; }
not_tracked() { ! tracked "$1"; }
commits()     { git -C "$REPO" rev-list --count HEAD; }
clean_tree()  { [ -z "$(git -C "$REPO" status --porcelain)" ]; }

# --- run 1: new content -----------------------------------------------------
run_block "Step 2 block"  "$STEP2"
run_block "copy block"    "$COPY"
run_block "commit block"  "$COMMIT"

check "agents/ lands in the repo root"          test -f "$REPO/agents/a.md"
check "output-styles/ lands in the repo root"   test -f "$REPO/output-styles/s.md"
check "scripts/ lands in the repo root"         test -f "$REPO/scripts/x.sh"
check "reference/ lands in the repo root"       test -f "$REPO/reference/r.md"
check "an existing target is still copied"      test -f "$REPO/hooks/h.sh"
check "ignore rules were appended, not assumed" bash -c 'grep -qx "__pycache__/" "$1" && grep -qx ".sync-log" "$1"' _ "$REPO/.gitignore"
check "the tracked .pyc is untracked"           not_tracked '\.pyc$'
check "the tracked .sync-log is untracked"      not_tracked '^\.sync-log$'
check "the .pyc working file still exists"      test -f "$REPO/scripts/__pycache__/x.pyc"
check "the .sync-log working file still exists" test -f "$REPO/.sync-log"
check "run 1 made exactly one commit"           test "$(commits)" = 2
check "run 1 printed committed"                 grep -qx committed "$TMP/out"
check "metadata records the CLI version"        grep -q '"claudeVersion": "9.9.9-test"' "$REPO/.settings-sync-meta.json"
check "metadata lists the four new folders"     bash -c 'for d in agents output-styles scripts reference; do grep -q "\"$d\"" "$1" || exit 1; done' _ "$REPO/.settings-sync-meta.json"
check "metadata parses as JSON"                 python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$REPO/.settings-sync-meta.json"
check "metadata escapes a quote in a stray name"  python3 -c 'import json,sys; sys.exit(0 if "weird\"name.txt" in json.load(open(sys.argv[1]))["filesIncluded"] else 1)' "$REPO/.settings-sync-meta.json"
check "run 1 leaves a clean tree"               clean_tree
check "run 1 wrote nothing to .sync-log"        test "$(wc -l < "$REPO/.sync-log" | tr -d ' ')" = 0

# --- run 2: nothing changed -------------------------------------------------
run_block "copy block (second run)"   "$COPY"
run_block "commit block (second run)" "$COMMIT"

check "run 2 adds no commit"                    test "$(commits)" = 2
check "run 2 printed no-change"                 grep -qx no-change "$TMP/out"
check ".sync-log has exactly one line"          test "$(wc -l < "$REPO/.sync-log" | tr -d ' ')" = 1
check "run 2 leaves a clean tree"               clean_tree
check ".sync-log is still untracked"            not_tracked '^\.sync-log$'

echo
if [ "$FAILURES" -ne 0 ]; then
  echo "FAIL ($FAILURES)"
  exit 1
fi
echo "PASS"
