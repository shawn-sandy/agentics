#!/usr/bin/env bash
set -euo pipefail

# Contract tests for the git-agent post-merge-cleanup skill.
#
# The objective test is the first one: a cleanable branch whose worktree holds
# an uncommitted file must survive cleanup with the file byte-identical. That
# assertion is the whole point of the skill — if the orphan check ever moves
# after the removal, or someone adds --force, this is what goes red.
#
# The fixture is a real throwaway git repo under mktemp -d, not a mock, because
# the property under test is git's own refusal to remove a dirty worktree. A
# mock would assert our belief about git rather than git's actual behaviour.
#
# The forbidden-flag checks scan *fenced code blocks only*. The safety contract
# has to name `--force` in order to forbid it, so a naive grep over the whole
# file would fail on a correctly written skill. Prose is a mention; a code block
# is an invocation.
#
# SCOPE — what this does and does not cover. A skill is a markdown prompt, not
# executable code, so this harness does not run the skill through a model. It
# tests two things instead: (1) the git behaviours the skill's safety design
# depends on, so a future git that stopped refusing dirty worktrees would go red
# here rather than silently in production, and (2) that the skill's documented
# commands and prohibitions actually say what the contract claims. Behavioural
# coverage of the prompt itself belongs in tests/plugins/test-skill-behavior-
# baselines.sh, which needs the `claude` CLI and is local-only.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL_DIR="$ROOT/kit/plugins/git-agent/skills/post-merge-cleanup"

PASS=0
FAIL=0
check() { # check <description> <0|1>
  if [ "$2" = "1" ]; then printf '  ok   %s\n' "$1"; PASS=$((PASS + 1))
  else printf '  FAIL %s\n' "$1"; FAIL=$((FAIL + 1)); fi
}

TMP=""
cleanup() { [ -n "$TMP" ] && [ -d "$TMP" ] && chmod -R u+w "$TMP" 2>/dev/null; [ -n "$TMP" ] && rm -rf "$TMP"; }
trap cleanup EXIT

echo "=== post-merge-cleanup contract ==="

# --- Gate: the skill must exist -------------------------------------------
for f in "$SKILL_DIR/SKILL.md" \
         "$SKILL_DIR/references/detection.md" \
         "$SKILL_DIR/references/sweep.md" \
         "$SKILL_DIR/references/stale-directories.md"; do
  [ -f "$f" ] || { echo "missing required file: $f"; exit 1; }
done

# --- Fixture ---------------------------------------------------------------
TMP="$(mktemp -d)"
REPO="$TMP/repo"
WTROOT="$REPO/.worktrees"
mkdir -p "$REPO"

git -C "$REPO" init -q -b main
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config user.name "Test"
echo seed > "$REPO/seed.txt"
# Keep the worktrees root out of the index. Without this, a later `add -A`
# stages the nested checkouts and git emits embedded-repository warnings that
# bury the actual test output.
echo '.worktrees/' > "$REPO/.gitignore"
git -C "$REPO" add -A && git -C "$REPO" commit -qm "seed"

mkdir -p "$WTROOT"

# ancestry-merged branch, worktree left DIRTY (one untracked file)
git -C "$REPO" branch dirty-branch
git -C "$REPO" worktree add -q "$WTROOT/dirty" dirty-branch
printf 'precious unsaved work\n' > "$WTROOT/dirty/notes.txt"
DIRTY_SUM_BEFORE="$(shasum -a 256 < "$WTROOT/dirty/notes.txt")"

# ancestry-merged branch, worktree CLEAN
git -C "$REPO" branch clean-branch
git -C "$REPO" worktree add -q "$WTROOT/clean" clean-branch

# a branch that is NOT an ancestor of main (stands in for squash-merged)
git -C "$REPO" checkout -q -b squashy
echo squashed > "$REPO/feature.txt"
git -C "$REPO" add -A && git -C "$REPO" commit -qm "feature work"
git -C "$REPO" checkout -q main

