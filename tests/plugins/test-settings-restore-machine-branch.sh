#!/usr/bin/env bash
set -euo pipefail

# settings-backup 1.3.0 writes each machine to its own `machines/<name>`
# branch; `master` is frozen 1.2 history holding whichever machine pushed last.
# Restore has to list the machines, check out the chosen one, and still
# restore a 1.2 repo that has no machine branch at all.
#
# This test runs the skill's own `**List machine branches.**` and
# `**Check out the chosen machine.**` blocks — extracted from SKILL.md, not
# copied here, so the two cannot drift — against a bare origin built with
# plain git: a legacy `master` newer than every machine branch (so its absence
# from the list is not an accident of ordering), `machines/alpha`, and
# `machines/beta` with different settings.json.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/settings-sync/skills/settings-restore/SKILL.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

extract() {  # $1 bold marker line — prints the first bash block after it
  awk -v m="$1" 'index($0, m) == 1 {f=1} f && /^```bash/ {c=1; next} c && /^```/ {exit} c {print}' "$SKILL"
}
LIST="$(extract '**List machine branches.**')"
if [ -z "$LIST" ]; then
  echo "FAIL: no bash block after '**List machine branches.**' in $SKILL"
  exit 1
fi
CHECKOUT="$(extract '**Check out the chosen machine.**')"
if [ -z "$CHECKOUT" ]; then
  echo "FAIL: no bash block after '**Check out the chosen machine.**' in $SKILL"
  exit 1
fi
SWITCHBACK="$(extract "**Switch back to this machine's branch.**")"
if [ -z "$SWITCHBACK" ]; then
  echo "FAIL: no bash block after '**Switch back to this machine's branch.**' in $SKILL"
  exit 1
fi

export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

commit_at() {  # $1 repo, $2 date, $3 settings.json body
  printf '%s\n' "$3" >"$1/settings.json"
  git -C "$1" add -A
  GIT_AUTHOR_DATE="$2" GIT_COMMITTER_DATE="$2" git -C "$1" commit -q -m "backup $2"
}

# --- the shared origin -------------------------------------------------------
SEED="$TMP/seed"
git init -q -b master "$SEED"
commit_at "$SEED" 2025-12-01T00:00:00Z '{"who":"legacy"}'
git -C "$SEED" switch -q -c machines/alpha
commit_at "$SEED" 2026-01-01T00:00:00Z '{"who":"alpha"}'
git -C "$SEED" switch -q master
git -C "$SEED" switch -q -c machines/beta
commit_at "$SEED" 2026-01-15T00:00:00Z '{"who":"beta-old"}'
commit_at "$SEED" 2026-02-01T00:00:00Z '{"who":"beta"}'
git -C "$SEED" switch -q master
commit_at "$SEED" 2026-03-01T00:00:00Z '{"who":"legacy-newest"}'
# Branch names git accepts but the machine pattern does not. Never offered:
# the chosen name is substituted into the checkout block as shell text.
git -C "$SEED" branch machines/Bad_Name machines/beta
git -C "$SEED" branch "machines/x';touch\${IFS}pwned;'" machines/beta

ORIGIN="$TMP/origin.git"
git clone -q --bare "$SEED" "$ORIGIN"
CLONE="$TMP/clone"
git clone -q "$ORIGIN" "$CLONE"

