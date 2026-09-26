#!/usr/bin/env bash
set -euo pipefail

# Every path that pushes a branch for a PR — ship, pr-agent, and their
# background mirrors — syncs with the base branch first. A branch cut before
# other PRs merged can describe behavior that no longer exists, and its
# CHANGELOG entry conflicts at merge time; both surfaced repeatedly in usage
# insights. ship-autonomous delegates to pr-agent, so it is covered through it.
#
# Contract per file: the sync step exists, comes before the push step, fetches,
# rebases an unpushed branch, merges (never force-pushes) a pushed one, and
# aborts on a conflict it cannot resolve. The foreground skills resolve a
# CHANGELOG-only conflict themselves; the agents are denied Edit, so they abort.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GA="$ROOT/kit/plugins/git-agent"
FAILURES=0
pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

# Section body from a heading matching $2 up to the next heading of any level.
section() { awk -v re="$2" '$0 ~ re {f=1; next} f && /^#+ /{exit} f' "$1"; }

SYNC_RE='^#+ Step [0-9.]+: Sync With Base$'
PUSH_RE='^#+ Step [0-9.]+: Push'

echo "=== sync with base before push ==="

for rel in skills/ship/SKILL.md skills/pr-agent/SKILL.md agents/agent-ship.md agents/agent-pr.md; do
  f="$GA/$rel"
  echo "$rel"

  sync_line=$(grep -n -E "$SYNC_RE" "$f" | head -1 | cut -d: -f1 || true)
  push_line=$(grep -n -E "$PUSH_RE" "$f" | head -1 | cut -d: -f1 || true)
  if [ -z "$sync_line" ]; then fail "no 'Sync With Base' step heading"; continue; fi
  if [ -n "$push_line" ] && [ "$sync_line" -lt "$push_line" ]; then pass; else
    fail "sync step (line $sync_line) must precede the push step (line ${push_line:-none})"
  fi

  body=$(section "$f" "$SYNC_RE")
  # ship's core is word-capped, so its procedure lives in a reference file.
  if [ "$rel" = skills/ship/SKILL.md ]; then
    ref="$GA/skills/ship/references/sync-with-base.md"
    if printf '%s\n' "$body" | grep -qF "references/sync-with-base.md" && [ -f "$ref" ]; then
      body=$(cat "$ref")
    else
      fail "Step must link references/sync-with-base.md, and that file must exist"; continue
    fi
  fi

  for needle in "git fetch origin" "git rebase origin/" "git merge --no-edit origin/" "--abort"; do
    printf '%s\n' "$body" | grep -qF -- "$needle" && pass || fail "section lacks \`$needle\`"
  done
  printf '%s\n' "$body" | grep -q -- "--force" && fail "section must never force-push" || pass

  # "Pushed" is decided by the remote branch ref, not @{u}: a worktree branch
  # cut with `git worktree add -b <b> origin/<base>` tracks origin/<base>, so
  # @{u} exits 0 on a branch that was never pushed.
  printf '%s\n' "$body" | grep -qF "refs/remotes/origin/" && pass ||
    fail "pushed-or-not must check refs/remotes/origin/<branch>, not @{u}"

  case "$rel" in
    skills/*) printf '%s\n' "$body" | grep -q "CHANGELOG" && pass || fail "skill must resolve CHANGELOG-only conflicts" ;;
  esac

  # pr-agent never commits the working tree, so it can start dirty — and
  # `git merge --abort` cannot always restore uncommitted changes.
  case "$rel" in
    *pr-agent*|*agent-pr*) printf '%s\n' "$body" | grep -qF -- "--untracked-files=no" && pass ||
      fail "must skip the sync when tracked changes are uncommitted" ;;
  esac
done

if [ "$FAILURES" -eq 0 ]; then echo "All checks passed."; else echo "$FAILURES check(s) failed."; exit 1; fi
