#!/usr/bin/env bash
set -euo pipefail

# Two Macs backing up into one repo left it holding only one of them. Every
# run mirrored that machine over the other's files, and the backup never
# pulled, so the machine whose clone fell behind committed on a stale base,
# had its push rejected as non-fast-forward, and kept committing locally on
# every scheduled run without ever pushing again.
#
# 1.3.0 gives each machine its own branch, machines/<name>, so every branch has
# exactly one writer. This test runs the skill's own blocks — extracted from
# SKILL.md by marker, never paraphrased — for two fake machines against one
# bare remote: alpha, then beta (whose clone holds an unpushed 1.2 commit and
# has nothing new to commit), then each again after an edit, then a third
# clone that reuses the name alpha and must be stopped, not merged.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/settings-sync/skills/settings-backup/SKILL.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- git isolated from the user's config (signing, hooks, default branch) ---
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL="$TMP/gitconfig"
git config --global user.name test
git config --global user.email test@example.com
git config --global commit.gpgsign false
git config --global init.defaultBranch master

mkdir -p "$TMP/bin"
printf '#!/bin/sh\necho 9.9.9-test\n' > "$TMP/bin/claude"
chmod +x "$TMP/bin/claude"

# --- one bare origin, seeded with a single master commit. Its commands/ is a
#     folder neither machine has: a branch created from master must drop it --
ORIGIN="$TMP/origin.git"
git init -q --bare "$ORIGIN"
git clone -q "$ORIGIN" "$TMP/seed" 2>/dev/null
echo seed > "$TMP/seed/README"
mkdir "$TMP/seed/commands" && echo legacy > "$TMP/seed/commands/old.md"
echo '{"legacy":true}' > "$TMP/seed/settings.local.json"   # opt-in file neither machine opted into
git -C "$TMP/seed" add -A
git -C "$TMP/seed" commit -q -m seed
git -C "$TMP/seed" push -q origin master
SEED="$(git -C "$ORIGIN" rev-parse master)"

# --- a fake home per machine: own settings.json, a shared rule, one skill only
#     that machine has, and a settings-sync.json naming the machine ---------
mk_machine() {  # $1 label, $2 machine name
  local claude="$TMP/home-$1/.claude"
  mkdir -p "$claude/rules" "$claude/skills/$1-only"
  printf '{"permissions":{"allow":["Read(/Users/%s/**)"]}}\n' "$1" > "$claude/settings.json"
  echo shared        > "$claude/rules/r.md"
  echo "$1 skill"    > "$claude/skills/$1-only/SKILL.md"
  printf '{\n  "repoPath": "%s",\n  "machine": "%s"\n}\n' "$TMP/clone-$1" "$2" > "$claude/settings-sync.json"
}
mk_machine alpha alpha
mk_machine beta beta

# Both clones exist before either machine runs — the real starting point. So
# does epsilon's: a third Mac that will reuse the name alpha, whose clone has
# never seen machines/alpha until the backup fetches.
git clone -q "$ORIGIN" "$TMP/clone-alpha"
git clone -q "$ORIGIN" "$TMP/clone-beta"
git clone -q "$ORIGIN" "$TMP/clone-epsilon"

extract() {  # $1 marker — prints the fenced bash block that follows it
  awk -v m="$1" 'index($0, m) == 1 {f=1} f && /^```bash/ {c=1; next} c && /^```/ {exit} c {print}' "$SKILL"
}
need() {  # $1 marker, $2 block
  if [ -z "$2" ]; then
    echo "FAIL: no bash block after '$1' in $SKILL"
    exit 1
  fi
}
RESOLVE="$(extract '**Resolve the machine name.**')"
SWITCH="$(extract '**Switch to the machine branch.**')"
STEP2="$(extract '**Ignore rules and already-tracked files.**')"
COPY="$(extract '**Copy the targets.**')"
COMMIT="$(extract '**Commit only real changes.**')"
PUSH="$(extract '**Push the machine branch.**')"
need '**Resolve the machine name.**' "$RESOLVE"
need '**Switch to the machine branch.**' "$SWITCH"
need '**Ignore rules and already-tracked files.**' "$STEP2"
need '**Copy the targets.**' "$COPY"
need '**Commit only real changes.**' "$COMMIT"
need '**Push the machine branch.**' "$PUSH"