# run_block <script> <repo> [machine-name] — stdout+stderr in $OUT, status in $RC
run_block() {
  local s="${1//<repo-path>/$2}"
  s="${s//<machine-name>/${3:-}}"
  RC=0
  OUT="$(bash -c "$s" 2>"$TMP/err")" || RC=$?
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
listed() { [ "$RC" -eq 0 ] && [ "$OUT" = "$(printf '%s\n' "$@")" ]; }
head_ref() { git -C "$CLONE" symbolic-ref -q HEAD; }
head_who() { sed -n 's/.*"who":"\([^"]*\)".*/\1/p' "$CLONE/settings.json"; }
state() { git -C "$CLONE" for-each-ref --format='%(refname) %(objectname)' refs/heads; head_ref; git -C "$CLONE" rev-parse HEAD; }

# --- listing -----------------------------------------------------------------
run_block "$LIST" "$CLONE"
check "list: exactly beta then alpha, newest first, master absent" listed beta alpha
echo "     got: $(printf '%s' "$OUT" | tr '\n' ' ')"

git -C "$CLONE" branch -q machines/alpha origin/machines/alpha
run_block "$LIST" "$CLONE"
check "list: a local machines/alpha beside origin's is not listed twice" listed beta alpha

git -C "$CLONE" remote set-url origin "$TMP/missing.git"
run_block "$LIST" "$CLONE"
check "list: an unreachable origin is not an error (local refs listed)" listed beta alpha
git -C "$CLONE" remote set-url origin "$ORIGIN"

git -C "$SEED" switch -q -c machines/gamma
commit_at "$SEED" 2026-04-01T00:00:00Z '{"who":"gamma"}'
git -C "$SEED" push -q "$ORIGIN" machines/gamma
run_block "$LIST" "$CLONE"
check "list: fetches origin first, so a branch pushed after the clone is listed" listed gamma beta alpha

# --- checkout ----------------------------------------------------------------
# A stale local machines/beta one commit behind origin: only the pull brings
# beta's newest settings.json into the tree.
git -C "$CLONE" branch -q --track machines/beta origin/machines/beta
git -C "$CLONE" update-ref refs/heads/machines/beta origin/machines/beta~1
run_block "$CHECKOUT" "$CLONE" beta
check "checkout beta: exits 0"                          test "$RC" -eq 0
check "checkout beta: HEAD is machines/beta"            test "$(head_ref)" = refs/heads/machines/beta
check "checkout beta: fast-forwarded to origin's tip"   test "$(git -C "$CLONE" rev-parse HEAD)" = "$(git -C "$CLONE" rev-parse origin/machines/beta)"
check "checkout beta: beta's settings.json in the tree" test "$(head_who)" = beta

run_block "$CHECKOUT" "$CLONE" gamma
check "checkout gamma (remote only): exits 0"                  test "$RC" -eq 0
check "checkout gamma (remote only): HEAD is machines/gamma"   test "$(head_ref)" = refs/heads/machines/gamma
check "checkout gamma (remote only): tracks origin"            test "$(git -C "$CLONE" rev-parse --abbrev-ref '@{upstream}')" = origin/machines/gamma
check "checkout gamma (remote only): gamma's settings.json"    test "$(head_who)" = gamma

# Names git itself accepts but the pattern does not: only the skill's own
# validation can stop these, so the branches exist and a bare switch would
# succeed.
git -C "$CLONE" branch -q machines/-x
git -C "$CLONE" branch -q machines/x_y
for bad in ../x -x x_y ''; do
  before="$(state)"
  run_block "$CHECKOUT" "$CLONE" "$bad"
  check "checkout '$bad': exits non-zero"            test "$RC" -ne 0
  check "checkout '$bad': HEAD and branches unchanged" test "$(state)" = "$before"
done

# A valid name with no branch behind it: the switch fails, and the block must
# stop rather than pull and restore whichever machine is checked out.
before="$(state)"
run_block "$CHECKOUT" "$CLONE" nosuch
check "checkout 'nosuch' (no branch): exits non-zero"    test "$RC" -ne 0
check "checkout 'nosuch' (no branch): HEAD unchanged"    test "$(state)" = "$before"

# --- switching back after the restore ----------------------------------------
# A real restore left the secondary Mac's clone on the primary's branch, and
# that Mac's session-end backup script then committed its own settings onto
# it and pushed them over the primary's backup. Restore's last git step puts
# the clone back on the branch this clone claimed, so nothing branch-unaware
# is ever left writing another machine's branch.
git -C "$CLONE" switch -q machines/beta
git -C "$CLONE" config settings-sync.branch machines/alpha
run_block "$SWITCHBACK" "$CLONE"
check "switch back: exits 0"                                test "$RC" -eq 0
check "switch back: HEAD is this clone's claimed branch"    test "$(head_ref)" = refs/heads/machines/alpha
check "switch back: the restored machine's branch is left"  test "$(git -C "$CLONE" rev-parse --abbrev-ref HEAD)" != machines/beta

# A clone that never backed up claims nothing: stay put, so this machine's first
# backup still starts its branch from the restored machine's history.
git -C "$CLONE" switch -q machines/beta
git -C "$CLONE" config --unset settings-sync.branch
before="$(state)"
run_block "$SWITCHBACK" "$CLONE"
check "switch back, unclaimed: exits 0"                     test "$RC" -eq 0
check "switch back, unclaimed: HEAD and branches unchanged" test "$(state)" = "$before"

# A claimed branch the switch cannot reach (deleted locally and on origin) is reported.
git -C "$CLONE" config settings-sync.branch machines/nowhere
run_block "$SWITCHBACK" "$CLONE"
check "switch back, unreachable: exits non-zero"            test "$RC" -ne 0
git -C "$CLONE" config --unset settings-sync.branch

# --- a 1.2 repo --------------------------------------------------------------
OLD_SEED="$TMP/old-seed"
git init -q -b master "$OLD_SEED"
commit_at "$OLD_SEED" 2025-12-01T00:00:00Z '{"who":"legacy"}'
git clone -q --bare "$OLD_SEED" "$TMP/old-origin.git"
git clone -q "$TMP/old-origin.git" "$TMP/old-clone"
run_block "$LIST" "$TMP/old-clone"
check "1.2 repo: no machine branch lists nothing and exits 0" test "$RC" -eq 0 -a -z "$OUT"

echo
if [ "$FAILURES" -ne 0 ]; then
  echo "last block stderr:"
  sed 's/^/  | /' "$TMP/err"
  echo "FAIL ($FAILURES)"
  exit 1
fi
echo "PASS"