# --- 1. OBJECTIVE: a dirty worktree survives, file byte-identical ----------
# The documented flow refuses when `git status --porcelain` is non-empty.
DIRTY_STATUS="$(git -C "$WTROOT/dirty" status --porcelain)"
if [ -n "$DIRTY_STATUS" ]; then
  # Skill must NOT remove it. Prove the unforced command git is told to use
  # actually refuses, which is the property the ordering relies on.
  if git -C "$REPO" worktree remove "$WTROOT/dirty" 2>/dev/null; then
    check "unforced worktree remove refuses a dirty worktree" 0
  else
    check "unforced worktree remove refuses a dirty worktree" 1
  fi
else
  check "fixture produced a dirty worktree" 0
fi
check "OBJECTIVE: dirty worktree still on disk after cleanup" \
  "$([ -d "$WTROOT/dirty" ] && echo 1 || echo 0)"
check "OBJECTIVE: uncommitted file byte-identical" \
  "$([ "$(shasum -a 256 < "$WTROOT/dirty/notes.txt")" = "$DIRTY_SUM_BEFORE" ] && echo 1 || echo 0)"
check "OBJECTIVE: blocked branch not deleted" \
  "$(git -C "$REPO" show-ref --verify -q refs/heads/dirty-branch && echo 1 || echo 0)"

# --- 2. The gate blocks dirty trees specifically, not everything -----------
git -C "$REPO" worktree remove "$WTROOT/clean" 2>/dev/null \
  && check "clean worktree IS removed (gate is not blanket-deny)" 1 \
  || check "clean worktree IS removed (gate is not blanket-deny)" 0
git -C "$REPO" branch -d clean-branch >/dev/null 2>&1 \
  && check "ancestry-merged branch deletes with -d" 1 \
  || check "ancestry-merged branch deletes with -d" 0

# --- 3. Dirty gate covers staged and unstaged, not just untracked ----------
git -C "$REPO" worktree add -q "$WTROOT/staged" -b staged-branch
echo tracked > "$WTROOT/staged/tracked.txt"
git -C "$WTROOT/staged" add tracked.txt
check "staged-only change blocks (porcelain non-empty)" \
  "$([ -n "$(git -C "$WTROOT/staged" status --porcelain)" ] && echo 1 || echo 0)"

git -C "$WTROOT/staged" commit -qm "add tracked"
echo modified >> "$WTROOT/staged/tracked.txt"
check "unstaged-only change blocks (porcelain non-empty)" \
  "$([ -n "$(git -C "$WTROOT/staged" status --porcelain)" ] && echo 1 || echo 0)"

# --- 4. Ancestry cannot see a non-ancestor branch (the squash premise) -----
git -C "$REPO" branch --merged main --format='%(refname:short)' | grep -qx squashy \
  && check "ancestry test does NOT list a non-ancestor branch" 0 \
  || check "ancestry test does NOT list a non-ancestor branch" 1
git -C "$REPO" branch -d squashy >/dev/null 2>&1 \
  && check "-d refuses a non-ancestor branch (so -D is required)" 0 \
  || check "-d refuses a non-ancestor branch (so -D is required)" 1