# The blocks run in the Bash tool's shell, which is zsh on macOS, where an
# unquoted $var does not word-split. Run them under zsh (no startup files, so
# default options) wherever it exists, bash otherwise.
if command -v zsh >/dev/null 2>&1; then BLOCK_SH="zsh -f"; else BLOCK_SH="bash"; fi
echo "blocks run under: $BLOCK_SH"
run_block() {  # $1 label, $2 machine name, $3 block — output appends to $TMP/out
  local home="$TMP/home-$1" repo="$TMP/clone-$1" s="$3"
  s="${s//<repo-path>/$repo}"
  s="${s//<machine-name>/$2}"
  HOME="$home" PATH="$TMP/bin:$PATH" $BLOCK_SH -c "$s" >>"$TMP/out" 2>&1
}
backup() {  # $1 label — every block in skill order; returns non-zero at the first failure
  local name rc=0
  : > "$TMP/out"
  name="$(HOME="$TMP/home-$1" PATH="$TMP/bin:$PATH" $BLOCK_SH -c "$RESOLVE" 2>>"$TMP/out")" || return 1
  for b in "$SWITCH" "$STEP2" "$COPY" "$COMMIT" "$PUSH"; do
    run_block "$1" "$name" "$b" || { rc=$?; break; }
  done
  return "$rc"
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
ran() {  # $1 label, rest: backup args — records pass/fail, shows output on failure
  local label="$1"; shift
  if backup "$@"; then
    echo "ok   $label"
  else
    echo "FAIL $label"
    sed 's/^/  | /' "$TMP/out"
    FAILURES=$((FAILURES + 1))
  fi
}
on_origin()  { git -C "$ORIGIN" rev-parse -q --verify "refs/heads/$1"; }
has_file()   { git -C "$ORIGIN" cat-file -e "$1:$2"; }
no_file()    { ! git -C "$ORIGIN" cat-file -e "$1:$2"; }
settings_of() { git -C "$ORIGIN" show "$1:settings.json" | grep -q "/Users/$2/"; }
tip()        { git -C "$ORIGIN" rev-parse "refs/heads/$1" 2>/dev/null || echo none; }

# --- beta's clone holds one 1.2 commit on master that never reached origin --
: > "$TMP/out"
run_block beta - "$STEP2" && run_block beta - "$COPY" && run_block beta - "$COMMIT"
STRANDED="$(git -C "$TMP/clone-beta" rev-parse HEAD)"
check "setup: beta has an unpushed 1.2 commit"         test "$STRANDED" != "$SEED"

# --- alpha, then beta -------------------------------------------------------
ran "alpha run 1 succeeds"                              alpha
ALPHA_1="$(tip machines/alpha)"
# A clone that already holds machines/alpha from this point: a second machine
# that once backed up as alpha and has fallen behind it.
git clone -q -b machines/alpha "$ORIGIN" "$TMP/clone-gamma"
mk_machine gamma alpha

ran "beta run 1 succeeds (push not rejected)"           beta
check "beta run 1 had nothing new to commit"            grep -qx no-change "$TMP/out"
check "origin holds machines/alpha"                     on_origin machines/alpha
check "origin holds machines/beta"                      on_origin machines/beta
check "beta's stranded 1.2 commit reached origin"       git -C "$ORIGIN" merge-base --is-ancestor "$STRANDED" machines/beta
check "origin master is untouched"                      test "$(tip master)" = "$SEED"
check "machines/alpha has alpha's settings.json"        settings_of machines/alpha alpha
check "machines/beta has beta's settings.json"          settings_of machines/beta beta
check "machines/alpha has alpha's own skill"            has_file machines/alpha skills/alpha-only/SKILL.md
check "machines/alpha lacks beta's skill"               no_file machines/alpha skills/beta-only/SKILL.md
check "machines/beta has beta's own skill"              has_file machines/beta skills/beta-only/SKILL.md
check "machines/beta lacks alpha's skill"               no_file machines/beta skills/alpha-only/SKILL.md
check "master has neither machine's settings"           no_file master settings.json
check "machines/alpha dropped the legacy commands/"     no_file machines/alpha commands/old.md
check "machines/beta dropped the legacy commands/"      no_file machines/beta commands/old.md
check "machines/alpha dropped settings.local.json"      no_file machines/alpha settings.local.json
check "machines/beta dropped settings.local.json"       no_file machines/beta settings.local.json

# --- each again, after an edit ----------------------------------------------
printf '{"permissions":{"allow":["Read(/Users/alpha/**)","Bash(ls)"]}}\n' > "$TMP/home-alpha/.claude/settings.json"
ran "alpha run 2 succeeds"                              alpha
check "alpha run 2 committed"                           grep -qx committed "$TMP/out"
ALPHA_2="$(tip machines/alpha)"
check "alpha run 2 moved machines/alpha"                test "$ALPHA_2" != "$ALPHA_1"
check "alpha run 2 was a fast-forward"                  git -C "$ORIGIN" merge-base --is-ancestor "$ALPHA_1" "$ALPHA_2"
check "machines/alpha carries the edit"                 bash -c 'git -C "$1" show machines/alpha:settings.json | grep -q "Bash(ls)"' _ "$ORIGIN"
printf '{"permissions":{"allow":["Read(/Users/beta/**)","Bash(pwd)"]}}\n' > "$TMP/home-beta/.claude/settings.json"
ran "beta run 2 succeeds"                               beta
check "beta run 2 committed"                            grep -qx committed "$TMP/out"
check "machines/beta carries beta's edit"               bash -c 'git -C "$1" show machines/beta:settings.json | grep -q "Bash(pwd)"' _ "$ORIGIN"
check "machines/alpha did not get beta's edit"          bash -c '! git -C "$1" show machines/alpha:settings.json | grep -q "Bash(pwd)"' _ "$ORIGIN"
check "alpha's clone is on machines/alpha"              test "$(git -C "$TMP/clone-alpha" symbolic-ref --short HEAD)" = machines/alpha
check "beta's clone is on machines/beta"                test "$(git -C "$TMP/clone-beta" symbolic-ref --short HEAD)" = machines/beta

# --- other clones reusing the name alpha are stopped, never merged ----------
# A fresh clone: origin has machines/alpha, this clone never created it. The
# two-Macs-with-one-default-hostname case, and a restore of alpha's branch
# followed by a backup under the same derived name.
git clone -q "$ORIGIN" "$TMP/clone-delta"
mk_machine delta alpha
if backup delta; then RC=0; else RC=1; fi
check "a fresh clone reusing alpha is stopped"          test "$RC" -ne 0
check "it stopped before committing anything"           bash -c '! grep -qx committed "$1"' _ "$TMP/out"
check "its stop message names the machine key"          grep -q '"machine"' "$TMP/out"
check "origin machines/alpha did not move (fresh)"      test "$(tip machines/alpha)" = "$ALPHA_2"

# A clone holding an older local machines/alpha it never created.
if backup gamma; then RC=0; else RC=1; fi
check "a stale clone reusing alpha is stopped"          test "$RC" -ne 0
check "it stopped before committing anything (stale)"   bash -c '! grep -qx committed "$1"' _ "$TMP/out"
check "origin machines/alpha did not move (stale)"      test "$(tip machines/alpha)" = "$ALPHA_2"

# The same stale clone after someone claims the branch for it by hand (the
# re-clone instruction followed on the wrong machine): the push is the
# backstop, rejected and reported as a name collision.
git -C "$TMP/clone-gamma" config settings-sync.branch machines/alpha
if backup gamma; then RC=0; else RC=1; fi
check "a claimed stale clone is stopped"                test "$RC" -ne 0
check "it was stopped at the push, after its commit"    grep -qx committed "$TMP/out"
check "the push stop names the machine key"             grep -q '"machine"' "$TMP/out"
check "origin machines/alpha did not move (claimed)"    test "$(tip machines/alpha)" = "$ALPHA_2"
check "origin holds only master and the two machines"   test "$(git -C "$ORIGIN" for-each-ref --format='%(refname:short)' refs/heads | tr '\n' ' ')" = "machines/alpha machines/beta master "

# A clone made before alpha ever pushed: only the backup's own fetch shows it
# that machines/alpha now exists.
mk_machine epsilon alpha
if backup epsilon; then RC=0; else RC=1; fi
check "an older clone reusing alpha is stopped"         test "$RC" -ne 0
check "it stopped before committing anything (older)"   bash -c '! grep -qx committed "$1"' _ "$TMP/out"
check "origin machines/alpha did not move (older)"      test "$(tip machines/alpha)" = "$ALPHA_2"

# --- someone edits alpha's branch by hand; alpha recovers --------------------
# The owning machine is now behind its own branch, so its push is rejected on
# every run. The skill's documented recovery — realign the clone once — has to
# put it back in business, keeping the hand edit.
git clone -q -b machines/alpha "$ORIGIN" "$TMP/hand"
echo note > "$TMP/hand/NOTES.md"
git -C "$TMP/hand" add NOTES.md && git -C "$TMP/hand" commit -q -m "hand edit" && git -C "$TMP/hand" push -q origin machines/alpha
HAND="$(tip machines/alpha)"
printf '{"permissions":{"allow":["Read(/Users/alpha/**)","Bash(ls)","Bash(pwd)"]}}\n' > "$TMP/home-alpha/.claude/settings.json"
if backup alpha; then RC=0; else RC=1; fi
check "alpha behind its edited branch is stopped"       test "$RC" -ne 0
check "origin machines/alpha kept the hand edit"        test "$(tip machines/alpha)" = "$HAND"
git -C "$TMP/clone-alpha" fetch -q origin && git -C "$TMP/clone-alpha" reset -q --hard origin/machines/alpha
ran "after realigning, alpha's backup succeeds"         alpha
check "the realigned push was a fast-forward"           git -C "$ORIGIN" merge-base --is-ancestor "$HAND" machines/alpha
check "the hand edit survived"                          has_file machines/alpha NOTES.md
check "alpha's newest settings arrived"                 bash -c 'git -C "$1" show machines/alpha:settings.json | grep -q "Bash(pwd)"' _ "$ORIGIN"

# --- a switch git refuses stops the run -------------------------------------
# alpha's clone left on beta's branch (a restore) with a conflicting edit: the
# switch back must fail the run, not carry on writing to beta's branch.
git -C "$TMP/clone-alpha" switch -q machines/beta
echo dirty >> "$TMP/clone-alpha/settings.json"
BETA_TIP="$(tip machines/beta)"
if backup alpha; then RC=0; else RC=1; fi
check "a refused switch stops the backup"               test "$RC" -ne 0
check "the clone stayed on machines/beta"               test "$(git -C "$TMP/clone-alpha" symbolic-ref --short HEAD)" = machines/beta
check "nothing was committed to beta's branch"          test "$(tip machines/beta)" = "$BETA_TIP"

echo
if [ "$FAILURES" -ne 0 ]; then
  echo "FAIL ($FAILURES)"
  exit 1
fi
echo "PASS"
