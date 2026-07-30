#!/usr/bin/env bash
# Fixed scenario input: builds a throwaway git sandbox with a dirty working tree
# that conflicts with a checkout, for the branch-agent and ship-autonomous
# behavioral baselines.
#
# Usage: bash dirty-tree.sh <target-dir>
#
# Resulting state:
#   <target>/            git repo on main, one commit ("initial"), remote origin
#   <target>/../origin.git   bare remote with main pushed
#   tracked.txt          committed as "original", modified to "local edit" (unstaged)
#   keep.txt             committed as "untouched", clean
#   scratch.txt          untracked, contains "scratch"

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <target-dir>" >&2
  exit 1
fi

TARGET=$1

# Normalize to an absolute path without requiring the directory to exist.
case "$TARGET" in
  /*) ;;
  *) TARGET="$PWD/$TARGET" ;;
esac

# Destructive-path guard: `rm -rf` below only ever runs inside a temp root or a
# path with a whole `sandbox` component.
#
# Deliberately NOT `*sandbox*`. The substring form accepts any path merely
# containing those letters, so a real project at ~/work/sandbox-experiments/live
# would qualify for rm -rf. Only a complete path component counts.
#
# The temp roots are listed explicitly rather than assumed to be /tmp: on macOS
# `mktemp -d` honours TMPDIR (/var/folders/...), and `pwd -P` then resolves that
# to /private/var/..., so both spellings have to be allowed or the sibling
# origin.git cleanup below is refused on a re-run.
TMP_ROOTS="/tmp /private/tmp"
if [ -n "${TMPDIR:-}" ]; then
  TMP_ROOTS="$TMP_ROOTS ${TMPDIR%/}"
  if RESOLVED_TMP=$(cd "$TMPDIR" 2>/dev/null && pwd -P); then
    TMP_ROOTS="$TMP_ROOTS $RESOLVED_TMP"
  fi
fi

is_safe_to_remove() {
  case "$1" in
    */sandbox|*/sandbox/*) return 0 ;;
  esac
  for _root in $TMP_ROOTS; do
    case "$1" in
      "$_root"/*) return 0 ;;
    esac
  done
  return 1
}

REFUSAL="not inside a temp root ($TMP_ROOTS) and has no 'sandbox' path component"

if [ -e "$TARGET" ]; then
  if is_safe_to_remove "$TARGET"; then
    rm -rf "$TARGET"
  else
    echo "refusing to remove '$TARGET': $REFUSAL" >&2
    exit 1
  fi
fi

mkdir -p "$TARGET"
# Resolve to the real path so the origin sibling lands next to the real target
# (matters on macOS where /tmp is a symlink to /private/tmp).
TARGET=$(cd "$TARGET" && pwd -P)
ORIGIN="$(dirname "$TARGET")/origin.git"

if [ -e "$ORIGIN" ]; then
  if is_safe_to_remove "$ORIGIN"; then
    rm -rf "$ORIGIN"
  else
    echo "refusing to remove '$ORIGIN': $REFUSAL" >&2
    exit 1
  fi
fi

git init -q -b main "$TARGET" >/dev/null
git -C "$TARGET" config user.email "baseline@example.invalid"
git -C "$TARGET" config user.name "Baseline Harness"
git -C "$TARGET" config commit.gpgsign false

printf 'original\n' > "$TARGET/tracked.txt"
printf 'untouched\n' > "$TARGET/keep.txt"
git -C "$TARGET" add tracked.txt keep.txt
git -C "$TARGET" commit -q -m "initial" >/dev/null

git init -q --bare "$ORIGIN" >/dev/null
git -C "$TARGET" remote add origin "$ORIGIN"
git -C "$TARGET" push -q origin main >/dev/null 2>&1
git -C "$TARGET" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main

# Make the tree dirty in a way a checkout would conflict with.
printf 'local edit\n' > "$TARGET/tracked.txt"
printf 'scratch\n' > "$TARGET/scratch.txt"

echo "SANDBOX READY"