# --- 5. Containment: paths outside the worktrees root are rejected ---------
contained() { # contained <dir> <root>
  local d r
  d="$(cd "$1" 2>/dev/null && pwd -P)/" || return 1
  r="$(cd "$2" 2>/dev/null && pwd -P)"
  case "$d" in "$r"/*) return 0 ;; *) return 1 ;; esac
}
mkdir -p "$TMP/outside"
contained "$WTROOT/dirty" "$WTROOT" \
  && check "path inside the worktrees root is accepted" 1 \
  || check "path inside the worktrees root is accepted" 0
contained "$TMP/outside" "$WTROOT" \
  && check "sibling path outside the root is rejected" 0 \
  || check "sibling path outside the root is rejected" 1
mkdir -p "$WTROOT/../escape"
contained "$WTROOT/../escape" "$WTROOT" \
  && check "traversal path is rejected after pwd -P resolution" 0 \
  || check "traversal path is rejected after pwd -P resolution" 1

# --- 6. Still-registered / admin-dir-bearing dirs are not rm candidates ----
REGISTERED="$(git -C "$REPO" worktree list --porcelain | awk '/^worktree /{print $2}' | grep -c "$WTROOT" || true)"
check "registered worktrees are visible to the detection command" \
  "$([ "$REGISTERED" -ge 1 ] && echo 1 || echo 0)"
check "a registered dir retains its admin directory" \
  "$([ -d "$REPO/.git/worktrees/staged" ] && echo 1 || echo 0)"

# --- 7. Forbidden flags: fenced code blocks only ---------------------------
# Extract fenced blocks, then scan those. Prose prohibitions must not fail.
code_blocks() { awk '/^```/{f=!f; next} f' "$1"; }

FORCE_HITS=0
DASHD_HITS=0
while IFS= read -r f; do
  blocks="$(code_blocks "$f")"
  printf '%s' "$blocks" | grep -qE 'worktree +remove +(--force|-f)\b' && FORCE_HITS=$((FORCE_HITS + 1))
  printf '%s' "$blocks" | grep -qE 'branch +-D\b'                     && DASHD_HITS=$((DASHD_HITS + 1))
done < <(find "$SKILL_DIR" -name '*.md')

check "no fenced code block invokes 'worktree remove --force'" \
  "$([ "$FORCE_HITS" -eq 0 ] && echo 1 || echo 0)"
check "no fenced code block invokes a bare 'branch -D'" \
  "$([ "$DASHD_HITS" -eq 0 ] && echo 1 || echo 0)"

# The prohibition must actually be stated somewhere in prose.
grep -q 'Never `git worktree remove --force`' "$SKILL_DIR/SKILL.md" \
  && check "safety contract states the --force prohibition in prose" 1 \
  || check "safety contract states the --force prohibition in prose" 0

# --- 7b. Documented commands must be portable ------------------------------
# `-newermt '-90 days'` is a GNU extension. BSD find rejects it and bfs (a
# common macOS replacement) errors with "Invalid timestamp". This fired for
# real during end-to-end verification, so it is pinned here.
PORT_HITS=0
while IFS= read -r f; do
  code_blocks "$f" | grep -qE -- "-newermt +['\"]?-[0-9]" && PORT_HITS=$((PORT_HITS + 1))
done < <(find "$SKILL_DIR" -name '*.md')
check "no GNU-only 'find -newermt <relative>' in a code block" \
  "$([ "$PORT_HITS" -eq 0 ] && echo 1 || echo 0)"

# The portable form the skill actually documents must still work here.
PORTDIR="$TMP/portcheck"; mkdir -p "$PORTDIR"; echo x > "$PORTDIR/f.txt"
find "$PORTDIR" -type f -mtime -90 -print >/dev/null 2>&1 \
  && check "documented 'find -mtime -90' runs on this platform" 1 \
  || check "documented 'find -mtime -90' runs on this platform" 0

# --- 8. Documented contracts the flows depend on --------------------------
grep -q 'pwd -P' "$SKILL_DIR/references/stale-directories.md" \
  && check "stale-directories documents pwd -P containment" 1 \
  || check "stale-directories documents pwd -P containment" 0
grep -q 'never the default option' "$SKILL_DIR/references/sweep.md" \
  && check "sweep documents batch approval is never the default" 1 \
  || check "sweep documents batch approval is never the default" 0
grep -q 'known-incomplete\|incomplete' "$SKILL_DIR/references/detection.md" \
  && check "detection documents the degraded-mode incompleteness warning" 1 \
  || check "detection documents the degraded-mode incompleteness warning" 0
grep -q 'cd. out first\|cd` out first' "$SKILL_DIR/SKILL.md" \
  && check "SKILL documents the self-deletion refusal" 1 \
  || check "SKILL documents the self-deletion refusal" 0

echo
echo "passed: $PASS   failed: $FAIL"
[ "$FAIL" -eq 0 ]
